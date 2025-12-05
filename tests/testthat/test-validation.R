test_that("get_example_data returns valid structure for laos monthly", {
  data <- get_example_data('laos', 'M')

  # Check that it returns a list with correct names
  expect_type(data, "list")
  expect_named(data, c("training_data", "historic_data", "future_data", "predictions"))

  # Check that training/historic/future are tsibbles
  expect_true(tsibble::is_tsibble(data$training_data))
  expect_true(tsibble::is_tsibble(data$historic_data))
  expect_true(tsibble::is_tsibble(data$future_data))

  # Predictions is a tibble (may have nested samples)
  expect_true(tibble::is_tibble(data$predictions))

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

  # Predictions should have time_period and location columns
  expect_true("time_period" %in% names(data$predictions))
  expect_true("location" %in% names(data$predictions))
})

test_that("get_example_data converts sample predictions to nested format", {
  data <- get_example_data('laos', 'M')

  # Check if predictions have samples column (nested format)
  format <- chap.r.sdk::detect_prediction_format(data$predictions)

  # The example data may or may not have samples depending on the dataset

  # If it has samples, they should be in nested format
  if (format == "nested") {
    expect_true("samples" %in% names(data$predictions))
    expect_type(data$predictions$samples, "list")
    expect_true(is.numeric(data$predictions$samples[[1]]))
  }
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

test_that("validate_model_io passes with deterministic model (single sample)", {
  # Define simple model functions that return single sample per forecast unit
  train_fn <- function(training_data, model_configuration = list()) {
    means <- training_data |>
      tibble::as_tibble() |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
      dplyr::select(-mean_cases)
  }

  # Test with single example_data
  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_type(result, "list")
  expect_named(result, c("success", "errors", "n_predictions", "n_samples"))
  expect_true(result$success)
  expect_length(result$errors, 0)
  expect_equal(result$n_predictions, 21)
  expect_equal(result$n_samples, 1)
})

test_that("validate_model_io passes with probabilistic model (multiple samples)", {
  # Define model functions that return multiple samples per forecast unit
  train_fn <- function(training_data, model_configuration = list()) {
    means <- training_data |>
      tibble::as_tibble() |>
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    n_samples <- 100
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::rowwise() |>
      dplyr::mutate(
        samples = list(rpois(n_samples, lambda = mean_cases))
      ) |>
      dplyr::ungroup() |>
      dplyr::select(-mean_cases)
  }

  # Test with single example_data
  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_type(result, "list")
  expect_true(result$success)
  expect_length(result$errors, 0)
  expect_equal(result$n_predictions, 21)
  expect_equal(result$n_samples, 100)
})

test_that("validate_model_io detects missing samples column", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return future_data as-is (no samples column)
    tibble::as_tibble(future_data)
  }

  example_data <- get_example_data('laos', 'M')
  result <- validate_model_io(train_fn, predict_fn, example_data)

  expect_false(result$success)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "samples", ignore.case = TRUE)
})

test_that("validate_model_io detects row count mismatch", {
  train_fn <- function(training_data, model_configuration = list()) {
    list(dummy = 1)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    # Return only first row with samples added
    future_data[1, ] |>
      dplyr::mutate(samples = list(c(0)))
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
      dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
    list(means = means)
  }

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list()) {
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
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
