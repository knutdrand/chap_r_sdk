# ARIMA Model Example

This example demonstrates an **ARIMA model with exogenous regressors** (ARIMAX) for disease forecasting. It showcases the key pattern of **refitting the model to historic data** before making predictions.

## Key Concept: Refitting to Historic Data

When CHAP calls the predict function, `historic_data` may contain **more recent observations** than the original `training_data`. For time series models like ARIMA, this means the model should be **refit** to the historic data before forecasting.

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

## Dependencies

This example requires:
- `fable` - Time series forecasting framework
- `distributional` - For extracting mean/variance from forecast distributions
- `lubridate` - For `yearmonth()` time period handling
- `tsibble` - Tidy time series data structures
- `dplyr` - Data manipulation

Install with:
```r
install.packages(c("fable", "distributional", "lubridate"))
```

## Usage

### Train the model
```bash
Rscript model.R train training_data.csv
```

### Generate predictions
```bash
Rscript model.R predict historic.csv future.csv model.rds
```

### Display model info
```bash
Rscript model.R info
```

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

Configure via YAML file:

```yaml
lag_periods: 3      # Months to lag climate variables (1-12)
n_samples: 100      # Monte Carlo samples per forecast (1-10000)
```

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
2. CHAP calls predict in June 2024 with `historic_data` from Jan 2020 - May 2024
3. Without refitting: Model uses 2022 state to forecast from 2024 (18-month gap!)
4. With refitting: Model updates to May 2024 state before forecasting

The `fable::refit()` function preserves the model structure (ARIMA order, coefficients approach) while updating to the new data.
