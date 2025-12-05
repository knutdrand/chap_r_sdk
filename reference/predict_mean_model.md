# Predict using mean model

Generates predictions by returning the mean disease cases for each
location

## Usage

``` r
predict_mean_model(historic_data, future_data, model, model_config = list())
```

## Arguments

- historic_data:

  A tsibble with historical data (not used by mean model, but kept for
  interface consistency)

- future_data:

  A tsibble with future time periods and locations to predict for

- model:

  The trained model object from train_mean_model()

- model_config:

  A list containing model configuration options (optional)

## Value

A tsibble with columns: time_period, location, disease_cases (predicted)
