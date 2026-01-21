#!/usr/bin/env Rscript
# Model Comparison for CHAP
#
# This model supports multiple fable forecasting methods for systematic comparison:
# - ETS: Exponential smoothing state space model
# - ARIMA: Auto-selected ARIMA model
# - NNETAR: Neural network with lagged inputs
# - THETA: Theta method (exponential smoothing with drift)
# - SNAIVE: Seasonal naive (baseline benchmark)
# - COMBINATION: Ensemble average of ETS, ARIMA, and THETA
#
# IMPORTANT: This model does NOT use climate covariates from future_data
# because forecasted climate data is typically of low quality.
# Instead, it relies solely on lagged disease case patterns.
#
# Usage:
#   Rscript model.R train training_data.csv
#   Rscript model.R predict historic.csv future.csv model.rds
#   Rscript model.R info

library(chapr)
library(dplyr)
library(fable)
library(tsibble)
library(lubridate)
library(distributional)

# Helper for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a

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

  non_na_idx <- which(!is.na(x))
  result <- approx(non_na_idx, x[non_na_idx], xout = seq_along(x), rule = 2)$y
  return(result)
}

#' Fit a model for a single location
#'
#' @param loc_tsibble A tsibble for a single location
#' @param model_type One of: "ETS", "ARIMA", "NNETAR", "THETA", "SNAIVE", "COMBINATION"
#' @return A fitted mable (model table)
fit_location_model <- function(loc_tsibble, model_type) {
  tryCatch({
    switch(model_type,
      "ETS" = loc_tsibble |> model(model = ETS(disease_cases)),
      "ARIMA" = loc_tsibble |> model(model = ARIMA(disease_cases)),
      "NNETAR" = loc_tsibble |> model(model = NNETAR(disease_cases, n_networks = 10)),
      "THETA" = loc_tsibble |> model(model = THETA(disease_cases)),
      "SNAIVE" = loc_tsibble |> model(model = SNAIVE(disease_cases)),
      "COMBINATION" = loc_tsibble |> model(
        ets = ETS(disease_cases),
        arima = ARIMA(disease_cases),
        theta = THETA(disease_cases)
      ),
      # Default fallback
      loc_tsibble |> model(model = ETS(disease_cases))
    )
  }, error = function(e) {
    message(sprintf("Model fitting failed: %s. Using MEAN model.", e$message))
    loc_tsibble |> model(model = MEAN(disease_cases))
  })
}

#' Train forecasting model
#'
#' Fits the specified model type for each location.
#'
#' @param training_data A data frame with columns: time_period, location, disease_cases
#' @param model_configuration A list with configuration options:
#'   \itemize{
#'     \item \code{model_type}: One of "ETS", "ARIMA", "NNETAR", "THETA", "SNAIVE", "COMBINATION"
#'     \item \code{n_samples}: Number of Monte Carlo samples (default: 100)
#'   }
#' @param run_info Run information from CHAP (optional)
#' @return A list containing fitted models for each location
train_model <- function(training_data, model_configuration = list(),
                        run_info = list()) {
  # Get configuration parameters
  model_type <- toupper(model_configuration$model_type %||% "ETS")
  n_samples <- model_configuration$n_samples %||% 100

  message(sprintf("Training %s model...", model_type))

  # Get unique locations
  locations <- unique(training_data$location)
  models <- list()
  location_means <- list()

  for (loc in locations) {
    # Filter to single location
    loc_data <- training_data |>
      filter(location == loc) |>
      as_tibble() |>
      arrange(time_period)

    # Interpolate missing values
    loc_data <- loc_data |>
      mutate(disease_cases = interpolate_na(disease_cases))

    # Store mean for fallback predictions
    location_means[[loc]] <- mean(loc_data$disease_cases, na.rm = TRUE)

    # Convert to tsibble with yearmonth index
    loc_tsibble <- loc_data |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # Fit the specified model
    models[[loc]] <- fit_location_model(loc_tsibble, model_type)
  }

  # Return model object with metadata
  list(
    models = models,
    location_means = location_means,
    model_type = model_type,
    n_samples = n_samples,
    trained_at = Sys.time()
  )
}

#' Generate samples from a forecast distribution
#'
#' @param dist A distributional object
#' @param n_samples Number of samples to generate
#' @param fallback_mean Fallback value if distribution is invalid
#' @return A numeric vector of samples
generate_samples <- function(dist, n_samples, fallback_mean) {
  mu <- mean(dist)
  sigma <- sqrt(variance(dist))

  if (is.na(mu)) mu <- fallback_mean
  if (is.na(sigma) || sigma <= 0) {
    samples <- rep(max(0, mu), n_samples)
  } else {
    samples <- rnorm(n_samples, mean = mu, sd = sigma)
  }

  # Ensure non-negative values (CHAP contract requirement)
  samples <- pmax(0, samples)
  samples[is.na(samples)] <- max(0, fallback_mean)
  samples
}

#' Predict with trained model
#'
#' Generates predictions by REFITTING the saved model to historic_data
#' before forecasting. This ensures the model uses the most recent observations.
#'
#' IMPORTANT: Does NOT use covariates from future_data since climate
#' forecasts are typically low quality.
#'
#' @param historic_data Historic observations
#' @param future_data Time periods to predict
#' @param saved_model A model object from train_model
#' @param model_configuration Configuration options
#' @param run_info Run information from CHAP (optional)
#' @return A tibble with predictions including a samples list-column
predict_model <- function(historic_data, future_data, saved_model,
                          model_configuration = list(), run_info = list()) {

  n_samples <- saved_model$n_samples
  model_type <- saved_model$model_type
  locations <- names(saved_model$models)
  is_combination <- model_type == "COMBINATION"

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

    h <- nrow(future_loc)

    # Interpolate missing values
    historic_loc <- historic_loc |>
      mutate(disease_cases = interpolate_na(disease_cases))

    # Get fallback mean for this location
    fallback_mean <- saved_model$location_means[[loc]] %||% 0

    # Convert to tsibble
    historic_tsibble <- historic_loc |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # Get saved model for location
    saved_model_loc <- saved_model$models[[loc]]

    # Attempt to refit and forecast
    samples_list <- tryCatch({
      refitted_model <- refit(saved_model_loc, historic_tsibble)
      forecasts <- forecast(refitted_model, h = h)

      if (is_combination) {
        # For combination models, average the distributions
        lapply(seq_len(h), function(i) {
          # Get distributions from each component model
          dists <- list(
            forecasts$disease_cases[[1]][i],  # ETS
            forecasts$disease_cases[[2]][i],  # ARIMA
            forecasts$disease_cases[[3]][i]   # THETA
          )

          # Sample from each and average
          all_samples <- sapply(dists, function(d) {
            generate_samples(d, n_samples, fallback_mean)
          })

          # Average across models (each column is a model)
          rowMeans(all_samples, na.rm = TRUE)
        })
      } else {
        # Single model
        lapply(seq_len(nrow(forecasts)), function(i) {
          generate_samples(forecasts$disease_cases[i], n_samples, fallback_mean)
        })
      }
    }, error = function(e) {
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
  title = "Model Comparison Configuration",
  type = "object",
  description = "Configuration for fable model comparison. Supports ETS, ARIMA, NNETAR, THETA, SNAIVE, and COMBINATION models.",
  properties = list(
    model_type = list(
      type = "string",
      description = "The forecasting model to use. Options: ETS (exponential smoothing), ARIMA (auto-selected), NNETAR (neural network), THETA (theta method), SNAIVE (seasonal naive baseline), COMBINATION (ensemble of ETS+ARIMA+THETA)",
      default = "ETS",
      enum = list("ETS", "ARIMA", "NNETAR", "THETA", "SNAIVE", "COMBINATION")
    ),
    n_samples = list(
      type = "integer",
      description = "Number of Monte Carlo samples to generate per forecast",
      default = 100,
      minimum = 1,
      maximum = 10000
    )
  )
)

# Model info describing data requirements
model_info <- list(
  period_type = "month",
  allows_additional_continuous_covariates = FALSE,
  required_covariates = character(0)
)

# Enable CLI with single function call
# Only run if script is executed directly (not sourced for testing)
if (!interactive() && !isTRUE(getOption("chapr.testing"))) {
  create_chap_cli(
    train_fn = train_model,
    predict_fn = predict_model,
    model_config_schema = config_schema,
    model_info = model_info
  )
}
