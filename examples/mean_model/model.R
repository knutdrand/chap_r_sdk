#!/usr/bin/env Rscript
# Unified CHAP CLI example with mean model
#
# This demonstrates the new simplified pattern where model developers only need
# to write business logic functions and one line to enable the CLI.
#
# The CLI automatically handles:
# - Loading CSV files and converting to tsibbles
# - Parsing YAML configuration files
# - Loading saved models
# - Saving results
#
# Usage:
#   Rscript model.R train examples/mean_model/example_data.csv
#   Rscript model.R predict examples/mean_model/example_data.csv examples/mean_model/future_data.csv model.rds
#   Rscript model.R info

library(chap.r.sdk)
library(dplyr)

#' Train mean model
#'
#' Calculates the mean disease cases for each location from the training data.
#' This mean will be used as the prediction for all future time periods.
#'
#' @param training_data A tsibble with columns: time_period, location, disease_cases, and optional covariates
#' @param model_configuration A list with model configuration options (currently unused)
#' @return A model object (list) containing the location means
train_mean_model <- function(training_data, model_configuration = list()) {
  # training_data is already a tsibble - no file I/O needed!

  # Calculate mean disease cases for each location
  # Use as_tibble() to collapse across time dimension
  means <- training_data |>
    as_tibble() |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)

  # Create model object
  model <- list(
    means = means,
    config = model_configuration,
    trained_at = Sys.time()
  )

  # Assign class for potential method dispatch
  class(model) <- c("mean_model", "chap_model")

  return(model)
}

#' Predict with mean model
#'
#' Generates predictions by using the historical mean for each location.
#' Simply joins the future data with the location means from the trained model.
#'
#' @param historic_data A tsibble with historic observations. Note: this may be more
#'   recent than training data. For mean models, refitting is not needed since the
#'   saved model already contains location means. Time series models (e.g., ARIMA)
#'   should typically refit to this data before forecasting - see examples/arima_model/.
#' @param future_data A tsibble with columns: time_period, location, and optional covariates
#' @param saved_model A model object from train_mean_model containing location means
#' @param model_configuration A list with model configuration options (currently unused)
#' @return A tsibble with predictions including a samples list-column
predict_mean_model <- function(historic_data, future_data, saved_model, model_configuration = list()) {
  # All inputs are already loaded - no file I/O needed!

  # Join future data with location means and create predictions with samples column
  predictions <- future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)

  return(predictions)
}

# Configuration schema for the info subcommand
config_schema <- list(
  title = "Mean Model Configuration",
  type = "object",
  description = "Configuration schema for the mean baseline model",
  properties = list(
    smoothing = list(
      type = "number",
      description = "Smoothing parameter (reserved for future use)",
      default = 0.0,
      minimum = 0.0,
      maximum = 1.0
    ),
    min_observations = list(
      type = "integer",
      description = "Minimum number of observations required per location",
      default = 1,
      minimum = 1
    )
  )
)

# Enable CLI with single function call!
# This automatically handles all file I/O, parsing, and subcommand dispatch
if (!interactive()) {
  create_chap_cli(train_mean_model, predict_mean_model, config_schema)
}
