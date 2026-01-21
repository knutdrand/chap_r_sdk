# Configuration Schema and Validation
#
# This module provides functionality for defining, validating, and working with
# model configuration schemas. It uses JSON Schema (draft-07) for validation.

# ============================================================================
# Schema Property Helpers
# ============================================================================

#' Define an Integer Schema Property
#'
#' Creates a JSON Schema property definition for an integer value.
#'
#' @param description Description of the parameter (displayed to users)
#' @param default Default value if not provided
#' @param minimum Minimum allowed value (inclusive)
#' @param maximum Maximum allowed value (inclusive)
#' @param exclusive_minimum Minimum value (exclusive)
#' @param exclusive_maximum Maximum value (exclusive)
#'
#' @return A list representing a JSON Schema integer property
#' @export
#'
#' @examples
#' # Simple integer with default
#' schema_integer(description = "Number of samples", default = 100L)
#'
#' # Integer with range constraints
#' schema_integer(
#'   description = "Lag periods",
#'   default = 3L,
#'   minimum = 1L,
#'   maximum = 12L
#' )
schema_integer <- function(description = NULL, default = NULL,
                           minimum = NULL, maximum = NULL,
                           exclusive_minimum = NULL, exclusive_maximum = NULL) {
  prop <- list(type = "integer")

  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) prop$default <- as.integer(default)
  if (!is.null(minimum)) prop$minimum <- as.integer(minimum)
  if (!is.null(maximum)) prop$maximum <- as.integer(maximum)
  if (!is.null(exclusive_minimum)) prop$exclusiveMinimum <- as.integer(exclusive_minimum)
  if (!is.null(exclusive_maximum)) prop$exclusiveMaximum <- as.integer(exclusive_maximum)

  prop
}


#' Define a Number Schema Property
#'
#' Creates a JSON Schema property definition for a numeric (float) value.
#'
#' @param description Description of the parameter
#' @param default Default value if not provided
#' @param minimum Minimum allowed value (inclusive)
#' @param maximum Maximum allowed value (inclusive)
#' @param exclusive_minimum Minimum value (exclusive)
#' @param exclusive_maximum Maximum value (exclusive)
#'
#' @return A list representing a JSON Schema number property
#' @export
#'
#' @examples
#' # Learning rate with constraints
#' schema_number(
#'   description = "Learning rate",
#'   default = 0.01,
#'   minimum = 0,
#'   maximum = 1
#' )
schema_number <- function(description = NULL, default = NULL,
                          minimum = NULL, maximum = NULL,
                          exclusive_minimum = NULL, exclusive_maximum = NULL) {
  prop <- list(type = "number")


  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) prop$default <- as.numeric(default)
  if (!is.null(minimum)) prop$minimum <- as.numeric(minimum)
  if (!is.null(maximum)) prop$maximum <- as.numeric(maximum)
  if (!is.null(exclusive_minimum)) prop$exclusiveMinimum <- as.numeric(exclusive_minimum)
  if (!is.null(exclusive_maximum)) prop$exclusiveMaximum <- as.numeric(exclusive_maximum)

  prop
}


#' Define a String Schema Property
#'
#' Creates a JSON Schema property definition for a string value.
#'
#' @param description Description of the parameter
#' @param default Default value if not provided
#' @param min_length Minimum string length
#' @param max_length Maximum string length
#' @param pattern Regular expression pattern the string must match
#'
#' @return A list representing a JSON Schema string property
#' @export
#'
#' @examples
#' # Simple string
#' schema_string(description = "Model name", default = "my_model")
#'
#' # String with pattern constraint
#' schema_string(
#'   description = "Date format",
#'   pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
#' )
schema_string <- function(description = NULL, default = NULL,
                          min_length = NULL, max_length = NULL,
                          pattern = NULL) {
  prop <- list(type = "string")

  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) prop$default <- as.character(default)
  if (!is.null(min_length)) prop$minLength <- as.integer(min_length)
  if (!is.null(max_length)) prop$maxLength <- as.integer(max_length)
  if (!is.null(pattern)) prop$pattern <- pattern

  prop
}


#' Define a Boolean Schema Property
#'
#' Creates a JSON Schema property definition for a boolean value.
#'
#' @param description Description of the parameter
#' @param default Default value if not provided
#'
#' @return A list representing a JSON Schema boolean property
#' @export
#'
#' @examples
#' schema_boolean(description = "Use cross-validation", default = TRUE)
schema_boolean <- function(description = NULL, default = NULL) {
  prop <- list(type = "boolean")

  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) prop$default <- as.logical(default)

  prop
}


#' Define an Enum Schema Property
#'
#' Creates a JSON Schema property definition for a value from a fixed set of options.
#'
#' @param values Character vector of allowed values
#' @param description Description of the parameter
#' @param default Default value if not provided (must be one of \code{values})
#'
#' @return A list representing a JSON Schema enum property
#' @export
#'
#' @examples
#' schema_enum(
#'   values = c("arima", "ets", "prophet"),
#'   description = "Forecasting method",
#'   default = "arima"
#' )
schema_enum <- function(values, description = NULL, default = NULL) {
  if (!is.character(values) || length(values) == 0) {
    stop("values must be a non-empty character vector")
  }

  prop <- list(type = "string", enum = as.list(values))

  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) {
    if (!default %in% values) {
      stop("default value '", default, "' must be one of: ", paste(values, collapse = ", "))
    }
    prop$default <- default
  }

  prop
}


#' Define an Array Schema Property
#'
#' Creates a JSON Schema property definition for an array of values.
#'
#' @param items Schema for array items (e.g., \code{list(type = "string")})
#' @param description Description of the parameter
#' @param default Default value if not provided
#' @param min_items Minimum number of items
#' @param max_items Maximum number of items
#' @param unique_items Whether items must be unique
#'
#' @return A list representing a JSON Schema array property
#' @export
#'
#' @examples
#' # Array of strings
#' schema_array(
#'   items = list(type = "string"),
#'   description = "List of covariate names",
#'   default = list("rainfall", "temperature")
#' )
#'
#' # Array of integers with constraints
#' schema_array(
#'   items = list(type = "integer"),
#'   description = "Lag values to use",
#'   min_items = 1,
#'   max_items = 10
#' )
schema_array <- function(items, description = NULL, default = NULL,
                         min_items = NULL, max_items = NULL,
                         unique_items = NULL) {
  prop <- list(type = "array", items = items)

  if (!is.null(description)) prop$description <- description
  if (!is.null(default)) prop$default <- as.list(default)
  if (!is.null(min_items)) prop$minItems <- as.integer(min_items)
  if (!is.null(max_items)) prop$maxItems <- as.integer(max_items)
  if (!is.null(unique_items)) prop$uniqueItems <- as.logical(unique_items)

  prop
}


# ============================================================================
# Schema Creation
# ============================================================================

#' Create a Model Configuration Schema
#'
#' Creates a JSON Schema for validating model configuration. The schema defines
#' what configuration options a model accepts, their types, constraints, and
#' default values.
#'
#' @param title Title for the schema (typically the model name)
#' @param description Description of the configuration
#' @param properties Named list of property definitions created with
#'   \code{schema_integer()}, \code{schema_number()}, \code{schema_string()},
#'   \code{schema_boolean()}, \code{schema_enum()}, or \code{schema_array()}
#' @param required Character vector of required property names
#' @param additional_properties Whether to allow properties not defined in schema
#'   (default: TRUE for flexibility)
#'
#' @return A list representing a complete JSON Schema object
#' @export
#'
#' @examples
#' # Define a configuration schema
#' my_schema <- create_config_schema(
#'   title = "My Forecasting Model",
#'   description = "Configuration for disease case forecasting",
#'   properties = list(
#'     n_samples = schema_integer(
#'       description = "Number of Monte Carlo samples for predictions",
#'       default = 100L,
#'       minimum = 1L,
#'       maximum = 10000L
#'     ),
#'     learning_rate = schema_number(
#'       description = "Learning rate for model optimization",
#'       default = 0.01,
#'       minimum = 0,
#'       maximum = 1
#'     ),
#'     method = schema_enum(
#'       values = c("arima", "ets", "prophet"),
#'       description = "Forecasting method to use",
#'       default = "arima"
#'     ),
#'     use_covariates = schema_boolean(
#'       description = "Whether to include additional covariates",
#'       default = TRUE
#'     )
#'   ),
#'   required = c("n_samples")
#' )
#'
#' # Use with create_chap_cli
#' \dontrun{
#' create_chap_cli(train_fn, predict_fn, model_config_schema = my_schema)
#' }
create_config_schema <- function(title = NULL, description = NULL,
                                  properties = list(),
                                  required = character(0),
                                  additional_properties = TRUE) {
  schema <- list(
    `$schema` = "http://json-schema.org/draft-07/schema#",
    type = "object"
  )

  if (!is.null(title)) schema$title <- title
  if (!is.null(description)) schema$description <- description
  if (length(properties) > 0) schema$properties <- properties
  if (length(required) > 0) schema$required <- as.list(required)
  schema$additionalProperties <- additional_properties

  class(schema) <- c("chap_config_schema", "list")
  schema
}


# ============================================================================
# Validation
# ============================================================================

#' Validate Model Configuration Against Schema
#'
#' Validates a configuration object against a JSON Schema. Returns detailed
#' error messages if validation fails.
#'
#' @param config Configuration to validate (list from YAML or JSON)
#' @param schema JSON Schema to validate against (from \code{create_config_schema()})
#' @param error If TRUE, throws an error on validation failure instead of
#'   returning a result object (default: FALSE)
#'
#' @return A list with:
#'   \itemize{
#'     \item \code{valid}: Logical indicating if configuration is valid
#'     \item \code{errors}: Character vector of error messages (empty if valid)
#'   }
#'   If \code{error = TRUE} and validation fails, throws an error instead.
#'
#' @export
#'
#' @examples
#' # Create a schema
#' schema <- create_config_schema(
#'   properties = list(
#'     n_samples = schema_integer(minimum = 1L),
#'     method = schema_enum(values = c("a", "b", "c"))
#'   ),
#'   required = c("n_samples")
#' )
#'
#' # Valid configuration
#' config <- list(n_samples = 100L, method = "a")
#' result <- validate_config(config, schema)
#' result$valid
#' # TRUE
#'
#' # Invalid configuration (missing required field)
#' config <- list(method = "a")
#' result <- validate_config(config, schema)
#' result$valid
#' # FALSE
#' result$errors
#' # Error message about missing n_samples
#'
#' # Throw error on invalid config
#' \dontrun{
#' validate_config(list(), schema, error = TRUE)
#' # Error: Configuration validation failed: ...
#' }
validate_config <- function(config, schema, error = FALSE) {
  # Handle NULL or empty config - ensure it becomes an empty object {}
  if (is.null(config) || (is.list(config) && length(config) == 0)) {
    config_json <- "{}"
  } else {
    # Convert config to JSON
    config_json <- jsonlite::toJSON(config, auto_unbox = TRUE, null = "null")
  }


  # Convert schema to JSON
  schema_json <- jsonlite::toJSON(schema, auto_unbox = TRUE, null = "null")

  # Create validator with ajv engine
  validator <- jsonvalidate::json_schema$new(schema_json, engine = "ajv")

  # Validate with verbose output to get error details
  result <- validator$validate(config_json, verbose = TRUE)

  if (result) {
    validation_result <- list(valid = TRUE, errors = character(0))
  } else {
    # Extract error messages from the errors attribute
    errors_df <- attr(result, "errors")
    if (!is.null(errors_df) && nrow(errors_df) > 0) {
      # Format error messages
      error_messages <- vapply(seq_len(nrow(errors_df)), function(i) {
        row <- errors_df[i, ]
        path <- if (!is.null(row$instancePath) && row$instancePath != "") {
          row$instancePath
        } else if (!is.null(row$dataPath) && row$dataPath != "") {
          row$dataPath
        } else {
          "(root)"
        }
        sprintf("%s: %s", path, row$message)
      }, character(1))
    } else {
      error_messages <- "Validation failed (no details available)"
    }
    validation_result <- list(valid = FALSE, errors = error_messages)
  }

  if (error && !validation_result$valid) {
    stop("Configuration validation failed:\n  ",
         paste(validation_result$errors, collapse = "\n  "),
         call. = FALSE)
  }

  validation_result
}


#' Apply Default Values from Schema to Configuration
#'
#' Fills in missing configuration values with defaults from the schema.
#' This ensures the configuration has all expected values even if the user
#' only provided a subset.
#'
#' @param config Configuration list (possibly incomplete)
#' @param schema JSON Schema with default values defined
#'
#' @return Configuration list with defaults applied for missing values
#' @export
#'
#' @examples
#' schema <- create_config_schema(
#'   properties = list(
#'     n_samples = schema_integer(default = 100L),
#'     method = schema_string(default = "arima"),
#'     verbose = schema_boolean(default = FALSE)
#'   )
#' )
#'
#' # Partial config - only n_samples provided
#' config <- list(n_samples = 500L)
#' full_config <- apply_config_defaults(config, schema)
#'
#' # full_config now has:
#' # $n_samples = 500L (user value preserved)
#' # $method = "arima" (default applied)
#' # $verbose = FALSE (default applied)
apply_config_defaults <- function(config, schema) {
  if (is.null(config)) config <- list()

  # Get properties from schema
  properties <- schema$properties
  if (is.null(properties)) return(config)

  # Apply defaults for missing properties

  for (prop_name in names(properties)) {
    if (is.null(config[[prop_name]])) {
      prop_def <- properties[[prop_name]]
      if (!is.null(prop_def$default)) {
        config[[prop_name]] <- prop_def$default
      }
    }
  }

  config
}


#' Extract Default Values from Schema
#'
#' Returns a list containing all default values defined in the schema.
#'
#' @param schema JSON Schema with default values defined
#'
#' @return Named list of default values
#' @export
#'
#' @examples
#' schema <- create_config_schema(
#'   properties = list(
#'     n_samples = schema_integer(default = 100L),
#'     method = schema_string(default = "arima")
#'   )
#' )
#'
#' defaults <- get_schema_defaults(schema)
#' # list(n_samples = 100L, method = "arima")
get_schema_defaults <- function(schema) {
  defaults <- list()

  properties <- schema$properties
  if (is.null(properties)) return(defaults)

  for (prop_name in names(properties)) {
    prop_def <- properties[[prop_name]]
    if (!is.null(prop_def$default)) {
      defaults[[prop_name]] <- prop_def$default
    }
  }

  defaults
}


# ============================================================================
# Legacy Functions (kept for compatibility)
# ============================================================================

#' Read Model Configuration
#'
#' Reads a YAML configuration file and optionally validates it against a schema.
#'
#' @param config_path Path to YAML configuration file
#' @param schema JSON Schema to validate against (optional)
#' @param validate Logical, whether to validate against schema (default: TRUE)
#' @param apply_defaults Logical, whether to apply default values from schema
#'   (default: TRUE)
#'
#' @return List containing parsed configuration with defaults applied
#' @export
#'
#' @examples
#' \dontrun{
#' # Read config without validation
#' config <- read_model_config("config.yaml")
#'
#' # Read config with validation
#' schema <- create_config_schema(...)
#' config <- read_model_config("config.yaml", schema = schema)
#' }
read_model_config <- function(config_path, schema = NULL, validate = TRUE,
                               apply_defaults = TRUE) {
  if (!file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  # Parse YAML with error handling
  config <- tryCatch(
    yaml::yaml.load_file(config_path),
    error = function(e) {
      stop("Failed to parse YAML configuration: ", e$message, call. = FALSE)
    }
  )

  # Handle NULL config (empty file)
  if (is.null(config)) config <- list()

  # Validate if schema provided
  if (validate && !is.null(schema)) {
    validate_config(config, schema, error = TRUE)
  }

  # Apply defaults if schema provided
  if (apply_defaults && !is.null(schema)) {
    config <- apply_config_defaults(config, schema)
  }

  config
}


#' Write Model Configuration
#'
#' Writes a configuration object to YAML file.
#'
#' @param config Configuration list
#' @param config_path Output path for YAML file
#' @param indent Number of spaces for indentation (default: 2)
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' config <- list(model_type = "rf", parameters = list(n_trees = 100))
#' write_model_config(config, "model_config.yaml")
#' }
write_model_config <- function(config, config_path, indent = 2) {
  tryCatch(
    {
      yaml_output <- yaml::as.yaml(
        config,
        indent = indent,
        indent.mapping.sequence = TRUE
      )
      write(yaml_output, file = config_path)
    },
    error = function(e) {
      stop("Failed to write configuration: ", e$message, call. = FALSE)
    }
  )

  message("Configuration written to: ", config_path)
  invisible(NULL)
}


#' Get Configuration Parameter
#'
#' Safely extracts a parameter from configuration with default fallback.
#'
#' @param config Configuration list
#' @param ... Path to parameter (passed to purrr::pluck)
#' @param .default Default value if parameter not found
#'
#' @return Parameter value or default
#' @export
#'
#' @examples
#' # Simple nested parameter extraction
#' config <- list(model = list(params = list(lr = 0.01)))
#' lr <- get_config_param(config, "model", "params", "lr", .default = 0.001)
#' print(lr)  # 0.01
#'
#' # With default fallback
#' missing <- get_config_param(config, "model", "missing", .default = "default")
#' print(missing)  # "default"
get_config_param <- function(config, ..., .default = NULL) {
  purrr::pluck(config, ..., .default = .default)
}


#' Convert Schema to JSON
#'
#' Converts a configuration schema to JSON format for external use.
#'
#' @param schema Schema created with \code{create_config_schema()}
#' @param pretty Whether to pretty-print the JSON (default: TRUE)
#'
#' @return JSON string representation of the schema
#' @export
#'
#' @examples
#' schema <- create_config_schema(
#'   title = "My Model",
#'   properties = list(
#'     n_samples = schema_integer(default = 100L)
#'   )
#' )
#' json <- schema_to_json(schema)
#' cat(json)
schema_to_json <- function(schema, pretty = TRUE) {
  jsonlite::toJSON(schema, auto_unbox = TRUE, null = "null", pretty = pretty)
}


#' Print Schema Summary
#'
#' Prints a human-readable summary of a configuration schema.
#'
#' @param x Schema object
#' @param ... Additional arguments (ignored)
#'
#' @return Invisible schema object
#' @export
print.chap_config_schema <- function(x, ...) {
  cat("Chap Configuration Schema\n")
  cat("=========================\n\n")

  if (!is.null(x$title)) {
    cat("Title:", x$title, "\n")
  }
  if (!is.null(x$description)) {
    cat("Description:", x$description, "\n")
  }

  if (!is.null(x$properties) && length(x$properties) > 0) {
    cat("\nProperties:\n")

    required <- if (!is.null(x$required)) unlist(x$required) else character(0)

    for (name in names(x$properties)) {
      prop <- x$properties[[name]]
      is_required <- name %in% required
      req_marker <- if (is_required) " *" else ""

      type_str <- prop$type %||% "any"
      if (!is.null(prop$enum)) {
        type_str <- paste0("enum(", paste(unlist(prop$enum), collapse = ", "), ")")
      }

      default_str <- if (!is.null(prop$default)) {
        paste0(" [default: ", format_value(prop$default), "]")
      } else {
        ""
      }

      cat(sprintf("  %s%s (%s)%s\n", name, req_marker, type_str, default_str))

      if (!is.null(prop$description)) {
        cat(sprintf("    %s\n", prop$description))
      }
    }

    if (length(required) > 0) {
      cat("\n* = required\n")
    }
  } else {
    cat("\nNo properties defined.\n")
  }

  invisible(x)
}

# Helper for formatting values in print output
format_value <- function(x) {
  if (is.logical(x)) {
    tolower(as.character(x))
  } else if (is.character(x)) {
    paste0("\"", x, "\"")
  } else if (is.list(x)) {
    jsonlite::toJSON(x, auto_unbox = TRUE)
  } else {
    as.character(x)
  }
}

# NULL coalescing operator
`%||%` <- function(a, b) if (is.null(a)) b else a
