test_that("get_example_data returns valid structure for laos monthly", {
  data <- get_example_data('laos', 'M')

  # Check that it returns a list with correct names
  expect_type(data, "list")
  expect_named(data, c("training_data", "historic_data", "future_data", "predictions"))

  # Check that all elements are tsibbles
  expect_true(tsibble::is_tsibble(data$training_data))
  expect_true(tsibble::is_tsibble(data$historic_data))
  expect_true(tsibble::is_tsibble(data$future_data))
  expect_true(tsibble::is_tsibble(data$predictions))

  # Check that data has rows
  expect_gt(nrow(data$training_data), 0)
  expect_gt(nrow(data$historic_data), 0)
  expect_gt(nrow(data$future_data), 0)
  expect_gt(nrow(data$predictions), 0)

  # Check key columns exist (time_period is the index, location is the key)
  expect_equal(tsibble::index_var(data$training_data), "time_period")
  expect_true("location" %in% tsibble::key_vars(data$training_data))
  expect_true("disease_cases" %in% names(data$training_data))

  expect_equal(tsibble::index_var(data$future_data), "time_period")
  expect_true("location" %in% tsibble::key_vars(data$future_data))

  expect_equal(tsibble::index_var(data$predictions), "time_period")
  expect_true("location" %in% tsibble::key_vars(data$predictions))
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
  # Define simple model functions that work correctly with tsibbles
  train_fn <- function(training_data, model_configuration = list()) {
    means <- training_data |>
      tibble::as_tibble() |>
      dplyr::group_by(location) |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      tibble::as_tibble() |>
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

test_that("validate_model_io detects missing disease_cases column", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return future_data as-is (no disease_cases column)
    future_data
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "disease_cases", ignore.case = TRUE)
})

test_that("validate_model_io detects row count mismatch", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return only first row with disease_cases added
    future_data[1, ] |>
      dplyr::mutate(disease_cases = 0)
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
      tibble::as_tibble() |>
      dplyr::group_by(location) |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      tibble::as_tibble() |>
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
