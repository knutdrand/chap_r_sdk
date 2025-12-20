# Handle chapkit predict subcommand

Internal function that handles the "predict" subcommand for
create_chapkit_cli(). Uses named arguments (–historic, –future, –output,
–config, –model).

## Usage

``` r
handle_chapkit_predict(
  predict_fn,
  args,
  default_config_path,
  default_model_path,
  schema = NULL
)
```

## Arguments

- predict_fn:

  User-provided prediction function

- args:

  Subcommand arguments

- default_config_path:

  Default config file path

- default_model_path:

  Default model input path

- schema:

  Optional JSON Schema for config validation

## Value

Path to saved predictions file
