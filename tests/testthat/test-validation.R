test_that("get_example_data returns valid structure for laos monthly", {
  data <- get_example_data('laos', 'M')

  # Check that it returns a list with correct names
  expect_type(data, "list")
  expect_named(data, c("training_data", "historic_data", "future_data", "predictions"))

  # Check that all elements are data frames/tibbles
  expect_s3_class(data$training_data, "data.frame")
  expect_s3_class(data$historic_data, "data.frame")
  expect_s3_class(data$future_data, "data.frame")
  expect_s3_class(data$predictions, "data.frame")

  # Check that data has rows
  expect_gt(nrow(data$training_data), 0)
  expect_gt(nrow(data$historic_data), 0)
  expect_gt(nrow(data$future_data), 0)
  expect_gt(nrow(data$predictions), 0)

  # Check key columns exist
  expect_true("time_period" %in% names(data$training_data))
  expect_true("location" %in% names(data$training_data))
  expect_true("disease_cases" %in% names(data$training_data))

  expect_true("time_period" %in% names(data$future_data))
  expect_true("location" %in% names(data$future_data))

  expect_true("time_period" %in% names(data$predictions))
  expect_true("location" %in% names(data$predictions))
})

test_that("get_example_data rejects unsupported country", {
  expect_error(
    get_example_data('norway', 'M'),
    "Country 'norway' not supported"
  )
})

test_that("get_example_data rejects unsupported frequency", {
  expect_error(
    get_example_data('laos', 'W'),
    "Frequency 'W' not supported"
  )
})

test_that("validate_model_output detects invalid predictions", {
  # TODO: Implement test
  skip("Not yet implemented")
})

test_that("validate_model_output passes valid predictions", {
  # TODO: Implement test
  skip("Not yet implemented")
})

test_that("run_model_tests executes full test suite", {
  # TODO: Implement test
  skip("Not yet implemented")
})

test_that("validate_model_io passes with correct model functions", {
  # Define simple model functions that work correctly
  train_fn <- function(training_data, model_configuration = list()) {
    means <- training_data |>
      dplyr::group_by(location) |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::mutate(disease_cases = mean_cases) |>
      dplyr::select(-mean_cases)
  }

  # Test with single example_data
  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_type(result, "list")
  expect_named(result, c("success", "errors", "n_predictions"))
  expect_true(result$success)
  expect_length(result$errors, 0)
  expect_equal(result$n_predictions, 21)
})

test_that("validate_model_io detects missing time_period column", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return data without time_period
    future_data |> dplyr::select(-time_period)
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "time_period", ignore.case = TRUE)
})

test_that("validate_model_io detects missing location column", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return data without location
    future_data |> dplyr::select(-location)
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "location", ignore.case = TRUE)
})

test_that("validate_model_io detects row count mismatch", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return only first row
    future_data[1, ]
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "Row count mismatch", ignore.case = TRUE)
})

test_that("validate_model_io handles train_fn errors gracefully", {
  train_fn <- function(training_data, model_configuration = list()) {
    stop("Intentional training error")
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "Error", ignore.case = TRUE)
})

test_that("validate_model_io_all validates all combinations when no params given", {
  train_fn <- function(training_data, model_configuration = list()) {
    means <- training_data |>
      dplyr::group_by(location) |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::mutate(disease_cases = mean_cases) |>
      dplyr::select(-mean_cases)
  }

  result <- validate_model_io_all(train_fn, predict_fn)

  expect_type(result, "list")
  expect_named(result, c("success", "results", "errors"))
  expect_gt(length(result$results), 0)
  # Should have validated laos_M
  expect_true("laos_M" %in% names(result$results))
  expect_true(result$success)
})
