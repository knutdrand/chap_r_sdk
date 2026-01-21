# Package index

## CLI Interface

Create command-line interfaces for CHAP models

- [`create_chap_cli()`](https://dhis2-chap.github.io/chap_r_sdk/reference/create_chap_cli.md)
  : Create CHAP CLI
- [`build_run_info()`](https://dhis2-chap.github.io/chap_r_sdk/reference/build_run_info.md)
  : Build default run_info object from data

## Configuration

Model configuration management

- [`read_model_config()`](https://dhis2-chap.github.io/chap_r_sdk/reference/read_model_config.md)
  : Read Model Configuration
- [`write_model_config()`](https://dhis2-chap.github.io/chap_r_sdk/reference/write_model_config.md)
  : Write Model Configuration
- [`get_config_param()`](https://dhis2-chap.github.io/chap_r_sdk/reference/get_config_param.md)
  : Get Configuration Parameter
- [`create_config_schema()`](https://dhis2-chap.github.io/chap_r_sdk/reference/create_config_schema.md)
  : Create a Model Configuration Schema
- [`validate_config()`](https://dhis2-chap.github.io/chap_r_sdk/reference/validate_config.md)
  : Validate Model Configuration Against Schema
- [`apply_config_defaults()`](https://dhis2-chap.github.io/chap_r_sdk/reference/apply_config_defaults.md)
  : Apply Default Values from Schema to Configuration
- [`get_schema_defaults()`](https://dhis2-chap.github.io/chap_r_sdk/reference/get_schema_defaults.md)
  : Extract Default Values from Schema

## Configuration Schema Builders

Helper functions to build JSON Schema configuration schemas

- [`schema_string()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_string.md)
  : Define a String Schema Property
- [`schema_number()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_number.md)
  : Define a Number Schema Property
- [`schema_integer()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_integer.md)
  : Define an Integer Schema Property
- [`schema_boolean()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_boolean.md)
  : Define a Boolean Schema Property
- [`schema_array()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_array.md)
  : Define an Array Schema Property
- [`schema_enum()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_enum.md)
  : Define an Enum Schema Property
- [`schema_to_json()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_to_json.md)
  : Convert Schema to JSON
- [`print(`*`<chap_config_schema>`*`)`](https://dhis2-chap.github.io/chap_r_sdk/reference/print.chap_config_schema.md)
  : Print Schema Summary

## Model Validation

Test and validate CHAP model implementations

- [`run_model_tests()`](https://dhis2-chap.github.io/chap_r_sdk/reference/run_model_tests.md)
  : Run Model Test Suite
- [`validate_model_io()`](https://dhis2-chap.github.io/chap_r_sdk/reference/validate_model_io.md)
  : Validate Model Input/Output with Example Data
- [`validate_model_io_all()`](https://dhis2-chap.github.io/chap_r_sdk/reference/validate_model_io_all.md)
  : Validate Model Input/Output for All Available Datasets
- [`validate_model_output()`](https://dhis2-chap.github.io/chap_r_sdk/reference/validate_model_output.md)
  : Validate Model Output

## Spatio-Temporal Data

Utilities for working with spatio-temporal data

- [`transform_spatiotemporal()`](https://dhis2-chap.github.io/chap_r_sdk/reference/transform_spatiotemporal.md)
  : Transform Spatio-Temporal Data
- [`aggregate_spatial()`](https://dhis2-chap.github.io/chap_r_sdk/reference/aggregate_spatial.md)
  : Aggregate Spatial Data
- [`aggregate_temporal()`](https://dhis2-chap.github.io/chap_r_sdk/reference/aggregate_temporal.md)
  : Aggregate Temporal Data

## Prediction Samples

Convert between prediction sample formats

- [`predictions_from_wide()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_from_wide.md)
  : Convert Wide Format Predictions to Nested Format
- [`predictions_to_wide()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_to_wide.md)
  : Convert Nested Format Predictions to Wide Format
- [`predictions_from_long()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_from_long.md)
  : Convert Long Format to Nested Format
- [`predictions_to_long()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_to_long.md)
  : Convert Nested Format to Long Format
- [`predictions_to_quantiles()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_to_quantiles.md)
  : Compute Quantiles from Prediction Samples
- [`predictions_summary()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predictions_summary.md)
  : Add Summary Statistics to Predictions
- [`has_prediction_samples()`](https://dhis2-chap.github.io/chap_r_sdk/reference/has_prediction_samples.md)
  : Check if Predictions Have Samples
- [`detect_prediction_format()`](https://dhis2-chap.github.io/chap_r_sdk/reference/detect_prediction_format.md)
  : Detect Prediction Sample Format

## Example Models

Reference model implementations

- [`train_mean_model()`](https://dhis2-chap.github.io/chap_r_sdk/reference/train_mean_model.md)
  : Train a simple mean model
- [`predict_mean_model()`](https://dhis2-chap.github.io/chap_r_sdk/reference/predict_mean_model.md)
  : Predict using mean model

## Environment

Docker and renv environment configuration for containerized models

- [`init_chap_env()`](https://dhis2-chap.github.io/chap_r_sdk/reference/init_chap_env.md)
  : Initialize CHAP model environment
- [`generate_dockerfile()`](https://dhis2-chap.github.io/chap_r_sdk/reference/generate_dockerfile.md)
  : Generate Dockerfile for CHAP model
- [`generate_mlproject()`](https://dhis2-chap.github.io/chap_r_sdk/reference/generate_mlproject.md)
  : Generate MLproject file for chap-core compatibility
- [`detect_system_deps()`](https://dhis2-chap.github.io/chap_r_sdk/reference/detect_system_deps.md)
  : Detect system dependencies from renv packages
- [`read_renv_r_version()`](https://dhis2-chap.github.io/chap_r_sdk/reference/read_renv_r_version.md)
  : Environment configuration for CHAP models. Read R version from
  renv.lock

## Utilities

Helper functions

- [`get_example_data()`](https://dhis2-chap.github.io/chap_r_sdk/reference/get_example_data.md)
  : Get Example Data for Testing
