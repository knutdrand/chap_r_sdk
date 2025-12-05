# Tests for prediction sample format conversion functions

test_that("predictions_from_wide converts wide format to nested format", {
  # Create test wide format data
  wide_df <- data.frame(
    time_period = c("2013-04", "2013-05", "2013-06"),
    location = c("Bokeo", "Bokeo", "Bokeo"),
    sample_0 = c(10, 20, 30),
    sample_1 = c(12, 22, 32),
    sample_2 = c(8, 18, 28)
  )

  result <- predictions_from_wide(wide_df)

  # Check structure

  expect_s3_class(result, "tbl_df")
  expect_true("samples" %in% names(result))
  expect_equal(nrow(result), 3)

  # Check samples are list-column with correct values
  expect_type(result$samples, "list")
  expect_equal(result$samples[[1]], c(10, 12, 8))
  expect_equal(result$samples[[2]], c(20, 22, 18))
  expect_equal(result$samples[[3]], c(30, 32, 28))

  # Check metadata preserved
  expect_equal(result$time_period, c("2013-04", "2013-05", "2013-06"))
  expect_equal(result$location, c("Bokeo", "Bokeo", "Bokeo"))
})

test_that("predictions_from_wide errors on missing sample columns", {
  df <- data.frame(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    value = c(10)
  )

  expect_error(
    predictions_from_wide(df),
    "No sample columns found"
  )
})

test_that("predictions_to_wide converts nested format to wide format", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    samples = list(
      c(10, 12, 8),
      c(20, 22, 18)
    )
  )

  result <- predictions_to_wide(nested_df)

  # Check structure
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 2)
  expect_true(all(c("sample_0", "sample_1", "sample_2") %in% names(result)))

  # Check values
  expect_equal(result$sample_0, c(10, 20))
  expect_equal(result$sample_1, c(12, 22))
  expect_equal(result$sample_2, c(8, 18))

  # Check metadata preserved
  expect_equal(result$time_period, c("2013-04", "2013-05"))
  expect_equal(result$location, c("Bokeo", "Bokeo"))
})

test_that("predictions_to_wide errors on missing samples column", {
  df <- tibble::tibble(
    time_period = c("2013-04"),
    location = c("Bokeo")
  )

  expect_error(
    predictions_to_wide(df),
    "must have a 'samples' column"
  )
})

test_that("predictions_to_wide errors on inconsistent sample counts", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    samples = list(
      c(10, 12, 8),
      c(20, 22)  # Only 2 samples instead of 3
    )
  )

  expect_error(
    predictions_to_wide(nested_df),
    "same number of samples"
  )
})

test_that("predictions_to_long converts nested to long format", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    samples = list(
      c(10, 12, 8),
      c(20, 22, 18)
    )
  )

  result <- predictions_to_long(nested_df)

  # Check structure - 2 rows × 3 samples = 6 rows

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 6)
  expect_true("prediction" %in% names(result))
  expect_true("sample_id" %in% names(result))

  # Check values for first forecast unit
  first_unit <- result[result$time_period == "2013-04", ]
  expect_equal(first_unit$prediction, c(10, 12, 8))
  expect_equal(first_unit$sample_id, c(1, 2, 3))
})

test_that("predictions_to_long respects custom value column name", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    samples = list(c(10, 12, 8))
  )

  result <- predictions_to_long(nested_df, value_col = "cases")

  expect_true("cases" %in% names(result))
  expect_false("prediction" %in% names(result))
})

test_that("predictions_from_long converts long to nested format", {
  long_df <- tibble::tibble(
    time_period = rep(c("2013-04", "2013-05"), each = 3),
    location = rep("Bokeo", 6),
    sample_id = rep(1:3, 2),
    prediction = c(10, 12, 8, 20, 22, 18)
  )

  result <- predictions_from_long(long_df)

  # Check structure
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true("samples" %in% names(result))

  # Check samples
  expect_equal(result$samples[[1]], c(10, 12, 8))
  expect_equal(result$samples[[2]], c(20, 22, 18))
})

test_that("predictions_from_long respects custom column names", {
  long_df <- tibble::tibble(
    period = rep(c("2013-04", "2013-05"), each = 3),
    loc = rep("Bokeo", 6),
    idx = rep(1:3, 2),
    value = c(10, 12, 8, 20, 22, 18)
  )

  result <- predictions_from_long(
    long_df,
    value_col = "value",
    sample_col = "idx",
    group_cols = c("period", "loc")
  )

  expect_equal(nrow(result), 2)
  expect_equal(result$samples[[1]], c(10, 12, 8))
})

test_that("predictions_to_quantiles computes correct quantiles", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    samples = list(1:100)  # Samples from 1 to 100
  )

  result <- predictions_to_quantiles(nested_df, probs = c(0.25, 0.5, 0.75))

  # Check structure - 1 row × 3 quantiles = 3 rows
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_true(all(c("quantile", "value") %in% names(result)))

  # Check quantile values
  expect_equal(result$quantile, c(0.25, 0.5, 0.75))
  expect_equal(unname(result$value[result$quantile == 0.5]), 50.5)  # Median of 1:100
})

test_that("predictions_summary adds mean, median, and CI columns", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    samples = list(
      1:100,
      51:150
    )
  )

  result <- predictions_summary(nested_df, ci_levels = c(0.5, 0.9))

  # Check columns added
  expect_true("mean" %in% names(result))
  expect_true("median" %in% names(result))
  expect_true("lower_50" %in% names(result))
  expect_true("upper_50" %in% names(result))
  expect_true("lower_90" %in% names(result))
  expect_true("upper_90" %in% names(result))

  # Check samples column preserved
  expect_true("samples" %in% names(result))

  # Check mean values
  expect_equal(result$mean[1], mean(1:100))
  expect_equal(result$mean[2], mean(51:150))
})

test_that("has_prediction_samples detects nested format", {
  nested_df <- tibble::tibble(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    samples = list(c(10, 12, 8))
  )

  expect_true(has_prediction_samples(nested_df))
})

test_that("has_prediction_samples detects wide format", {
  wide_df <- data.frame(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    sample_0 = c(10),
    sample_1 = c(12)
  )

  expect_true(has_prediction_samples(wide_df))
})

test_that("has_prediction_samples returns FALSE for no samples", {
  df <- data.frame(
    time_period = c("2013-04"),
    location = c("Bokeo"),
    disease_cases = c(10)
  )

  expect_false(has_prediction_samples(df))
})

test_that("detect_prediction_format correctly identifies formats", {
  # Nested format
  nested_df <- tibble::tibble(
    time_period = c("2013-04"),
    samples = list(c(10, 12, 8))
  )
  expect_equal(detect_prediction_format(nested_df), "nested")

  # Wide format
  wide_df <- data.frame(
    time_period = c("2013-04"),
    sample_0 = c(10),
    sample_1 = c(12)
  )
  expect_equal(detect_prediction_format(wide_df), "wide")

  # Long format
  long_df <- data.frame(
    time_period = c("2013-04", "2013-04"),
    sample_id = c(1, 2),
    prediction = c(10, 12)
  )
  expect_equal(detect_prediction_format(long_df), "long")

  # No samples
  df <- data.frame(
    time_period = c("2013-04"),
    disease_cases = c(10)
  )
  expect_equal(detect_prediction_format(df), "none")
})

test_that("round-trip conversion preserves data (wide -> nested -> wide)", {
  original <- data.frame(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    sample_0 = c(10, 20),
    sample_1 = c(12, 22),
    sample_2 = c(8, 18)
  )

  result <- original |>
    predictions_from_wide() |>
    predictions_to_wide()

  expect_equal(result$time_period, original$time_period)
  expect_equal(result$location, original$location)
  expect_equal(result$sample_0, original$sample_0)
  expect_equal(result$sample_1, original$sample_1)
  expect_equal(result$sample_2, original$sample_2)
})

test_that("round-trip conversion preserves data (nested -> long -> nested)", {
  original <- tibble::tibble(
    time_period = c("2013-04", "2013-05"),
    location = c("Bokeo", "Bokeo"),
    samples = list(
      c(10, 12, 8),
      c(20, 22, 18)
    )
  )

  result <- original |>
    predictions_to_long() |>
    predictions_from_long()

  expect_equal(result$time_period, original$time_period)
  expect_equal(result$location, original$location)
  expect_equal(result$samples[[1]], original$samples[[1]])
  expect_equal(result$samples[[2]], original$samples[[2]])
})
