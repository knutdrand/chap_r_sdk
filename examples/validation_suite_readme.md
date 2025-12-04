# Model Testing & Validation Suite

## Overview

The `chap.r.sdk` package provides functions to help test and validate CHAP-compatible models. This ensures models produce output consistent with CHAP platform expectations.

## Getting Example Data

### `get_example_data(country, frequency)`

Returns standardized test datasets for validating models.

**Parameters:**
- `country`: Country name (currently only `'laos'` supported)
- `frequency`: Temporal frequency (currently only `'M'` for monthly supported)

**Returns:**
A named list with four tibbles:
- `training_data`: Historical data for training the model
- `historic_data`: Historical context data for predictions
- `future_data`: Future time periods to predict
- `predictions`: Example prediction output format

**Example:**

```r
library(chap.r.sdk)

# Load test data
data <- get_example_data('laos', 'M')

# Use in model workflow
model <- train_my_model(data$training_data)

predictions <- predict_my_model(
  data$historic_data,
  data$future_data,
  model
)

# Validate output format matches expected structure
stopifnot(all(c("time_period", "location") %in% names(predictions)))
```

## Data Structure

### Training Data
Contains historical observations with:
- `time_period`: Temporal identifier (e.g., "2000-07")
- `location`: Spatial identifier (e.g., "Bokeo", "Champasak")
- `disease_cases`: Observed case counts
- Covariates: rainfall, temperature, population, etc.

### Historic Data
Similar to training data but may cover different time period, used as context for predictions.

### Future Data
Contains future time periods with:
- `time_period`: Future dates to predict
- `location`: Spatial units
- Covariates: rainfall, temperature (may be forecasted)
- NO `disease_cases` column (this is what the model predicts)

### Predictions
Example output format with:
- `time_period`: Matches future_data
- `location`: Matches future_data
- `sample_0` to `sample_999`: Monte Carlo samples of predictions

## Validation Functions (Coming Soon)

### `validate_model_output(predictions, expected_schema)`
Validates that model output conforms to CHAP expectations.

### `run_model_tests(train_fn, predict_fn, test_data)`
Runs comprehensive test suite on model functions.

## Testing Your Model

```r
# Get example data
data <- get_example_data('laos', 'M')

# Test training
model <- train_my_model(data$training_data)
stopifnot(!is.null(model))

# Test prediction
preds <- predict_my_model(
  data$historic_data,
  data$future_data,
  model
)

# Validate structure
stopifnot(nrow(preds) == nrow(data$future_data))
stopifnot("time_period" %in% names(preds))
stopifnot("location" %in% names(preds))

# Check for Monte Carlo samples
sample_cols <- grep("^sample_", names(preds), value = TRUE)
stopifnot(length(sample_cols) > 0)

cat("✓ Model validation passed!\n")
```

## Future Enhancements

Additional countries and frequencies will be added:
- Weekly frequency (`'W'`)
- Other geographic regions
- Different disease types

Validation functions will be implemented to automatically check:
- Output schema compliance
- Required column presence
- Data type correctness
- Sample dimension requirements
- Time period continuity
- Location consistency
