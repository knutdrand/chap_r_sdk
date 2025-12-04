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
