# Mean Model Example

This directory contains a simple example of using the chap.r.sdk CLI infrastructure with a basic mean model.

## Overview

The mean model is a simple baseline model that predicts disease cases for each location based on the historical mean for that location. This example demonstrates:

1. Creating a unified CLI with `create_chap_cli()` (**NEW - Recommended Pattern**)
2. Automatic file I/O handling (no manual CSV loading needed)
3. Clean separation of business logic from infrastructure
4. Legacy pattern with `create_train_cli()` and `create_predict_cli()` (deprecated)

## Files

### New Unified Pattern (Recommended)
- `model.R` - **NEW**: Single file with unified CLI using `create_chap_cli()`

### Legacy Pattern (Deprecated)
- `train.R` - Legacy CLI wrapper for training (uses deprecated `create_train_cli()`)
- `predict.R` - Legacy CLI wrapper for prediction (uses deprecated `create_predict_cli()`)

### Data Files
- `example_data.csv` - Sample training data
- `future_data.csv` - Sample future data for predictions

## Model Description

The mean model calculates the mean disease cases for each location from the training data and uses this mean as the prediction for all future time periods.

**Training**: Calculates mean disease cases per location
**Prediction**: Returns the historical mean for each location-time combination

## Usage

### New Unified CLI Pattern (Recommended)

#### Command Line

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

#### Interactive

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

### Legacy CLI Pattern (Deprecated)

#### Command Line

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

#### Interactive

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

## Implementation Comparison

### New Unified Pattern vs. Legacy Pattern

**Code Reduction**: The new pattern reduces boilerplate by **41%** (from 119 lines across 2 files to 70 lines in 1 file)

**Key Advantages of New Pattern:**
1. **Single File**: `model.R` combines training and prediction in one place
2. **Zero File I/O Boilerplate**: No manual CSV loading, tsibble conversion, or file saving
3. **Clean Functions**: Model functions only contain business logic
4. **Subcommand Dispatch**: `train`, `predict`, and `info` subcommands from one script
5. **Auto-Detection**: Automatic identification of time and key columns

**Migration Guide:**
- Old pattern: CLI wrapper functions receive file paths and handle all I/O
- New pattern: Model functions receive loaded tsibbles; CLI handles I/O automatically
- Legacy `create_train_cli()` and `create_predict_cli()` are deprecated but still functional

## Implementation Details

### New Unified CLI Pattern

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

### Legacy CLI Wrapper Pattern

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
