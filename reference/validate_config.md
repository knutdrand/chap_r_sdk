# Validate Model Configuration Against Schema

Validates a configuration object against a JSON Schema. Returns detailed
error messages if validation fails.

## Usage

``` r
validate_config(config, schema, error = FALSE)
```

## Arguments

- config:

  Configuration to validate (list from YAML or JSON)

- schema:

  JSON Schema to validate against (from
  [`create_config_schema()`](https://dhis2-chap.github.io/chap_r_sdk/reference/create_config_schema.md))

- error:

  If TRUE, throws an error on validation failure instead of returning a
  result object (default: FALSE)

## Value

A list with:

- `valid`: Logical indicating if configuration is valid

- `errors`: Character vector of error messages (empty if valid)

If `error = TRUE` and validation fails, throws an error instead.

## Examples

``` r
# Create a schema
schema <- create_config_schema(
  properties = list(
    n_samples = schema_integer(minimum = 1L),
    method = schema_enum(values = c("a", "b", "c"))
  ),
  required = c("n_samples")
)

# Valid configuration
config <- list(n_samples = 100L, method = "a")
result <- validate_config(config, schema)
result$valid
#> [1] TRUE
# TRUE

# Invalid configuration (missing required field)
config <- list(method = "a")
result <- validate_config(config, schema)
result$valid
#> [1] FALSE
# FALSE
result$errors
#> [1] "(root): must have required property 'n_samples'"
# Error message about missing n_samples

# Throw error on invalid config
if (FALSE) { # \dontrun{
validate_config(list(), schema, error = TRUE)
# Error: Configuration validation failed: ...
} # }
```
