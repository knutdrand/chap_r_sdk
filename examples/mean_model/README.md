# Mean Model Example

This directory contains a simple example of using the chap.r.sdk CLI infrastructure with a basic mean model.

## Overview

The mean model is a simple baseline model that predicts disease cases for each location based on the historical mean for that location. This example demonstrates:

1. Creating CLI wrappers for model functions
2. Handling data I/O (CSV files)
3. Converting between data frames and tsibbles
4. Using the SDK's `create_train_cli()` and `create_predict_cli()` functions

## Files

- `train.R` - CLI wrapper for training the mean model
- `predict.R` - CLI wrapper for generating predictions
- `example_data.csv` - Sample training data
- `future_data.csv` - Sample future data for predictions

## Model Description

The mean model calculates the mean disease cases for each location from the training data and uses this mean as the prediction for all future time periods.

**Training**: Calculates mean disease cases per location
**Prediction**: Returns the historical mean for each location-time combination

## Usage

### Interactive

```r
# Source the functions
source("examples/mean_model/train.R")
source("examples/mean_model/predict.R")

# Train
model_path <- train_mean_model_cli(
  training_data = "examples/mean_model/example_data.csv",
  model_configuration = NULL
)

# Predict
predictions_path <- predict_mean_model_cli(
  historic_data = "examples/mean_model/example_data.csv",
  future_data = "examples/mean_model/future_data.csv",
  saved_model = model_path,
  model_configuration = NULL
)

# Load and view predictions
predictions <- readr::read_csv(predictions_path)
print(predictions)
```

### Command Line

```bash
# Train the model
Rscript examples/mean_model/train.R \
  examples/mean_model/example_data.csv

# Generate predictions
Rscript examples/mean_model/predict.R \
  examples/mean_model/example_data.csv \
  examples/mean_model/future_data.csv \
  mean_model.rds
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

### Output (`mean_model_predictions.csv`)

Columns:
- `time_period` - Time period identifier
- `location` - Location identifier
- `disease_cases` - Predicted disease cases (mean from training data)
- Any other columns from future_data

## Implementation Details

### CLI Wrapper Pattern

The CLI wrappers follow this pattern:

```r
library(chap.r.sdk)

# Define wrapper function
model_cli <- function(training_data, model_configuration = NULL) {
  # 1. Load data from file paths
  df <- readr::read_csv(training_data)

  # 2. Convert to required format (tsibble)
  tsibble_data <- tsibble::as_tsibble(df, index = time_period, key = location)

  # 3. Load configuration (if provided)
  config <- if (!is.null(model_configuration)) {
    read_model_config(model_configuration)
  } else {
    list()
  }

  # 4. Call the actual model function
  result <- actual_model_function(tsibble_data, config)

  # 5. Save results to file
  saveRDS(result, "output.rds")

  # 6. Return output file path
  return("output.rds")
}

# Use SDK CLI wrapper
if (!interactive()) {
  create_train_cli(model_cli)
}
```

### Key Points

1. **File I/O Separation**: The CLI wrappers handle all file I/O, while the core model functions work with R objects
2. **tsibble Conversion**: Data is converted to tsibbles for compatibility with time series operations
3. **Configuration Handling**: Optional configuration files are loaded and passed to model functions
4. **Return Paths**: CLI functions return file paths to saved outputs
5. **Interactive Guard**: `if (!interactive())` ensures CLI wrapper only runs in script mode

## Extending the Example

To adapt this for your own model:

1. Create wrapper functions that handle file I/O
2. Load and convert data to the format your model expects
3. Call your actual model functions
4. Save outputs and return file paths
5. Use `create_train_cli()` and `create_predict_cli()` at the end

## Dependencies

```r
library(chap.r.sdk)  # CLI and config functions
library(tsibble)     # Time series data structures
library(dplyr)       # Data manipulation
library(readr)       # CSV reading/writing
```

## Comparison with EWARS Model

Unlike the EWARS model which combines training and prediction:
- Mean model has a clear train/predict separation
- Training produces a simple lookup table (means per location)
- Prediction is just a join operation
- This is a more typical model pattern

## License

Same as parent chap_r_sdk package.
