"""Chapkit service entry point for the fable ETS model.

This demonstrates R model integration with chapkit using chap.r.sdk.
The model uses Exponential Smoothing (ETS) from the fable package for
time series forecasting of disease cases.
"""

from pathlib import Path

from chapkit.api import AssessedStatus, MLServiceBuilder, MLServiceInfo, PeriodType
from chapkit.artifact import ArtifactHierarchy
from chapkit.ml import ShellModelRunner, discover_model_info

# Get the directory where this script lives (for finding model.R)
SCRIPT_DIR = Path(__file__).parent

# ============================================================================
# Schema Discovery from R Model
# ============================================================================
# Discover configuration schema from R model's `info --format json` command

model_info = discover_model_info(
    "Rscript model.R info --format json",
    model_name="FableETSConfig",
    cwd=SCRIPT_DIR,
)

print(f"Discovered config schema: {model_info.config_class.model_json_schema()}")


# ============================================================================
# Shell Model Runner
# ============================================================================
# Uses chap.r.sdk's create_chap_cli() interface with named arguments

MODEL_SCRIPT = SCRIPT_DIR / "model.R"

train_command = (
    f"Rscript {MODEL_SCRIPT} train "
    "--data {data_file} "
    "--run-info {run_info_file}"
)

predict_command = (
    f"Rscript {MODEL_SCRIPT} predict "
    "--historic {historic_file} "
    "--future {future_file} "
    "--output {output_file} "
    "--run-info {run_info_file}"
)

runner = ShellModelRunner(
    train_command=train_command,
    predict_command=predict_command,
)


# ============================================================================
# Service Configuration
# ============================================================================

info = MLServiceInfo(
    display_name="Fable ETS Model",
    version="1.0.0",
    summary="ETS-based time series forecasting model implemented in R",
    description=(
        "Exponential Smoothing (ETS) model for disease prediction using the "
        "fable package. ETS models can capture trend and seasonality patterns "
        "in time series data. Configuration schema is automatically discovered "
        "from the R model."
    ),
    author="CHAP Team",
    author_note="Fable ETS model with automatic schema discovery",
    author_assessed_status=AssessedStatus.yellow,
    contact_email="chap@example.com",
    supported_period_type=PeriodType(model_info.period_type),
    required_covariates=model_info.required_covariates,
    allow_free_additional_continuous_covariates=model_info.allows_additional_continuous_covariates,
)

# Create artifact hierarchy for ML artifacts
HIERARCHY = ArtifactHierarchy(
    name="fable_ml_pipeline",
    level_labels={0: "ml_training", 1: "ml_prediction"},
)

# Build the FastAPI application using the discovered config schema
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


if __name__ == "__main__":
    from chapkit.api import run_app

    run_app("main:app", reload=False)
