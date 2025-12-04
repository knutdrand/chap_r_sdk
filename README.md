# Chap R SDK

This package provides convenience functionality for developing CHAP models and integrating existing models with CHAP.

## Features

- **CLI Interface Generator**: Create CHAP-compatible command line interfaces from functions fulfilling the CHAP interface
  - `train(training_data, model_configuration) -> saved_model`
  - `predict(historic_data, future_data, saved_model, model_configuration)`
- **Test Suite**: Sanity check models to ensure prediction output is consistent with CHAP expectations
- **Configuration Management**: Expose model configuration schemas to CHAP
- **Data Transformations**: Common functionality for extracting and transforming spatio-temporal data

The package is tidyverse-oriented and follows best practices in R development.

## Installation

### Development Version (from GitHub)

You can install the development version of chap.r.sdk from GitHub:

```r
# Using remotes (recommended)
install.packages("remotes")
remotes::install_github("knutdrand/chap_r_sdk")

# Or using devtools
install.packages("devtools")
devtools::install_github("knutdrand/chap_r_sdk")
```

### CRAN Version (Coming Soon)

Once published on CRAN, you'll be able to install with:

```r
install.packages("chap.r.sdk")
```

## Quick Start

### Example: Mean Model

The SDK includes a simple mean model as a reference implementation. This model predicts the mean disease cases for each location based on historical data.

#### Using the R Functions

```r
library(chapr)
library(tsibble)
library(dplyr)

# Load and prepare training data
training_data <- read.csv("inst/testdata/ewars_example/monthly/training_data.csv") |>
  mutate(time_period = yearmonth(time_period)) |>
  as_tsibble(index = time_period, key = location)

# Train the model
model <- train_mean_model(training_data, model_config = list())

# Load future data for prediction
future_data <- read.csv("inst/testdata/ewars_example/monthly/future_data.csv") |>
  mutate(time_period = yearmonth(time_period)) |>
  as_tsibble(index = time_period, key = location)

# Generate predictions
predictions <- predict_mean_model(
  historic_data = NULL,  # Not used by mean model
  future_data = future_data,
  model = model,
  model_config = list()
)
```

#### Using the CLI

The SDK provides command-line scripts for training and prediction:

```bash
# Train a model
Rscript inst/scripts/train_cli.R \
  --data inst/testdata/ewars_example/monthly/training_data.csv \
  --config inst/testdata/ewars_example/monthly/config.yaml \
  --output model.rds

# Generate predictions
Rscript inst/scripts/predict_cli.R \
  --model model.rds \
  --historic inst/testdata/ewars_example/monthly/historic_data.csv \
  --future inst/testdata/ewars_example/monthly/future_data.csv \
  --output predictions.csv
```

See `examples/test_mean_model.sh` for a complete working example.

## Data Format

### Training Data

Training data should be provided as a tsibble with the following columns:

- `time_period`: Temporal index (yearmonth for monthly data, yearweek for weekly)
- `location`: Spatial key (location name)
- `disease_cases`: Target variable (number of disease cases)
- Additional covariates (e.g., `rainfall`, `mean_temperature`, `population`)

Example:
```csv
time_period,location,disease_cases,rainfall,mean_temperature,population
2000-07,Bokeo,0.0,430.119,23.44,58502.77
2000-08,Bokeo,0.0,321.913,23.82,58502.77
```

### Future Data

Future data should have the same structure but without the `disease_cases` column:

```csv
time_period,location,rainfall,mean_temperature,population
2013-04,Bokeo,39.474,26.8,80013.60
2013-05,Bokeo,170.046,25.85,80013.60
```

### Prediction Output

Predictions are returned as a tsibble with the same structure as training data, including the predicted `disease_cases` column.

## Model Interface

All CHAP models should implement two functions:

### Train Function

```r
train_model <- function(training_data, model_config) {
  # training_data: tsibble with historical disease cases and covariates
  # model_config: list with model configuration options

  # Train your model here

  # Return model object
  return(model)
}
```

### Predict Function

```r
predict_model <- function(historic_data, future_data, model, model_config) {
  # historic_data: tsibble with recent historical data
  # future_data: tsibble with future time periods and covariates
  # model: trained model object
  # model_config: list with model configuration options

  # Generate predictions

  # Return tsibble with predictions
  return(predictions)
}
```

## Configuration Files

Model configurations can be provided as YAML or JSON files:

```yaml
# config.yaml
additional_continuous_covariates: []
user_option_values:
  chap__covid_mask: true
```

## Architecture Decisions

See the `docs/decisions/` directory for Architecture Decision Records (ADRs) documenting key technical decisions:

- [ADR 001: CLI Interface Approach](docs/decisions/001-cli-interface-approach.md) - Why we use `optparse` for command-line interfaces

## Development

### Project Structure

```
chap_r_sdk/
├── R/                      # R package code
│   ├── mean_model.R        # Example mean model implementation
│   ├── cli.R              # CLI helper functions
│   ├── config.R           # Configuration management
│   ├── validation.R       # Model validation utilities
│   └── spatial_temporal.R # Data transformation utilities
├── inst/
│   ├── scripts/           # CLI scripts
│   │   ├── train_cli.R    # Training CLI
│   │   └── predict_cli.R  # Prediction CLI
│   └── testdata/          # Test datasets
├── tests/                 # Unit tests
├── examples/              # Example scripts
├── docs/
│   └── decisions/         # Architecture Decision Records
└── README.md
```

### Running Tests

```r
devtools::test()
```

### Building Documentation

```r
devtools::document()
pkgdown::build_site()
```

## Related Jira Epic

This project is tracked in Jira: [CLIM-201 - CHAP R SDK Development](https://dhis2.atlassian.net/browse/CLIM-201)

## Contributing

Contributions are welcome! Please follow R package development best practices and tidyverse style guidelines.

## License

See LICENSE file for details.
