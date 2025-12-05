#!/usr/bin/env Rscript
# ARIMA Model Example for CHAP
#
# This example demonstrates the key pattern of REFITTING a time series model
# to historic_data before making predictions. This is necessary because
# historic_data may contain more recent observations than the original
# training data.
#
# The model uses the fable package for ARIMA modeling with exogenous variables
# (rainfall and temperature lags).
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

#' Create lagged feature
#'
#' Creates a lagged version of a column, shifting values forward by the
#' specified number of time periods.
#'
#' @param df A data frame
#' @param feature Name of the column to lag (string)
#' @param lag Number of periods to lag
#' @return Data frame with new lagged column named \code{feature_lag}
create_lagged_feature <- function(df, feature, lag) {
  lag_col_name <- paste0(feature, "_", lag)
  df[[lag_col_name]] <- dplyr::lag(df[[feature]], n = lag)
  return(df)
}

#' Train ARIMA model
#'
#' Fits an ARIMA model with exogenous regressors (lagged rainfall and
#' temperature) for each location. The model structure is stored for
#' later refitting during prediction.
#'
#' @param training_data A tsibble with columns: time_period, location,
#'   disease_cases, rainfall, mean_temperature
#' @param model_configuration A list with model configuration options
#' @return A list of fitted ARIMA models, one per location
train_arima <- function(training_data, model_configuration = list()) {
  # Get lag parameter from config or use default
  lag_periods <- model_configuration$lag_periods %||% 3
  n_samples <- model_configuration$n_samples %||% 100

  # Process each location separately
  locations <- unique(training_data$location)
  models <- list()

  for (loc in locations) {
    # Filter to single location
    loc_data <- training_data |>
      filter(location == loc) |>
      as_tibble() |>
      arrange(time_period)

    # Create lagged features
    loc_data <- loc_data |>
      create_lagged_feature("rainfall", lag_periods) |>
      create_lagged_feature("mean_temperature", lag_periods)

    # Remove rows with NA from lagging
    loc_data <- loc_data |>
      filter(!is.na(.data[[paste0("rainfall_", lag_periods)]]))

    # Convert to tsibble with yearmonth index for proper time series handling
    loc_tsibble <- loc_data |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # Fit ARIMA with exogenous regressors
    rainfall_col <- paste0("rainfall_", lag_periods)
    temp_col <- paste0("mean_temperature_", lag_periods)

    # Build formula dynamically
    formula <- as.formula(paste0(
      "disease_cases ~ ", rainfall_col, " + ", temp_col
    ))

    model <- loc_tsibble |>
      model(arima = ARIMA(formula))

    models[[loc]] <- model
  }

  # Return model object with metadata
  list(
    models = models,
    lag_periods = lag_periods,
    n_samples = n_samples,
    trained_at = Sys.time()
  )
}

#' Predict with ARIMA model
#'
#' Generates predictions by REFITTING the saved model to historic_data
#' before forecasting. This is the key pattern for time series models:
#' historic_data may contain more recent observations than training_data,
#' so the model must be refit to produce accurate forecasts.
#'
#' The workflow is:
#' 1. Combine historic_data and future_data for lag computation
#' 2. Refit the saved model structure to the historic data
#' 3. Forecast the future periods
#' 4. Generate samples from the forecast distribution
#'
#' @param historic_data A tsibble with historic observations. NOTE: This may
#'   contain more recent data than the original training data. The model
#'   will be refit to this data before forecasting.
#' @param future_data A tsibble with time periods to predict
#' @param saved_model A model object from train_arima
#' @param model_configuration A list with model configuration options
#' @return A tibble with predictions including a samples list-column
predict_arima <- function(historic_data, future_data, saved_model,
                          model_configuration = list()) {

  lag_periods <- saved_model$lag_periods
  n_samples <- saved_model$n_samples
  locations <- names(saved_model$models)

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

    # Add placeholder disease_cases to future data for row-binding
    future_loc$disease_cases <- NA

    # Combine historic and future for lag computation
    combined <- bind_rows(historic_loc, future_loc) |>
      create_lagged_feature("rainfall", lag_periods) |>
      create_lagged_feature("mean_temperature", lag_periods) |>
      mutate(time_period = yearmonth(time_period)) |>
      as_tsibble(index = time_period)

    # Split back into historic and future
    n_historic <- nrow(historic_loc)
    historic_tsibble <- combined[1:n_historic, ]
    future_tsibble <- combined[(n_historic + 1):nrow(combined), ]

    # KEY STEP: Refit the saved model to the historic data
    # This updates the model with the most recent observations
    saved_arima <- saved_model$models[[loc]]
    refitted_model <- refit(saved_arima, historic_tsibble)

    # Generate forecasts
    forecasts <- forecast(refitted_model, new_data = future_tsibble)

    # Extract samples from forecast distribution
    samples_list <- lapply(seq_len(nrow(forecasts)), function(i) {
      dist <- forecasts$disease_cases[i]
      # Sample from the forecast distribution
      rnorm(n_samples, mean = mean(dist), sd = sqrt(variance(dist)))
    })

    # Build prediction dataframe
    loc_preds <- future_loc |>
      select(-disease_cases) |>
      mutate(samples = samples_list)

    all_predictions[[loc]] <- loc_preds
  }

  # Combine all locations
  bind_rows(all_predictions)
}

# Configuration schema for the info subcommand
config_schema <- list(
  title = "ARIMA Model Configuration",
  type = "object",
  description = "Configuration for ARIMA model with lagged climate covariates",
  properties = list(
    lag_periods = list(
      type = "integer",
      description = "Number of periods to lag rainfall and temperature",
      default = 3,
      minimum = 1,
      maximum = 12
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

# Enable CLI with single function call
if (!interactive()) {
  create_chap_cli(train_arima, predict_arima, config_schema)
}
