# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R package (chap_r_sdk) that provides convenience functionality for developing chap-compatible models and integrating existing models with the chap system. The package is tidyverse-oriented and follows R best practices.

## Core Functionality

The SDK provides three main areas of functionality:

1. **CLI Interface Creation**: Convenience functions to create chap-compatible command line interfaces from functions that implement:
   - `train(training_data, model_configuration) -> saved_model`
   - `predict(historic_data, future_data, saved_model, model_configuration)`

2. **Model Validation**: Test suite to sanity check models and ensure prediction output is consistent with chap expectations

3. **Spatio-temporal Data Utilities**: Common transformations for spatio-temporal data

4. **Configuration Schema**: Functionality to expose model configuration schemas to chap

## Development Status

This is an early-stage project with no code implemented yet. When implementing:

- Follow tidyverse conventions and R best practices
- The package should integrate with standard R package development tools (devtools, roxygen2, testthat)
- All functions should be well-documented with roxygen2 comments
- Focus on spatio-temporal data compatibility

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
