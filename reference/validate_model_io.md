# Validate Model Input/Output with Example Data

Validates that a model's training and prediction functions work
correctly with a specific example dataset and produce output with the
expected structure (matching time periods and locations).

## Usage

``` r
validate_model_io(
  train_fn,
  predict_fn,
  example_data,
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
  with a `samples` list-column.

- example_data:

  Named list containing training_data, historic_data, future_data, and
  predictions (as returned by get_example_data())

- model_configuration:

  Optional list of model configuration parameters to pass to train_fn
  and predict_fn

## Value

A list with validation results:

- `success`: Logical indicating if validation passed

- `errors`: Character vector of error messages (if any)

- `n_predictions`: Number of prediction rows returned

- `n_samples`: Number of samples per forecast unit

## Details

All models must return predictions with a `samples` list-column
containing numeric vectors. For deterministic models, use a single
sample per forecast unit (e.g., `samples = list(c(42))`). For
probabilistic models, include multiple Monte Carlo samples (e.g., 1000
samples per forecast unit).

## Examples

``` r
if (FALSE) { # \dontrun{
# Define simple model functions
my_train <- function(training_data, model_configuration = list()) {
  means <- training_data |>
    dplyr::group_by(location) |>
    dplyr::summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
  list(means = means)
}

my_predict <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data |>
    tibble::as_tibble() |>
    dplyr::left_join(saved_model$means, by = "location") |>
    dplyr::mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    dplyr::select(-mean_cases)
}

# Get example data and validate
example_data <- get_example_data('laos', 'M')
result <- validate_model_io(my_train, my_predict, example_data)
if (result$success) {
  cat("Model validation passed!\n")
} else {
  cat("Validation failed:\n")
  print(result$errors)
}
} # }
```
