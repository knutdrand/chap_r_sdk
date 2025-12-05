# Get Example Data for Testing

Returns example datasets for testing and validating CHAP models.
Currently supports Laos monthly data.

## Usage

``` r
get_example_data(country, frequency)
```

## Arguments

- country:

  Character string specifying the country. Currently only 'laos' is
  supported.

- frequency:

  Character string specifying the temporal frequency. Currently only 'M'
  (monthly) is supported.

## Value

A named list containing four tibbles:

- `training_data`: Historical data for training the model

- `historic_data`: Historical data for making predictions

- `future_data`: Future time periods for prediction

- `predictions`: Example prediction output

## Examples

``` r
if (FALSE) { # \dontrun{
data <- get_example_data('laos', 'M')
model <- train_fn(data$training_data)
preds <- predict_fn(data$historic_data, data$future_data, model)
} # }
```
