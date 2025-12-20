# Load, Validate, and Apply Defaults to Configuration

Loads a YAML configuration file, validates it against a schema (if
provided), and applies default values from the schema for any missing
properties.

## Usage

``` r
load_and_validate_config(config_path, schema = NULL)
```

## Arguments

- config_path:

  Path to YAML configuration file (can be NULL or empty string)

- schema:

  JSON Schema to validate against (from
  [`create_config_schema()`](https://knutdrand.github.io/chap_r_sdk/reference/create_config_schema.md)).
  If NULL, no validation is performed and no defaults are applied.

## Value

Parsed configuration as a list with defaults applied. Returns empty list
if no config file exists and no schema defaults are available.
