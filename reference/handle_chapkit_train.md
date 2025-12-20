# Handle chapkit train subcommand

Internal function that handles the "train" subcommand for
create_chapkit_cli(). Uses named arguments (–data, –config, –model).

## Usage

``` r
handle_chapkit_train(
  train_fn,
  args,
  default_config_path,
  default_model_path,
  schema = NULL
)
```

## Arguments

- train_fn:

  User-provided training function

- args:

  Subcommand arguments

- default_config_path:

  Default config file path

- default_model_path:

  Default model output path

- schema:

  Optional JSON Schema for config validation

## Value

Path to saved model file
