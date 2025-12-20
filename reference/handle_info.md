# Handle info subcommand

Internal function that handles the "info" subcommand for
create_chap_cli(). Displays model information, data requirements, and
configuration schema.

## Usage

``` r
handle_info(model_config_schema, model_info = NULL, format = "yaml")
```

## Arguments

- model_config_schema:

  Optional configuration schema to display

- model_info:

  Optional list with model data requirements (period_type,
  allows_additional_continuous_covariates, required_covariates)

- format:

  Output format: "yaml" (default, human-readable) or "json"
  (machine-readable for chapkit integration)

## Value

NULL (invisibly)
