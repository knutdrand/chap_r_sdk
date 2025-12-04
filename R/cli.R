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
