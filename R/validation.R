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


#' Validate Model Input/Output with Example Data
#'
#' Validates that a model's training and prediction functions work correctly
#' with a specific example dataset and produce output with the expected structure
#' (matching time periods and locations).
#'
#' @param train_fn Training function that takes (training_data, model_configuration = list())
#'   and returns a trained model object
#' @param predict_fn Prediction function that takes (historic_data, future_data, saved_model,
#'   model_configuration = list()) and returns predictions
#' @param example_data Named list containing training_data, historic_data, future_data,
#'   and predictions (as returned by get_example_data())
#' @param model_configuration Optional list of model configuration parameters to pass to
#'   train_fn and predict_fn
#'
#' @return A list with validation results:
#'   \itemize{
#'     \item \code{success}: Logical indicating if validation passed
#'     \item \code{errors}: Character vector of error messages (if any)
#'     \item \code{n_predictions}: Number of prediction rows returned
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Define simple model functions
#' my_train <- function(training_data, model_configuration = list()) {
#'   list(mean_cases = mean(training_data$disease_cases, na.rm = TRUE))
#' }
#'
#' my_predict <- function(historic_data, future_data, saved_model,
#'                        model_configuration = list()) {
#'   future_data$disease_cases <- saved_model$mean_cases
#'   future_data
#' }
#'
#' # Get example data and validate
#' example_data <- get_example_data('laos', 'M')
#' result <- validate_model_io(my_train, my_predict, example_data)
#' if (result$success) {
#'   cat("✓ Model validation passed!\n")
#' } else {
#'   cat("✗ Validation failed:\n")
#'   print(result$errors)
#' }
#' }
validate_model_io <- function(train_fn, predict_fn, example_data,
                               model_configuration = list()) {
  validation_errors <- character(0)
  n_predictions <- NA

  tryCatch({
    # Train model
    model <- train_fn(example_data$training_data, model_configuration)

    # Make predictions
    predictions <- predict_fn(
      example_data$historic_data,
      example_data$future_data,
      model,
      model_configuration
    )

    # Check that predictions is a data frame
    if (!is.data.frame(predictions)) {
      validation_errors <- c(validation_errors,
                             "Predictions must be a data frame")
    } else {
      n_predictions <- nrow(predictions)

      # Check required columns exist
      if (!"time_period" %in% names(predictions)) {
        validation_errors <- c(validation_errors,
                               "Predictions missing required column: time_period")
      }
      if (!"location" %in% names(predictions)) {
        validation_errors <- c(validation_errors,
                               "Predictions missing required column: location")
      }

      # Check dimensions match expected
      expected_rows <- nrow(example_data$predictions)
      actual_rows <- nrow(predictions)
      if (actual_rows != expected_rows) {
        validation_errors <- c(validation_errors,
                               sprintf("Row count mismatch: expected %d, got %d",
                                       expected_rows, actual_rows))
      }

      # Check time_period × location combinations match
      if ("time_period" %in% names(predictions) && "location" %in% names(predictions)) {
        expected_combos <- paste(example_data$predictions$time_period,
                                 example_data$predictions$location, sep = "|")
        actual_combos <- paste(predictions$time_period,
                               predictions$location, sep = "|")

        expected_sorted <- sort(expected_combos)
        actual_sorted <- sort(actual_combos)

        if (!identical(expected_sorted, actual_sorted)) {
          missing <- setdiff(expected_sorted, actual_sorted)
          extra <- setdiff(actual_sorted, expected_sorted)

          if (length(missing) > 0) {
            validation_errors <- c(validation_errors,
                                   sprintf("Missing %d time_period×location combinations",
                                           length(missing)))
          }
          if (length(extra) > 0) {
            validation_errors <- c(validation_errors,
                                   sprintf("Extra %d time_period×location combinations",
                                           length(extra)))
          }
        }
      }
    }
  }, error = function(e) {
    validation_errors <<- c(validation_errors, sprintf("Error: %s", e$message))
  })

  # Return result
  list(
    success = length(validation_errors) == 0,
    errors = validation_errors,
    n_predictions = n_predictions
  )
}

# Helper for NULL coalescing
`%||%` <- function(a, b) if (is.null(a)) b else a


#' Validate Model Input/Output for All Available Datasets
#'
#' Validates that a model's training and prediction functions work correctly
#' with all available example datasets. This function iterates over all
#' country/frequency combinations and validates each one using validate_model_io().
#'
#' @param train_fn Training function that takes (training_data, model_configuration = list())
#'   and returns a trained model object
#' @param predict_fn Prediction function that takes (historic_data, future_data, saved_model,
#'   model_configuration = list()) and returns predictions
#' @param country Optional character string specifying country. If NULL, tests all available countries.
#'   Currently supports: 'laos'
#' @param frequency Optional character string specifying temporal frequency. If NULL, tests all
#'   available frequencies. Currently supports: 'M' (monthly)
#' @param model_configuration Optional list of model configuration parameters to pass to
#'   train_fn and predict_fn
#'
#' @return A list with validation results:
#'   \itemize{
#'     \item \code{success}: Logical indicating if all validations passed
#'     \item \code{results}: Named list of validation results for each country/frequency combination
#'     \item \code{errors}: Character vector of all error messages (if any)
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Define simple model functions
#' my_train <- function(training_data, model_configuration = list()) {
#'   list(mean_cases = mean(training_data$disease_cases, na.rm = TRUE))
#' }
#'
#' my_predict <- function(historic_data, future_data, saved_model,
#'                        model_configuration = list()) {
#'   future_data$disease_cases <- saved_model$mean_cases
#'   future_data
#' }
#'
#' # Validate across all available datasets
#' result <- validate_model_io_all(my_train, my_predict)
#' if (result$success) {
#'   cat("✓ All validations passed!\n")
#' } else {
#'   cat("✗ Validation failed:\n")
#'   print(result$errors)
#' }
#'
#' # Validate with specific country and frequency
#' result <- validate_model_io_all(my_train, my_predict, country = 'laos', frequency = 'M')
#' }
validate_model_io_all <- function(train_fn, predict_fn, country = NULL, frequency = NULL,
                                   model_configuration = list()) {
  # Define all available country/frequency combinations
  available_combinations <- list(
    list(country = 'laos', frequency = 'M')
  )

  # Filter combinations based on parameters
  if (!is.null(country) || !is.null(frequency)) {
    available_combinations <- Filter(function(combo) {
      country_match <- is.null(country) || combo$country == country
      freq_match <- is.null(frequency) || combo$frequency == frequency
      country_match && freq_match
    }, available_combinations)

    if (length(available_combinations) == 0) {
      return(list(
        success = FALSE,
        results = list(),
        errors = c(sprintf("No available data for country='%s', frequency='%s'",
                           country %||% "NULL", frequency %||% "NULL"))
      ))
    }
  }

  # Run validation for each combination
  results <- list()
  all_errors <- character(0)

  for (combo in available_combinations) {
    combo_name <- sprintf("%s_%s", combo$country, combo$frequency)

    # Get example data
    example_data <- tryCatch(
      get_example_data(combo$country, combo$frequency),
      error = function(e) {
        error_msg <- sprintf("Error loading data for %s: %s", combo_name, e$message)
        all_errors <<- c(all_errors, error_msg)
        results[[combo_name]] <<- list(
          country = combo$country,
          frequency = combo$frequency,
          success = FALSE,
          errors = c(error_msg),
          n_predictions = NA
        )
        return(NULL)
      }
    )

    if (is.null(example_data)) {
      next
    }

    # Validate using the single-dataset function
    validation_result <- validate_model_io(train_fn, predict_fn, example_data, model_configuration)

    # Store results
    results[[combo_name]] <- list(
      country = combo$country,
      frequency = combo$frequency,
      success = validation_result$success,
      errors = validation_result$errors,
      n_predictions = validation_result$n_predictions
    )

    if (!validation_result$success) {
      all_errors <- c(all_errors, sprintf("[%s] %s", combo_name,
                                          paste(validation_result$errors, collapse = "; ")))
    }
  }

  # Return overall result
  list(
    success = length(all_errors) == 0,
    results = results,
    errors = all_errors
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
