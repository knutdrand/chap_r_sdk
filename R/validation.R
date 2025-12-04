#' Get Example Data for Testing
#'
#' Returns example datasets for testing and validating CHAP models.
#' Currently supports Laos monthly data.
#'
#' @param country Character string specifying the country. Currently only 'laos' is supported.
#' @param frequency Character string specifying the temporal frequency.
#'   Currently only 'M' (monthly) is supported.
#'
#' @return A named list containing four tibbles:
#'   \itemize{
#'     \item \code{training_data}: Historical data for training the model
#'     \item \code{historic_data}: Historical data for making predictions
#'     \item \code{future_data}: Future time periods for prediction
#'     \item \code{predictions}: Example prediction output
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data <- get_example_data('laos', 'M')
#' model <- train_fn(data$training_data)
#' preds <- predict_fn(data$historic_data, data$future_data, model)
#' }
get_example_data <- function(country, frequency) {
  # Validate inputs
  if (!country %in% c('laos')) {
    stop("Country '", country, "' not supported. Currently only 'laos' is available.")
  }

  if (!frequency %in% c('M')) {
    stop("Frequency '", frequency, "' not supported. Currently only 'M' (monthly) is available.")
  }

  # Construct paths to test data
  data_dir <- system.file("testdata", "ewars_example", "monthly", package = "chap.r.sdk")

  if (data_dir == "") {
    stop("Test data not found. Make sure the package is properly installed.")
  }

  # Load the data files
  training_data <- readr::read_csv(
    file.path(data_dir, "training_data.csv"),
    show_col_types = FALSE
  )

  historic_data <- readr::read_csv(
    file.path(data_dir, "historic_data.csv"),
    show_col_types = FALSE
  )

  future_data <- readr::read_csv(
    file.path(data_dir, "future_data.csv"),
    show_col_types = FALSE
  )

  predictions <- readr::read_csv(
    file.path(data_dir, "predictions.csv"),
    show_col_types = FALSE
  )

  # Return as named list
  list(
    training_data = training_data,
    historic_data = historic_data,
    future_data = future_data,
    predictions = predictions
  )
}


#' Validate Model Output
#'
#' Performs sanity checks on model prediction output to ensure it is
#' consistent with chap expectations
#'
#' @param predictions The prediction output to validate
#' @param expected_schema The expected schema for predictions
#'
#' @return A list with validation results (pass/fail and any error messages)
#' @export
#'
#' @examples
#' \dontrun{
#' validate_model_output(predictions, schema)
#' }
validate_model_output <- function(predictions, expected_schema) {
  # TODO: Implement validation logic
  stop("Not yet implemented")
}


#' Run Model Test Suite
#'
#' Runs a comprehensive test suite to sanity check a chap model
#'
#' @param train_fn The training function to test
#' @param predict_fn The prediction function to test
#' @param test_data Test dataset for validation
#'
#' @return A test results object with pass/fail status and details
#' @export
#'
#' @examples
#' \dontrun{
#' run_model_tests(my_train, my_predict, test_data)
#' }
run_model_tests <- function(train_fn, predict_fn, test_data) {
  # TODO: Implement test suite
  stop("Not yet implemented")
}
