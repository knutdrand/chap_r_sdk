# Read Model Configuration

Reads a YAML configuration file and optionally validates it against a
schema.

## Usage

``` r
read_model_config(
  config_path,
  schema = NULL,
  validate = TRUE,
  apply_defaults = TRUE
)
```

## Arguments

- config_path:

  Path to YAML configuration file

- schema:

  JSON Schema to validate against (optional)

- validate:

  Logical, whether to validate against schema (default: TRUE)

- apply_defaults:

  Logical, whether to apply default values from schema (default: TRUE)

## Value

List containing parsed configuration with defaults applied

## Examples

``` r
if (FALSE) { # \dontrun{
# Read config without validation
config <- read_model_config("config.yaml")

# Read config with validation
schema <- create_config_schema(...)
config <- read_model_config("config.yaml", schema = schema)
} # }
```
