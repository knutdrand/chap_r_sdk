#!/usr/bin/env Rscript
# CLI wrapper for mean_model training

library(chap.r.sdk)
library(tsibble)
library(dplyr)
library(readr)

#' Train mean model with CLI interface
#'
#' Wrapper function that loads data from files and trains the mean model
#'
#' @param training_data Path to training data CSV file
#' @param model_configuration Path to model configuration YAML file (optional)
#' @return Path to saved model file
train_mean_model_cli <- function(training_data, model_configuration = NULL) {

  # Load training data
  cat("Loading training data from:", training_data, "\n")
  df <- readr::read_csv(training_data, show_col_types = FALSE)

  # Convert to tsibble
  # Assume columns: time_period, location, disease_cases, and optional covariates
  training_tsibble <- tsibble::as_tsibble(
    df,
    index = time_period,
    key = location
  )

  # Load configuration if provided
  config <- if (!is.null(model_configuration) && model_configuration != "") {
    cat("Loading configuration from:", model_configuration, "\n")
    read_model_config(model_configuration, validate = FALSE)
  } else {
    list()
  }

  # Train the model
  cat("Training mean model...\n")
  model <- train_mean_model(training_tsibble, config)

  # Save the model
  model_path <- "mean_model.rds"
  saveRDS(model, model_path)
  cat("Model saved to:", model_path, "\n")

  return(model_path)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_train_cli(train_mean_model_cli)
}
