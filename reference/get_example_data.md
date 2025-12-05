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

A named list containing four elements:

- `training_data`: tsibble with historical data for training the model

- `historic_data`: tsibble with historical data for making predictions

- `future_data`: tsibble with future time periods for prediction

- `predictions`: tibble with example prediction output. If the
  predictions contain sample columns (sample_0, sample_1, ...), they are
  converted to nested list-column format with a `samples` column
  containing numeric vectors.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- get_example_data('laos', 'M')
model <- train_fn(data$training_data)
preds <- predict_fn(data$historic_data, data$future_data, model)

# If predictions have samples, access them like this:
data$predictions$samples[[1]]  # Samples for first forecast unit
} # }
```
