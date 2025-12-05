# Handle train subcommand

Internal function that handles the "train" subcommand for
create_chap_cli(). Loads training data, parses configuration, calls the
training function, and saves the resulting model.

## Usage

``` r
handle_train(train_fn, args)
```

## Arguments

- train_fn:

  User-provided training function

- args:

  Subcommand arguments (training_data path and optional config path)

## Value

Path to saved model file
