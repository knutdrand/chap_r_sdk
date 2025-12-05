# Write Model Configuration

Writes a configuration object to YAML file

## Usage

``` r
write_model_config(config, config_path, indent = 2)
```

## Arguments

- config:

  Configuration list

- config_path:

  Output path for YAML file

- indent:

  Number of spaces for indentation (default: 2)

## Value

Invisible NULL

## Examples

``` r
if (FALSE) { # \dontrun{
config <- list(model_type = "rf", parameters = list(n_trees = 100))
write_model_config(config, "model_config.yaml")
} # }
```
