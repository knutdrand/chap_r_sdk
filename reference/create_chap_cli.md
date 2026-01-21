# Create Chap CLI

Creates a command-line interface for Chap-compatible models using
optparse. Uses named arguments (–data, –historic, –future, –output) for
clear, explicit command-line usage. Config and model paths have sensible
defaults but can be overridden.

## Usage

``` r
create_chap_cli(
  train_fn,
  predict_fn,
  model_config_schema = NULL,
  model_info = NULL,
  default_config_path = "config.yml",
  default_model_path = "model.rds",
  args = commandArgs(trailingOnly = TRUE)
)
```

## Arguments

- train_fn:

  Training function with signature:
  `function(training_data, model_configuration = list(), run_info = list())`
  where `training_data` is a tsibble, `model_configuration` is a list of
  user-defined configuration options, and `run_info` is a list
  containing Chap-provided run information (see Run Info section).
  Should return a model object that will be automatically saved as RDS.

- predict_fn:

  Prediction function with signature:
  `function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list())`
  where all data inputs are tsibbles, `saved_model` is a loaded object,
  `model_configuration` is a list of user-defined configuration options,
  and `run_info` is a list containing Chap-provided run information.
  Must return a tibble with a `samples` list-column containing numeric
  vectors. For deterministic models, use a single sample per forecast
  unit (e.g., `samples = list(c(42))`). For probabilistic models,
  include multiple Monte Carlo samples. The CLI automatically converts
  the nested samples to wide CSV format (sample_0, sample_1, ...) for
  Chap.

  **Important**: `historic_data` may contain more recent observations
  than the original training data. Chap may call predict with updated
  data after the model was trained. For time series models, you should
  typically refit the model to `historic_data` before forecasting. Use
  `saved_model` to store model hyperparameters or structure that should
  persist across predictions, rather than the fitted model itself. See
  `examples/arima_model/` for a demonstration of this pattern using
  `fable::refit()`.

- model_config_schema:

  Optional model configuration schema (reserved for future use). Can be
  used with the "info" subcommand to display schema information.

- model_info:

  Optional list describing the model's data requirements and
  capabilities. Used by Chap to validate data before sending to the
  model and displayed via the "info" subcommand. See Model Info section
  for details.

- default_config_path:

  Default path to config file (default: "config.yml")

- default_model_path:

  Default path to model file (default: "model.rds")

- args:

  Command line arguments (defaults to
  `commandArgs(trailingOnly = TRUE)`)

## Value

Invisible result of the called function

## Details

This CLI style is designed for integration with chapkit's ML service
framework, which manages workspaces and file paths automatically.

### Training Command

    Rscript model.R train --data <path> [--config <path>] [--model <path>] [--run-info <path>]

- `--data`: Path to training data CSV (required)

- `--config`: Path to YAML config file (default: config.yml)

- `--model`: Path to save trained model (default: model.rds)

- `--run-info`: Path to run_info YAML/JSON file (optional, provided by
  Chap)

### Prediction Command

    Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>] [--run-info <path>]

- `--historic`: Path to historic data CSV (required)

- `--future`: Path to future data CSV (required)

- `--output`: Path to write predictions CSV (required)

- `--config`: Path to YAML config file (default: config.yml)

- `--model`: Path to load trained model (default: model.rds)

- `--run-info`: Path to run_info YAML/JSON file (optional, provided by
  Chap)

### Info Command

    Rscript model.R info [--format yaml|json]

- `--format`: Output format, either "yaml" (default, human-readable) or
  "json" (machine-readable for chapkit integration)

### Chapkit Integration

Configure ShellModelRunner in chapkit:

    runner = ShellModelRunner(
        train_command="Rscript model.R train --data {data_file} --run-info {run_info_file}",
        predict_command="Rscript model.R predict --historic {historic_file} --future {future_file} --output {output_file} --run-info {run_info_file}"
    )

## Model Info

The `model_info` parameter describes what data and configuration the
model expects. This information is used by Chap to validate inputs and
displayed via the "info" subcommand.

- period_type:

  Character. The temporal resolution the model expects ("month", "week",
  "day"). Chap will ensure data is provided at this resolution.

- allows_additional_continuous_covariates:

  Logical. If TRUE, the model can accept additional continuous
  covariates beyond those it specifically requires. Chap will list these
  in `run_info$additional_continuous_covariates`.

- required_covariates:

  Character vector. Names of columns that must be present in the data
  (e.g., `c("population", "rainfall")`). Chap will validate these exist
  before calling the model.

## Run Info

The `run_info` parameter is provided by Chap and passed to both train
and predict functions. It contains runtime information about the current
Chap execution:

- prediction_length:

  Integer. The number of time periods the model is expected to forecast.

- additional_continuous_covariates:

  Character vector. Names of additional covariate columns that the user
  has specified beyond the standard columns. Models that declared
  `allows_additional_continuous_covariates = TRUE` in their `model_info`
  should use these columns.

- future_covariate_origin:

  Character or NULL. Origin/source of future covariate forecasts (e.g.,
  "chap_baseline", "user_provided").

The run_info is passed to the CLI via the `--run-info` argument pointing
to a YAML or JSON file. If not provided, a default run_info is
constructed from the data.

## Examples

``` r
if (FALSE) { # \dontrun{
library(chapr)
library(dplyr)

train_my_model <- function(training_data, model_configuration = list(),
                           run_info = list()) {
  # training_data is already a tsibble - no file I/O needed!
  # run_info contains prediction_length, n_locations, period_type
  means <- training_data |>
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
  return(list(means = means))
}

predict_my_model <- function(historic_data, future_data, saved_model,
                              model_configuration = list(), run_info = list()) {
  # All inputs are already loaded - no file I/O needed!
  # run_info contains prediction_length, n_locations, period_type
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

model_info <- list(
  period_type = "month",
  allows_additional_continuous_covariates = TRUE,
  required_covariates = c("population", "rainfall")
)

# Single function call enables full CLI!
if (!interactive()) {
  create_chap_cli(train_my_model, predict_my_model, config_schema, model_info)
}

# Command line usage:
# Rscript model.R train --data data.csv [--config config.yml] [--run-info run_info.yaml]
# Rscript model.R predict --historic historic.csv --future future.csv \
#     --output predictions.csv [--config config.yml]
# Rscript model.R info                    # Human-readable YAML output
# Rscript model.R info --format json      # Machine-readable JSON for chapkit
} # }
```
