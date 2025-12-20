# Extract Default Values from Schema

Returns a list containing all default values defined in the schema.

## Usage

``` r
get_schema_defaults(schema)
```

## Arguments

- schema:

  JSON Schema with default values defined

## Value

Named list of default values

## Examples

``` r
schema <- create_config_schema(
  properties = list(
    n_samples = schema_integer(default = 100L),
    method = schema_string(default = "arima")
  )
)

defaults <- get_schema_defaults(schema)
# list(n_samples = 100L, method = "arima")
```
