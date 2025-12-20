# Apply Default Values from Schema to Configuration

Fills in missing configuration values with defaults from the schema.
This ensures the configuration has all expected values even if the user
only provided a subset.

## Usage

``` r
apply_config_defaults(config, schema)
```

## Arguments

- config:

  Configuration list (possibly incomplete)

- schema:

  JSON Schema with default values defined

## Value

Configuration list with defaults applied for missing values

## Examples

``` r
schema <- create_config_schema(
  properties = list(
    n_samples = schema_integer(default = 100L),
    method = schema_string(default = "arima"),
    verbose = schema_boolean(default = FALSE)
  )
)

# Partial config - only n_samples provided
config <- list(n_samples = 500L)
full_config <- apply_config_defaults(config, schema)

# full_config now has:
# $n_samples = 500L (user value preserved)
# $method = "arima" (default applied)
# $verbose = FALSE (default applied)
```
