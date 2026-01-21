# Build default run_info object from data

Constructs a default run_info list by inferring values from the loaded
data. This is used as a fallback when Chap doesn't provide a run_info
file (e.g., during local development or testing).

## Usage

``` r
build_run_info(training_data = NULL, future_data = NULL)
```

## Arguments

- training_data:

  Optional tsibble with training data

- future_data:

  Optional tsibble with future data

## Value

A list containing:

- `prediction_length`: Number of unique time periods in future_data (NA
  for train)

- `additional_continuous_covariates`: Character vector of numeric column
  names beyond the standard columns (time index, key columns,
  disease_cases)

- `future_covariate_origin`: Always NULL for default run_info

## Details

In production, Chap provides run_info directly via a file. This function
is primarily used for:

- Local testing without Chap

- Model validation via
  [`validate_model_io()`](https://dhis2-chap.github.io/chap_r_sdk/reference/validate_model_io.md)

- Backwards compatibility
