# Create Chapkit-Compatible CLI

Creates a command-line interface compatible with chapkit's
ShellModelRunner. Uses named arguments (–data, –historic, –future,
–output) instead of positional arguments. Config and model paths have
sensible defaults but can be overridden.

## Usage

``` r
create_chapkit_cli(
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
  containing CHAP-provided run information (see
  [`create_chap_cli`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)
  for details). Should return a model object that will be automatically
  saved as RDS.

- predict_fn:

  Prediction function with signature:
  `function(historic_data, future_data, saved_model, model_configuration = list(), run_info = list())`
  where all data inputs are tsibbles, `saved_model` is a loaded object,
  `model_configuration` is a list of user-defined configuration options,
  and `run_info` is a list containing CHAP-provided run information.
  Must return a tibble with a `samples` list-column containing numeric
  vectors.

- model_config_schema:

  Optional model configuration schema (for info subcommand).

- model_info:

  Optional list describing the model's data requirements and
  capabilities. See
  [`create_chap_cli`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)
  for details on the model_info structure.

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
  CHAP)

### Prediction Command

    Rscript model.R predict --historic <path> --future <path> --output <path> [--config <path>] [--model <path>] [--run-info <path>]

- `--historic`: Path to historic data CSV (required)

- `--future`: Path to future data CSV (required)

- `--output`: Path to write predictions CSV (required)

- `--config`: Path to YAML config file (default: config.yml)

- `--model`: Path to load trained model (default: model.rds)

- `--run-info`: Path to run_info YAML/JSON file (optional, provided by
  CHAP)

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

## Examples

``` r
if (FALSE) { # \dontrun{
library(chap.r.sdk)

train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
  list(mean = mean(training_data$disease_cases, na.rm = TRUE))
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list(), run_info = list()) {
  future_data |>
    dplyr::mutate(samples = purrr::map(seq_len(dplyr::n()), ~c(saved_model$mean)))
}

if (!interactive()) {
  create_chapkit_cli(train_fn, predict_fn)
}
} # }
```
