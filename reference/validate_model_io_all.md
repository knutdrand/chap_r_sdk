# Validate Model Input/Output for All Available Datasets

Validates that a model's training and prediction functions work
correctly with all available example datasets. This function iterates
over all country/frequency combinations and validates each one using
validate_model_io().

## Usage

``` r
validate_model_io_all(
  train_fn,
  predict_fn,
  country = NULL,
  frequency = NULL,
  model_configuration = list()
)
```

## Arguments

- train_fn:

  Training function that takes (training_data, model_configuration =
  list()) and returns a trained model object

- predict_fn:

  Prediction function that takes (historic_data, future_data,
  saved_model, model_configuration = list()) and returns predictions

- country:

  Optional character string specifying country. If NULL, tests all
  available countries. Currently supports: 'laos'

- frequency:

  Optional character string specifying temporal frequency. If NULL,
  tests all available frequencies. Currently supports: 'M' (monthly)

- model_configuration:

  Optional list of model configuration parameters to pass to train_fn
  and predict_fn

## Value

A list with validation results:

- `success`: Logical indicating if all validations passed

- `results`: Named list of validation results for each country/frequency
  combination

- `errors`: Character vector of all error messages (if any)

## Examples

``` r
if (FALSE) { # \dontrun{
# Define simple model functions
my_train <- function(training_data, model_configuration = list()) {
  list(mean_cases = mean(training_data$disease_cases, na.rm = TRUE))
}

my_predict <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data$disease_cases <- saved_model$mean_cases
  future_data
}

# Validate across all available datasets
result <- validate_model_io_all(my_train, my_predict)
if (result$success) {
  cat("✓ All validations passed!\n")
} else {
  cat("✗ Validation failed:\n")
  print(result$errors)
}

# Validate with specific country and frequency
result <- validate_model_io_all(my_train, my_predict, country = 'laos', frequency = 'M')
} # }
```
