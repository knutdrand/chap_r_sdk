#' Create Unified CHAP CLI
#'
#' Creates a unified command-line interface for both training and prediction.
#' Automatically handles all file I/O, parsing, and conversion. Model functions
#' receive loaded tsibbles and configuration lists, not file paths.
#'
#' This is the standard way to create CHAP-compatible CLI scripts, providing
#' a single unified interface with subcommand dispatch.
#'
#' @param train_fn Training function with signature:
#'   \code{function(training_data, model_configuration = list(), run_info = list())} where
#'   \code{training_data} is a tsibble, \code{model_configuration} is a list of user-defined
#'   configuration options, and \code{run_info} is a list containing CHAP-provided run
#'   information (see Run Info section). Should return a model object that will be
#'   automatically saved as RDS.
#' @param predict_fn Prediction function with signature:
#'   \code{function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list())}
#'   where all data inputs are tsibbles, \code{saved_model} is a loaded object,
#'   \code{model_configuration} is a list of user-defined configuration options,
#'   and \code{run_info} is a list containing CHAP-provided run information.
#'   Must return a tibble with a \code{samples} list-column containing numeric vectors.
#'   For deterministic models, use a single sample per forecast unit
#'   (e.g., \code{samples = list(c(42))}). For probabilistic models, include multiple
#'   Monte Carlo samples. The CLI automatically converts the nested samples to wide
#'   CSV format (sample_0, sample_1, ...) for CHAP.
#'
#'   **Important**: \code{historic_data} may contain more recent observations than
#'   the original training data. CHAP may call predict with updated data after the
#'   model was trained. For time series models, you should typically refit the model
#'   to \code{historic_data} before forecasting. Use \code{saved_model} to store model
#'   hyperparameters or structure that should persist across predictions, rather than
#'   the fitted model itself. See \code{examples/arima_model/} for a demonstration of
#'   this pattern using \code{fable::refit()}.
#' @param model_config_schema Optional model configuration schema (reserved for future use).
#'   Can be used with the "info" subcommand to display schema information.
#' @param model_info Optional list describing the model's data requirements and capabilities.
#'   Used by CHAP to validate data before sending to the model and displayed via the "info"
#'   subcommand. See Model Info section for details.
#' @param args Command line arguments (defaults to \code{commandArgs(trailingOnly = TRUE)})
#'
#' @section Model Info:
#' The \code{model_info} parameter describes what data and configuration the model expects.
#' This information is used by CHAP to validate inputs and displayed via the "info" subcommand.
#' \describe{
#'   \item{period_type}{Character. The temporal resolution the model expects ("month", "week", "day").
#'     CHAP will ensure data is provided at this resolution.}
#'   \item{allows_additional_continuous_covariates}{Logical. If TRUE, the model can accept
#'     additional continuous covariates beyond those it specifically requires. CHAP will list
#'     these in \code{run_info$additional_continuous_covariates}.}
#'   \item{required_covariates}{Character vector. Names of columns that must be present in the

#'     data (e.g., \code{c("population", "rainfall")}). CHAP will validate these exist before
#'     calling the model.}
#' }
#'
#' @section Run Info:
#' The \code{run_info} parameter is provided by CHAP and passed to both train and predict
#' functions. It contains runtime information about the current CHAP execution:
#' \describe{
#'   \item{prediction_length}{Integer. The number of time periods the model is expected
#'     to forecast.}
#'   \item{additional_continuous_covariates}{Character vector. Names of additional covariate
#'     columns that the user has specified beyond the standard columns. Models that declared
#'     \code{allows_additional_continuous_covariates = TRUE} in their \code{model_info}
#'     should use these columns.}
#'   \item{future_covariate_origin}{Character or NULL. Origin/source of future covariate
#'     forecasts (e.g., "chap_baseline", "user_provided").}
#' }
#'
#' The run_info is passed to the CLI via the \code{--run-info} argument pointing to a
#' YAML or JSON file. If not provided, a default run_info is constructed from the data.
#'
#' @return Invisible result of the called function
#' @export
#'
#' @examples
#' \dontrun{
#' # In model.R file:
#' library(chap.r.sdk)
#' library(dplyr)
#'
#' train_my_model <- function(training_data, model_configuration = list(),
#'                            run_info = list()) {
#'   # training_data is already a tsibble - no file I/O needed!
#'   # run_info contains prediction_length, n_locations, period_type
#'   means <- training_data |>
#'     group_by(location) |>
#'     summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
#'   return(list(means = means))
#' }
#'
#' predict_my_model <- function(historic_data, future_data, saved_model,
#'                               model_configuration = list(), run_info = list()) {
#'   # All inputs are already loaded - no file I/O needed!
#'   # run_info contains prediction_length, n_locations, period_type
#'   # Return samples list-column (single sample for deterministic model)
#'   future_data |>
#'     as_tibble() |>
#'     left_join(saved_model$means, by = "location") |>
#'     mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
#'     select(-mean_cases)
#' }
#'
#' config_schema <- list(
#'   title = "My Model Configuration",
#'   type = "object",
#'   properties = list()
#' )
#'
#' model_info <- list(
#'   period_type = "month",
#'   allows_additional_continuous_covariates = TRUE,
#'   required_covariates = c("population", "rainfall")
#' )
#'
#' # Single function call enables full CLI!
#' if (!interactive()) {
#'   create_chap_cli(train_my_model, predict_my_model, config_schema, model_info)
#' }
#'
#' # Command line usage:
#' # Rscript model.R train data.csv [config.yaml] [--run-info run_info.yaml]
#' # Rscript model.R predict historic.csv future.csv model.rds [config.yaml] [--run-info run_info.yaml]
#' # Rscript model.R info
#' }
create_chap_cli <- function(train_fn, predict_fn, model_config_schema = NULL,
                            model_info = NULL,
                            args = commandArgs(trailingOnly = TRUE)) {

  # Validate inputs
  if (!is.function(train_fn)) {
    stop("train_fn must be a function")
  }
  if (!is.function(predict_fn)) {
    stop("predict_fn must be a function")
  }

  # Parse subcommand
  if (length(args) < 1) {
    stop("Usage: Rscript model.R <train|predict|info> [arguments...]\n",
         "  train:   Rscript model.R train <training_data> [model_config]\n",
         "  predict: Rscript model.R predict <historic_data> <future_data> <saved_model> [model_config]\n",
         "  info:    Rscript model.R info")
  }

  subcommand <- tolower(args[1])
  subcommand_args <- if (length(args) > 1) args[-1] else character(0)

  # Dispatch to appropriate handler
  result <- switch(subcommand,
    "train" = handle_train(train_fn, subcommand_args, model_config_schema),
    "predict" = handle_predict(predict_fn, subcommand_args, model_config_schema),
    "info" = handle_info(model_config_schema, model_info),
    stop("Invalid subcommand: '", subcommand, "'. Use 'train', 'predict', or 'info'")
  )

  invisible(result)
}

#' Handle train subcommand
#'
#' Internal function that handles the "train" subcommand for create_chap_cli().
#' Loads training data, parses configuration, calls the training function,
#' and saves the resulting model.
#'
#' @param train_fn User-provided training function
#' @param args Subcommand arguments (training_data path, optional config path, optional --run-info)
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved model file
#' @keywords internal
handle_train <- function(train_fn, args, schema = NULL) {
  # Extract --run-info if present
  parsed <- extract_run_info_arg(args)
  positional_args <- parsed$positional
  run_info_path <- parsed$run_info_path

  # Parse positional arguments
  if (length(positional_args) < 1) {
    stop("Usage: Rscript model.R train <training_data> [model_config] [--run-info <path>]")
  }

  training_data_path <- positional_args[1]
  config_path <- if (length(positional_args) >= 2) positional_args[2] else NULL

  # Validate files exist
  if (!file.exists(training_data_path)) {
    stop("Training data file not found: ", training_data_path)
  }
  if (!is.null(config_path) && config_path != "" && !file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  # Load and parse data
  message("Loading training data from: ", training_data_path)
  training_data <- load_tsibble(training_data_path)

  # Load configuration with optional validation and defaults
  config <- load_and_validate_config(config_path, schema)
  if (!is.null(config_path) && config_path != "") {
    message("Loaded configuration from: ", config_path)
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(run_info_path, training_data = training_data)

  # Call training function
  message("Training model...")
  model <- tryCatch({
    train_fn(training_data, config, run_info)
  }, error = function(e) {
    stop("Training failed: ", e$message, call. = FALSE)
  })

  # Save model
  model_path <- save_model(model, output_path = "model.rds")

  return(model_path)
}

#' Handle predict subcommand
#'
#' Internal function that handles the "predict" subcommand for create_chap_cli().
#' Loads historic data, future data, saved model, and configuration, calls the
#' prediction function, and saves the resulting predictions.
#'
#' @param predict_fn User-provided prediction function
#' @param args Subcommand arguments (historic_data, future_data, saved_model, optional config, optional --run-info)
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved predictions file
#' @keywords internal
handle_predict <- function(predict_fn, args, schema = NULL) {
  # Extract --run-info if present
  parsed <- extract_run_info_arg(args)
  positional_args <- parsed$positional
  run_info_path <- parsed$run_info_path

  # Parse positional arguments
  if (length(positional_args) < 3) {
    stop("Usage: Rscript model.R predict <historic_data> <future_data> <saved_model> [model_config] [--run-info <path>]")
  }

  historic_path <- positional_args[1]
  future_path <- positional_args[2]
  model_path <- positional_args[3]
  config_path <- if (length(positional_args) >= 4) positional_args[4] else NULL

  # Validate files exist
  if (!file.exists(historic_path)) {
    stop("Historic data file not found: ", historic_path)
  }
  if (!file.exists(future_path)) {
    stop("Future data file not found: ", future_path)
  }
  if (!file.exists(model_path)) {
    stop("Model file not found: ", model_path)
  }
  if (!is.null(config_path) && config_path != "" && !file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  # Load data
  message("Loading historic data from: ", historic_path)
  historic_data <- load_tsibble(historic_path)

  message("Loading future data from: ", future_path)
  future_data <- load_tsibble(future_path)

  message("Loading model from: ", model_path)
  model <- readRDS(model_path)

  # Load configuration with optional validation and defaults
  config <- load_and_validate_config(config_path, schema)
  if (!is.null(config_path) && config_path != "") {
    message("Loaded configuration from: ", config_path)
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(run_info_path, training_data = historic_data, future_data = future_data)

  # Call prediction function
  message("Generating predictions...")
  predictions <- tryCatch({
    predict_fn(historic_data, future_data, model, config, run_info)
  }, error = function(e) {
    stop("Prediction failed: ", e$message, call. = FALSE)
  })

  # Save predictions
  predictions_path <- sub("\\.rds$", "_predictions.csv", model_path)
  save_predictions(predictions, predictions_path)

  return(predictions_path)
}

#' Handle info subcommand
#'
#' Internal function that handles the "info" subcommand for create_chap_cli().
#' Displays model information, data requirements, and configuration schema.
#'
#' @param model_config_schema Optional configuration schema to display
#' @param model_info Optional list with model data requirements (period_type,
#'   allows_additional_continuous_covariates, required_covariates)
#' @return NULL (invisibly)
#' @keywords internal
handle_info <- function(model_config_schema, model_info = NULL) {
  cat("Model Information\n")
  cat("=================\n\n")

  # Display model info (data requirements)
  if (!is.null(model_info)) {
    cat("Data Requirements:\n")

    if (!is.null(model_info$period_type)) {
      cat("  period_type: ", model_info$period_type, "\n", sep = "")
    }

    if (!is.null(model_info$allows_additional_continuous_covariates)) {
      cat("  allows_additional_continuous_covariates: ",
          tolower(as.character(model_info$allows_additional_continuous_covariates)), "\n", sep = "")
    }

    if (!is.null(model_info$required_covariates) && length(model_info$required_covariates) > 0) {
      cat("  required_covariates:\n")
      for (cov in model_info$required_covariates) {
        cat("    - ", cov, "\n", sep = "")
      }
    }

    cat("\n")
  }

  # Display configuration schema
  if (is.null(model_config_schema)) {
    cat("No configuration schema defined.\n")
  } else {
    cat("Configuration Schema:\n")
    cat(yaml::as.yaml(model_config_schema))
  }

  invisible(NULL)
}

#' Create Chapkit-Compatible CLI
#'
#' Creates a command-line interface compatible with chapkit's ShellModelRunner.
#' Uses named arguments (--data, --historic, --future, --output) instead of
#' positional arguments. Config and model paths have sensible defaults but
#' can be overridden.
#'
#' This CLI style is designed for integration with chapkit's ML service framework,
#' which manages workspaces and file paths automatically.
#'
#' @param train_fn Training function with signature:
#'   \code{function(training_data, model_configuration = list(), run_info = list())} where
#'   \code{training_data} is a tsibble, \code{model_configuration} is a list of user-defined
#'   configuration options, and \code{run_info} is a list containing CHAP-provided run
#'   information (see \code{\link{create_chap_cli}} for details).
#'   Should return a model object that will be automatically saved as RDS.
#' @param predict_fn Prediction function with signature:
#'   \code{function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list())}
#'   where all data inputs are tsibbles, \code{saved_model} is a loaded object,
#'   \code{model_configuration} is a list of user-defined configuration options,
#'   and \code{run_info} is a list containing CHAP-provided run information.
#'   Must return a tibble with a \code{samples} list-column containing numeric vectors.
#' @param model_config_schema Optional model configuration schema (for info subcommand).
#' @param model_info Optional list describing the model's data requirements and capabilities.
#'   See \code{\link{create_chap_cli}} for details on the model_info structure.
#' @param default_config_path Default path to config file (default: "config.yml")
#' @param default_model_path Default path to model file (default: "model.rds")
#' @param args Command line arguments (defaults to \code{commandArgs(trailingOnly = TRUE)})
#'
#' @return Invisible result of the called function
#' @export
#'
#' @details
#' ## Training Command
#' ```
#' Rscript model.R train --data <path> [--config <path>] [--model <path>] [--run-info <path>]
#' ```
#' - `--data`: Path to training data CSV (required)
#' - `--config`: Path to YAML config file (default: config.yml)
#' - `--model`: Path to save trained model (default: model.rds)
#' - `--run-info`: Path to run_info YAML/JSON file (optional, provided by CHAP)
#'
#' ## Prediction Command
#' ```
#' Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>] [--run-info <path>]
#' ```
#' - `--historic`: Path to historic data CSV (required)
#' - `--future`: Path to future data CSV (required)
#' - `--output`: Path to write predictions CSV (required)
#' - `--config`: Path to YAML config file (default: config.yml)
#' - `--model`: Path to load trained model (default: model.rds)
#' - `--run-info`: Path to run_info YAML/JSON file (optional, provided by CHAP)
#'
#' ## Info Command
#' ```
#' Rscript model.R info
#' ```
#'
#' ## Chapkit Integration
#' Configure ShellModelRunner in chapkit:
#' ```python
#' runner = ShellModelRunner(
#'     train_command="Rscript model.R train --data {data_file} --run-info {run_info_file}",
#'     predict_command="Rscript model.R predict --historic {historic_file} --future {future_file} --output {output_file} --run-info {run_info_file}"
#' )
#' ```
#'
#' @examples
#' \dontrun{
#' library(chap.r.sdk)
#'
#' train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
#'   list(mean = mean(training_data$disease_cases, na.rm = TRUE))
#' }
#'
#' predict_fn <- function(historic_data, future_data, saved_model,
#'                        model_configuration = list(), run_info = list()) {
#'   future_data |>
#'     dplyr::mutate(samples = purrr::map(seq_len(dplyr::n()), ~c(saved_model$mean)))
#' }
#'
#' if (!interactive()) {
#'   create_chapkit_cli(train_fn, predict_fn)
#' }
#' }
create_chapkit_cli <- function(train_fn, predict_fn, model_config_schema = NULL,
                                model_info = NULL,
                                default_config_path = "config.yml",
                                default_model_path = "model.rds",
                                args = commandArgs(trailingOnly = TRUE)) {

  # Validate inputs
  if (!is.function(train_fn)) {
    stop("train_fn must be a function")
  }
  if (!is.function(predict_fn)) {
    stop("predict_fn must be a function")
  }

  # Parse subcommand
  if (length(args) < 1) {
    stop("Usage: Rscript model.R <train|predict|info> [arguments...]\n",
         "  train:   Rscript model.R train --data <path> [--config <path>] [--model <path>]\n",
         "  predict: Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>]\n",
         "  info:    Rscript model.R info")
  }

  subcommand <- tolower(args[1])
  subcommand_args <- if (length(args) > 1) args[-1] else character(0)

  # Dispatch to appropriate handler
  result <- switch(subcommand,
    "train" = handle_chapkit_train(train_fn, subcommand_args, default_config_path, default_model_path, model_config_schema),
    "predict" = handle_chapkit_predict(predict_fn, subcommand_args, default_config_path, default_model_path, model_config_schema),
    "info" = handle_info(model_config_schema, model_info),
    stop("Invalid subcommand: '", subcommand, "'. Use 'train', 'predict', or 'info'")
  )

  invisible(result)
}

#' Parse named arguments from command line
#'
#' Parses command line arguments in the form --name value or --name=value.
#'
#' @param args Character vector of command line arguments
#' @param defaults Named list of default values for arguments
#' @return Named list of parsed argument values
#' @keywords internal
parse_named_args <- function(args, defaults = list()) {
  result <- defaults

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]

    if (startsWith(arg, "--")) {
      # Check for --name=value format
      if (grepl("=", arg)) {
        parts <- strsplit(arg, "=", fixed = TRUE)[[1]]
        name <- sub("^--", "", parts[1])
        value <- paste(parts[-1], collapse = "=")
        result[[name]] <- value
      } else {
        # --name value format
        name <- sub("^--", "", arg)
        if (i < length(args) && !startsWith(args[i + 1], "--")) {
          result[[name]] <- args[i + 1]
          i <- i + 1
        } else {
          # Flag without value (boolean)
          result[[name]] <- TRUE
        }
      }
    }
    i <- i + 1
  }

  return(result)
}

#' Handle chapkit train subcommand
#'
#' Internal function that handles the "train" subcommand for create_chapkit_cli().
#' Uses named arguments (--data, --config, --model).
#'
#' @param train_fn User-provided training function
#' @param args Subcommand arguments
#' @param default_config_path Default config file path
#' @param default_model_path Default model output path
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved model file
#' @keywords internal
handle_chapkit_train <- function(train_fn, args, default_config_path, default_model_path, schema = NULL) {
  # Parse named arguments with defaults
  parsed <- parse_named_args(args, list(
    data = NULL,
    config = default_config_path,
    model = default_model_path,
    "run-info" = NULL
  ))

  # Validate required arguments
  if (is.null(parsed$data)) {
    stop("Missing required argument: --data <path>\n",
         "Usage: Rscript model.R train --data <path> [--config <path>] [--model <path>] [--run-info <path>]")
  }

  # Validate files exist
  if (!file.exists(parsed$data)) {
    stop("Training data file not found: ", parsed$data)
  }

  # Load and parse data
  message("Loading training data from: ", parsed$data)
  training_data <- load_tsibble(parsed$data)

  # Load configuration with optional validation and defaults
  config <- if (file.exists(parsed$config)) {
    message("Loading configuration from: ", parsed$config)
    load_and_validate_config(parsed$config, schema)
  } else {
    # Apply defaults from schema even if no config file
    if (!is.null(schema)) {
      apply_config_defaults(list(), schema)
    } else {
      list()
    }
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(parsed$"run-info", training_data = training_data)

  # Call training function
  message("Training model...")
  model <- tryCatch({
    train_fn(training_data, config, run_info)
  }, error = function(e) {
    stop("Training failed: ", e$message, call. = FALSE)
  })

  # Save model
  model_path <- save_model(model, output_path = parsed$model)

  return(model_path)
}

#' Handle chapkit predict subcommand
#'
#' Internal function that handles the "predict" subcommand for create_chapkit_cli().
#' Uses named arguments (--historic, --future, --output, --config, --model).
#'
#' @param predict_fn User-provided prediction function
#' @param args Subcommand arguments
#' @param default_config_path Default config file path
#' @param default_model_path Default model input path
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved predictions file
#' @keywords internal
handle_chapkit_predict <- function(predict_fn, args, default_config_path, default_model_path, schema = NULL) {
  # Parse named arguments with defaults
  parsed <- parse_named_args(args, list(
    historic = NULL,
    future = NULL,
    output = NULL,
    config = default_config_path,
    model = default_model_path,
    "run-info" = NULL
  ))

  # Validate required arguments
  missing_args <- c()
  if (is.null(parsed$historic)) missing_args <- c(missing_args, "--historic")
  if (is.null(parsed$future)) missing_args <- c(missing_args, "--future")
  if (is.null(parsed$output)) missing_args <- c(missing_args, "--output")

  if (length(missing_args) > 0) {
    stop("Missing required argument(s): ", paste(missing_args, collapse = ", "), "\n",
         "Usage: Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>] [--run-info <path>]")
  }

  # Validate files exist
  if (!file.exists(parsed$historic)) {
    stop("Historic data file not found: ", parsed$historic)
  }
  if (!file.exists(parsed$future)) {
    stop("Future data file not found: ", parsed$future)
  }
  if (!file.exists(parsed$model)) {
    stop("Model file not found: ", parsed$model)
  }

  # Load data
  message("Loading historic data from: ", parsed$historic)
  historic_data <- load_tsibble(parsed$historic)

  message("Loading future data from: ", parsed$future)
  future_data <- load_tsibble(parsed$future)

  message("Loading model from: ", parsed$model)
  model <- readRDS(parsed$model)

  # Load configuration with optional validation and defaults
  config <- if (file.exists(parsed$config)) {
    message("Loading configuration from: ", parsed$config)
    load_and_validate_config(parsed$config, schema)
  } else {
    # Apply defaults from schema even if no config file
    if (!is.null(schema)) {
      apply_config_defaults(list(), schema)
    } else {
      list()
    }
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(parsed$"run-info", training_data = historic_data, future_data = future_data)

  # Call prediction function
  message("Generating predictions...")
  predictions <- tryCatch({
    predict_fn(historic_data, future_data, model, config, run_info)
  }, error = function(e) {
    stop("Prediction failed: ", e$message, call. = FALSE)
  })

  # Save predictions to specified output path
  save_predictions(predictions, parsed$output)

  return(parsed$output)
}

#' Extract --run-info argument from command line args
#'
#' Separates the --run-info argument from positional arguments.
#'
#' @param args Character vector of command line arguments
#' @return A list with:
#'   \itemize{
#'     \item \code{positional}: Character vector of positional arguments
#'     \item \code{run_info_path}: Path to run_info file, or NULL if not provided
#'   }
#' @keywords internal
extract_run_info_arg <- function(args) {
  run_info_path <- NULL
  positional <- character(0)

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]

    if (arg == "--run-info" && i < length(args)) {
      run_info_path <- args[i + 1]
      i <- i + 2
    } else if (startsWith(arg, "--run-info=")) {
      run_info_path <- sub("^--run-info=", "", arg)
      i <- i + 1
    } else {
      positional <- c(positional, arg)
      i <- i + 1
    }
  }

  list(
    positional = positional,
    run_info_path = run_info_path
  )
}

#' Load run_info from file or build default
#'
#' Loads run_info from a YAML/JSON file if provided, otherwise builds a default
#' run_info from the data. This is used when CHAP doesn't provide run_info
#' (e.g., during local testing).
#'
#' @param run_info_path Path to run_info YAML/JSON file, or NULL
#' @param training_data Optional tsibble with training data (for building default)
#' @param future_data Optional tsibble with future data (for building default)
#' @return A list containing run_info fields
#' @keywords internal
load_run_info <- function(run_info_path, training_data = NULL, future_data = NULL) {
  if (!is.null(run_info_path) && file.exists(run_info_path)) {
    message("Loading run_info from: ", run_info_path)

    # Determine file type and load
    if (grepl("\\.(yaml|yml)$", run_info_path, ignore.case = TRUE)) {
      run_info <- yaml::yaml.load_file(run_info_path)
    } else if (grepl("\\.json$", run_info_path, ignore.case = TRUE)) {
      run_info <- jsonlite::fromJSON(run_info_path, simplifyVector = TRUE)
    } else {
      # Try YAML first, then JSON
      run_info <- tryCatch(
        yaml::yaml.load_file(run_info_path),
        error = function(e) jsonlite::fromJSON(run_info_path, simplifyVector = TRUE)
      )
    }

    # Ensure required fields have defaults
    if (is.null(run_info$prediction_length)) {
      run_info$prediction_length <- NA_integer_
    }
    if (is.null(run_info$additional_continuous_covariates)) {
      run_info$additional_continuous_covariates <- character(0)
    }
    if (is.null(run_info$future_covariate_origin)) {
      run_info$future_covariate_origin <- NULL
    }

    return(run_info)
  }

  # Build default run_info from data
  build_run_info(training_data = training_data, future_data = future_data)
}

#' Build default run_info object from data
#'
#' Constructs a default run_info list by inferring values from the loaded data.
#' This is used as a fallback when CHAP doesn't provide a run_info file
#' (e.g., during local development or testing).
#'
#' In production, CHAP provides run_info directly via a file. This function
#' is primarily used for:
#' \itemize{
#'   \item Local testing without CHAP
#'   \item Model validation via \code{validate_model_io()}
#'   \item Backwards compatibility
#' }
#'
#' @param training_data Optional tsibble with training data
#' @param future_data Optional tsibble with future data
#' @return A list containing:
#'   \itemize{
#'     \item \code{prediction_length}: Number of unique time periods in future_data (NA for train)
#'     \item \code{additional_continuous_covariates}: Character vector of numeric column names
#'       beyond the standard columns (time index, key columns, disease_cases)
#'     \item \code{future_covariate_origin}: Always NULL for default run_info
#'   }
#' @export
build_run_info <- function(training_data = NULL, future_data = NULL) {
  # Use whichever data is available
  data <- if (!is.null(future_data)) future_data else training_data

  if (is.null(data)) {
    return(list(
      prediction_length = NA_integer_,
      additional_continuous_covariates = character(0),
      future_covariate_origin = NULL
    ))
  }

  # Get the time index column and key columns
  time_col <- tsibble::index_var(data)
  key_cols <- tsibble::key_vars(data)

  # Calculate prediction_length from future_data
  prediction_length <- if (!is.null(future_data)) {
    length(unique(future_data[[time_col]]))
  } else {
    NA_integer_
  }

  # Detect additional continuous covariates
  # Standard columns that are NOT additional covariates
  standard_cols <- c(time_col, key_cols, "disease_cases")

  # Get all column names
  all_cols <- names(data)

  # Find numeric columns that are not standard columns
  additional_covariates <- character(0)
  for (col in all_cols) {
    if (!(col %in% standard_cols) && is.numeric(data[[col]])) {
      additional_covariates <- c(additional_covariates, col)
    }
  }

  list(
    prediction_length = prediction_length,
    additional_continuous_covariates = additional_covariates,
    future_covariate_origin = NULL
  )
}

#' Detect period type from time values
#'
#' Determines the temporal resolution of a time column based on its class.
#'
#' @param time_values Vector of time values
#' @return Character string: "month", "week", "quarter", "day", or "unknown"
#' @keywords internal
detect_period_type <- function(time_values) {
  if (inherits(time_values, "yearmonth")) {
    return("month")
  } else if (inherits(time_values, "yearweek")) {
    return("week")
  } else if (inherits(time_values, "yearquarter")) {
    return("quarter")
  } else if (inherits(time_values, "Date")) {
    return("day")
  } else if (inherits(time_values, c("POSIXct", "POSIXlt"))) {
    return("day")  # Could be finer, but default to day

  } else {
    return("unknown")
  }
}
