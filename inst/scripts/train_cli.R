#!/usr/bin/env Rscript

# Train CLI for CHAP R SDK
# This script provides a command-line interface for training CHAP models

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
load_training_data <- function(filepath) {
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
    c("-d", "--data"),
    type = "character",
    default = NULL,
    help = "Path to training data CSV file",
    metavar = "FILE"
  ),
  make_option(
    c("-c", "--config"),
    type = "character",
    default = NULL,
    help = "Path to model configuration YAML/JSON file",
    metavar = "FILE"
  ),
  make_option(
    c("-o", "--output"),
    type = "character",
    default = "model.rds",
    help = "Output path for trained model [default= %default]",
    metavar = "FILE"
  )
)

# Parse command-line arguments
opt_parser <- OptionParser(
  usage = "%prog [options]",
  option_list = option_list,
  description = "\nTrain a CHAP mean model from training data"
)

opt <- parse_args(opt_parser)

# Validate required arguments
if (is.null(opt$data)) {
  print_help(opt_parser)
  stop("Error: --data argument is required", call. = FALSE)
}

# Load configuration
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

# Load training data
cat(sprintf("Loading training data from: %s\n", opt$data))
training_data <- load_training_data(opt$data)

cat(sprintf("Training data: %d rows, %d locations, %d time periods\n",
            nrow(training_data),
            dplyr::n_distinct(training_data$location),
            dplyr::n_distinct(training_data$time_period)))

# Train model
cat("Training mean model...\n")
model <- train_mean_model(training_data, model_config)

# Save model
cat(sprintf("Saving model to: %s\n", opt$output))
saveRDS(model, opt$output)

cat("Training complete!\n")

# Print model summary
cat("\nModel summary:\n")
cat(sprintf("  Model type: %s\n", model$model_type))
cat(sprintf("  Trained at: %s\n", model$trained_at))
cat(sprintf("  Number of locations: %d\n", nrow(model$location_means)))
cat("\nMean cases per location:\n")
print(model$location_means, n = Inf)
