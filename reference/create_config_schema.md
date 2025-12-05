# Expose Model Configuration Schema

Generates and exposes a model configuration schema in a format that can
be consumed by chap

## Usage

``` r
create_config_schema(config_definition, output_format = "json")
```

## Arguments

- config_definition:

  A list or object defining the configuration schema

- output_format:

  The format for the schema (default: "json")

## Value

The configuration schema in the specified format

## Examples

``` r
if (FALSE) { # \dontrun{
schema <- create_config_schema(config_definition)
} # }
```
