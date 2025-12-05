# Package index

## CLI Interface

Create command-line interfaces for CHAP models

- [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)
  : Create Unified CHAP CLI

## Configuration

Model configuration management

- [`read_model_config()`](https://knutdrand.github.io/chap_r_sdk/reference/read_model_config.md)
  : Read Model Configuration
- [`write_model_config()`](https://knutdrand.github.io/chap_r_sdk/reference/write_model_config.md)
  : Write Model Configuration
- [`get_config_param()`](https://knutdrand.github.io/chap_r_sdk/reference/get_config_param.md)
  : Get Configuration Parameter
- [`create_config_schema()`](https://knutdrand.github.io/chap_r_sdk/reference/create_config_schema.md)
  : Expose Model Configuration Schema
- [`validate_config()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_config.md)
  : Validate Model Configuration

## Model Validation

Test and validate CHAP model implementations

- [`run_model_tests()`](https://knutdrand.github.io/chap_r_sdk/reference/run_model_tests.md)
  : Run Model Test Suite
- [`validate_model_io()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_model_io.md)
  : Validate Model Input/Output with Example Data
- [`validate_model_io_all()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_model_io_all.md)
  : Validate Model Input/Output for All Available Datasets
- [`validate_model_output()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_model_output.md)
  : Validate Model Output

## Spatio-Temporal Data

Utilities for working with spatio-temporal data

- [`transform_spatiotemporal()`](https://knutdrand.github.io/chap_r_sdk/reference/transform_spatiotemporal.md)
  : Transform Spatio-Temporal Data
- [`aggregate_spatial()`](https://knutdrand.github.io/chap_r_sdk/reference/aggregate_spatial.md)
  : Aggregate Spatial Data
- [`aggregate_temporal()`](https://knutdrand.github.io/chap_r_sdk/reference/aggregate_temporal.md)
  : Aggregate Temporal Data

## Prediction Samples

Convert between prediction sample formats

- [`predictions_from_wide()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_from_wide.md)
  : Convert Wide Format Predictions to Nested Format
- [`predictions_to_wide()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_to_wide.md)
  : Convert Nested Format Predictions to Wide Format
- [`predictions_from_long()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_from_long.md)
  : Convert Long Format to Nested Format
- [`predictions_to_long()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_to_long.md)
  : Convert Nested Format to Long Format
- [`predictions_to_quantiles()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_to_quantiles.md)
  : Compute Quantiles from Prediction Samples
- [`predictions_summary()`](https://knutdrand.github.io/chap_r_sdk/reference/predictions_summary.md)
  : Add Summary Statistics to Predictions
- [`has_prediction_samples()`](https://knutdrand.github.io/chap_r_sdk/reference/has_prediction_samples.md)
  : Check if Predictions Have Samples
- [`detect_prediction_format()`](https://knutdrand.github.io/chap_r_sdk/reference/detect_prediction_format.md)
  : Detect Prediction Sample Format

## Example Models

Reference model implementations

- [`train_mean_model()`](https://knutdrand.github.io/chap_r_sdk/reference/train_mean_model.md)
  : Train a simple mean model
- [`predict_mean_model()`](https://knutdrand.github.io/chap_r_sdk/reference/predict_mean_model.md)
  : Predict using mean model

## Utilities

Helper functions

- [`get_example_data()`](https://knutdrand.github.io/chap_r_sdk/reference/get_example_data.md)
  : Get Example Data for Testing
