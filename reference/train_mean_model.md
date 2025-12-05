# Train a simple mean model

Trains a model that predicts the mean disease cases for each location

## Usage

``` r
train_mean_model(training_data, model_config = list())
```

## Arguments

- training_data:

  A tsibble with columns: time_period, location, disease_cases, and
  covariates

- model_config:

  A list containing model configuration options

## Value

A list containing the trained model (mean values per location)
