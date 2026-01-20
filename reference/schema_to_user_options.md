# Convert JSON Schema to chap-core user_options format

Converts a JSON Schema properties object to the user_options format
expected by chap-core's MLproject files. JSON Schema types are passed
through directly as they match chap-core's expected types.

## Usage

``` r
schema_to_user_options(config_schema)
```

## Arguments

- config_schema:

  A JSON Schema object with properties

## Value

A list in chap-core user_options format, or NULL if no schema
