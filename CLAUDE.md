# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R package (chap_r_sdk) that provides convenience functionality for developing chap-compatible models and integrating existing models with the chap system. The package is tidyverse-oriented and follows R best practices.

## Core Functionality

The SDK provides three main areas of functionality:

1. **CLI Interface Creation**: Unified CLI infrastructure with automatic file I/O handling:
   - **NEW**: `create_chap_cli(train_fn, predict_fn, schema)` - Single unified CLI with subcommand dispatch
   - **Deprecated**: `create_train_cli()` and `create_predict_cli()` - Legacy separate CLI wrappers
   - Automatically handles CSV loading, tsibble conversion, YAML config parsing, and output saving
   - Model functions receive loaded data objects, not file paths

2. **Model Validation**: Test suite to sanity check models and ensure prediction output is consistent with chap expectations

3. **Spatio-temporal Data Utilities**: Common transformations for spatio-temporal data

4. **Configuration Schema**: Functionality to expose model configuration schemas to chap

## Development Status

This is an early-stage project with skeleton code structure. When implementing:

- Follow tidyverse conventions and R best practices
- The package should integrate with standard R package development tools (devtools, roxygen2, testthat)
- All functions should be well-documented with roxygen2 comments
- Focus on spatio-temporal data compatibility

## Examples

### Mean Model Example (Recommended Pattern)

The **recommended pattern** for new models is shown in `examples/mean_model/model.R`. This uses the unified CLI interface:

```r
library(chap.r.sdk)
library(dplyr)

# Pure business logic - no file I/O!
train_my_model <- function(training_data, model_configuration = list()) {
  # training_data is already a tsibble
  means <- training_data |>
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))

  return(list(means = means))
}

predict_my_model <- function(historic_data, future_data, saved_model,
                              model_configuration = list()) {
  # All inputs are already loaded
  predictions <- future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(disease_cases = mean_cases)

  return(predictions)
}

config_schema <- list(
  title = "My Model Configuration",
  type = "object",
  properties = list()
)

# One line enables full CLI with train/predict/info subcommands!
if (!interactive()) {
  create_chap_cli(train_my_model, predict_my_model, config_schema)
}
```

**Usage:**
```bash
Rscript model.R train data.csv [config.yaml]
Rscript model.R predict historic.csv future.csv model.rds [config.yaml]
Rscript model.R info
```

**Key Benefits:**
- **41% less code** compared to legacy pattern
- **Zero file I/O boilerplate** - handled automatically
- **Single file** - train and predict together
- **Automatic detection** of time and key columns
- **Subcommand dispatch** built-in

See `examples/mean_model/README.md` for detailed documentation.

### EWARS Model Example (Legacy Pattern)

A complex working example using the **legacy pattern** is available in `examples/ewars_model/`. This demonstrates:

- Using deprecated `create_train_cli()` and `create_predict_cli()` wrappers
- YAML configuration parsing with `read_model_config()`
- Safe parameter extraction with `get_config_param()`
- Models that combine training and prediction in a single step
- Handling spatio-temporal data with covariates

See `examples/ewars_model/README.md` for detailed documentation and `examples/ewars_model/MIGRATION_TO_CHAP_SDK.md` for migration guide from legacy code.

**Note:** For new models, use the unified `create_chap_cli()` pattern shown in the Mean Model Example instead.

## Standard R Package Commands

Once the package structure is established, typical commands will be:

```r
# Development workflow
devtools::load_all()        # Load package for interactive development
devtools::document()        # Generate documentation from roxygen2 comments
devtools::test()            # Run test suite
devtools::check()           # Run R CMD check

# Testing
testthat::test_file("tests/testthat/test-file.R")  # Run single test file
devtools::test_active_file()                        # Test currently open file
```

## Best Practices and Pre-Push Checklist

**IMPORTANT**: Before committing or pushing code, ALWAYS verify the following:

### Code Organization
- New functions are placed in the appropriate R source file:
  - CLI functions → `R/cli.R`
  - Validation functions → `R/validation.R`
  - Configuration functions → `R/config.R`
  - Spatio-temporal functions → `R/spatial_temporal.R`
- Each function has complete roxygen2 documentation with `@param`, `@return`, `@export`, and `@examples`
- Related test files exist in `tests/testthat/test-*.R` matching the source file name

### Documentation
- All exported functions have roxygen2 documentation blocks
- Documentation includes meaningful examples (even if wrapped in `\dontrun{}`)
- After adding/modifying functions, run `devtools::document()` to update NAMESPACE and man files

### Testing
- Every new function has corresponding tests in `tests/testthat/`
- Tests follow the naming pattern: `test_that("function_name does expected behavior", { ... })`
- Run `devtools::test()` to ensure all tests pass
- Tests should be meaningful, not just placeholder `skip()` calls

### Package Validation
- Run `devtools::check()` before pushing to catch:
  - Missing documentation
  - NAMESPACE issues
  - Undefined global variables
  - Code quality issues
- Address all ERRORS and WARNINGS (NOTEs are acceptable but should be reviewed)

### Code Quality
- Follow tidyverse style guide conventions
- Use meaningful variable and function names
- Avoid code duplication - extract common logic into helper functions
- Functions should have clear, single responsibilities

### Dependencies
- Only add new dependencies to DESCRIPTION if truly necessary
- Use `Imports:` for packages required for the package to work
- Use `Suggests:` for packages only needed for tests, vignettes, or optional features

### Version Control
- Commit messages should be clear and descriptive
- Group related changes together in single commits
- Don't commit generated files (man/*.Rd files are auto-generated but should be committed)
