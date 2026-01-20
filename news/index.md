# Changelog

## chap.r.sdk (development version)

### Breaking Changes

- **CLI consolidated to
  [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)**:
  The `create_chapkit_cli()` function has been removed. All CLI
  functionality is now provided by
  [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md),
  which uses named arguments (`--data`, `--historic`, `--future`,
  `--output`) powered by the optparse package.

- **CLI argument style changed**: The CLI now uses named arguments
  instead of positional arguments:

  - Train: `Rscript model.R train --data data.csv` (was:
    `train data.csv`)
  - Predict:
    `Rscript model.R predict --historic h.csv --future f.csv --output out.csv`
    (was: `predict h.csv f.csv model.rds`)

- **optparse dependency added**: The CLI now uses the optparse package
  for argument parsing, providing better help messages and argument
  validation.

### Enhancements

- [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)
  now supports both short (`-d`) and long (`--data`) option forms
- Improved error messages for missing required arguments
- Better help text via `Rscript model.R train --help`

------------------------------------------------------------------------

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
