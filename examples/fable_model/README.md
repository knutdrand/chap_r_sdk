# Fable ETS Model for Chap

This example demonstrates how to develop an R-based time series model for disease prediction using the fable package and integrate it with Chap via chapkit.

## Model Overview

The model uses **Exponential Smoothing (ETS)** from the fable package for forecasting disease cases. ETS models can capture trend and seasonality patterns in time series data.

**Key features:**
- Automatic ETS model selection (error/trend/seasonal components)
- REFIT pattern for prediction (refits model to latest historic data)
- Probabilistic forecasts with Monte Carlo sampling
- Optional climate covariates support (ARIMA with external regressors)

## Baseline Performance

Evaluated on the Laos monthly dataset:

| Metric | Value |
|--------|-------|
| RMSE | 274.66 |
| MAE | 105.78 |
| CRPS | 82.27 |
| 80% Coverage | 81.0% |
| 50% Coverage | 60.3% |

## Development Process

This section documents the complete workflow for developing an R model compatible with Chap.

### Step 1: Create the R Model

Create a model.R file using the `create_chap_cli()` function from chapr:

```r
library(chapr)
library(dplyr)
library(fable)
library(tsibble)

# Define train function
train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
  # Your training logic here
  # Returns a model object (list)
}

# Define predict function
predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list(), run_info = list()) {
  # Your prediction logic here
  # Must return data with a 'samples' list-column
}

# Define configuration schema
config_schema <- list(
  title = "My Model Configuration",
  type = "object",
  properties = list(
    n_samples = list(type = "integer", default = 100)
  )
)

# Define model info
model_info <- list(
  period_type = "month",
  allows_additional_continuous_covariates = FALSE,
  required_covariates = character(0)
)

# Enable CLI
if (!interactive()) {
  create_chap_cli(train_fn, predict_fn, config_schema, model_info)
}
```

### Step 2: Test with SDK Validation

Run the SDK validation tests to ensure your model is compatible:

```r
# In R
options(chapr.testing = TRUE)
devtools::load_all()
source('model.R', local = TRUE)

example_data <- get_example_data('laos', 'M')
result <- validate_model_io(train_fn, predict_fn, example_data)
print(result)
```

The validation checks:
- Predictions have a `samples` list-column
- All samples are non-negative
- No NA/NaN values
- Row count matches future_data

### Step 3: Create chapkit Service Files

Create `pyproject.toml`:

```toml
[project]
name = "my-model"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "chapkit @ git+https://github.com/dhis2-chap/chapkit.git@feat/r-sdk-integration",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.metadata]
allow-direct-references = true

[tool.hatch.build.targets.wheel]
packages = ["."]
only-include = ["main.py"]
```

Create `main.py`:

```python
from pathlib import Path
from chapkit.api import AssessedStatus, MLServiceBuilder, MLServiceInfo, PeriodType
from chapkit.artifact import ArtifactHierarchy
from chapkit.ml import ShellModelRunner, discover_model_info

SCRIPT_DIR = Path(__file__).parent

# Discover schema from R model
model_info = discover_model_info(
    "Rscript model.R info --format json",
    model_name="MyModelConfig",
    cwd=SCRIPT_DIR,
)

# Create shell runner
runner = ShellModelRunner(
    train_command=f"Rscript {SCRIPT_DIR}/model.R train --data {{data_file}} --run-info {{run_info_file}}",
    predict_command=f"Rscript {SCRIPT_DIR}/model.R predict --historic {{historic_file}} --future {{future_file}} --output {{output_file}} --run-info {{run_info_file}}",
)

# Build service
info = MLServiceInfo(
    display_name="My Model",
    version="1.0.0",
    supported_period_type=PeriodType(model_info.period_type),
    required_covariates=model_info.required_covariates,
)

app = (
    MLServiceBuilder(
        info=info,
        config_schema=model_info.config_class,
        hierarchy=ArtifactHierarchy(name="ml", level_labels={0: "ml_training", 1: "ml_prediction"}),
        runner=runner,
    )
    .with_monitoring()
    .build()
)
```

### Step 4: Evaluate with chap evaluate2

Run the evaluation on your dataset:

```bash
cd /path/to/chap-core
uv run chap evaluate2 \
    /path/to/your/model \
    /path/to/dataset.csv \
    /path/to/output.nc \
    3 3 1 \
    true true '' timestamp true
```

Arguments explained:
- Model path
- Dataset CSV path
- Output NetCDF path
- `n-periods`: Number of periods to predict (e.g., 3 months)
- `n-splits`: Number of backtest splits
- `stride`: Step size between splits
- `ignore-environment`: Skip environment setup (use system R)
- `debug`: Enable debug logging
- Empty string for log-file
- `timestamp`: Run directory type
- `true`: is-chapkit-model flag

### Step 5: Export and Analyze Metrics

```bash
uv run chap export-metrics \
    --input-files /path/to/output.nc \
    --output-file /path/to/metrics.csv
```

Key metrics to review:
- **RMSE**: Root Mean Square Error (lower is better)
- **MAE**: Mean Absolute Error (lower is better)
- **CRPS**: Continuous Ranked Probability Score (lower is better)
- **80% Coverage**: Should be close to 80%
- **50% Coverage**: Should be close to 50%

### Step 6: Iterate on Model Improvements

Based on metrics, consider:
1. Different model specifications (ETS vs ARIMA)
2. Adding covariates (rainfall, temperature)
3. Different lag structures
4. Seasonal adjustments

**Important finding**: In our testing, the simple ETS model outperformed ARIMA with climate covariates. Always validate improvements with metrics!

## Files

- `model.R` - R model implementation
- `main.py` - Chapkit service entry point
- `pyproject.toml` - Python package configuration

## Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `n_samples` | integer | 100 | Monte Carlo samples per forecast |
| `seasonal_period` | integer | 12 | Seasonal period (months) |
| `use_covariates` | boolean | false | Use climate covariates |
| `covariate_lag` | integer | 1 | Lag for covariates in months |

## Environment Setup

This example uses **renv** for reproducible R package management.

### First-time Setup

```bash
cd examples/fable_model

# Restore R dependencies
Rscript -e 'renv::restore()'

# Install Python dependencies
uv sync
```

### Updating Dependencies

If you add new R packages:

```bash
# Install the package
Rscript -e 'renv::install("package_name")'

# Update the lockfile
Rscript -e 'renv::snapshot()'
```

### Requirements

#### R packages (managed by renv)
- chapr
- fable
- fabletools
- tsibble
- dplyr
- lubridate
- distributional

#### Python
- Python >= 3.13
- chapkit (from feat/r-sdk-integration branch)

## Usage

### CLI Commands

```bash
# Get model info
Rscript model.R info --format json

# Train model
Rscript model.R train --data training.csv --run-info run_info.yaml

# Predict
Rscript model.R predict \
    --historic historic.csv \
    --future future.csv \
    --output predictions.csv \
    --run-info run_info.yaml
```

### As a Service

```bash
# Start the chapkit service
cd examples/fable_model
uv run fastapi dev main.py --port 8001
```

## Key Implementation Details

### The REFIT Pattern

For time series models, the REFIT pattern is essential:

1. During training, fit the model to training_data
2. During prediction, **refit** the saved model structure to historic_data
3. This ensures the model uses the most recent observations

```r
# In predict function
refitted_model <- refit(saved_model, historic_tsibble)
forecasts <- forecast(refitted_model, h = h)
```

### Handling Missing Values

ETS doesn't support NAs. Use interpolation:

```r
interpolate_na <- function(x) {
  if (all(is.na(x))) return(rep(0, length(x)))
  if (!any(is.na(x))) return(x)
  non_na_idx <- which(!is.na(x))
  approx(non_na_idx, x[non_na_idx], xout = seq_along(x), rule = 2)$y
}
```

### Generating Probabilistic Forecasts

Chap requires a `samples` list-column with Monte Carlo samples:

```r
samples_list <- lapply(seq_len(nrow(forecasts)), function(i) {
  dist <- forecasts$disease_cases[i]
  mu <- mean(dist)
  sigma <- sqrt(variance(dist))
  samples <- rnorm(n_samples, mean = mu, sd = sigma)
  pmax(0, samples)  # Ensure non-negative
})
```

### Contract Requirements

Your predict function must return predictions with:
- `samples` list-column (required)
- All samples non-negative
- No NA/NaN values
- Same number of rows as future_data
