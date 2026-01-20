# chap.r.sdk (development version)

## Breaking Changes

* **CLI consolidated to `create_chap_cli()`**: The `create_chapkit_cli()` function has been removed. All CLI functionality is now provided by `create_chap_cli()`, which uses named arguments (`--data`, `--historic`, `--future`, `--output`) powered by the optparse package.

* **CLI argument style changed**: The CLI now uses named arguments instead of positional arguments:
  - Train: `Rscript model.R train --data data.csv` (was: `train data.csv`)
  - Predict: `Rscript model.R predict --historic h.csv --future f.csv --output out.csv` (was: `predict h.csv f.csv model.rds`)

* **optparse dependency added**: The CLI now uses the optparse package for argument parsing, providing better help messages and argument validation.

## Enhancements

* `create_chap_cli()` now supports both short (`-d`) and long (`--data`) option forms
* Improved error messages for missing required arguments
* Better help text via `Rscript model.R train --help`

---

# chap.r.sdk 0.1.0

## Initial CRAN Release

### New Features

* **Unified CLI Infrastructure**: `create_chap_cli()` function provides single-file model development with automatic file I/O handling
  - Automatic CSV loading and tsibble conversion
  - Auto-detection of time and key columns
  - Subcommand dispatch (train/predict/info)

* **Configuration Management**:
  - `read_model_config()` for YAML configuration parsing
  - `write_model_config()` for configuration serialization
  - `get_config_param()` for safe nested parameter extraction
  - Optional schema validation with ajv package

* **Model Examples**:
  - Mean model baseline example demonstrating unified CLI pattern
  - EWARS spatio-temporal model example


### Infrastructure

* Comprehensive test suite (28 tests)
* Complete roxygen2 documentation
* YAML configuration support (yaml package)
* Optional schema validation (ajv package)
* Proper namespacing for all external package dependencies
