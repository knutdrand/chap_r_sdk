#!/usr/bin/env Rscript
#' Mean Model Example with Docker Support
#'
#' This example demonstrates a CHAP-compatible model with full Docker and
#' renv environment support. Use this as a template for creating containerized
#' R models.
#'
#' Setup:
#'   1. Run init_chap_env() in R console to initialize renv
#'   2. Run generate_dockerfile() to create Dockerfile
#'   3. Build with: docker build -t mean-model .
#'   4. Run with: docker run -p 8000:8000 mean-model
#'
#' Usage (CLI):
#'   Rscript model.R train --data data.csv [--run-info run_info.yml]
#'   Rscript model.R predict --historic historic.csv --future future.csv --output predictions.csv
#'   Rscript model.R info --format json

library(chapr)
library(dplyr)

#' Train mean model
#'
#' Calculates the mean disease cases for each location from the training data.
#'
#' @param training_data A tsibble with disease_cases column
#' @param model_configuration Model configuration options
#' @param run_info Runtime information from CHAP
#' @return A model object containing location means
train_mean_model <- function(training_data, model_configuration = list(), run_info = list()) {
  message("Training mean model...")
  message("  Locations: ", length(unique(training_data$location)))
  message("  Time periods: ", length(unique(training_data[[tsibble::index_var(training_data)]])))

  # Calculate mean disease cases for each location
  means <- training_data |>
    as_tibble() |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)

  # Create model object
  model <- list(
    means = means,
    config = model_configuration,
    trained_at = Sys.time()
  )

  class(model) <- c("mean_model", "chap_model")

  message("Training complete!")
  return(model)
}

#' Predict with mean model
#'
#' Generates predictions using the historical mean for each location.
#'
#' @param historic_data Historic observations
#' @param future_data Future time periods to predict
#' @param saved_model Trained model from train_mean_model
#' @param model_configuration Model configuration options
#' @param run_info Runtime information from CHAP
#' @return A tibble with predictions including samples column
predict_mean_model <- function(historic_data, future_data, saved_model,
                                model_configuration = list(), run_info = list()) {
  message("Generating predictions...")

  # Join future data with location means
  predictions <- future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)

  message("Predictions complete!")
  return(predictions)
}

# Configuration schema
config_schema <- create_config_schema(
  title = "Mean Model Configuration",
  description = "Configuration for the mean baseline model",
  properties = list(
    smoothing = schema_number(
      description = "Smoothing parameter (reserved for future use)",
      default = 0.0,
      minimum = 0.0,
      maximum = 1.0
    )
  )
)

# Model info for CHAP validation
model_info <- list(
  period_type = "any",
  allows_additional_continuous_covariates = FALSE,
  required_covariates = character(0)
)

# Enable CLI
if (!interactive()) {
  create_chap_cli(
    train_fn = train_mean_model,
    predict_fn = predict_mean_model,
    model_config_schema = config_schema,
    model_info = model_info
  )
}
