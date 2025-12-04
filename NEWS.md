# chap.r.sdk 0.1.0

## Initial CRAN Release

### New Features

* **Unified CLI Infrastructure**: `create_chap_cli()` function provides single-file model development with automatic file I/O handling
  - Automatic CSV loading and tsibble conversion
  - Auto-detection of time and key columns
  - Subcommand dispatch (train/predict/info)
  - 41% code reduction compared to legacy pattern

* **Configuration Management**:
  - `read_model_config()` for YAML configuration parsing
  - `write_model_config()` for configuration serialization
  - `get_config_param()` for safe nested parameter extraction
  - Optional schema validation with ajv package

* **Model Examples**:
  - Mean model baseline example demonstrating unified CLI pattern
  - EWARS spatio-temporal model example

### Deprecated

* `create_train_cli()` - Use `create_chap_cli()` instead
* `create_predict_cli()` - Use `create_chap_cli()` instead

### Infrastructure

* Comprehensive test suite (28 tests)
* Complete roxygen2 documentation
* YAML configuration support (yaml package)
* Optional schema validation (ajv package)
* Proper namespacing for all external package dependencies
