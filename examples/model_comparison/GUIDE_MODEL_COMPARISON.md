# Guide: Running Model Comparisons with Chap

This guide walks through how to systematically compare different forecasting models using the Chap evaluation framework. It's written for R model developers and highlights common difficulties you may encounter.

## Overview

The model comparison workflow is:

1. Create a configurable R model that supports multiple model types
2. Set up the chapkit integration (main.py)
3. Create configuration files for each model variant
4. Run evaluations using `chap evaluate2`
5. Export and analyze metrics

## Prerequisites

- **chap-core** installed and accessible via `uv run chap`
- Your R model working with `chapr`
- Dataset(s) in Chap CSV format

## Step 1: Create a Configurable Model

Your `model.R` should accept a configuration parameter to switch between model types:

```r
library(chapr)
library(fable)
library(dplyr)

train_model <- function(training_data, model_configuration = list()) {

  # Get model type from configuration (default to ETS)
  model_type <- model_configuration$model_type %||% "ETS"

  # Fit different models based on configuration
  models <- training_data |>
    group_by(location) |>
    group_map(~ fit_model(.x, model_type), .keep = TRUE)

  return(list(models = models, model_type = model_type))
}

fit_model <- function(data, model_type) {
  switch(model_type,
    "ETS" = data |> model(m = ETS(disease_cases)),
    "ARIMA" = data |> model(m = ARIMA(disease_cases)),
    "NNETAR" = data |> model(m = NNETAR(disease_cases)),
    # ... other model types
  )
}
```

### Difficulty: Configuration Not Reaching R

**Problem**: Your `model_configuration` parameter is empty or NULL.

**Cause**: The configuration YAML isn't being passed correctly through the chapkit layer.

**Solution**: Check that:
1. Your `main.py` includes the configuration in the schema
2. The YAML file path is correct in the evaluate2 command
3. The YAML keys match what your R code expects

```yaml
# config_ETS.yaml
model_type: ETS
```

## Step 2: Set Up Chapkit Integration

Create `main.py` with required metadata:

```python
from chapkit import MLServiceBuilder, ShellModelRunner, discover_model_info
from chapkit.api.spec import MLServiceInfo, PeriodType, AssessedStatus

model_info = discover_model_info("model_info.yaml")

info = MLServiceInfo(
    display_name="My Model Comparison",
    version="1.0.0",
    summary="Comparison of forecasting models",
    description="Detailed description here...",  # REQUIRED!
    author="Your Name",                           # REQUIRED!
    author_assessed_status=AssessedStatus.yellow, # REQUIRED!
    # ... other fields
)

runner = ShellModelRunner(
    train_command="Rscript model.R train {training_data} {model}",
    predict_command="Rscript model.R predict {historic_data} {future_data} {model} {predictions}",
)

app = MLServiceBuilder().set_runner(runner).set_service_info(info).build()
```

### Difficulty: Missing Metadata Errors

**Problem**: Evaluation fails with validation errors like:
```
3 validation errors for ModelTemplateConfigV2
meta_data.description: Field required
meta_data.author: Field required
meta_data.author_assessed_status: Field required
```

**Solution**: Add ALL required fields to `MLServiceInfo`:
- `description` (not just `summary`)
- `author`
- `author_assessed_status` (use `AssessedStatus.yellow`, `.green`, or `.red`)

## Step 3: Create Configuration Files

Create a YAML file for each model variant you want to test:

```bash
# Create config files
echo "model_type: ETS" > config_ETS.yaml
echo "model_type: ARIMA" > config_ARIMA.yaml
echo "model_type: NNETAR" > config_NNETAR.yaml
```

## Step 4: Run Evaluations

### Basic Command Structure

```bash
cd /path/to/chap-core

uv run chap evaluate2 \
    --model-name="/path/to/your/model" \
    --dataset-csv="/path/to/data.csv" \
    --output-file="/tmp/output.nc" \
    --backtest-params.n-periods=3 \
    --backtest-params.n-splits=12 \
    --backtest-params.stride=1 \
    --run-config.is-chapkit-model \
    --run-config.ignore-environment \
    --model-configuration-yaml="/path/to/config.yaml"
```

### Difficulty: CLI Argument Parsing Errors

**Problem**: Errors like:
```
Cannot specify token '' positionally for parameter 'run-config.debug'
```

**Cause**: The `chap evaluate2` command uses cyclopts which has specific parsing rules. Mixing positional and named arguments can cause issues.

**Solutions**:

1. **Use ALL named arguments** (recommended):
```bash
uv run chap evaluate2 \
    --model-name="/path/to/model" \
    --dataset-csv="/path/to/data.csv" \
    --output-file="/tmp/output.nc" \
    # ... all other args with --
```

2. **Run via bash subprocess** (workaround):
```bash
/bin/bash -c 'uv run chap evaluate2 --model-name=... --dataset-csv=...'
```

3. **Check help for exact syntax**:
```bash
uv run chap evaluate2 --help
```

### Difficulty: Port Already in Use

**Problem**: Error message:
```
OSError: [Errno 48] Address already in use
```

**Cause**: Previous evaluation runs left orphan processes listening on ports 8001-8003.

**Solution**: Kill orphan processes before running:
```bash
pkill -9 -f "evaluate2"
pkill -9 -f "fastapi"
# Or find specific processes:
lsof -i :8001 | grep LISTEN
```

### Difficulty: Evaluations Hang or Get Stuck

**Problem**: Evaluation seems to run forever, especially with many splits.

**Causes**:
1. R model taking too long per location
2. Too many splits requested
3. Memory issues with large datasets

**Solutions**:

1. **Start with fewer splits** to test:
```bash
--backtest-params.n-splits=3  # Start small
```

2. **Run sequentially** rather than in parallel - create a bash script:
```bash
#!/bin/bash
set -e  # Exit on first error

for model_type in ETS ARIMA NNETAR; do
    echo "Running $model_type..."
    uv run chap evaluate2 \
        --model-name="$MODEL_DIR" \
        --dataset-csv="$DATA_FILE" \
        --output-file="/tmp/${model_type}.nc" \
        --model-configuration-yaml="/tmp/config_${model_type}.yaml" \
        # ... other args
done
```

3. **Add timeout handling** in your R code for problematic locations

### Difficulty: Model Fails for Some Locations

**Problem**: Evaluation crashes partway through with R errors.

**Cause**: Some locations have insufficient data or patterns that break certain models (e.g., ARIMA needs enough observations, NNETAR needs enough data for neural network).

**Solution**: Add fallback logic in your R model:
```r
fit_model <- function(data, model_type) {
  tryCatch({
    switch(model_type,
      "ARIMA" = data |> model(m = ARIMA(disease_cases)),
      # ...
    )
  }, error = function(e) {
    warning(paste("Model failed, falling back to MEAN:", e$message))
    data |> model(m = MEAN(disease_cases))
  })
}
```

## Step 5: Export and Analyze Metrics

### Export Metrics to CSV

```bash
uv run chap export-metrics \
    --input-files /tmp/laos_ETS.nc \
    --input-files /tmp/laos_ARIMA.nc \
    --input-files /tmp/laos_NNETAR.nc \
    --output-file /tmp/all_metrics.csv
```

### Analyze with Python

```python
import pandas as pd

df = pd.read_csv('/tmp/all_metrics.csv')

# Extract model type from filename
df['model_type'] = df['filename'].apply(
    lambda x: x.split('_')[1].replace('.nc', '')
)

# Rank models by CRPS (lower is better)
df_sorted = df.sort_values('crps')
print(df_sorted[['model_type', 'crps', 'rmse_aggregate', 'mae_aggregate']])
```

### Key Metrics to Compare

| Metric | Description | Better |
|--------|-------------|--------|
| `crps` | Continuous Ranked Probability Score | Lower |
| `rmse_aggregate` | Root Mean Square Error | Lower |
| `mae_aggregate` | Mean Absolute Error | Lower |
| `ratio_within_10th_90th` | Calibration (80% interval) | Higher |
| `ratio_within_25th_75th` | Calibration (50% interval) | Higher |

## Complete Workflow Script

Here's a complete script for running model comparisons:

```bash
#!/bin/bash
set -e

# Configuration
MODEL_DIR="/path/to/your/model"
DATA_DIR="/path/to/datasets"
OUTPUT_DIR="/tmp/model_comparison"
Chap_CORE="/path/to/chap-core"

MODEL_TYPES="ETS ARIMA NNETAR"
DATASETS="laos thailand vietnam"

N_SPLITS=3
N_PERIODS=3

# Create output directory
mkdir -p $OUTPUT_DIR

# Create config files
for model_type in $MODEL_TYPES; do
    echo "model_type: $model_type" > "${OUTPUT_DIR}/config_${model_type}.yaml"
done

# Kill any orphan processes
pkill -9 -f "evaluate2" 2>/dev/null || true
pkill -9 -f "fastapi" 2>/dev/null || true

cd $Chap_CORE

# Run evaluations
for dataset in $DATASETS; do
    for model_type in $MODEL_TYPES; do
        output_file="${OUTPUT_DIR}/${dataset}_${model_type}.nc"
        config_file="${OUTPUT_DIR}/config_${model_type}.yaml"

        # Skip if already exists
        if [ -f "$output_file" ]; then
            echo "Skipping ${dataset}/${model_type} - already exists"
            continue
        fi

        echo "Running: ${dataset} / ${model_type}"

        uv run chap evaluate2 \
            --model-name="${MODEL_DIR}" \
            --dataset-csv="${DATA_DIR}/${dataset}.csv" \
            --output-file="${output_file}" \
            --backtest-params.n-periods=${N_PERIODS} \
            --backtest-params.n-splits=${N_SPLITS} \
            --backtest-params.stride=1 \
            --run-config.is-chapkit-model \
            --run-config.ignore-environment \
            --run-config.no-debug \
            --model-configuration-yaml="${config_file}"

        if [ -f "$output_file" ]; then
            echo "SUCCESS: ${dataset}/${model_type}"
        else
            echo "FAILED: ${dataset}/${model_type}"
        fi
    done
done

echo "Exporting metrics..."
# Build input-files arguments
INPUT_ARGS=""
for f in ${OUTPUT_DIR}/*.nc; do
    INPUT_ARGS="$INPUT_ARGS --input-files $f"
done

uv run chap export-metrics \
    $INPUT_ARGS \
    --output-file "${OUTPUT_DIR}/all_metrics.csv"

echo "Done! Results in ${OUTPUT_DIR}/all_metrics.csv"
```

## Summary of Common Difficulties

| Difficulty | Symptom | Solution |
|------------|---------|----------|
| Missing metadata | Validation errors on start | Add description, author, author_assessed_status |
| CLI parsing | "Cannot specify token" errors | Use all named arguments or bash wrapper |
| Port conflicts | "Address already in use" | Kill orphan processes with pkill |
| Hanging evals | Never completes | Reduce n_splits, run sequentially |
| Model failures | R errors mid-evaluation | Add tryCatch fallback logic |
| Empty config | model_configuration is NULL | Check YAML path and key names |

## Tips for R Developers

1. **Test your model locally first** before running evaluations:
   ```bash
   Rscript model.R train test_data.csv model.rds config.yaml
   Rscript model.R predict historic.csv future.csv model.rds predictions.csv config.yaml
   ```

2. **Use logging** to debug issues:
   ```r
   message(paste("Model type:", model_configuration$model_type))
   message(paste("Training data rows:", nrow(training_data)))
   ```

3. **Start small**: Test with 1 dataset, 1 model type, 3 splits before scaling up

4. **Check output files**: If evaluation "succeeds" but no .nc file, check stderr for R errors

5. **Memory management**: For large datasets, consider processing locations in batches
