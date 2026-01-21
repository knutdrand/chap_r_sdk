
<!-- README.md is generated from README.Rmd. Please edit that file -->

# chap.r.sdk

<!-- badges: start -->

[![R-CMD-check](https://github.com/knutdrand/chap_r_sdk/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/knutdrand/chap_r_sdk/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The CHAP R SDK provides tools for building disease forecasting models
compatible with the [CHAP platform](https://github.com/dhis2/chap-core).

## Documentation

**[Read the full
documentation](https://knutdrand.github.io/chap_r_sdk/)**

- [Getting
  Started](https://knutdrand.github.io/chap_r_sdk/articles/getting-started.html) -
  Installation and quick start guide
- [Building Your First
  Model](https://knutdrand.github.io/chap_r_sdk/articles/model-development-tutorial.html) -
  Step-by-step tutorial
- [Function
  Reference](https://knutdrand.github.io/chap_r_sdk/reference/index.html) -
  API documentation

## What is this?

The CHAP (Climate and Health Analytics Platform) enables health
ministries to run disease forecasting models. This R SDK helps model
developers create models that integrate seamlessly with CHAP.

### Who is this for?

- **Epidemiologists and researchers** who want to deploy their R models
  on CHAP
- **Model developers** who need a standardized interface for
  train/predict workflows
- **Teams** who want to share models with collaborators via CHAP

### Key Features

- **Zero boilerplate CLI**: One function creates a complete command-line
  interface
- **Automatic data handling**: CSV loading, tsibble conversion, output
  formatting
- **Configuration schemas**: YAML/JSON config with validation and
  defaults
- **Model validation**: Test suite to verify CHAP compatibility before
  deployment

## Quick Example

A complete CHAP-compatible model in one file:

``` r
library(chap.r.sdk)
library(dplyr)

train_fn <- function(training_data, model_configuration = list(), run_info = list()) {
  means <- training_data |>
    as_tibble() |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
  list(means = means)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list(), run_info = list()) {
  future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)
}

if (!interactive()) {
  create_chap_cli(train_fn, predict_fn)
}
```

Then run from the command line:

``` bash
Rscript model.R train --data training_data.csv
Rscript model.R predict --historic historic.csv --future future.csv --output predictions.csv
Rscript model.R info
```

## Installation

Install from GitHub by running the following R-code:

``` r
# install.packages("remotes")
remotes::install_github("knutdrand/chap_r_sdk")
```

### For Model Examples

Each example in `examples/` has its own renv environment which keeps
track of the packages and the versions used:

``` bash
cd examples/fable_model
Rscript -e 'renv::restore()'
```

## Getting Help

- **Documentation**:
  [knutdrand.github.io/chap_r_sdk](https://knutdrand.github.io/chap_r_sdk/)
- **Issues**: [GitHub
  Issues](https://github.com/knutdrand/chap_r_sdk/issues)
- **CHAP Platform**:
  [github.com/dhis2/chap-core](https://github.com/dhis2/chap-core)
