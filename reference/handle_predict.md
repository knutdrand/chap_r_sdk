# Handle predict subcommand

Internal function that handles the "predict" subcommand for
create_chap_cli(). Loads historic data, future data, saved model, and
configuration, calls the prediction function, and saves the resulting
predictions.

## Usage

``` r
handle_predict(predict_fn, args)
```

## Arguments

- predict_fn:

  User-provided prediction function

- args:

  Subcommand arguments (historic_data, future_data, saved_model,
  optional config)

## Value

Path to saved predictions file
