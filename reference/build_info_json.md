# Build structured JSON output for info command

Creates a structured output combining service_info and config_schema for
programmatic consumption by chapkit.

## Usage

``` r
build_info_json(model_config_schema, model_info = NULL)
```

## Arguments

- model_config_schema:

  Optional configuration schema

- model_info:

  Optional list with model data requirements

## Value

A list with service_info and config_schema fields
