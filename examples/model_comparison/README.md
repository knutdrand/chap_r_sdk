# Fable Model Comparison Example

This example provides a systematic comparison of multiple fable forecasting models for disease prediction. It supports 6 different model types and is designed to find the best forecasting approach without relying on climate covariates.

## Key Design Decision: No Climate Covariates

This model intentionally does NOT use climate covariates from `future_data` because forecasted climate data is typically of low quality. Instead, it relies purely on the disease case time series patterns.

## Supported Model Types

Configure via `model_type` in the YAML configuration:

| Model Type | Description | Strengths |
|------------|-------------|-----------|
| `ETS` | Exponential Smoothing | Simple, robust, handles trend/seasonality |
| `ARIMA` | AutoRegressive Integrated Moving Average | Classic time series, good for stationary data |
| `NNETAR` | Neural Network Autoregression | Captures non-linear patterns |
| `THETA` | Theta Method | Simple, often competitive with complex models |
| `SNAIVE` | Seasonal Naive | Baseline using last year's same period |
| `COMBINATION` | Ensemble (ETS + ARIMA + THETA) | Combines multiple models, reduces variance |

## Evaluation Results

Evaluated on 3 datasets (Laos, Thailand, Vietnam) with 3 splits each:

### Overall Rankings (Average Rank Across All Metrics)

| Rank | Model | Avg Rank | Mean CRPS | Mean RMSE |
|------|-------|----------|-----------|-----------|
| 1 | **NNETAR** | 2.0 | 46.39 | 130.66 |
| 2 | SNAIVE | 2.2 | 47.65 | 132.32 |
| 3 | THETA | 3.4 | 47.52 | 132.39 |
| 4 | COMBINATION | 3.8 | 47.16 | 134.80 |
| 5 | ARIMA | 4.6 | 48.06 | 138.12 |
| 6 | ETS | 5.0 | 47.91 | 135.17 |

### Best Model Per Dataset (by CRPS)

- **Laos**: NNETAR (CRPS: 84.29)
- **Thailand**: COMBINATION (CRPS: 16.92)
- **Vietnam**: SNAIVE (CRPS: 37.59)

### Key Findings

1. **NNETAR** (Neural Network) performs best overall, particularly for the challenging Laos dataset with high variance
2. **SNAIVE** (Seasonal Naive baseline) is surprisingly competitive - a strong indication that seasonality is the dominant signal
3. **COMBINATION** ensemble works well on Thailand but doesn't consistently outperform individual models
4. All models perform well on probability calibration (ratio_within_10th_90th > 87%)

## Usage

### Configuration

Create a YAML file with the model type:

```yaml
model_type: NNETAR
```

### Running Evaluations

```bash
cd /path/to/chap-core

# Single evaluation
uv run chap evaluate2 \
    --model-name="/path/to/chap_r_sdk/examples/model_comparison" \
    --dataset-csv="/path/to/data.csv" \
    --output-file="/tmp/output.nc" \
    --backtest-params.n-periods=3 \
    --backtest-params.n-splits=12 \
    --backtest-params.stride=1 \
    --run-config.is-chapkit-model \
    --run-config.ignore-environment \
    --model-configuration-yaml="/path/to/config.yaml"
```

### Exporting Metrics

```bash
uv run chap export-metrics \
    --input-files /tmp/*.nc \
    --output-file /tmp/metrics.csv
```

## Technical Details

### Model Architecture

1. **Training**: Fits the selected model type per location using `fable`
2. **Prediction**: Uses `refit()` to update the model with historic data before forecasting
3. **Ensemble**: COMBINATION uses mean of forecasts from ETS, ARIMA, and THETA
4. **Fallback**: If a model fails for a location, falls back to MEAN model

### Uncertainty Quantification

All models provide probabilistic forecasts via 200 bootstrap samples for the `samples` list-column.

## Files

- `model.R` - Main R model implementation
- `main.py` - Chapkit service entry point
- `pyproject.toml` - Python dependencies
- `model_info.yaml` - Model metadata

## Recommendations

For new deployments:
1. Start with **NNETAR** as the default - best overall performance
2. Consider **SNAIVE** for simpler deployments - competitive accuracy with minimal computational cost
3. Use **COMBINATION** if you want more stable predictions with lower variance
