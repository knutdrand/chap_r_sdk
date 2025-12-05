#' Read Model Configuration
#'
#' Reads a YAML configuration file and optionally validates it against a schema
#'
#' @param config_path Path to YAML configuration file
#' @param schema_path Path to JSON schema file (optional)
#' @param validate Logical, whether to validate against schema (default: TRUE)
#'
#' @return List containing parsed configuration
#' @export
#'
#' @examples
#' \dontrun{
#' config <- read_model_config("model_config.yaml")
#' config <- read_model_config("model_config.yaml", "schema.json", validate = TRUE)
#' }
read_model_config <- function(config_path, schema_path = NULL, validate = TRUE) {
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

  # Validate if schema provided

  # NOTE: Schema validation is not yet implemented.
  # The ajv R package API has changed and requires a different approach.
  # For now, we skip validation and just warn the user.
  if (validate && !is.null(schema_path)) {
    warning("Schema validation is not yet implemented. Skipping validation.")
  }

  return(config)
}


#' Write Model Configuration
#'
#' Writes a configuration object to YAML file
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
#' Safely extracts a parameter from configuration with default fallback
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
#'
#' # Deep nesting
#' complex_config <- list(
#'   training = list(
#'     optimizer = list(
#'       type = "adam",
#'       params = list(lr = 0.001, beta1 = 0.9)
#'     )
#'   )
#' )
#' beta1 <- get_config_param(complex_config, "training", "optimizer", "params", "beta1")
#' print(beta1)  # 0.9
get_config_param <- function(config, ..., .default = NULL) {
  purrr::pluck(config, ..., .default = .default)
}


#' Expose Model Configuration Schema
#'
#' Generates and exposes a model configuration schema in a format
#' that can be consumed by chap
#'
#' @param config_definition A list or object defining the configuration schema
#' @param output_format The format for the schema (default: "json")
#'
#' @return The configuration schema in the specified format
#' @export
#'
#' @examples
#' \dontrun{
#' schema <- create_config_schema(config_definition)
#' }
create_config_schema <- function(config_definition, output_format = "json") {
  # TODO: Implement schema generation
  stop("Not yet implemented")
}


#' Validate Model Configuration
#'
#' Validates a model configuration against its schema
#'
#' @param config The configuration to validate
#' @param schema The schema to validate against
#'
#' @return TRUE if valid, otherwise throws an error with details
#' @export
#'
#' @examples
#' \dontrun{
#' validate_config(my_config, schema)
#' }
validate_config <- function(config, schema) {
  # TODO: Implement configuration validation
  stop("Not yet implemented")
}
