# Read Model Configuration

Reads a YAML configuration file and optionally validates it against a
schema

## Usage

``` r
read_model_config(config_path, schema_path = NULL, validate = TRUE)
```

## Arguments

- config_path:

  Path to YAML configuration file

- schema_path:

  Path to JSON schema file (optional)

- validate:

  Logical, whether to validate against schema (default: TRUE)

## Value

List containing parsed configuration

## Examples

``` r
if (FALSE) { # \dontrun{
config <- read_model_config("model_config.yaml")
config <- read_model_config("model_config.yaml", "schema.json", validate = TRUE)
} # }
```
