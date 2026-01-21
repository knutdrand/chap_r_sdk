# ARIMA Model Example

This example demonstrates an **ARIMA model with exogenous regressors** (ARIMAX) for disease forecasting. It showcases the key pattern of **refitting the model to historic data** before making predictions.

## Environment Setup (renv)

This example uses [renv](https://rstudio.github.io/renv/) for reproducible dependency management.

### First-time Setup

```bash
cd examples/arima_model
Rscript -e 'renv::restore()'
```

This installs all required packages (fable, distributional, lubridate, tsibble, dplyr, chapr) from the `renv.lock` file.

### Dependencies

All dependencies are tracked in `renv.lock`:
- `fable` - Time series forecasting framework
- `distributional` - For extracting mean/variance from forecast distributions
- `lubridate` - For `yearmonth()` time period handling
- `tsibble` - Tidy time series data structures
- `dplyr` - Data manipulation
- `chapr` - Chap SDK for CLI and utilities

## Usage

### Command Line Interface

This model uses named arguments (chapkit-style) for compatibility with MLproject:

#### Train the model
```bash
Rscript model.R train --data training_data.csv
Rscript model.R train --data training_data.csv --config config.yml --model model.rds
```

#### Generate predictions
```bash
Rscript model.R predict --historic historic.csv --future future.csv --output predictions.csv
Rscript model.R predict --historic historic.csv --future future.csv --output predictions.csv --config config.yml --model model.rds
```

#### Display model info
```bash
Rscript model.R info
Rscript model.R info --format json  # Machine-readable output
```

### Using with chap-core (MLproject)

This example includes an `MLproject` file for direct integration with chap-core:

```bash
# From the chap-core CLI
chap evaluate --model-name ./examples/arima_model --dataset-csv data.csv

# Or run via mlflow
mlflow run ./examples/arima_model -e train -P train_data=data.csv -P model=model.rds
```

The MLproject file specifies:
- `renv_env: renv.lock` - Uses renv for environment management
- `user_options` - Configuration parameters (lag_periods, n_samples)
- Entry points for `train` and `predict`

## Key Concept: Refitting to Historic Data

When Chap calls the predict function, `historic_data` may contain **more recent observations** than the original `training_data`. For time series models like ARIMA, this means the model should be **refit** to the historic data before forecasting.

The workflow in `predict_arima()` is:

1. Combine `historic_data` and `future_data` to compute lagged features correctly
2. **Refit** the saved model structure to the historic data using `fable::refit()`
3. Forecast the future periods
4. Generate samples from the forecast distribution

```r
# KEY STEP: Refit the saved model to the historic data
refitted_model <- refit(saved_arima, historic_tsibble)
forecasts <- forecast(refitted_model, new_data = future_tsibble)
```

This pattern ensures predictions use the most recent available data, not just the original training data.

## Model Description

The model fits a separate ARIMA model for each location with:
- **Target variable**: `disease_cases`
- **Exogenous regressors**: Lagged rainfall and temperature (default: 3-month lag)
- **Probabilistic output**: Samples drawn from the forecast distribution

## Input Data Requirements

### Training/Historic Data
CSV with columns:
- `time_period` - Monthly time period (e.g., "2023-01")
- `location` - Location identifier
- `disease_cases` - Target variable (case counts)
- `rainfall` - Rainfall covariate
- `mean_temperature` - Temperature covariate

### Future Data
Same structure but without `disease_cases`.

## Configuration Options

Configure via YAML file (`config.yml`):

```yaml
lag_periods: 3      # Months to lag climate variables (1-12)
n_samples: 100      # Monte Carlo samples per forecast (1-10000)
```

These options are also exposed in the MLproject `user_options` section.

## Comparison with Mean Model

| Aspect | Mean Model | ARIMA Model |
|--------|------------|-------------|
| Uses `historic_data` | No (unused) | Yes (refits model) |
| Saved model contains | Location means | Model structure/parameters |
| Time series aware | No | Yes |
| Uses covariates | No | Yes (lagged climate) |
| Output type | Deterministic | Probabilistic |

## Why Refitting Matters

Consider this scenario:
1. Model trained on data from Jan 2020 - Dec 2022
2. Chap calls predict in June 2024 with `historic_data` from Jan 2020 - May 2024
3. Without refitting: Model uses 2022 state to forecast from 2024 (18-month gap!)
4. With refitting: Model updates to May 2024 state before forecasting

The `fable::refit()` function preserves the model structure (ARIMA order, coefficients approach) while updating to the new data.

## File Structure

```
arima_model/
├── model.R           # Model implementation with CLI
├── MLproject         # chap-core entry points
├── README.md         # This file
├── renv.lock         # Package dependencies lockfile
├── .Rprofile         # Sources renv activation
├── .gitignore        # Ignores local artifacts
└── renv/
    ├── activate.R    # renv bootstrap script
    ├── settings.json # renv configuration
    └── .gitignore    # Ignores renv library
```
