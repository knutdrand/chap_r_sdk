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

# Tests for run_info parameter
test_that("handle_train passes run_info to train function", {
  run_info_received <- NULL

  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    run_info_received <<- run_info
    return(list(test = "model"))
  }

  # Create test data file with yearmonth format
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02", "2020-01", "2020-02"),
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18)
  )
  readr::write_csv(test_data, temp_csv)

  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)

  handle_train(train_fn, c(temp_csv))

  # Check run_info was passed with CHAP contract fields
  expect_type(run_info_received, "list")
  expect_true("prediction_length" %in% names(run_info_received))
  expect_true("additional_continuous_covariates" %in% names(run_info_received))
  expect_true("future_covariate_origin" %in% names(run_info_received))
  # During training, prediction_length is NA (no future_data)
  expect_true(is.na(run_info_received$prediction_length))
  expect_equal(run_info_received$additional_continuous_covariates, character(0))

  # Cleanup
  unlink("model.rds")
  setwd(old_wd)
  unlink(temp_csv)
})

test_that("handle_predict passes run_info to predict function", {
  run_info_received <- NULL

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list(), run_info = list()) {
    run_info_received <<- run_info
    future_data |>
      dplyr::mutate(samples = purrr::map(seq_len(dplyr::n()), ~c(10)))
  }

  temp_dir <- tempdir()
  old_wd <- getwd()
  setwd(temp_dir)

  # Create test files
  historic_data <- data.frame(
    time_period = c("2020-01", "2020-02", "2020-01", "2020-02"),
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18)
  )
  readr::write_csv(historic_data, "historic.csv")

  future_data <- data.frame(
    time_period = c("2020-03", "2020-04", "2020-03", "2020-04"),
    location = rep(c("A", "B"), each = 2)
  )
  readr::write_csv(future_data, "future.csv")

  saveRDS(list(test = "model"), "model.rds")

  handle_predict(predict_fn, c("historic.csv", "future.csv", "model.rds"))

  # Check run_info was passed with CHAP contract fields
  expect_type(run_info_received, "list")
  expect_equal(run_info_received$prediction_length, 2L)  # 2 unique time periods
  expect_true("additional_continuous_covariates" %in% names(run_info_received))
  expect_true("future_covariate_origin" %in% names(run_info_received))
  expect_equal(run_info_received$additional_continuous_covariates, character(0))

  # Cleanup
  unlink(c("historic.csv", "future.csv", "model.rds", "model_predictions.csv"))
  setwd(old_wd)
})

# Tests for --run-info file loading
test_that("handle_train loads run_info from file when provided", {
  run_info_received <- NULL

  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    run_info_received <<- run_info
    return(list(test = "model"))
  }

  # Create test data file
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02"),
    location = c("A", "A"),
    disease_cases = c(10, 12)
  )
  readr::write_csv(test_data, temp_csv)

  # Create run_info YAML file
  run_info_yaml <- tempfile(fileext = ".yaml")
  yaml::write_yaml(list(
    prediction_length = 6L,
    additional_continuous_covariates = c("rainfall", "temperature"),
    future_covariate_origin = "chap_baseline"
  ), run_info_yaml)

  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)

  handle_train(train_fn, c(temp_csv, "--run-info", run_info_yaml))

  # Check run_info was loaded from file
  expect_type(run_info_received, "list")
  expect_equal(run_info_received$prediction_length, 6L)
  expect_equal(run_info_received$additional_continuous_covariates, c("rainfall", "temperature"))
  expect_equal(run_info_received$future_covariate_origin, "chap_baseline")

  # Cleanup
  unlink("model.rds")
  setwd(old_wd)
  unlink(c(temp_csv, run_info_yaml))
})

test_that("handle_predict loads run_info from file when provided", {
  run_info_received <- NULL

  predict_fn <- function(historic_data, future_data, saved_model,
                         model_configuration = list(), run_info = list()) {
    run_info_received <<- run_info
    future_data |>
      dplyr::mutate(samples = purrr::map(seq_len(dplyr::n()), ~c(10)))
  }

  temp_dir <- tempdir()
  old_wd <- getwd()
  setwd(temp_dir)

  # Create test files
  historic_data <- data.frame(
    time_period = c("2020-01", "2020-02"),
    location = c("A", "A"),
    disease_cases = c(10, 12)
  )
  readr::write_csv(historic_data, "historic.csv")

  future_data <- data.frame(
    time_period = c("2020-03", "2020-04"),
    location = c("A", "A")
  )
  readr::write_csv(future_data, "future.csv")

  saveRDS(list(test = "model"), "model.rds")

  # Create run_info JSON file
  run_info_json <- tempfile(fileext = ".json")
  jsonlite::write_json(list(
    prediction_length = 12L,
    additional_continuous_covariates = list("population"),
    future_covariate_origin = "user_provided"
  ), run_info_json, auto_unbox = TRUE)

  handle_predict(predict_fn, c("historic.csv", "future.csv", "model.rds", "--run-info", run_info_json))

  # Check run_info was loaded from file
  expect_type(run_info_received, "list")
  expect_equal(run_info_received$prediction_length, 12L)
  expect_equal(run_info_received$additional_continuous_covariates, "population")
  expect_equal(run_info_received$future_covariate_origin, "user_provided")

  # Cleanup
  unlink(c("historic.csv", "future.csv", "model.rds", "model_predictions.csv", run_info_json))
  setwd(old_wd)
})

test_that("extract_run_info_arg separates --run-info from positional args", {
  # Test --run-info value format
  result <- extract_run_info_arg(c("train", "data.csv", "--run-info", "info.yaml"))
  expect_equal(result$positional, c("train", "data.csv"))
  expect_equal(result$run_info_path, "info.yaml")

  # Test --run-info=value format
  result2 <- extract_run_info_arg(c("train", "data.csv", "--run-info=info.json"))
  expect_equal(result2$positional, c("train", "data.csv"))
  expect_equal(result2$run_info_path, "info.json")

  # Test no --run-info
  result3 <- extract_run_info_arg(c("train", "data.csv"))
  expect_equal(result3$positional, c("train", "data.csv"))
  expect_null(result3$run_info_path)
})

test_that("load_run_info loads YAML file", {
  run_info_yaml <- tempfile(fileext = ".yaml")
  yaml::write_yaml(list(
    prediction_length = 3L,
    additional_continuous_covariates = c("x", "y"),
    future_covariate_origin = "test"
  ), run_info_yaml)

  result <- load_run_info(run_info_yaml)

  expect_equal(result$prediction_length, 3L)
  expect_equal(result$additional_continuous_covariates, c("x", "y"))
  expect_equal(result$future_covariate_origin, "test")

  unlink(run_info_yaml)
})

test_that("load_run_info loads JSON file", {
  run_info_json <- tempfile(fileext = ".json")
  jsonlite::write_json(list(
    prediction_length = 5L,
    additional_continuous_covariates = list("a", "b"),
    future_covariate_origin = jsonlite::unbox(NULL)
  ), run_info_json, auto_unbox = TRUE, null = "null")

  result <- load_run_info(run_info_json)

  expect_equal(result$prediction_length, 5L)
  expect_equal(result$additional_continuous_covariates, c("a", "b"))

  unlink(run_info_json)
})

test_that("load_run_info falls back to build_run_info when no file", {
  # Create test tsibble
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02"),
    location = c("A", "A"),
    disease_cases = c(10, 12),
    rainfall = c(100, 110)
  )

  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)
  ts_data <- load_tsibble(temp_csv)

  result <- load_run_info(NULL, training_data = ts_data)

  expect_type(result, "list")
  expect_true("prediction_length" %in% names(result))
  expect_true("additional_continuous_covariates" %in% names(result))
  expect_true("rainfall" %in% result$additional_continuous_covariates)

  unlink(temp_csv)
})

# Tests for model_info parameter
test_that("handle_info displays model_info", {
  model_info <- list(
    period_type = "month",
    allows_additional_continuous_covariates = TRUE,
    required_covariates = c("population", "rainfall")
  )

  output <- capture.output(handle_info(NULL, model_info))
  output_text <- paste(output, collapse = "\n")

  expect_match(output_text, "period_type: month")
  expect_match(output_text, "allows_additional_continuous_covariates: true")
  expect_match(output_text, "population")
  expect_match(output_text, "rainfall")
})

test_that("handle_info works with only model_config_schema", {
  schema <- list(title = "Test Schema")

  output <- capture.output(handle_info(schema, NULL))
  output_text <- paste(output, collapse = "\n")

  expect_match(output_text, "Configuration Schema")
  expect_match(output_text, "Test Schema")
})

test_that("handle_info works with both model_info and schema", {
  model_info <- list(period_type = "week")
  schema <- list(title = "Test Schema")

  output <- capture.output(handle_info(schema, model_info))
  output_text <- paste(output, collapse = "\n")

  expect_match(output_text, "period_type: week")
  expect_match(output_text, "Configuration Schema")
})

# Tests for JSON output format (chapkit integration)
test_that("handle_info outputs valid JSON with --format json", {
  model_info <- list(
    period_type = "month",
    allows_additional_continuous_covariates = TRUE,
    required_covariates = c("population", "rainfall")
  )
  schema <- list(
    title = "Test Schema",
    type = "object",
    properties = list(
      param1 = list(type = "integer", default = 5)
    )
  )

  output <- capture.output(handle_info(schema, model_info, format = "json"))
  output_text <- paste(output, collapse = "\n")

  # Parse as JSON - should not error
  parsed <- jsonlite::fromJSON(output_text)

  # Check service_info structure
  expect_true("service_info" %in% names(parsed))
  expect_equal(parsed$service_info$period_type, "month")
  expect_true(parsed$service_info$allows_additional_continuous_covariates)
  expect_equal(parsed$service_info$required_covariates, c("population", "rainfall"))

  # Check config_schema structure
  expect_true("config_schema" %in% names(parsed))
  expect_equal(parsed$config_schema$title, "Test Schema")
})

test_that("handle_info JSON format provides defaults when model_info is NULL", {
  schema <- list(title = "Test Schema")

  output <- capture.output(handle_info(schema, NULL, format = "json"))
  output_text <- paste(output, collapse = "\n")

  parsed <- jsonlite::fromJSON(output_text)

  # Should have default values

  expect_equal(parsed$service_info$period_type, "any")
  expect_false(parsed$service_info$allows_additional_continuous_covariates)
  expect_equal(parsed$service_info$required_covariates, list())
})

test_that("handle_info JSON format handles NULL schema", {
  model_info <- list(period_type = "week")

  output <- capture.output(handle_info(NULL, model_info, format = "json"))
  output_text <- paste(output, collapse = "\n")

  parsed <- jsonlite::fromJSON(output_text)

  expect_equal(parsed$service_info$period_type, "week")
  expect_null(parsed$config_schema)
})

test_that("build_info_json creates correct structure", {
  model_info <- list(
    period_type = "day",
    allows_additional_continuous_covariates = FALSE,
    required_covariates = c("temperature")
  )
  schema <- list(title = "My Schema")

  result <- build_info_json(schema, model_info)

  expect_true(is.list(result))
  expect_equal(names(result), c("service_info", "config_schema", "environment"))
  expect_equal(result$service_info$period_type, "day")
  expect_false(result$service_info$allows_additional_continuous_covariates)
  expect_equal(result$service_info$required_covariates, list("temperature"))
  expect_equal(result$config_schema$title, "My Schema")
})

test_that("create_chap_cli info subcommand respects --format json", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) list()
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) tibble::tibble()

  model_info <- list(period_type = "month")
  schema <- list(title = "Test")

  output <- capture.output(
    create_chap_cli(train_fn, predict_fn, schema, model_info, args = c("info", "--format", "json"))
  )
  output_text <- paste(output, collapse = "\n")

  # Should be valid JSON
  parsed <- jsonlite::fromJSON(output_text)
  expect_equal(parsed$service_info$period_type, "month")
})

test_that("create_chapkit_cli info subcommand respects --format json", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) list()
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) tibble::tibble()

  model_info <- list(period_type = "week", required_covariates = c("rainfall"))
  schema <- list(title = "Chapkit Test")

  output <- capture.output(
    create_chapkit_cli(train_fn, predict_fn, schema, model_info, args = c("info", "--format", "json"))
  )
  output_text <- paste(output, collapse = "\n")

  # Should be valid JSON
  parsed <- jsonlite::fromJSON(output_text)
  expect_equal(parsed$service_info$period_type, "week")
  expect_equal(parsed$service_info$required_covariates, "rainfall")
  expect_equal(parsed$config_schema$title, "Chapkit Test")
})

test_that("handle_info defaults to yaml format", {
  schema <- list(title = "Test Schema")

  # Without format argument, should produce YAML
  output <- capture.output(handle_info(schema, NULL))
  output_text <- paste(output, collapse = "\n")

  expect_match(output_text, "Model Information")
  expect_match(output_text, "Configuration Schema")
})

# Tests for build_run_info and detect_period_type
test_that("detect_period_type identifies yearmonth", {
  values <- tsibble::yearmonth(c("2020-01", "2020-02"))
  expect_equal(detect_period_type(values), "month")
})

test_that("detect_period_type identifies yearweek", {
  values <- tsibble::yearweek(c("2020 W01", "2020 W02"))
  expect_equal(detect_period_type(values), "week")
})

test_that("detect_period_type identifies Date", {
  values <- as.Date(c("2020-01-01", "2020-01-02"))
  expect_equal(detect_period_type(values), "day")
})

test_that("detect_period_type returns unknown for other types", {
  values <- c(1, 2, 3)
  expect_equal(detect_period_type(values), "unknown")
})

# Tests for additional_continuous_covariates in run_info
test_that("build_run_info detects additional continuous covariates", {
  # Create test data with covariates
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02", "2020-01", "2020-02"),
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18),
    rainfall = c(100, 120, 90, 110),
    temperature = c(25, 26, 24, 25),
    population = c(1000, 1000, 2000, 2000)
  )

  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)

  ts_data <- load_tsibble(temp_csv)
  run_info <- build_run_info(training_data = ts_data)

  expect_true("additional_continuous_covariates" %in% names(run_info))
  expect_type(run_info$additional_continuous_covariates, "character")

  # Should detect rainfall, temperature, population as additional covariates
  expect_true("rainfall" %in% run_info$additional_continuous_covariates)
  expect_true("temperature" %in% run_info$additional_continuous_covariates)
  expect_true("population" %in% run_info$additional_continuous_covariates)

  # Should NOT include standard columns
 expect_false("time_period" %in% run_info$additional_continuous_covariates)
  expect_false("location" %in% run_info$additional_continuous_covariates)
  expect_false("disease_cases" %in% run_info$additional_continuous_covariates)

  unlink(temp_csv)
})

test_that("build_run_info returns empty vector when no additional covariates", {
  # Create minimal test data without extra covariates
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02"),
    location = c("A", "A"),
    disease_cases = c(10, 12)
  )

  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)

  ts_data <- load_tsibble(temp_csv)
  run_info <- build_run_info(training_data = ts_data)

  expect_equal(run_info$additional_continuous_covariates, character(0))

  unlink(temp_csv)
})

test_that("build_run_info excludes non-numeric columns from covariates", {
  # Create test data with a character column
  test_data <- data.frame(
    time_period = c("2020-01", "2020-02"),
    location = c("A", "A"),
    disease_cases = c(10, 12),
    rainfall = c(100, 120),
    region_name = c("North", "North")  # Character column - should be excluded
  )

  temp_csv <- tempfile(fileext = ".csv")
  readr::write_csv(test_data, temp_csv)

  ts_data <- load_tsibble(temp_csv)
  run_info <- build_run_info(training_data = ts_data)

  expect_true("rainfall" %in% run_info$additional_continuous_covariates)
  expect_false("region_name" %in% run_info$additional_continuous_covariates)

  unlink(temp_csv)
})

test_that("create_chap_cli requires subcommand argument", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {}

  expect_error(
    create_chap_cli(train_fn, predict_fn, args = character(0)),
    "Usage: Rscript model.R"
  )
})

test_that("create_chap_cli rejects invalid subcommand", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {}

  expect_error(
    create_chap_cli(train_fn, predict_fn, args = c("invalid")),
    "Invalid subcommand"
  )
})

test_that("handle_train validates required arguments", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_train(train_fn, character(0)),
    "Usage: Rscript model.R train"
  )
})

test_that("handle_train validates file existence", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_train(train_fn, c("nonexistent_file.csv")),
    "Training data file not found"
  )
})

test_that("handle_predict validates required arguments", {
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
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
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    expect_s3_class(training_data, "tbl_ts")
    expect_type(model_configuration, "list")
    expect_type(run_info, "list")
    return(list(means = "test_model"))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
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

# Tests for chapkit-compatible CLI

test_that("parse_named_args parses --name value format", {
  args <- c("--data", "file.csv", "--config", "config.yml")
  result <- parse_named_args(args)

  expect_equal(result$data, "file.csv")
  expect_equal(result$config, "config.yml")
})

test_that("parse_named_args parses --name=value format", {
  args <- c("--data=file.csv", "--config=config.yml")
  result <- parse_named_args(args)

  expect_equal(result$data, "file.csv")
  expect_equal(result$config, "config.yml")
})

test_that("parse_named_args applies defaults", {
  args <- c("--data", "file.csv")
  defaults <- list(data = NULL, config = "default.yml", model = "model.rds")
  result <- parse_named_args(args, defaults)

  expect_equal(result$data, "file.csv")
  expect_equal(result$config, "default.yml")
  expect_equal(result$model, "model.rds")
})

test_that("parse_named_args handles boolean flags", {
  args <- c("--verbose", "--data", "file.csv")
  result <- parse_named_args(args)

  expect_true(result$verbose)
  expect_equal(result$data, "file.csv")
})

test_that("parse_named_args handles values with equals signs", {
  args <- c("--query=a=b=c")
  result <- parse_named_args(args)

  expect_equal(result$query, "a=b=c")
})

test_that("create_chapkit_cli validates function inputs", {
  expect_error(
    create_chapkit_cli("not_a_function", function() {}, args = c("train")),
    "train_fn must be a function"
  )

  expect_error(
    create_chapkit_cli(function() {}, "not_a_function", args = c("train")),
    "predict_fn must be a function"
  )
})

test_that("create_chapkit_cli requires subcommand argument", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {}

  expect_error(
    create_chapkit_cli(train_fn, predict_fn, args = character(0)),
    "Usage: Rscript model.R"
  )
})

test_that("create_chapkit_cli rejects invalid subcommand", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {}
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {}

  expect_error(
    create_chapkit_cli(train_fn, predict_fn, args = c("invalid")),
    "Invalid subcommand"
  )
})

test_that("handle_chapkit_train validates required arguments", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_chapkit_train(train_fn, character(0), "config.yml", "model.rds"),
    "Missing required argument: --data"
  )
})

test_that("handle_chapkit_train validates file existence", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(test = "model"))
  }

  expect_error(
    handle_chapkit_train(train_fn, c("--data", "nonexistent_file.csv"), "config.yml", "model.rds"),
    "Training data file not found"
  )
})

test_that("handle_chapkit_predict validates required arguments", {
  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
    return(data.frame())
  }

  # Missing --output
  expect_error(
    handle_chapkit_predict(predict_fn, c("--historic", "h.csv", "--future", "f.csv"), "config.yml", "model.rds"),
    "Missing required argument.*--output"
  )

  # Missing multiple
  expect_error(
    handle_chapkit_predict(predict_fn, c("--historic", "h.csv"), "config.yml", "model.rds"),
    "Missing required argument.*--future.*--output"
  )
})

test_that("create_chapkit_cli train subcommand works end-to-end", {
  # Create mock train function
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    expect_s3_class(training_data, "tbl_ts")
    expect_type(model_configuration, "list")
    expect_type(run_info, "list")
    return(list(means = "test_model"))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
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

  result <- create_chapkit_cli(train_fn, predict_fn, args = c("train", "--data", temp_csv))

  expect_true(file.exists("model.rds"))
  expect_equal(result, "model.rds")

  # Cleanup
  unlink("model.rds")
  setwd(old_wd)
  unlink(temp_csv)
})

test_that("create_chapkit_cli train respects custom model path", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(means = "test_model"))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
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

  result <- create_chapkit_cli(train_fn, predict_fn,
    args = c("train", "--data", temp_csv, "--model", "custom_model.rds"))

  expect_true(file.exists("custom_model.rds"))
  expect_equal(result, "custom_model.rds")

  # Cleanup
  unlink("custom_model.rds")
  setwd(old_wd)
  unlink(temp_csv)
})

test_that("create_chapkit_cli predict subcommand works end-to-end", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(means = data.frame(location = c("A", "B"), mean_cases = c(11, 16.5))))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
    future_data |>
      dplyr::left_join(saved_model$means, by = "location") |>
      dplyr::mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
      dplyr::select(-mean_cases)
  }

  # Create test data files
  temp_dir <- tempdir()
  old_wd <- getwd()
  setwd(temp_dir)

  historic_data <- data.frame(
    time_period = 1:4,
    location = rep(c("A", "B"), each = 2),
    disease_cases = c(10, 12, 15, 18)
  )
  readr::write_csv(historic_data, "historic.csv")

  future_data <- data.frame(
    time_period = c(5, 5),
    location = c("A", "B")
  )
  readr::write_csv(future_data, "future.csv")

  # Save a model
  saveRDS(list(means = data.frame(location = c("A", "B"), mean_cases = c(11, 16.5))), "model.rds")

  result <- create_chapkit_cli(train_fn, predict_fn,
    args = c("predict", "--historic", "historic.csv", "--future", "future.csv", "--output", "predictions.csv"))

  expect_true(file.exists("predictions.csv"))
  expect_equal(result, "predictions.csv")

  # Check predictions format
  preds <- readr::read_csv("predictions.csv", show_col_types = FALSE)
  expect_true("sample_0" %in% names(preds))

  # Cleanup
  unlink(c("historic.csv", "future.csv", "model.rds", "predictions.csv"))
  setwd(old_wd)
})

test_that("create_chapkit_cli uses default paths correctly", {
  train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
    return(list(test = "model"))
  }

  predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list()) {
    return(data.frame(samples = I(list(c(1)))))
  }

  # Create test files
  temp_dir <- tempdir()
  old_wd <- getwd()
  setwd(temp_dir)

  test_data <- data.frame(
    time_period = 1:2,
    location = c("A", "A"),
    disease_cases = c(10, 12)
  )
  readr::write_csv(test_data, "data.csv")

  # Test with default model path
  result <- create_chapkit_cli(train_fn, predict_fn,
    args = c("train", "--data", "data.csv"))
  expect_equal(result, "model.rds")
  expect_true(file.exists("model.rds"))

  # Test with custom default model path
  result2 <- create_chapkit_cli(train_fn, predict_fn,
    default_model_path = "my_model.rds",
    args = c("train", "--data", "data.csv"))
  expect_equal(result2, "my_model.rds")
  expect_true(file.exists("my_model.rds"))

  # Cleanup
  unlink(c("data.csv", "model.rds", "my_model.rds"))
  setwd(old_wd)
})
