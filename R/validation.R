#' Get Example Data for Testing
#'
#' Returns example datasets for testing and validating CHAP models.
#' Currently supports Laos monthly data.
#'
#' @param country Character string specifying the country. Currently only 'laos' is supported.
#' @param frequency Character string specifying the temporal frequency.
#'   Currently only 'M' (monthly) is supported.
#'
#' @return A named list containing four elements:
#'   \itemize{
#'     \item \code{training_data}: tsibble with historical data for training the model
#'     \item \code{historic_data}: tsibble with historical data for making predictions
#'     \item \code{future_data}: tsibble with future time periods for prediction
#'     \item \code{predictions}: tibble with example prediction output. If the predictions
#'       contain sample columns (sample_0, sample_1, ...), they are converted to nested
#'       list-column format with a \code{samples} column containing numeric vectors.
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data <- get_example_data('laos', 'M')
#' model <- train_fn(data$training_data)
#' preds <- predict_fn(data$historic_data, data$future_data, model)
#'
#' # If predictions have samples, access them like this:
#' data$predictions$samples[[1]]  # Samples for first forecast unit
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

  # Load the data files using load_tsibble for consistent handling
  training_data <- load_tsibble(file.path(data_dir, "training_data.csv"))
  historic_data <- load_tsibble(file.path(data_dir, "historic_data.csv"))
  future_data <- load_tsibble(file.path(data_dir, "future_data.csv"))

  # Load predictions and convert to nested sample format if samples are present
  predictions_path <- file.path(data_dir, "predictions.csv")
  predictions_raw <- readr::read_csv(predictions_path, show_col_types = FALSE)

  # Check if predictions have sample columns and convert to nested format
  if (detect_prediction_format(predictions_raw) == "wide") {
    predictions <- predictions_from_wide(predictions_raw)
  } else {
    predictions <- tibble::as_tibble(predictions_raw)
  }

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
#' Models can return either:
#' \itemize{
#'   \item Point predictions with a \code{disease_cases} column
#'   \item Sample-based predictions with a \code{samples} list-column containing
#'     numeric vectors of Monte Carlo samples
#' }
#'
#' @param train_fn Training function that takes (training_data, model_configuration = list())
#'   and returns a trained model object
#' @param predict_fn Prediction function that takes (historic_data, future_data, saved_model,
#'   model_configuration = list()) and returns predictions. Can return either point predictions
#'   (with disease_cases column) or sample-based predictions (with samples list-column).
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
#'     \item \code{prediction_format}: Format of predictions ("point", "samples", or "unknown")
#'     \item \code{n_samples}: Number of samples per forecast unit (if sample-based)
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
  prediction_format <- "unknown"
  n_samples <- NA

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
                             "Predictions must be a data frame or tibble")
    } else {
      n_predictions <- nrow(predictions)

      # Detect prediction format
      has_disease_cases <- "disease_cases" %in% names(predictions)
      has_samples <- "samples" %in% names(predictions) && is.list(predictions$samples)

      if (has_samples) {
        prediction_format <- "samples"
        # Validate samples structure
        if (length(predictions$samples) > 0) {
          n_samples <- length(predictions$samples[[1]])

          # Check all rows have same number of samples
          sample_lengths <- vapply(predictions$samples, length, integer(1))
          if (!all(sample_lengths == n_samples)) {
            validation_errors <- c(validation_errors,
                                   "All rows must have the same number of samples")
          }

          # Check samples are numeric
          if (!all(vapply(predictions$samples, is.numeric, logical(1)))) {
            validation_errors <- c(validation_errors,
                                   "All samples must be numeric vectors")
          }
        }
      } else if (has_disease_cases) {
        prediction_format <- "point"
      } else {
        validation_errors <- c(validation_errors,
                               "Predictions must have either 'disease_cases' column (point predictions) or 'samples' list-column (sample-based predictions)")
      }

      # Check dimensions match expected
      expected_rows <- nrow(example_data$future_data)
      actual_rows <- nrow(predictions)
      if (actual_rows != expected_rows) {
        validation_errors <- c(validation_errors,
                               sprintf("Row count mismatch: expected %d, got %d",
                                       expected_rows, actual_rows))
      }
    }
  }, error = function(e) {
    validation_errors <<- c(validation_errors, sprintf("Error: %s", e$message))
  })

  # Return result
  list(
    success = length(validation_errors) == 0,
    errors = validation_errors,
    n_predictions = n_predictions,
    prediction_format = prediction_format,
    n_samples = n_samples
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
