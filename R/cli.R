#' Create Chap-Compatible CLI for Train Function
#'
#' Creates a command-line interface wrapper around a training function
#' that follows the chap interface: train(training_data, model_configuration) -> saved_model
#'
#' @param train_fn A function that accepts training_data and model_configuration
#'   and returns a saved model
#' @param args Command line arguments (defaults to commandArgs(trailingOnly = TRUE))
#'
#' @return The result of the train function
#' @export
#'
#' @examples
#' \dontrun{
#' my_train <- function(training_data, model_configuration) {
#'   # Training logic here
#'   return(model)
#' }
#' create_train_cli(my_train)
#' }
create_train_cli <- function(train_fn, args = commandArgs(trailingOnly = TRUE)) {
  # Deprecation warning
  .Deprecated("create_chap_cli",
              msg = "create_train_cli() is deprecated. Use create_chap_cli(train_fn, predict_fn) instead for a unified CLI interface.")

  # Parse arguments
  if (length(args) < 1) {
    stop("Usage: Rscript train.R <training_data> [model_configuration]")
  }

  training_data <- args[1]
  model_configuration <- if (length(args) >= 2) args[2] else NULL

  # Validate training data exists
  if (!file.exists(training_data)) {
    stop("Training data file not found: ", training_data)
  }

  # Validate model configuration if provided
  if (!is.null(model_configuration) && model_configuration != "" && !file.exists(model_configuration)) {
    stop("Model configuration file not found: ", model_configuration)
  }

  # Call training function
  tryCatch({
    result <- train_fn(training_data, model_configuration)
    invisible(result)
  }, error = function(e) {
    stop("Training failed: ", e$message, call. = FALSE)
  })
}


#' Create Chap-Compatible CLI for Predict Function
#'
#' Creates a command-line interface wrapper around a prediction function
#' that follows the chap interface: predict(historic_data, future_data, saved_model, model_configuration)
#'
#' @param predict_fn A function that accepts historic_data, future_data,
#'   saved_model, and model_configuration
#' @param args Command line arguments (defaults to commandArgs(trailingOnly = TRUE))
#'
#' @return The result of the predict function
#' @export
#'
#' @examples
#' \dontrun{
#' my_predict <- function(historic_data, future_data, saved_model, model_configuration) {
#'   # Prediction logic here
#'   return(predictions)
#' }
#' create_predict_cli(my_predict)
#' }
create_predict_cli <- function(predict_fn, args = commandArgs(trailingOnly = TRUE)) {
  # Deprecation warning
  .Deprecated("create_chap_cli",
              msg = "create_predict_cli() is deprecated. Use create_chap_cli(train_fn, predict_fn) instead for a unified CLI interface.")

  # Parse arguments
  if (length(args) < 3) {
    stop("Usage: Rscript predict.R <historic_data> <future_data> <saved_model> [model_configuration]")
  }

  historic_data <- args[1]
  future_data <- args[2]
  saved_model <- args[3]
  model_configuration <- if (length(args) >= 4) args[4] else NULL

  # Validate historic data exists
  if (!file.exists(historic_data)) {
    stop("Historic data file not found: ", historic_data)
  }

  # Validate future data exists
  if (!file.exists(future_data)) {
    stop("Future data file not found: ", future_data)
  }

  # Validate model configuration if provided
  if (!is.null(model_configuration) && model_configuration != "" && !file.exists(model_configuration)) {
    stop("Model configuration file not found: ", model_configuration)
  }

  # Call prediction function
  tryCatch({
    result <- predict_fn(historic_data, future_data, saved_model, model_configuration)
    invisible(result)
  }, error = function(e) {
    stop("Prediction failed: ", e$message, call. = FALSE)
  })
}


#' Create Unified CHAP CLI
#'
#' Creates a unified command-line interface for both training and prediction.
#' Automatically handles all file I/O, parsing, and conversion. Model functions
#' receive loaded tsibbles and configuration lists, not file paths.
#'
#' This is the recommended way to create CHAP-compatible CLI scripts. It replaces
#' the older create_train_cli() and create_predict_cli() functions by providing
#' a single unified interface with subcommand dispatch.
#'
#' @param train_fn Training function with signature:
#'   \code{function(training_data, model_configuration = list())} where
#'   \code{training_data} is a tsibble and \code{model_configuration} is a list.
#'   Should return a model object that will be automatically saved as RDS.
#' @param predict_fn Prediction function with signature:
#'   \code{function(historic_data, future_data, saved_model, model_configuration = list())}
#'   where all data inputs are tsibbles, \code{saved_model} is a loaded object,
#'   and \code{model_configuration} is a list. Should return a predictions tsibble.
#' @param model_config_schema Optional model configuration schema (reserved for future use).
#'   Can be used with the "info" subcommand to display schema information.
#' @param args Command line arguments (defaults to \code{commandArgs(trailingOnly = TRUE)})
#'
#' @return Invisible result of the called function
#' @export
#'
#' @examples
#' \dontrun{
#' # In model.R file:
#' library(chap.r.sdk)
#' library(dplyr)
#'
#' train_my_model <- function(training_data, model_configuration = list()) {
#'   # training_data is already a tsibble - no file I/O needed!
#'   means <- training_data |>
#'     group_by(location) |>
#'     summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
#'   return(list(means = means))
#' }
#'
#' predict_my_model <- function(historic_data, future_data, saved_model,
#'                               model_configuration = list()) {
#'   # All inputs are already loaded - no file I/O needed!
#'   predictions <- future_data |>
#'     left_join(saved_model$means, by = "location") |>
#'     mutate(disease_cases = mean_cases)
#'   return(predictions)
#' }
#'
#' config_schema <- list(
#'   title = "My Model Configuration",
#'   type = "object",
#'   properties = list()
#' )
#'
#' # Single function call enables full CLI!
#' if (!interactive()) {
#'   create_chap_cli(train_my_model, predict_my_model, config_schema)
#' }
#'
#' # Command line usage:
#' # Rscript model.R train data.csv [config.yaml]
#' # Rscript model.R predict historic.csv future.csv model.rds [config.yaml]
#' # Rscript model.R info
#' }
create_chap_cli <- function(train_fn, predict_fn, model_config_schema = NULL,
                            args = commandArgs(trailingOnly = TRUE)) {

  # Validate inputs
  if (!is.function(train_fn)) {
    stop("train_fn must be a function")
  }
  if (!is.function(predict_fn)) {
    stop("predict_fn must be a function")
  }

  # Parse subcommand
  if (length(args) < 1) {
    stop("Usage: Rscript model.R <train|predict|info> [arguments...]\n",
         "  train:   Rscript model.R train <training_data> [model_config]\n",
         "  predict: Rscript model.R predict <historic_data> <future_data> <saved_model> [model_config]\n",
         "  info:    Rscript model.R info")
  }

  subcommand <- tolower(args[1])
  subcommand_args <- if (length(args) > 1) args[-1] else character(0)

  # Dispatch to appropriate handler
  result <- switch(subcommand,
    "train" = handle_train(train_fn, subcommand_args),
    "predict" = handle_predict(predict_fn, subcommand_args),
    "info" = handle_info(model_config_schema),
    stop("Invalid subcommand: '", subcommand, "'. Use 'train', 'predict', or 'info'")
  )

  invisible(result)
}

#' Handle train subcommand
#'
#' Internal function that handles the "train" subcommand for create_chap_cli().
#' Loads training data, parses configuration, calls the training function,
#' and saves the resulting model.
#'
#' @param train_fn User-provided training function
#' @param args Subcommand arguments (training_data path and optional config path)
#' @return Path to saved model file
#' @keywords internal
handle_train <- function(train_fn, args) {
  # Parse arguments
  if (length(args) < 1) {
    stop("Usage: Rscript model.R train <training_data> [model_config]")
  }

  training_data_path <- args[1]
  config_path <- if (length(args) >= 2) args[2] else NULL

  # Validate files exist
  if (!file.exists(training_data_path)) {
    stop("Training data file not found: ", training_data_path)
  }
  if (!is.null(config_path) && config_path != "" && !file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  # Load and parse data
  message("Loading training data from: ", training_data_path)
  training_data <- load_tsibble(training_data_path)

  # Load configuration
  config <- load_config(config_path)
  if (!is.null(config_path) && config_path != "") {
    message("Loaded configuration from: ", config_path)
  }

  # Call training function
  message("Training model...")
  model <- tryCatch({
    train_fn(training_data, config)
  }, error = function(e) {
    stop("Training failed: ", e$message, call. = FALSE)
  })

  # Save model
  model_path <- save_model(model, output_path = "model.rds")

  return(model_path)
}

#' Handle predict subcommand
#'
#' Internal function that handles the "predict" subcommand for create_chap_cli().
#' Loads historic data, future data, saved model, and configuration, calls the
#' prediction function, and saves the resulting predictions.
#'
#' @param predict_fn User-provided prediction function
#' @param args Subcommand arguments (historic_data, future_data, saved_model, optional config)
#' @return Path to saved predictions file
#' @keywords internal
handle_predict <- function(predict_fn, args) {
  # Parse arguments
  if (length(args) < 3) {
    stop("Usage: Rscript model.R predict <historic_data> <future_data> <saved_model> [model_config]")
  }

  historic_path <- args[1]
  future_path <- args[2]
  model_path <- args[3]
  config_path <- if (length(args) >= 4) args[4] else NULL

  # Validate files exist
  if (!file.exists(historic_path)) {
    stop("Historic data file not found: ", historic_path)
  }
  if (!file.exists(future_path)) {
    stop("Future data file not found: ", future_path)
  }
  if (!file.exists(model_path)) {
    stop("Model file not found: ", model_path)
  }
  if (!is.null(config_path) && config_path != "" && !file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  # Load data
  message("Loading historic data from: ", historic_path)
  historic_data <- load_tsibble(historic_path)

  message("Loading future data from: ", future_path)
  future_data <- load_tsibble(future_path)

  message("Loading model from: ", model_path)
  model <- readRDS(model_path)

  # Load configuration
  config <- load_config(config_path)
  if (!is.null(config_path) && config_path != "") {
    message("Loaded configuration from: ", config_path)
  }

  # Call prediction function
  message("Generating predictions...")
  predictions <- tryCatch({
    predict_fn(historic_data, future_data, model, config)
  }, error = function(e) {
    stop("Prediction failed: ", e$message, call. = FALSE)
  })

  # Save predictions
  predictions_path <- sub("\\.rds$", "_predictions.csv", model_path)
  save_predictions(predictions, predictions_path)

  return(predictions_path)
}

#' Handle info subcommand
#'
#' Internal function that handles the "info" subcommand for create_chap_cli().
#' Displays model information and configuration schema if provided.
#'
#' @param model_config_schema Optional configuration schema to display
#' @return NULL (invisibly)
#' @keywords internal
handle_info <- function(model_config_schema) {
  cat("Model Information\n")
  cat("=================\n\n")

  if (is.null(model_config_schema)) {
    cat("No configuration schema defined.\n")
  } else {
    cat("Configuration Schema:\n")
    cat(yaml::as.yaml(model_config_schema))
  }

  invisible(NULL)
}
