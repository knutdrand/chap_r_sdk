"""Chapkit service entry point for the mean model."""

from pathlib import Path

from servicekit.artifact import ArtifactHierarchy

from chapkit.api import MLServiceBuilder, MLServiceInfo
from chapkit.config.schemas import BaseConfig
from chapkit.ml.runner import ShellModelRunner
from chapkit.ml.schema_discovery import discover_model_info


# Discover model info from R script
model_info = discover_model_info("Rscript model.R info --format json")


class MeanModelConfig(BaseConfig):
    """Configuration for the mean model."""

    smoothing: float = 0.0


# Use discovered config class if available
ConfigClass = model_info.config_class if model_info else MeanModelConfig


# Create the model runner
runner = ShellModelRunner(
    train_command="Rscript model.R train --data {data_file} --run-info {run_info_file}",
    predict_command=(
        "Rscript model.R predict "
        "--historic {historic_file} "
        "--future {future_file} "
        "--output {output_file} "
        "--run-info {run_info_file}"
    ),
)


# Build the service
app = (
    MLServiceBuilder(
        info=MLServiceInfo(
            display_name="Mean Model",
            description="Simple mean baseline model for disease prediction",
        )
    )
    .with_config(ConfigClass)
    .with_artifacts(
        hierarchy=ArtifactHierarchy(
            name="ml",
            level_labels={0: "ml_training", 1: "ml_prediction"},
        )
    )
    .with_jobs()
    .with_ml(runner)
    .build()
)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
