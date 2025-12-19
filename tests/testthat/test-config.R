# Tests for configuration schema and validation

# ============================================================================
# Schema Helper Tests
# ============================================================================

test_that("schema_integer creates valid integer property", {
  prop <- schema_integer(
    description = "Number of samples",
    default = 100L,
    minimum = 1L,
    maximum = 1000L
  )

  expect_equal(prop$type, "integer")
  expect_equal(prop$description, "Number of samples")
  expect_equal(prop$default, 100L)
  expect_equal(prop$minimum, 1L)
  expect_equal(prop$maximum, 1000L)
})

test_that("schema_number creates valid number property", {
  prop <- schema_number(
    description = "Learning rate",
    default = 0.01,
    minimum = 0,
    maximum = 1
  )

  expect_equal(prop$type, "number")
  expect_equal(prop$description, "Learning rate")
  expect_equal(prop$default, 0.01)
  expect_equal(prop$minimum, 0)
  expect_equal(prop$maximum, 1)
})

test_that("schema_string creates valid string property", {
  prop <- schema_string(
    description = "Model name",
    default = "my_model",
    min_length = 1L,
    max_length = 100L
  )

  expect_equal(prop$type, "string")
  expect_equal(prop$description, "Model name")
  expect_equal(prop$default, "my_model")
  expect_equal(prop$minLength, 1L)
  expect_equal(prop$maxLength, 100L)
})

test_that("schema_string supports pattern constraint", {
  prop <- schema_string(
    pattern = "^[a-z]+$"
  )

  expect_equal(prop$pattern, "^[a-z]+$")
})

test_that("schema_boolean creates valid boolean property", {
  prop <- schema_boolean(
    description = "Enable feature",
    default = TRUE
  )

  expect_equal(prop$type, "boolean")
  expect_equal(prop$description, "Enable feature")
  expect_equal(prop$default, TRUE)
})

test_that("schema_enum creates valid enum property", {
  prop <- schema_enum(
    values = c("a", "b", "c"),
    description = "Choose option",
    default = "a"
  )

  expect_equal(prop$type, "string")
  expect_equal(prop$enum, list("a", "b", "c"))
  expect_equal(prop$description, "Choose option")
  expect_equal(prop$default, "a")
})

test_that("schema_enum validates default is in values", {
  expect_error(
    schema_enum(values = c("a", "b"), default = "c"),
    "must be one of"
  )
})

test_that("schema_enum requires non-empty character vector", {
  expect_error(
    schema_enum(values = character(0)),
    "non-empty character vector"
  )

  expect_error(
    schema_enum(values = c(1, 2, 3)),
    "non-empty character vector"
  )
})

test_that("schema_array creates valid array property", {
  prop <- schema_array(
    items = list(type = "string"),
    description = "List of names",
    default = list("a", "b"),
    min_items = 1L,
    max_items = 10L
  )

  expect_equal(prop$type, "array")
  expect_equal(prop$items, list(type = "string"))
  expect_equal(prop$description, "List of names")
  expect_equal(prop$default, list("a", "b"))
  expect_equal(prop$minItems, 1L)
  expect_equal(prop$maxItems, 10L)
})

# ============================================================================
# Schema Creation Tests
# ============================================================================

test_that("create_config_schema creates valid schema object", {
  schema <- create_config_schema(
    title = "Test Schema",
    description = "A test schema",
    properties = list(
      n_samples = schema_integer(default = 100L)
    ),
    required = c("n_samples")
  )

  expect_s3_class(schema, "chap_config_schema")
  expect_equal(schema$`$schema`, "http://json-schema.org/draft-07/schema#")
  expect_equal(schema$type, "object")
  expect_equal(schema$title, "Test Schema")
  expect_equal(schema$description, "A test schema")
  expect_equal(schema$required, list("n_samples"))
  expect_true(schema$additionalProperties)
})

test_that("create_config_schema handles empty properties", {
  schema <- create_config_schema()

  expect_s3_class(schema, "chap_config_schema")
  expect_equal(schema$type, "object")
  expect_null(schema$properties)
})

test_that("create_config_schema can disable additional properties", {
  schema <- create_config_schema(
    additional_properties = FALSE
  )

  expect_false(schema$additionalProperties)
})

# ============================================================================
# Validation Tests
# ============================================================================

test_that("validate_config accepts valid configuration", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(minimum = 1L),
      name = schema_string()
    ),
    required = c("n_samples")
  )

  config <- list(n_samples = 100L, name = "test")
  result <- validate_config(config, schema)

  expect_true(result$valid)
  expect_length(result$errors, 0)
})

test_that("validate_config rejects missing required field", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer()
    ),
    required = c("n_samples")
  )

  config <- list()
  result <- validate_config(config, schema)

  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
  expect_match(result$errors[1], "n_samples|required", ignore.case = TRUE)
})

test_that("validate_config rejects wrong type", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer()
    )
  )

  config <- list(n_samples = "not an integer")
  result <- validate_config(config, schema)

  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validate_config rejects value below minimum", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(minimum = 10L)
    )
  )

  config <- list(n_samples = 5L)
  result <- validate_config(config, schema)

  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validate_config rejects value above maximum", {
  schema <- create_config_schema(
    properties = list(
      rate = schema_number(maximum = 1.0)
    )
  )

  config <- list(rate = 1.5)
  result <- validate_config(config, schema)

  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validate_config rejects invalid enum value", {
  schema <- create_config_schema(
    properties = list(
      method = schema_enum(values = c("a", "b", "c"))
    )
  )

  config <- list(method = "invalid")
  result <- validate_config(config, schema)

  expect_false(result$valid)
  expect_gt(length(result$errors), 0)
})

test_that("validate_config throws error when error = TRUE", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer()
    ),
    required = c("n_samples")
  )

  expect_error(
    validate_config(list(), schema, error = TRUE),
    "Configuration validation failed"
  )
})

test_that("validate_config accepts empty config with no required fields", {
  schema <- create_config_schema(
    properties = list(
      optional_field = schema_string()
    )
  )

  config <- list()
  result <- validate_config(config, schema)

  expect_true(result$valid)
})

# ============================================================================
# Default Application Tests
# ============================================================================

test_that("apply_config_defaults adds missing defaults", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(default = 100L),
      method = schema_string(default = "arima"),
      verbose = schema_boolean(default = FALSE)
    )
  )

  config <- list(n_samples = 50L)  # Only one value provided
  result <- apply_config_defaults(config, schema)

  expect_equal(result$n_samples, 50L)  # Preserved
  expect_equal(result$method, "arima")  # Default applied
  expect_equal(result$verbose, FALSE)  # Default applied
})

test_that("apply_config_defaults preserves existing values", {
  schema <- create_config_schema(
    properties = list(
      value = schema_integer(default = 100L)
    )
  )

  config <- list(value = 999L)
  result <- apply_config_defaults(config, schema)

  expect_equal(result$value, 999L)  # User value preserved
})

test_that("apply_config_defaults handles NULL config", {
  schema <- create_config_schema(
    properties = list(
      value = schema_integer(default = 42L)
    )
  )

  result <- apply_config_defaults(NULL, schema)

  expect_equal(result$value, 42L)
})

test_that("apply_config_defaults handles schema with no defaults", {
  schema <- create_config_schema(
    properties = list(
      value = schema_integer()  # No default
    )
  )

  config <- list()
  result <- apply_config_defaults(config, schema)

  expect_null(result$value)
})

test_that("get_schema_defaults extracts all defaults", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(default = 100L),
      method = schema_string(default = "test"),
      no_default = schema_number()
    )
  )

  defaults <- get_schema_defaults(schema)

  expect_equal(defaults$n_samples, 100L)
  expect_equal(defaults$method, "test")
  expect_null(defaults$no_default)
  expect_length(defaults, 2)  # Only properties with defaults
})

# ============================================================================
# Integration Tests
# ============================================================================

test_that("read_model_config validates and applies defaults", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(default = 100L, minimum = 1L),
      method = schema_string(default = "arima")
    ),
    required = c("n_samples")
  )

  # Create temp config file
  config_path <- tempfile(fileext = ".yaml")
  writeLines("n_samples: 50", config_path)

  config <- read_model_config(config_path, schema = schema)

  expect_equal(config$n_samples, 50L)
  expect_equal(config$method, "arima")  # Default applied

  unlink(config_path)
})

test_that("read_model_config throws on invalid config", {
  schema <- create_config_schema(
    properties = list(
      n_samples = schema_integer(minimum = 10L)
    ),
    required = c("n_samples")
  )

  # Create temp config file with invalid value
  config_path <- tempfile(fileext = ".yaml")
  writeLines("n_samples: 5", config_path)  # Below minimum

  expect_error(
    read_model_config(config_path, schema = schema),
    "Configuration validation failed"
  )

  unlink(config_path)
})

test_that("schema_to_json produces valid JSON", {
  schema <- create_config_schema(
    title = "Test",
    properties = list(
      value = schema_integer(default = 42L)
    )
  )

  json <- schema_to_json(schema)

  expect_type(json, "character")
  expect_match(json, "Test")
  expect_match(json, "integer")

  # Should be parseable
  parsed <- jsonlite::fromJSON(json)
  expect_equal(parsed$title, "Test")
})

test_that("print.chap_config_schema produces readable output", {
  schema <- create_config_schema(
    title = "My Model",
    description = "Test model config",
    properties = list(
      n_samples = schema_integer(
        description = "Number of samples",
        default = 100L
      ),
      method = schema_enum(
        values = c("a", "b"),
        description = "Method to use",
        default = "a"
      )
    ),
    required = c("n_samples")
  )

  output <- capture.output(print(schema))
  output_text <- paste(output, collapse = "\n")

  expect_match(output_text, "My Model")
  expect_match(output_text, "n_samples")
  expect_match(output_text, "method")
  expect_match(output_text, "100")
  expect_match(output_text, "required", ignore.case = TRUE)
})

# ============================================================================
# CLI Integration Tests
# ============================================================================

test_that("load_and_validate_config validates and applies defaults", {
  schema <- create_config_schema(
    properties = list(
      value = schema_integer(default = 42L, minimum = 1L)
    )
  )

  # Create temp config
  config_path <- tempfile(fileext = ".yaml")
  writeLines("value: 10", config_path)

  config <- load_and_validate_config(config_path, schema)

  expect_equal(config$value, 10L)

  unlink(config_path)
})

test_that("load_and_validate_config applies defaults when no file", {
  schema <- create_config_schema(
    properties = list(
      value = schema_integer(default = 42L)
    )
  )

  config <- load_and_validate_config(NULL, schema)

  expect_equal(config$value, 42L)
})

test_that("load_and_validate_config works without schema", {
  # Create temp config
  config_path <- tempfile(fileext = ".yaml")
  writeLines("value: 10", config_path)

  config <- load_and_validate_config(config_path, schema = NULL)

  expect_equal(config$value, 10)

  unlink(config_path)
})

test_that("load_and_validate_config returns empty list when no file and no schema", {
  config <- load_and_validate_config(NULL, schema = NULL)

  expect_type(config, "list")
  expect_length(config, 0)
})
