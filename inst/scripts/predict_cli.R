#!/usr/bin/env Rscript

# Predict CLI for CHAP R SDK
# This script provides a command-line interface for making predictions with CHAP models

suppressPackageStartupMessages({
  library(optparse)
  library(tsibble)
  library(dplyr)
  library(readr)
  library(yaml)
})

# Source the model functions
source(file.path(dirname(dirname(dirname(sys.frame(1)$ofile))), "R", "mean_model.R"))

#' Load CSV data and convert to tsibble
#'
#' @param filepath Path to CSV file
#' @return A tsibble
load_data <- function(filepath) {
  data <- readr::read_csv(filepath, show_col_types = FALSE)

  # Convert time_period to yearmonth
  data <- data |>
    dplyr::mutate(
      time_period = tsibble::yearmonth(time_period)
    )

  # Create tsibble with location as key and time_period as index
  ts_data <- tsibble::as_tsibble(
    data,
    index = time_period,
    key = location
  )

  return(ts_data)
}

# Define command-line options
option_list <- list(
  make_option(
    c("-m", "--model"),
    type = "character",
    default = NULL,
    help = "Path to trained model RDS file",
    metavar = "FILE"
  ),
  make_option(
    c("-H", "--historic"),
    type = "character",
    default = NULL,
    help = "Path to historic data CSV file",
    metavar = "FILE"
  ),
  make_option(
    c("-f", "--future"),
    type = "character",
    default = NULL,
    help = "Path to future data CSV file (with covariates)",
    metavar = "FILE"
  ),
  make_option(
    c("-c", "--config"),
    type = "character",
    default = NULL,
    help = "Path to model configuration YAML/JSON file (optional)",
    metavar = "FILE"
  ),
  make_option(
    c("-o", "--output"),
    type = "character",
    default = "predictions.csv",
    help = "Output path for predictions CSV [default= %default]",
    metavar = "FILE"
  )
)

# Parse command-line arguments
opt_parser <- OptionParser(
  usage = "%prog [options]",
  option_list = option_list,
  description = "\nGenerate predictions using a trained CHAP model"
)

opt <- parse_args(opt_parser)

# Validate required arguments
if (is.null(opt$model)) {
  print_help(opt_parser)
  stop("Error: --model argument is required", call. = FALSE)
}

if (is.null(opt$future)) {
  print_help(opt_parser)
  stop("Error: --future argument is required", call. = FALSE)
}

# Load model
cat(sprintf("Loading model from: %s\n", opt$model))
model <- readRDS(opt$model)

# Load configuration (optional)
model_config <- list()
if (!is.null(opt$config)) {
  if (file.exists(opt$config)) {
    if (grepl("\\.ya?ml$", opt$config, ignore.case = TRUE)) {
      model_config <- yaml::read_yaml(opt$config)
    } else if (grepl("\\.json$", opt$config, ignore.case = TRUE)) {
      model_config <- jsonlite::fromJSON(opt$config)
    } else {
      warning("Config file format not recognized (use .yaml or .json). Using empty config.")
    }
  } else {
    warning(sprintf("Config file not found: %s. Using empty config.", opt$config))
  }
}

# Load historic data (optional for mean model, but part of interface)
historic_data <- NULL
if (!is.null(opt$historic)) {
  cat(sprintf("Loading historic data from: %s\n", opt$historic))
  historic_data <- load_data(opt$historic)
  cat(sprintf("Historic data: %d rows\n", nrow(historic_data)))
}

# Load future data
cat(sprintf("Loading future data from: %s\n", opt$future))
future_data <- load_data(opt$future)

cat(sprintf("Future data: %d rows, %d locations, %d time periods\n",
            nrow(future_data),
            dplyr::n_distinct(future_data$location),
            dplyr::n_distinct(future_data$time_period)))

# Generate predictions
cat("Generating predictions...\n")
predictions <- predict_mean_model(historic_data, future_data, model, model_config)

cat(sprintf("Generated %d predictions\n", nrow(predictions)))

# Convert back to regular data frame for CSV output
predictions_df <- predictions |>
  dplyr::mutate(
    time_period = as.character(time_period)
  ) |>
  as.data.frame()

# Save predictions
cat(sprintf("Saving predictions to: %s\n", opt$output))
readr::write_csv(predictions_df, opt$output)

cat("Prediction complete!\n")

# Print preview
cat("\nPrediction preview (first 10 rows):\n")
print(head(predictions, 10))

# Print summary statistics
cat("\nPrediction summary by location:\n")
summary_stats <- predictions |>
  dplyr::group_by(location) |>
  dplyr::summarise(
    n_predictions = dplyr::n(),
    mean_predicted = mean(disease_cases, na.rm = TRUE),
    total_predicted = sum(disease_cases, na.rm = TRUE)
  )
print(summary_stats, n = Inf)
