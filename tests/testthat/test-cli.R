test_that("create_chap_cli validates function inputs", {
  expect_error(
    create_chap_cli("not_a_function", function() {}, args = c("train")),
    "train_fn must be a function"
  )

  expect_error(
    create_chap_cli(function() {}, "not_a_function", args = c("train")),
    "predict_fn must be a function"
  )
})

test_that("create_chap_cli requires subcommand argument", {
  train_fn <- function(training_data, model_configuration = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list()) {}

  expect_error(
    create_chap_cli(train_fn, predict_fn, args = character(0)),
    "Usage: Rscript model.R"
  )
})

test_that("create_chap_cli rejects invalid subcommand", {
  train_fn <- function(training_data, model_configuration = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list()) {}

  expect_error(
    create_chap_cli(train_fn, predict_fn, args = c("invalid")),
    "Invalid subcommand"
  )
})

test_that("handle_train validates required arguments", {
  train_fn <- function(training_data, model_configuration = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_train(train_fn, character(0)),
    "Usage: Rscript model.R train"
  )
})

test_that("handle_train validates file existence", {
  train_fn <- function(training_data, model_configuration = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_train(train_fn, c("nonexistent_file.csv")),
    "Training data file not found"
  )
})

test_that("handle_predict validates required arguments", {
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list()) {
    return(data.frame())
  }

  expect_error(
    handle_predict(predict_fn, c("historic.csv", "future.csv")),
    "Usage: Rscript model.R predict"
  )
})

test_that("handle_info displays schema when provided", {
  schema <- list(
    title = "Test Schema",
    type = "object",
    properties = list(
      param1 = list(type = "string")
    )
  )

  expect_output(
    handle_info(schema),
    "Configuration Schema"
  )
})

test_that("handle_info handles NULL schema", {
  expect_output(
    handle_info(NULL),
    "No configuration schema defined"
  )
})

test_that("create_chap_cli train subcommand works end-to-end", {
  # Create mock train function
  train_fn <- function(training_data, model_configuration = list()) {
    expect_s3_class(training_data, "tbl_ts")
    expect_type(model_configuration, "list")
    return(list(means = "test_model"))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list()) {
    return(data.frame(prediction = 1))
  }

  # Create test data file
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    time_period = 1:4,
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18)
  )
  readr::write_csv(test_data, temp_csv)

  # Create temporary directory for output
  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)

  result <- create_chap_cli(train_fn, predict_fn, args = c("train", temp_csv))

  expect_true(file.exists("model.rds"))
  expect_equal(result, "model.rds")

  # Cleanup
  unlink("model.rds")
  setwd(old_wd)
  unlink(temp_csv)
})
