test_that("detect_time_column finds standard time columns", {
  # Test with time_period
  df1 <- data.frame(time_period = 1:5, value = rnorm(5))
  expect_equal(detect_time_column(df1), "time_period")

  # Test with date
  df2 <- data.frame(date = as.Date("2023-01-01") + 0:4, value = rnorm(5))
  expect_equal(detect_time_column(df2), "date")

  # Test with week
  df3 <- data.frame(week = 1:5, value = rnorm(5))
  expect_equal(detect_time_column(df3), "week")

  # Test with month
  df4 <- data.frame(month = 1:5, value = rnorm(5))
  expect_equal(detect_time_column(df4), "month")
})

test_that("detect_time_column falls back to first column with warning", {
  df <- data.frame(my_time = 1:5, value = rnorm(5))
  expect_warning(result <- detect_time_column(df), "No standard time column found")
  expect_equal(result, "my_time")
})

test_that("detect_key_columns finds standard spatial keys", {
  # Test with location
  df1 <- data.frame(location = c("A", "B"), time = 1:2, value = rnorm(2))
  expect_equal(detect_key_columns(df1), "location")

  # Test with region
  df2 <- data.frame(region = c("A", "B"), time = 1:2, value = rnorm(2))
  expect_equal(detect_key_columns(df2), "region")

  # Test with multiple keys
  df3 <- data.frame(location = c("A", "B"), region = c("R1", "R2"), time = 1:2, value = rnorm(2))
  result <- detect_key_columns(df3)
  expect_true("location" %in% result)
  expect_true("region" %in% result)
})

test_that("detect_key_columns returns NULL for univariate time series", {
  df <- data.frame(time_period = 1:5, value = rnorm(5))
  expect_null(detect_key_columns(df))
})

test_that("load_config returns empty list for NULL or empty path", {
  expect_equal(load_config(NULL), list())
  expect_equal(load_config(""), list())
})

test_that("load_config returns empty list for non-existent file", {
  expect_equal(load_config("nonexistent_file.yaml"), list())
})

test_that("load_config loads valid YAML file", {
  # Create temporary YAML file
  temp_config <- tempfile(fileext = ".yaml")
  writeLines(c("param1: value1", "param2: 42"), temp_config)

  config <- load_config(temp_config)
  expect_equal(config$param1, "value1")
  expect_equal(config$param2, 42)

  unlink(temp_config)
})

test_that("save_model saves RDS file", {
  model <- list(weights = rnorm(10), type = "test")
  temp_file <- tempfile(fileext = ".rds")

  result <- save_model(model, temp_file)
  expect_equal(result, temp_file)
  expect_true(file.exists(temp_file))

  loaded_model <- readRDS(temp_file)
  expect_equal(loaded_model, model)

  unlink(temp_file)
})

test_that("save_predictions saves CSV file with samples converted to wide format", {
  predictions <- tibble::tibble(
    time_period = 1:5,
    location = rep("A", 5),
    samples = list(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9), c(10, 11, 12), c(13, 14, 15))
  )
  temp_file <- tempfile(fileext = ".csv")

  result <- save_predictions(predictions, temp_file)
  expect_equal(result, temp_file)
  expect_true(file.exists(temp_file))

  loaded_predictions <- readr::read_csv(temp_file, show_col_types = FALSE)
  expect_equal(nrow(loaded_predictions), 5)
  # Should have converted samples to wide format
  expect_true(all(c("time_period", "location", "sample_0", "sample_1", "sample_2") %in% names(loaded_predictions)))
  expect_false("samples" %in% names(loaded_predictions))

  unlink(temp_file)
})

test_that("load_tsibble loads CSV and converts to tsibble", {
  # Create temporary CSV file
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    time_period = 1:4,
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18)
  )
  readr::write_csv(test_data, temp_csv)

  result <- load_tsibble(temp_csv)

  expect_s3_class(result, "tbl_ts")
  expect_equal(nrow(result), 4)
  expect_true("time_period" %in% names(result))
  expect_true("location" %in% names(result))

  unlink(temp_csv)
})

test_that("load_tsibble handles univariate time series", {
  # Create temporary CSV without key columns
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    time_period = 1:5,
    value = rnorm(5)
  )
  readr::write_csv(test_data, temp_csv)

  result <- load_tsibble(temp_csv)

  expect_s3_class(result, "tbl_ts")
  expect_equal(nrow(result), 5)

  unlink(temp_csv)
})
