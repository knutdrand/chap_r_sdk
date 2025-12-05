# Create Unified CHAP CLI

Creates a unified command-line interface for both training and
prediction. Automatically handles all file I/O, parsing, and conversion.
Model functions receive loaded tsibbles and configuration lists, not
file paths.

## Usage

``` r
create_chap_cli(
  train_fn,
  predict_fn,
  model_config_schema = NULL,
  args = commandArgs(trailingOnly = TRUE)
)
```

## Arguments

- train_fn:

  Training function with signature:
  `function(training_data, model_configuration = list())` where
  `training_data` is a tsibble and `model_configuration` is a list.
  Should return a model object that will be automatically saved as RDS.

- predict_fn:

  Prediction function with signature:
  `function(historic_data, future_data, saved_model, model_configuration = list())`
  where all data inputs are tsibbles, `saved_model` is a loaded object,
  and `model_configuration` is a list. Must return a tibble with a
  `samples` list-column containing numeric vectors. For deterministic
  models, use a single sample per forecast unit (e.g.,
  `samples = list(c(42))`). For probabilistic models, include multiple
  Monte Carlo samples. The CLI automatically converts the nested samples
  to wide CSV format (sample_0, sample_1, ...) for CHAP.

  **Important**: `historic_data` may contain more recent observations
  than the original training data. CHAP may call predict with updated
  data after the model was trained. For time series models, you should
  typically refit the model to `historic_data` before forecasting. Use
  `saved_model` to store model hyperparameters or structure that should
  persist across predictions, rather than the fitted model itself. See
  `examples/arima_model/` for a demonstration of this pattern using
  `fable::refit()`.

- model_config_schema:

  Optional model configuration schema (reserved for future use). Can be
  used with the "info" subcommand to display schema information.

- args:

  Command line arguments (defaults to
  `commandArgs(trailingOnly = TRUE)`)

## Value

Invisible result of the called function

## Details

This is the standard way to create CHAP-compatible CLI scripts,
providing a single unified interface with subcommand dispatch.

## Examples

``` r
if (FALSE) { # \dontrun{
# In model.R file:
library(chap.r.sdk)
library(dplyr)

train_my_model <- function(training_data, model_configuration = list()) {
  # training_data is already a tsibble - no file I/O needed!
  means <- training_data |>
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
  return(list(means = means))
}

predict_my_model <- function(historic_data, future_data, saved_model,
                              model_configuration = list()) {
  # All inputs are already loaded - no file I/O needed!
  # Return samples list-column (single sample for deterministic model)
  future_data |>
    as_tibble() |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)
}

config_schema <- list(
  title = "My Model Configuration",
  type = "object",
  properties = list()
)

# Single function call enables full CLI!
if (!interactive()) {
  create_chap_cli(train_my_model, predict_my_model, config_schema)
}

# Command line usage:
# Rscript model.R train data.csv [config.yaml]
# Rscript model.R predict historic.csv future.csv model.rds [config.yaml]
# Rscript model.R info
} # }
```
