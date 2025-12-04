#!/usr/bin/env Rscript
# CLI wrapper for mean_model prediction

library(chap.r.sdk)
library(tsibble)
library(dplyr)
library(readr)

#' Predict with mean model using CLI interface
#'
#' Wrapper function that loads data from files and generates predictions
#'
#' @param historic_data Path to historic data CSV file
#' @param future_data Path to future data CSV file
#' @param saved_model Path to saved model RDS file
#' @param model_configuration Path to model configuration YAML file (optional)
#' @return Path to predictions CSV file
predict_mean_model_cli <- function(historic_data, future_data, saved_model, model_configuration = NULL) {

  # Load historic data
  cat("Loading historic data from:", historic_data, "\n")
  historic_df <- readr::read_csv(historic_data, show_col_types = FALSE)
  historic_tsibble <- tsibble::as_tsibble(
    historic_df,
    index = time_period,
    key = location
  )

  # Load future data
  cat("Loading future data from:", future_data, "\n")
  future_df <- readr::read_csv(future_data, show_col_types = FALSE)
  future_tsibble <- tsibble::as_tsibble(
    future_df,
    index = time_period,
    key = location
  )

  # Load the model
  cat("Loading model from:", saved_model, "\n")
  model <- readRDS(saved_model)

  # Load configuration if provided
  config <- if (!is.null(model_configuration) && model_configuration != "") {
    cat("Loading configuration from:", model_configuration, "\n")
    read_model_config(model_configuration, validate = FALSE)
  } else {
    list()
  }

  # Generate predictions
  cat("Generating predictions...\n")
  predictions <- predict_mean_model(historic_tsibble, future_tsibble, model, config)

  # Save predictions
  predictions_path <- sub("\\.rds$", "_predictions.csv", saved_model)
  readr::write_csv(predictions, predictions_path)
  cat("Predictions saved to:", predictions_path, "\n")

  return(predictions_path)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_predict_cli(predict_mean_model_cli)
}
