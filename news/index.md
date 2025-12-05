# Changelog

## chap.r.sdk 0.1.0

### Initial CRAN Release

#### New Features

- **Unified CLI Infrastructure**:
  [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)
  function provides single-file model development with automatic file
  I/O handling
  - Automatic CSV loading and tsibble conversion
  - Auto-detection of time and key columns
  - Subcommand dispatch (train/predict/info)
- **Configuration Management**:
  - [`read_model_config()`](https://knutdrand.github.io/chap_r_sdk/reference/read_model_config.md)
    for YAML configuration parsing
  - [`write_model_config()`](https://knutdrand.github.io/chap_r_sdk/reference/write_model_config.md)
    for configuration serialization
  - [`get_config_param()`](https://knutdrand.github.io/chap_r_sdk/reference/get_config_param.md)
    for safe nested parameter extraction
  - Optional schema validation with ajv package
- **Model Examples**:
  - Mean model baseline example demonstrating unified CLI pattern
  - EWARS spatio-temporal model example

#### Infrastructure

- Comprehensive test suite (28 tests)
- Complete roxygen2 documentation
- YAML configuration support (yaml package)
- Optional schema validation (ajv package)
- Proper namespacing for all external package dependencies
