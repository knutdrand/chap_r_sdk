#!/usr/bin/env Rscript
# Fable ETS Model for CHAP
#
# This model uses Exponential Smoothing (ETS) from the fable package for
# forecasting disease cases. ETS models can capture trend and seasonality
# in time series data.
#
# The model follows the REFIT pattern: during prediction, it refits the saved
# model structure to historic_data before forecasting. This ensures the model
# incorporates the most recent observations.
#
# Usage:
#   Rscript model.R train training_data.csv
#   Rscript model.R predict historic.csv future.csv model.rds
#   Rscript model.R info

library(chap.r.sdk)
library(dplyr)
library(fable)
library(tsibble)
library(lubridate)
library(distributional)

#' Interpolate missing values in a numeric vector
#'
#' Uses linear interpolation to fill NA values. Leading/trailing NAs are
#' filled with the nearest non-NA value.
#'
#' @param x A numeric vector
#' @return A numeric vector with NAs interpolated
interpolate_na <- function(x) {
  if (all(is.na(x))) return(rep(0, length(x)))
  if (!any(is.na(x))) return(x)

  # Get indices of non-NA values
  non_na_idx <- which(!is.na(x))

  # Use approx for interpolation
  result <- approx(non_na_idx, x[non_na_idx], xout = seq_along(x), rule = 2)$y
  return(result)
}

#' Train ETS model with covariates
#'
#' Fits an ETS (Error-Trend-Seasonality) model for each location.
#' Can optionally use lagged climate covariates as regressors.
#'
#' @param training_data A tsibble with columns: time_period, location,
#'   disease_cases, and optional covariates (rainfall, mean_temperature)
#' @param model_configuration A list with model configuration options:
#'   \itemize{
#'     \item \code{n_samples}: Number of Monte Carlo samples (default: 100)
#'     \item \code{seasonal_period}: Seasonal period (default: 12 for monthly)
#'     \item \code{use_covariates}: Whether to use climate covariates (default: TRUE)
#'     \item \code{covariate_lag}: Lag for covariates in months (default: 1)
#'   }
#' @param run_info Run information from CHAP (optional)
#' @return A list containing fitted ETS models for each location
train_ets <- function(training_data, model_configuration = list(),
                      run_info = list()) {
  # Get configuration parameters
  n_samples <- model_configuration$n_samples %||% 100
  seasonal_period <- model_configuration$seasonal_period %||% 12
  use_covariates <- model_configuration$use_covariates %||% TRUE
  covariate_lag <- model_configuration$covariate_lag %||% 1

  # Get unique locations
  locations <- unique(training_data$location)
  models <- list()
  location_means <- list()

  # Check if covariates are available
  has_rainfall <- "rainfall" %in% names(training_data)
  has_temperature <- "mean_temperature" %in% names(training_data)
  use_xreg <- use_covariates && (has_rainfall || has_temperature)

  for (loc in locations) {
    # Filter to single location
    loc_data <- training_data |>
      filter(location == loc) |>
      as_tibble() |>
      arrange(time_period)

    # Interpolate missing values (ETS doesn't support NAs)
    loc_data <- loc_data |>
      mutate(disease_cases = interpolate_na(disease_cases))

    # Add lagged covariates if available and requested
    if (use_xreg && has_rainfall) {
      loc_data <- loc_data |>
        mutate(
          rainfall = interpolate_na(rainfall),
          rainfall_lag = lag(rainfall, covariate_lag)
        )
    }
    if (use_xreg && has_temperature) {
      loc_data <- loc_data |>
        mutate(
          mean_temperature = interpolate_na(mean_temperature),
          temp_lag = lag(mean_temperature, covariate_lag)
        )
    }

    # Remove rows with NA in lagged covariates
    if (use_xreg) {
      loc_data <- loc_data |> filter(!is.na(rainfall_lag) | !is.na(temp_lag))
    }

    # Store mean for fallback predictions
    location_means[[loc]] <- mean(loc_data$disease_cases, na.rm = TRUE)

    # Convert to tsibble with yearmonth index for proper time series handling
    loc_tsibble <- loc_data |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # Fit ETS model (ETS doesn't support external regressors, so we use ARIMA with xreg)
    model <- tryCatch({
      if (use_xreg && has_rainfall && has_temperature) {
        # Use ARIMA with covariates for better forecasting
        loc_tsibble |>
          model(
            model = ARIMA(disease_cases ~ rainfall_lag + temp_lag)
          )
      } else if (use_xreg && has_rainfall) {
        loc_tsibble |>
          model(model = ARIMA(disease_cases ~ rainfall_lag))
      } else {
        # Fallback to ETS without covariates
        loc_tsibble |>
          model(model = ETS(disease_cases))
      }
    }, error = function(e) {
      # Fallback to simpler model if fitting fails
      message(sprintf("Model fitting failed for location %s: %s. Using mean model.", loc, e$message))
      loc_tsibble |>
        model(model = MEAN(disease_cases))
    })

    models[[loc]] <- model
  }

  # Return model object with metadata
  list(
    models = models,
    location_means = location_means,
    n_samples = n_samples,
    seasonal_period = seasonal_period,
    use_covariates = use_xreg,
    covariate_lag = covariate_lag,
    has_rainfall = has_rainfall,
    has_temperature = has_temperature,
    trained_at = Sys.time()
  )
}

#' Predict with ETS/ARIMA model
#'
#' Generates predictions by REFITTING the saved model to historic_data
#' before forecasting. This is essential for time series models because
#' historic_data may contain more recent observations than training_data.
#'
#' The workflow is:
#' 1. Prepare historic data with lagged covariates if needed
#' 2. Prepare future data with covariate values
#' 3. Refit the saved model structure to historic data
#' 4. Forecast the future periods
#' 5. Generate samples from the forecast distribution
#' 6. Ensure all samples are non-negative (CHAP requirement)
#'
#' @param historic_data A tsibble with historic observations.
#' @param future_data A tsibble with time periods to predict
#' @param saved_model A model object from train_ets
#' @param model_configuration A list with model configuration options
#' @param run_info Run information from CHAP (optional)
#' @return A tibble with predictions including a samples list-column
predict_ets <- function(historic_data, future_data, saved_model,
                        model_configuration = list(), run_info = list()) {

  n_samples <- saved_model$n_samples
  locations <- names(saved_model$models)
  use_covariates <- saved_model$use_covariates %||% FALSE
  covariate_lag <- saved_model$covariate_lag %||% 1
  has_rainfall <- saved_model$has_rainfall %||% FALSE
  has_temperature <- saved_model$has_temperature %||% FALSE

  all_predictions <- list()

  for (loc in locations) {
    # Get data for this location
    historic_loc <- historic_data |>
      filter(location == loc) |>
      as_tibble() |>
      arrange(time_period)

    future_loc <- future_data |>
      filter(location == loc) |>
      as_tibble() |>
      arrange(time_period)

    # Number of periods to forecast
    h <- nrow(future_loc)

    # Interpolate missing values in historic data
    historic_loc <- historic_loc |>
      mutate(disease_cases = interpolate_na(disease_cases))

    # Prepare lagged covariates for historic data
    if (use_covariates && has_rainfall) {
      historic_loc <- historic_loc |>
        mutate(
          rainfall = interpolate_na(rainfall),
          rainfall_lag = lag(rainfall, covariate_lag)
        )
    }
    if (use_covariates && has_temperature) {
      historic_loc <- historic_loc |>
        mutate(
          mean_temperature = interpolate_na(mean_temperature),
          temp_lag = lag(mean_temperature, covariate_lag)
        )
    }

    # Prepare future data with lagged covariates from the tail of historic
    if (use_covariates) {
      # Get the last covariate_lag values from historic for lagged covariates in future
      if (has_rainfall) {
        future_loc <- future_loc |>
          mutate(rainfall = interpolate_na(rainfall))
        last_rainfall <- tail(historic_loc$rainfall, covariate_lag)
        future_rainfall_lag <- c(last_rainfall, head(future_loc$rainfall, h - covariate_lag))
        future_loc$rainfall_lag <- future_rainfall_lag[1:h]
      }
      if (has_temperature) {
        future_loc <- future_loc |>
          mutate(mean_temperature = interpolate_na(mean_temperature))
        last_temp <- tail(historic_loc$mean_temperature, covariate_lag)
        future_temp_lag <- c(last_temp, head(future_loc$mean_temperature, h - covariate_lag))
        future_loc$temp_lag <- future_temp_lag[1:h]
      }

      # Remove rows with NA in lagged covariates from historic
      if (has_rainfall || has_temperature) {
        historic_loc <- historic_loc |>
          filter(
            (!has_rainfall | !is.na(rainfall_lag)) &
            (!has_temperature | !is.na(temp_lag))
          )
      }
    }

    # Get fallback mean for this location
    fallback_mean <- saved_model$location_means[[loc]] %||% 0

    # Convert to tsibble with yearmonth index
    historic_tsibble <- historic_loc |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    future_tsibble <- future_loc |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # KEY STEP: Refit the saved model to the historic data
    saved_model_loc <- saved_model$models[[loc]]

    # Attempt to refit and forecast
    samples_list <- tryCatch({
      refitted_model <- refit(saved_model_loc, historic_tsibble)

      # Generate forecasts with new_data for covariates
      if (use_covariates) {
        forecasts <- forecast(refitted_model, new_data = future_tsibble)
      } else {
        forecasts <- forecast(refitted_model, h = h)
      }

      # Extract samples from forecast distribution
      lapply(seq_len(nrow(forecasts)), function(i) {
        dist <- forecasts$disease_cases[i]
        # Get mean and variance from distribution
        mu <- mean(dist)
        sigma <- sqrt(variance(dist))

        # Handle NA or invalid values
        if (is.na(mu)) mu <- fallback_mean
        if (is.na(sigma) || sigma <= 0) {
          # Deterministic forecast - return point estimate
          samples <- rep(max(0, mu), n_samples)
        } else {
          # Sample from normal distribution
          samples <- rnorm(n_samples, mean = mu, sd = sigma)
        }

        # Ensure non-negative values (CHAP contract requirement)
        samples <- pmax(0, samples)
        samples[is.na(samples)] <- max(0, fallback_mean)
        samples
      })
    }, error = function(e) {
      # Fallback: use location mean if forecasting fails
      message(sprintf("Forecast failed for location %s: %s. Using mean.", loc, e$message))
      lapply(seq_len(h), function(i) {
        rep(max(0, fallback_mean), n_samples)
      })
    })

    # Build prediction dataframe
    loc_preds <- future_loc |>
      mutate(samples = samples_list)

    all_predictions[[loc]] <- loc_preds
  }

  # Combine all locations
  bind_rows(all_predictions)
}

# Configuration schema for the info subcommand
config_schema <- list(
  title = "Fable ETS Model Configuration",
  type = "object",
  description = "Configuration for ETS/ARIMA model from fable package with optional climate covariates",
  properties = list(
    n_samples = list(
      type = "integer",
      description = "Number of Monte Carlo samples to generate per forecast",
      default = 100,
      minimum = 1,
      maximum = 10000
    ),
    seasonal_period = list(
      type = "integer",
      description = "Seasonal period for the ETS model (12 for monthly data)",
      default = 12,
      minimum = 1,
      maximum = 52
    ),
    use_covariates = list(
      type = "boolean",
      description = "Whether to use climate covariates (rainfall, temperature) as regressors. When TRUE, uses ARIMA with external regressors instead of ETS.",
      default = FALSE
    ),
    covariate_lag = list(
      type = "integer",
      description = "Lag in months for climate covariates. E.g., lag=1 means this month's disease cases are predicted using last month's weather.",
      default = 1,
      minimum = 0,
      maximum = 6
    )
  )
)

# Model info describing data requirements
model_info <- list(
  period_type = "month",
  allows_additional_continuous_covariates = FALSE,
  required_covariates = character(0)
)

# Helper for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a

# Enable CLI with single function call
# Only run if script is executed directly (not sourced for testing)
if (!interactive() && !isTRUE(getOption("chap.r.sdk.testing"))) {
  create_chap_cli(
    train_fn = train_ets,
    predict_fn = predict_ets,
    model_config_schema = config_schema,
    model_info = model_info
  )
}
