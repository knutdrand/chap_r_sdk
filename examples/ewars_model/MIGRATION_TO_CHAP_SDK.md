# Migration to CHAP R SDK

This document describes the changes made to adapt the EWARS template model to use the new CHAP R SDK CLI infrastructure.

## Summary of Changes

The EWARS model has been updated to use the `chap.r.sdk` package for:
1. Standardized CLI argument parsing
2. YAML configuration file parsing
3. Consistent function signatures matching CHAP conventions

## What Changed

### 1. train.R

**Before:**
```r
library(INLA)
source('lib.R')

train_chap <- function(train_fn, model_fn){
  #would normally train the model here
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 2) {
  train_fn <- args[1]
  model_fn <- args[2]

  train_chap(csv_fn, model_fn)
}
```

**After:**
```r
library(INLA)
library(chap.r.sdk)
source('lib.R')

#' Train CHAP Model
#'
#' This model does not perform training in the traditional sense.
#' All training and prediction happens in the predict step.
#'
#' @param training_data Path to training data CSV file
#' @param model_configuration Optional path to model configuration YAML file
#' @return Path to saved model file (empty in this case)
train_chap <- function(training_data, model_configuration = NULL){
  # This model does not train in the traditional sense
  # All training happens in the predict step
  # Return NULL to indicate no model file is created
  return(NULL)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_train_cli(train_chap)
}
```

**Key Changes:**
- Added `library(chap.r.sdk)` for SDK functions
- Updated function signature to match CHAP conventions: `train(training_data, model_configuration)`
- Replaced manual `commandArgs()` parsing with `create_train_cli()` wrapper
- Added roxygen2 documentation
- Added `if (!interactive())` guard for CLI mode

### 2. predict.R

**Before:**
```r
library(yaml)
# Manual argument parsing
parse_model_configuration <- function(file_path) {
  config <- yaml.load_file(file_path)
  # Manual parsing...
}

predict_chap <- function(model_fn, hist_fn, future_fn, preds_fn, config_fn=""){
  # Function body...
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 1) {
  model_fn <- args[1]
  hist_fn <- args[2]
  future_fn <- args[3]
  preds_fn <- args[4]
  if (length(args) == 5) {
    config_fn <- args[5]
  } else {
    config_fn <- ""
  }
  predict_chap(model_fn, hist_fn, future_fn, preds_fn, config_fn)
}
```

**After:**
```r
library(chap.r.sdk)
library(purrr)
# SDK-based argument parsing

parse_model_configuration <- function(file_path) {
  if (is.null(file_path) || file_path == "") {
    return(list(
      user_option_values = list(),
      additional_continuous_covariates = character()
    ))
  }

  # Use chap.r.sdk config reading function
  config <- read_model_config(file_path, validate = FALSE)

  # Use purrr::pluck for safe nested access
  user_option_values <- pluck(config, "user_option_values", .default = list())
  additional_continuous_covariates <- pluck(config, "additional_continuous_covariates", .default = character())

  list(
    user_option_values = user_option_values,
    additional_continuous_covariates = additional_continuous_covariates
  )
}

#' Predict with EWARS Model
#'
#' This model trains and predicts in a single step.
#'
#' @param historic_data Path to historic data CSV file
#' @param future_data Path to future data CSV file
#' @param saved_model Path to saved model file (will be created)
#' @param model_configuration Path to model configuration YAML file (optional)
#' @return Path to predictions CSV file
predict_chap <- function(historic_data, future_data, saved_model, model_configuration = NULL){
  # Parse configuration using SDK functions
  if (!is.null(model_configuration) && model_configuration != "") {
    config <- parse_model_configuration(model_configuration)
    covariate_names <- config$additional_continuous_covariates
    nlag <- get_config_param(config$user_option_values, "n_lag", .default = 3)
    precision <- get_config_param(config$user_option_values, "precision", .default = 0.01)
  } else {
    # Default values
    covariate_names <- c("rainfall", "mean_temperature")
    nlag <- 3
    precision <- 0.01
  }

  # Rest of function uses new parameter names
  df <- read.csv(future_data)  # was: future_fn
  historic_df <- read.csv(historic_data)  # was: hist_fn

  # ... model training and prediction ...

  # Generate predictions output file path
  preds_fn <- sub("\\.rds$", "_predictions.csv", saved_model)

  write.csv(new.df, preds_fn, row.names = FALSE)
  saveRDS(model, file = saved_model)  # was: model_fn

  return(preds_fn)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_predict_cli(predict_chap)
}
```

**Key Changes:**
- Added `library(chap.r.sdk)` and `library(purrr)` for SDK functions
- Updated function signature to match CHAP conventions: `predict(historic_data, future_data, saved_model, model_configuration)`
- Replaced manual `yaml.load_file()` with `read_model_config()` from SDK
- Used `get_config_param()` for safe parameter extraction with defaults
- Used `purrr::pluck()` for safe nested list access
- Replaced manual `commandArgs()` parsing with `create_predict_cli()` wrapper
- Added roxygen2 documentation
- Updated all variable references to use new parameter names
- Added return value (predictions file path)

## Configuration File Changes

The YAML configuration format remains the same:

```yaml
additional_continuous_covariates:
  - rainfall
  - mean_temperature
user_option_values:
  n_lag: 3
  precision: 1
```

However, parsing now uses:
- `read_model_config()` instead of `yaml.load_file()`
- `get_config_param()` for safe parameter access with defaults
- `purrr::pluck()` for nested value extraction

## Dependencies

### Added Dependencies

The model now requires the `chap.r.sdk` package:

```r
# Install from source (once published)
# install.packages("chap.r.sdk")

# Or from local path during development:
# devtools::install("/path/to/chap_r_sdk")
```

### Existing Dependencies (unchanged)

- INLA
- dlnm
- dplyr
- sf
- spdep
- yaml
- jsonlite

## Function Signature Changes

### Train Function

| Before | After |
|--------|-------|
| `train_chap(train_fn, model_fn)` | `train_chap(training_data, model_configuration)` |

### Predict Function

| Before | After |
|--------|-------|
| `predict_chap(model_fn, hist_fn, future_fn, preds_fn, config_fn)` | `predict_chap(historic_data, future_data, saved_model, model_configuration)` |

**Note:** The `preds_fn` parameter is no longer needed as output path - it's now automatically generated from `saved_model` path.

## CLI Usage

### Before (Manual Argument Parsing)

```bash
# Train
Rscript train.R train_data.csv model.rds

# Predict
Rscript predict.R model.rds historic.csv future.csv predictions.csv config.yaml
```

### After (SDK CLI Wrapper)

The CLI interface remains the same from the user's perspective, but now uses the SDK's standardized argument parsing:

```bash
# Train
Rscript train.R train_data.csv model.rds

# Predict
Rscript predict.R historic.csv future.csv model.rds config.yaml
```

**Note:** The argument order for predict has changed to match CHAP conventions:
- `historic_data` comes first
- `future_data` comes second
- `saved_model` comes third
- `model_configuration` is optional fourth

## Benefits of Migration

1. **Standardization**: Consistent interface with other CHAP models
2. **Better Error Handling**: SDK provides informative error messages via `cli` package
3. **Safe Configuration Access**: `get_config_param()` provides defaults and safe nested access
4. **Documentation**: Roxygen2 documentation for all functions
5. **Maintainability**: Less boilerplate code for argument parsing
6. **Future-Proof**: Easy to adopt new SDK features (validation, schema support, etc.)

## Testing

To test the migrated model:

```r
# Option 1: Interactive testing
source("predict.R")
result <- predict_chap(
  historic_data = "example_data_monthly/historic_data.csv",
  future_data = "example_data_monthly/future_data.csv",
  saved_model = "example_data_monthly/model.rds",
  model_configuration = "example_config.yaml"
)

# Option 2: Command line testing
system("Rscript predict.R example_data_monthly/historic_data.csv example_data_monthly/future_data.csv example_data_monthly/model.rds example_config.yaml")
```

## Rollback Plan

If issues arise, you can revert to the old implementation:

```bash
git checkout HEAD~1 -- train.R predict.R
```

Or keep both versions:
```bash
cp train.R train_new.R
cp predict.R predict_new.R
# Then restore old versions
```

## Next Steps

1. **Install chap.r.sdk**: Ensure the SDK package is available
2. **Test thoroughly**: Run with example data to verify functionality
3. **Update MLproject**: Update the MLproject file if needed to reflect new argument order
4. **Update documentation**: Update any additional model documentation
5. **Consider validation**: Add schema validation for configuration files using SDK's `ajv` integration

## Questions?

For issues or questions about the CHAP R SDK, see:
- SDK documentation: `/path/to/chap_r_sdk/CLAUDE.md`
- Configuration decision: `/path/to/chap_r_sdk/docs/decisions/001-yaml-config-parsing.md`
