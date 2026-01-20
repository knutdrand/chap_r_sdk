# Handle train subcommand

Internal function that handles the "train" subcommand for
create_chap_cli(). Loads training data, parses configuration, calls the
training function, and saves the resulting model.

## Usage

``` r
handle_train(train_fn, opts, schema = NULL)
```

## Arguments

- train_fn:

  User-provided training function

- opts:

  Parsed options from optparse

- schema:

  Optional JSON Schema for config validation

## Value

Path to saved model file
