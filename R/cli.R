#' Create Chap CLI
#'
#' Creates a command-line interface for Chap-compatible models using optparse.
#' Uses named arguments (--data, --historic, --future, --output) for clear,
#' explicit command-line usage. Config and model paths have sensible defaults
#' but can be overridden.
#'
#' This CLI style is designed for integration with chapkit's ML service framework,
#' which manages workspaces and file paths automatically.
#'
#' @param train_fn Training function with signature:
#'   \code{function(training_data, model_configuration = list(), run_info = list())} where
#'   \code{training_data} is a tsibble, \code{model_configuration} is a list of user-defined
#'   configuration options, and \code{run_info} is a list containing Chap-provided run
#'   information (see Run Info section). Should return a model object that will be
#'   automatically saved as RDS.
#' @param predict_fn Prediction function with signature:
#'   \code{function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list())}
#'   where all data inputs are tsibbles, \code{saved_model} is a loaded object,
#'   \code{model_configuration} is a list of user-defined configuration options,
#'   and \code{run_info} is a list containing Chap-provided run information.
#'   Must return a tibble with a \code{samples} list-column containing numeric vectors.
#'   For deterministic models, use a single sample per forecast unit
#'   (e.g., \code{samples = list(c(42))}). For probabilistic models, include multiple
#'   Monte Carlo samples. The CLI automatically converts the nested samples to wide
#'   CSV format (sample_0, sample_1, ...) for Chap.
#'
#'   **Important**: \code{historic_data} may contain more recent observations than
#'   the original training data. Chap may call predict with updated data after the
#'   model was trained. For time series models, you should typically refit the model
#'   to \code{historic_data} before forecasting. Use \code{saved_model} to store model
#'   hyperparameters or structure that should persist across predictions, rather than
#'   the fitted model itself. See \code{examples/arima_model/} for a demonstration of
#'   this pattern using \code{fable::refit()}.
#' @param model_config_schema Optional model configuration schema (reserved for future use).
#'   Can be used with the "info" subcommand to display schema information.
#' @param model_info Optional list describing the model's data requirements and capabilities.
#'   Used by Chap to validate data before sending to the model and displayed via the "info"
#'   subcommand. See Model Info section for details.
#' @param default_config_path Default path to config file (default: "config.yml")
#' @param default_model_path Default path to model file (default: "model.rds")
#' @param args Command line arguments (defaults to \code{commandArgs(trailingOnly = TRUE)})
#'
#' @section Model Info:
#' The \code{model_info} parameter describes what data and configuration the model expects.
#' This information is used by Chap to validate inputs and displayed via the "info" subcommand.
#' \describe{
#'   \item{period_type}{Character. The temporal resolution the model expects ("month", "week", "day").
#'     Chap will ensure data is provided at this resolution.}
#'   \item{allows_additional_continuous_covariates}{Logical. If TRUE, the model can accept
#'     additional continuous covariates beyond those it specifically requires. Chap will list
#'     these in \code{run_info$additional_continuous_covariates}.}
#'   \item{required_covariates}{Character vector. Names of columns that must be present in the
#'     data (e.g., \code{c("population", "rainfall")}). Chap will validate these exist before
#'     calling the model.}
#' }
#'
#' @section Run Info:
#' The \code{run_info} parameter is provided by Chap and passed to both train and predict
#' functions. It contains runtime information about the current Chap execution:
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
#' @details
#' ## Training Command
#' ```
#' Rscript model.R train --data <path> [--config <path>] [--model <path>] [--run-info <path>]
#' ```
#' - `--data`: Path to training data CSV (required)
#' - `--config`: Path to YAML config file (default: config.yml)
#' - `--model`: Path to save trained model (default: model.rds)
#' - `--run-info`: Path to run_info YAML/JSON file (optional, provided by Chap)
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
#' - `--run-info`: Path to run_info YAML/JSON file (optional, provided by Chap)
#'
#' ## Info Command
#' ```
#' Rscript model.R info [--format yaml|json]
#' ```
#' - `--format`: Output format, either "yaml" (default, human-readable) or "json"
#'   (machine-readable for chapkit integration)
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
#' library(chapr)
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
#' # Rscript model.R train --data data.csv [--config config.yml] [--run-info run_info.yaml]
#' # Rscript model.R predict --historic historic.csv --future future.csv \
#' #     --output predictions.csv [--config config.yml]
#' # Rscript model.R info                    # Human-readable YAML output
#' # Rscript model.R info --format json      # Machine-readable JSON for chapkit
#' }
create_chap_cli <- function(train_fn, predict_fn, model_config_schema = NULL,
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
         "  info:    Rscript model.R info [--format yaml|json]")
  }

  subcommand <- tolower(args[1])
  subcommand_args <- if (length(args) > 1) args[-1] else character(0)

  # Dispatch to appropriate handler
  result <- switch(subcommand,
    "train" = {
      parser <- make_train_parser(default_config_path, default_model_path)
      opts <- optparse::parse_args(parser, args = subcommand_args)
      handle_train(train_fn, opts, model_config_schema)
    },
    "predict" = {
      parser <- make_predict_parser(default_config_path, default_model_path)
      opts <- optparse::parse_args(parser, args = subcommand_args)
      handle_predict(predict_fn, opts, model_config_schema)
    },
    "info" = {
      parser <- make_info_parser()
      opts <- optparse::parse_args(parser, args = subcommand_args)
      handle_info(model_config_schema, model_info, format = opts$format)
    },
    stop("Invalid subcommand: '", subcommand, "'. Use 'train', 'predict', or 'info'")
  )

  invisible(result)
}

#' Create optparse parser for train subcommand
#'
#' @param default_config_path Default config file path
#' @param default_model_path Default model output path
#' @return An OptionParser object
#' @keywords internal
make_train_parser <- function(default_config_path = "config.yml",
                               default_model_path = "model.rds") {
  optparse::OptionParser(
    usage = "usage: %prog train [options]",
    description = "Train the model on provided data",
    option_list = list(
      optparse::make_option(
        c("-d", "--data"),
        type = "character",
        default = NULL,
        help = "Path to training data CSV (required)"
      ),
      optparse::make_option(
        c("-c", "--config"),
        type = "character",
        default = default_config_path,
        help = paste0("Path to YAML config file [default: ", default_config_path, "]")
      ),
      optparse::make_option(
        c("-m", "--model"),
        type = "character",
        default = default_model_path,
        help = paste0("Path to save trained model [default: ", default_model_path, "]")
      ),
      optparse::make_option(
        c("-r", "--run-info"),
        type = "character",
        default = NULL,
        dest = "run_info",
        help = "Path to run_info YAML/JSON file (optional, provided by Chap)"
      )
    )
  )
}

#' Create optparse parser for predict subcommand
#'
#' @param default_config_path Default config file path
#' @param default_model_path Default model input path
#' @return An OptionParser object
#' @keywords internal
make_predict_parser <- function(default_config_path = "config.yml",
                                 default_model_path = "model.rds") {
  optparse::OptionParser(
    usage = "usage: %prog predict [options]",
    description = "Generate predictions using a trained model",
    option_list = list(
      optparse::make_option(
        c("-H", "--historic"),
        type = "character",
        default = NULL,
        help = "Path to historic data CSV (required)"
      ),
      optparse::make_option(
        c("-f", "--future"),
        type = "character",
        default = NULL,
        help = "Path to future data CSV (required)"
      ),
      optparse::make_option(
        c("-o", "--output"),
        type = "character",
        default = NULL,
        help = "Path to write predictions CSV (required)"
      ),
      optparse::make_option(
        c("-c", "--config"),
        type = "character",
        default = default_config_path,
        help = paste0("Path to YAML config file [default: ", default_config_path, "]")
      ),
      optparse::make_option(
        c("-m", "--model"),
        type = "character",
        default = default_model_path,
        help = paste0("Path to load trained model [default: ", default_model_path, "]")
      ),
      optparse::make_option(
        c("-r", "--run-info"),
        type = "character",
        default = NULL,
        dest = "run_info",
        help = "Path to run_info YAML/JSON file (optional, provided by Chap)"
      )
    )
  )
}

#' Create optparse parser for info subcommand
#'
#' @return An OptionParser object
#' @keywords internal
make_info_parser <- function() {
  optparse::OptionParser(
    usage = "usage: %prog info [options]",
    description = "Display model information and configuration schema",
    option_list = list(
      optparse::make_option(
        c("-F", "--format"),
        type = "character",
        default = "yaml",
        help = "Output format: yaml (human-readable) or json (machine-readable) [default: yaml]"
      )
    )
  )
}

#' Handle train subcommand
#'
#' Internal function that handles the "train" subcommand for create_chap_cli().
#' Loads training data, parses configuration, calls the training function,
#' and saves the resulting model.
#'
#' @param train_fn User-provided training function
#' @param opts Parsed options from optparse
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved model file
#' @keywords internal
handle_train <- function(train_fn, opts, schema = NULL) {
  # Validate required arguments
  if (is.null(opts$data)) {
    stop("Missing required argument: --data <path>\n",
         "Usage: Rscript model.R train --data <path> [--config <path>] [--model <path>] [--run-info <path>]")
  }

  # Validate files exist
  if (!file.exists(opts$data)) {
    stop("Training data file not found: ", opts$data)
  }

  # Load and parse data
  message("Loading training data from: ", opts$data)
  training_data <- load_tsibble(opts$data)

  # Load configuration with optional validation and defaults
  config <- if (file.exists(opts$config)) {
    message("Loading configuration from: ", opts$config)
    load_and_validate_config(opts$config, schema)
  } else {
    # Apply defaults from schema even if no config file
    if (!is.null(schema)) {
      apply_config_defaults(list(), schema)
    } else {
      list()
    }
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(opts$run_info, training_data = training_data)

  # Call training function
  message("Training model...")
  model <- tryCatch({
    train_fn(training_data, config, run_info)
  }, error = function(e) {
    stop("Training failed: ", e$message, call. = FALSE)
  })

  # Save model
  model_path <- save_model(model, output_path = opts$model)

  return(model_path)
}

#' Handle predict subcommand
#'
#' Internal function that handles the "predict" subcommand for create_chap_cli().
#' Loads historic data, future data, saved model, and configuration, calls the
#' prediction function, and saves the resulting predictions.
#'
#' @param predict_fn User-provided prediction function
#' @param opts Parsed options from optparse
#' @param schema Optional JSON Schema for config validation
#' @return Path to saved predictions file
#' @keywords internal
handle_predict <- function(predict_fn, opts, schema = NULL) {
  # Validate required arguments
  missing_args <- c()
  if (is.null(opts$historic)) missing_args <- c(missing_args, "--historic")
  if (is.null(opts$future)) missing_args <- c(missing_args, "--future")
  if (is.null(opts$output)) missing_args <- c(missing_args, "--output")

  if (length(missing_args) > 0) {
    stop("Missing required argument(s): ", paste(missing_args, collapse = ", "), "\n",
         "Usage: Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>] [--run-info <path>]")
  }

  # Validate files exist
  if (!file.exists(opts$historic)) {
    stop("Historic data file not found: ", opts$historic)
  }
  if (!file.exists(opts$future)) {
    stop("Future data file not found: ", opts$future)
  }
  if (!file.exists(opts$model)) {
    stop("Model file not found: ", opts$model)
  }

  # Load data
  message("Loading historic data from: ", opts$historic)
  historic_data <- load_tsibble(opts$historic)

  message("Loading future data from: ", opts$future)
  future_data <- load_tsibble(opts$future)

  message("Loading model from: ", opts$model)
  model <- readRDS(opts$model)

  # Load configuration with optional validation and defaults
  config <- if (file.exists(opts$config)) {
    message("Loading configuration from: ", opts$config)
    load_and_validate_config(opts$config, schema)
  } else {
    # Apply defaults from schema even if no config file
    if (!is.null(schema)) {
      apply_config_defaults(list(), schema)
    } else {
      list()
    }
  }

  # Load run_info from file if provided, otherwise build default
  run_info <- load_run_info(opts$run_info, training_data = historic_data, future_data = future_data)

  # Call prediction function
  message("Generating predictions...")
  predictions <- tryCatch({
    predict_fn(historic_data, future_data, model, config, run_info)
  }, error = function(e) {
    stop("Prediction failed: ", e$message, call. = FALSE)
  })

  # Save predictions to specified output path
  save_predictions(predictions, opts$output)

  return(opts$output)
}

#' Handle info subcommand
#'
#' Internal function that handles the "info" subcommand for create_chap_cli().
#' Displays model information, data requirements, and configuration schema.
#'
#' @param model_config_schema Optional configuration schema to display
#' @param model_info Optional list with model data requirements (period_type,
#'   allows_additional_continuous_covariates, required_covariates)
#' @param format Output format: "yaml" (default, human-readable) or "json"
#'   (machine-readable for chapkit integration)
#' @return NULL (invisibly)
#' @keywords internal
handle_info <- function(model_config_schema, model_info = NULL, format = "yaml") {
  # Validate format

  format <- match.arg(format, c("yaml", "json"))

  if (format == "json") {
    # Structured JSON output for chapkit integration
    output <- build_info_json(model_config_schema, model_info)
    cat(jsonlite::toJSON(output, auto_unbox = TRUE, pretty = TRUE, null = "null"))
    cat("\n")
  } else {
    # Human-readable YAML output (original behavior)
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
  }

  invisible(NULL)
}

#' Build structured JSON output for info command
#'
#' Creates a structured output combining service_info, config_schema, and
#' environment info for programmatic consumption by chapkit.
#'
#' @param model_config_schema Optional configuration schema
#' @param model_info Optional list with model data requirements
#' @return A list with service_info, config_schema, and environment fields
#' @keywords internal
build_info_json <- function(model_config_schema, model_info = NULL) {
  # Build service_info from model_info

  service_info <- list(
    period_type = if (!is.null(model_info$period_type)) model_info$period_type else "any",
    required_covariates = if (!is.null(model_info$required_covariates)) {
      as.list(model_info$required_covariates)
    } else {
      list()
    },
    allows_additional_continuous_covariates = if (!is.null(model_info$allows_additional_continuous_covariates)) {
      model_info$allows_additional_continuous_covariates
    } else {
      FALSE
    }
  )

  # Get environment info (from environment.R)
  environment_info <- tryCatch(
    get_environment_info(),
    error = function(e) {
      list(
        r_version = NULL,
        has_renv_lock = FALSE,
        system_deps = list()
      )
    }
  )

  # Build output structure
  list(
    service_info = service_info,
    config_schema = model_config_schema,
    environment = environment_info
  )
}

#' Load run_info from file or build default
#'
#' Loads run_info from a YAML/JSON file if provided, otherwise builds a default
#' run_info from the data. This is used when Chap doesn't provide run_info
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
#' This is used as a fallback when Chap doesn't provide a run_info file
#' (e.g., during local development or testing).
#'
#' In production, Chap provides run_info directly via a file. This function
#' is primarily used for:
#' \itemize{
#'   \item Local testing without Chap
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
