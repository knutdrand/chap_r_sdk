# Plan: Model Configuration Parsing and Validation

## Overview

Implement model configuration parsing and validation according to JSON Schema, matching the CHAP model contract. This allows model developers to define configuration schemas that CHAP can use to validate user-provided configuration values.

## Background

From the Python SDK MODEL_CONTRACT.md:
> The model specifies what kind of configuration options are available through a ModelConfig class, which is a pydantic model. The actual values of these configuration options are sent to the model as the model_config part of the config object.

In R, we'll use JSON Schema (draft-07) for validation via the `jsonvalidate` package, which provides a similar validation capability to Pydantic.

## Implementation Steps

### Step 1: Add jsonvalidate dependency

Add `jsonvalidate` to DESCRIPTION Imports. This package uses the `ajv` engine for JSON Schema validation (drafts 04, 06, 07).

**Files to modify:**
- `DESCRIPTION`

### Step 2: Implement `validate_config()` function

Create a function that validates a configuration list against a JSON Schema.

```r
validate_config <- function(config, schema, error = FALSE) {
  # Convert R list to JSON
  # Validate against schema using jsonvalidate
  # Return TRUE/FALSE or throw error with details
}
```

**Key features:**
- Accept config as R list (from YAML) or JSON string
- Accept schema as R list or JSON string
- Return validation result with detailed error messages
- Option to throw error on validation failure

**Files to modify:**
- `R/config.R`

### Step 3: Implement `create_config_schema()` helper

Create a helper function to define configuration schemas in R-friendly syntax that outputs valid JSON Schema.

```r
create_config_schema <- function(
  title = NULL,
  description = NULL,
  properties = list(),
  required = character(0),
  ...
)
```

**Key features:**
- R-native syntax for defining properties
- Helper functions for common types: `schema_integer()`, `schema_number()`, `schema_string()`, `schema_boolean()`, `schema_array()`, `schema_enum()`
- Automatic conversion to JSON Schema format
- Support for property descriptions and default values

**Files to modify:**
- `R/config.R`

### Step 4: Integrate validation into CLI handlers

Update `load_config()` or add a new `load_and_validate_config()` function that:
1. Loads the YAML config file
2. Validates against the model's schema (if provided)
3. Applies default values from schema
4. Returns validated config or throws error

Update CLI handlers to use schema validation when `model_config_schema` is provided.

**Files to modify:**
- `R/cli_utils.R` (add `load_and_validate_config()`)
- `R/cli.R` (update handlers to use validation)

### Step 5: Add default value application

Implement a function to apply default values from schema to config:

```r
apply_config_defaults <- function(config, schema) {
  # Walk schema properties
  # For each property with a default, apply if missing in config
  # Return config with defaults applied
}
```

**Files to modify:**
- `R/config.R`

### Step 6: Update tests

Add comprehensive tests for:
- Schema creation helpers
- Config validation (valid/invalid cases)
- Error message quality
- Default value application
- Integration with CLI

**Files to modify:**
- `tests/testthat/test-config.R`

### Step 7: Update documentation

- Add roxygen2 documentation for all new functions
- Update vignettes with configuration schema examples
- Add example model with custom configuration

**Files to modify:**
- `R/config.R` (roxygen2 comments)
- `vignettes/` (if needed)
- `examples/` (add example with config schema)

## API Design

### Schema Definition Example

```r
# Define a model configuration schema
my_schema <- create_config_schema(
  title = "My Model Configuration",
  description = "Configuration options for my CHAP model",
  properties = list(
    n_samples = schema_integer(
      description = "Number of Monte Carlo samples",
      default = 100L,
      minimum = 1L,
      maximum = 10000L
    ),
    learning_rate = schema_number(
      description = "Learning rate for optimization",
      default = 0.01,
      minimum = 0,
      maximum = 1
    ),
    method = schema_enum(
      description = "Forecasting method to use",
      values = c("arima", "ets", "prophet"),
      default = "arima"
    ),
    use_covariates = schema_boolean(
      description = "Whether to use additional covariates",
      default = TRUE
    )
  ),
  required = c("n_samples")  # Required fields
)

# Use in create_chap_cli
create_chap_cli(train_fn, predict_fn, model_config_schema = my_schema)
```

### Validation Usage

```r
# Validate config manually
config <- list(n_samples = 500, learning_rate = 0.05)
result <- validate_config(config, my_schema)
if (!result$valid) {
  stop("Invalid configuration: ", paste(result$errors, collapse = "; "))
}

# Or with automatic error throwing
validate_config(config, my_schema, error = TRUE)
```

## Dependencies

- `jsonvalidate` (>= 1.5.0) - JSON Schema validation using ajv engine
- Existing: `jsonlite`, `yaml`

## Testing Strategy

1. **Unit tests for schema helpers**: Verify each helper produces valid JSON Schema
2. **Validation tests**: Test valid configs pass, invalid configs fail with correct errors
3. **Default value tests**: Verify defaults are applied correctly
4. **Integration tests**: Test full CLI flow with config validation
5. **Edge cases**: Empty schema, empty config, nested properties, arrays

## Open Questions

1. Should we support nested object properties in the first version?
2. Should validation be opt-in (default off) or opt-out (default on) when schema is provided?
3. How should we handle extra properties not in schema - ignore, warn, or error?

## Estimated Complexity

- Step 1: Low (dependency addition)
- Step 2: Medium (core validation logic)
- Step 3: Medium (schema builder DSL)
- Step 4: Low (integration)
- Step 5: Low (default application)
- Step 6: Medium (comprehensive tests)
- Step 7: Low (documentation)
