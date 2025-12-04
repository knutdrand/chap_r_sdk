# Mean Model Example

This directory contains a simple example of using the chap.r.sdk CLI infrastructure with a basic mean model.

## Overview

The mean model is a simple baseline model that predicts disease cases for each location based on the historical mean for that location. This example demonstrates:

1. Creating a unified CLI with `create_chap_cli()`
2. Automatic file I/O handling (no manual CSV loading needed)
3. Clean separation of business logic from infrastructure
4. Subcommand dispatch (train/predict/info)

## Files

- `model.R` - Single file with unified CLI using `create_chap_cli()`
- `example_data.csv` - Sample training data
- `future_data.csv` - Sample future data for predictions

## Model Description

The mean model calculates the mean disease cases for each location from the training data and uses this mean as the prediction for all future time periods.

**Training**: Calculates mean disease cases per location
**Prediction**: Returns the historical mean for each location-time combination

## Usage

### Command Line

```bash
# Train the model
Rscript examples/mean_model/model.R train examples/mean_model/example_data.csv

# Generate predictions
Rscript examples/mean_model/model.R predict \
  examples/mean_model/example_data.csv \
  examples/mean_model/future_data.csv \
  model.rds

# Display model info and configuration schema
Rscript examples/mean_model/model.R info
```

### Interactive

```r
# Source the model functions
source("examples/mean_model/model.R")

# Train
model <- train_mean_model(
  training_data = training_tsibble,  # Already loaded tsibble
  model_configuration = list()
)

# Predict
predictions <- predict_mean_model(
  historic_data = historic_tsibble,  # Already loaded tsibble
  future_data = future_tsibble,      # Already loaded tsibble
  saved_model = model,
  model_configuration = list()
)

print(predictions)
```

## Data Format

### Training Data (`example_data.csv`)

Required columns:
- `time_period` - Time period identifier (e.g., "2023-01")
- `location` - Location identifier
- `disease_cases` - Number of disease cases
- Optional: `population` or other covariates

### Future Data (`future_data.csv`)

Required columns:
- `time_period` - Time period identifier for future predictions
- `location` - Location identifier
- Optional: `population` or other covariates (must match training data)

### Output (`model_predictions.csv`)

Columns:
- `time_period` - Time period identifier
- `location` - Location identifier
- `disease_cases` - Predicted disease cases (mean from training data)
- Any other columns from future_data

## Implementation Details

### Unified CLI Pattern

With `create_chap_cli()`, you only write business logic:

```r
library(chap.r.sdk)
library(dplyr)

# Pure business logic - no file I/O!
train_mean_model <- function(training_data, model_configuration = list()) {
  means <- training_data |>
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))

  return(list(means = means))
}

predict_mean_model <- function(historic_data, future_data, saved_model,
                                model_configuration = list()) {
  predictions <- future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(disease_cases = mean_cases)

  return(predictions)
}

config_schema <- list(
  title = "Mean Model Configuration",
  type = "object",
  properties = list()
)

# One line enables full CLI!
if (!interactive()) {
  create_chap_cli(train_mean_model, predict_mean_model, config_schema)
}
```

The `create_chap_cli()` function automatically:
- Parses subcommands (train/predict/info)
- Loads CSV files and converts to tsibbles
- Detects time and key columns
- Parses YAML configuration files
- Loads saved models
- Saves outputs (RDS for models, CSV for predictions)

### Key Points

1. **File I/O Separation**: The CLI handles all file I/O, while the core model functions work with R objects
2. **tsibble Conversion**: Data is converted to tsibbles for compatibility with time series operations
3. **Configuration Handling**: Optional configuration files are loaded and passed to model functions
4. **Return Paths**: CLI functions return file paths to saved outputs
5. **Interactive Guard**: `if (!interactive())` ensures CLI wrapper only runs in script mode

## Extending the Example

To adapt this for your own model:

1. Define train and predict functions that work with tsibbles
2. Implement your model logic (file I/O handled automatically)
3. Define a configuration schema (optional)
4. Use `create_chap_cli(train_fn, predict_fn, schema)` at the end

## Dependencies

```r
library(chap.r.sdk)  # CLI and config functions
library(dplyr)       # Data manipulation (in your model functions)
```

## Comparison with EWARS Model

Unlike the EWARS model which combines training and prediction:
- Mean model has a clear train/predict separation
- Training produces a simple lookup table (means per location)
- Prediction is just a join operation
- This is a more typical model pattern

## License

Same as parent chap_r_sdk package.
