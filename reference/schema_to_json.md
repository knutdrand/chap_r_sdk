# Convert Schema to JSON

Converts a configuration schema to JSON format for external use.

## Usage

``` r
schema_to_json(schema, pretty = TRUE)
```

## Arguments

- schema:

  Schema created with
  [`create_config_schema()`](https://dhis2-chap.github.io/chap_r_sdk/reference/create_config_schema.md)

- pretty:

  Whether to pretty-print the JSON (default: TRUE)

## Value

JSON string representation of the schema

## Examples

``` r
schema <- create_config_schema(
  title = "My Model",
  properties = list(
    n_samples = schema_integer(default = 100L)
  )
)
json <- schema_to_json(schema)
cat(json)
#> {
#>   "$schema": "http://json-schema.org/draft-07/schema#",
#>   "type": "object",
#>   "title": "My Model",
#>   "properties": {
#>     "n_samples": {
#>       "type": "integer",
#>       "default": 100
#>     }
#>   },
#>   "additionalProperties": true
#> }
```
