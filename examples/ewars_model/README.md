# EWARS Model Example

This directory contains a complete example of a CHAP-compatible EWARS (Early Warning and Response System) model that has been adapted to use the chap.r.sdk package.

## Overview

The EWARS model is a spatio-temporal disease surveillance model that uses INLA (Integrated Nested Laplace Approximations) for Bayesian inference. This model demonstrates:

1. How to adapt existing models to use the chap.r.sdk CLI infrastructure
2. YAML-based configuration management
3. Models that combine training and prediction in a single step
4. Handling of spatio-temporal data with covariates

## Model Characteristics

- **Training**: No-op (all training happens in predict step)
- **Prediction**: Combines historic and future data, trains INLA model, generates predictions
- **Temporal Resolution**: Supports both weekly and monthly data
- **Covariates**: Rainfall and temperature with distributed lag effects
- **Output**: 1000 posterior samples per prediction

## Files

- `train.R` - Training script (no-op, returns NULL)
- `predict.R` - Prediction script (trains and predicts)
- `lib.R` - Helper functions for temporal offset calculations
- `example_config.yaml` - Sample configuration file
- `MIGRATION_TO_CHAP_SDK.md` - Detailed migration guide

## Dependencies

```r
# Core CHAP SDK
library(chap.r.sdk)

# Statistical modeling
library(INLA)
library(dlnm)

# Data manipulation
library(dplyr)
library(purrr)

# Spatial analysis
library(sf)
library(spdep)

# Configuration
library(yaml)
library(jsonlite)
```

## Configuration

The model uses YAML configuration files. Example:

```yaml
additional_continuous_covariates:
  - rainfall
  - mean_temperature
user_option_values:
  n_lag: 3
  precision: 1
```

### Configuration Parameters

- `additional_continuous_covariates`: List of covariate names to include in the model
- `user_option_values.n_lag`: Number of lag periods for distributed lag models
- `user_option_values.precision`: Precision parameter for INLA fixed effects

## Usage

### Interactive

```r
# Source the functions
source("examples/ewars_model/predict.R")

# Run prediction
result <- predict_chap(
  historic_data = "path/to/historic_data.csv",
  future_data = "path/to/future_data.csv",
  saved_model = "path/to/model.rds",
  model_configuration = "examples/ewars_model/example_config.yaml"
)
```

### Command Line

```bash
# Train (no-op)
Rscript examples/ewars_model/train.R train_data.csv model.rds

# Predict
Rscript examples/ewars_model/predict.R \
  historic_data.csv \
  future_data.csv \
  model.rds \
  examples/ewars_model/example_config.yaml
```

## Data Format

### Input Data (Historic and Future)

Required columns:
- `time_period` - Time period identifier (e.g., "2023-05")
- `location` - Location identifier
- `disease_cases` or `Cases` - Number of disease cases
- `population` or `E` - Population size
- `week` or `month` - Temporal unit
- `year` or `ID_year` - Year
- Covariate columns (e.g., `rainfall`, `mean_temperature`)

### Output Data (Predictions)

Columns:
- `time_period` - Time period identifier
- `location` - Location identifier
- `sample_0`, `sample_1`, ..., `sample_999` - 1000 posterior predictive samples

## Model Details

### Formula Structure

For weekly data with covariates:
```r
Cases ~ 1 +
  f(ID_spat, model='iid', replicate=ID_year) +
  f(ID_time_cyclic, model='rw1', cyclic=TRUE, scale.model=TRUE) +
  basis_rainfall +
  basis_mean_temperature
```

### Key Features

1. **Spatial Random Effects**: IID random effects per location, replicated by year
2. **Temporal Cyclic Effects**: RW1 prior with cyclic boundary (for seasonality)
3. **Distributed Lag Effects**: Natural cubic splines for lagged covariates using `dlnm::crossbasis()`
4. **Negative Binomial Family**: Handles overdispersion in count data
5. **Population Offset**: log(population) offset for incidence modeling

### Temporal Offset Logic

The model includes special logic to align data to consistent temporal cycles:

- **Weekly data**: Aligns to week 26 (mid-year) with 52-week cycle
- **Monthly data**: Aligns to month 6 (June) with 12-month cycle

This ensures the cyclic random walk has consistent boundary conditions.

## Implementation Notes

### Why Train is Empty

This model doesn't perform a separate training step because:
1. INLA models are fit quickly enough to run during prediction
2. The model needs both historic and future data to create proper lagged covariates
3. Predictions are generated simultaneously with model fitting

### CLI Wrapper Usage

The model uses `create_train_cli()` and `create_predict_cli()` from chap.r.sdk:

```r
# In train.R
if (!interactive()) {
  create_train_cli(train_chap)
}

# In predict.R
if (!interactive()) {
  create_predict_cli(predict_chap)
}
```

This provides:
- Automatic argument parsing
- Consistent error handling
- Standard CHAP interface
- Interactive mode detection

### Configuration Parsing

The model uses SDK functions for safe configuration access:

```r
config <- read_model_config(file_path, validate = FALSE)
covariate_names <- pluck(config, "additional_continuous_covariates", .default = character())
nlag <- get_config_param(config$user_option_values, "n_lag", .default = 3)
```

Benefits:
- Safe nested access with defaults
- Consistent error messages
- Future schema validation support

## Migration from Legacy Code

See `MIGRATION_TO_CHAP_SDK.md` for detailed information about:
- Changes from the original implementation
- Function signature updates
- CLI interface changes
- Testing procedures
- Rollback plan

## Key Differences from Traditional CHAP Models

1. **Combined Train/Predict**: Unlike most models, this one does all work in predict step
2. **No Separate Model File**: The model is trained fresh each time
3. **Temporal Alignment**: Special preprocessing to align weekly/monthly cycles
4. **Multiple Samples**: Returns 1000 posterior samples instead of point predictions

## Extending the Model

To add new features:

1. **New Covariates**: Add to `additional_continuous_covariates` in config
2. **Different Lag Structure**: Modify `generate_lagged_model()` function
3. **Alternative Priors**: Update INLA control parameters
4. **Spatial Structure**: Modify spatial random effects specification

## References

- INLA: [r-inla.org](https://www.r-inla.org/)
- dlnm: [Distributed Lag Non-linear Models](https://cran.r-project.org/package=dlnm)
- CHAP SDK: See main repository documentation

## License

Same as parent chap_r_sdk package.
