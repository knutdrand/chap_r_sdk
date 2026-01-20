# Generate MLproject file for chap-core compatibility

Creates an MLproject file that allows chap-core to run R models directly
using renv for environment management. The generated file follows
chap-core's expected format with train and predict entry points.

## Usage

``` r
generate_mlproject(
  model_script = "model.R",
  model_name = NULL,
  config_schema = NULL,
  output_path = "MLproject",
  include_config = !is.null(config_schema)
)
```

## Arguments

- model_script:

  Path to the R model script (default: "model.R")

- model_name:

  Name of the model. If NULL, auto-detected from the directory name

- config_schema:

  Optional JSON Schema for model configuration. Will be converted to
  chap-core's user_options format

- output_path:

  Where to write the MLproject file (default: "MLproject")

- include_config:

  Whether to include config parameter in entry points (default: TRUE if
  config_schema is provided)

## Value

Invisible path to created MLproject file

## See also

[`create_chapkit_cli`](https://knutdrand.github.io/chap_r_sdk/reference/create_chapkit_cli.md)
for creating the CLI that this MLproject file will invoke

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate basic MLproject
generate_mlproject()

# Generate with model name and config schema
config_schema <- list(
  type = "object",
  properties = list(
    n_samples = list(
      type = "integer",
      title = "Number of samples",
      description = "Number of Monte Carlo samples",
      default = 100
    )
  )
)
generate_mlproject(model_name = "my_arima_model", config_schema = config_schema)
} # }
```
