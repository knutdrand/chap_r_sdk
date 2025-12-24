"""
Model Comparison Service for CHAP

This chapkit service wraps the R model comparison implementation,
enabling systematic evaluation of different forecasting methods:
- ETS: Exponential smoothing
- ARIMA: Auto-selected ARIMA
- NNETAR: Neural network with lagged inputs
- THETA: Theta method
- SNAIVE: Seasonal naive baseline
- COMBINATION: Ensemble average

Configure via model_type parameter to select which model to use.
"""

from pathlib import Path

from chapkit.api import AssessedStatus, MLServiceBuilder, MLServiceInfo, PeriodType
from chapkit.artifact import ArtifactHierarchy
from chapkit.ml import ShellModelRunner, discover_model_info

SCRIPT_DIR = Path(__file__).parent
MODEL_SCRIPT = SCRIPT_DIR / "model.R"

# Discover schema from R model
model_info = discover_model_info(
    "Rscript model.R info --format json",
    model_name="ModelComparisonConfig",
    cwd=SCRIPT_DIR,
)

# Create shell runner for R model
runner = ShellModelRunner(
    train_command=f"Rscript {MODEL_SCRIPT} train --data {{data_file}} --run-info {{run_info_file}}",
    predict_command=f"Rscript {MODEL_SCRIPT} predict --historic {{historic_file}} --future {{future_file}} --output {{output_file}} --run-info {{run_info_file}}",
)

# Standard hierarchy for ML models
HIERARCHY = ArtifactHierarchy(
    name="model_comparison",
    level_labels={0: "ml_training", 1: "ml_prediction"},
)

# Service info with required metadata
info = MLServiceInfo(
    display_name="Fable Model Comparison",
    version="1.0.0",
    summary="Systematic comparison of fable forecasting models",
    description=(
        "Supports multiple fable forecasting methods: ETS (exponential smoothing), "
        "ARIMA, NNETAR (neural network), THETA, SNAIVE (seasonal naive baseline), "
        "and COMBINATION (ensemble average). Configure via model_type parameter. "
        "Does NOT use climate covariates from future_data since forecasted climate "
        "data is typically of low quality."
    ),
    author="CHAP Team",
    author_note="Model comparison framework for systematic evaluation",
    author_assessed_status=AssessedStatus.yellow,
    contact_email="chap@example.com",
    supported_period_type=PeriodType(model_info.period_type),
    required_covariates=model_info.required_covariates,
    allow_free_additional_continuous_covariates=model_info.allows_additional_continuous_covariates,
)

# Build the FastAPI application
app = (
    MLServiceBuilder(
        info=info,
        config_schema=model_info.config_class,
        hierarchy=HIERARCHY,
        runner=runner,
    )
    .with_monitoring()
    .build()
)
