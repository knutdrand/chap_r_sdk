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
