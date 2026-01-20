# Handle predict subcommand

Internal function that handles the "predict" subcommand for
create_chap_cli(). Loads historic data, future data, saved model, and
configuration, calls the prediction function, and saves the resulting
predictions.

## Usage

``` r
handle_predict(predict_fn, opts, schema = NULL)
```

## Arguments

- predict_fn:

  User-provided prediction function

- opts:

  Parsed options from optparse

- schema:

  Optional JSON Schema for config validation

## Value

Path to saved predictions file
