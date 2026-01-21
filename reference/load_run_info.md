# Load run_info from file or build default

Loads run_info from a YAML/JSON file if provided, otherwise builds a
default run_info from the data. This is used when Chap doesn't provide
run_info (e.g., during local testing).

## Usage

``` r
load_run_info(run_info_path, training_data = NULL, future_data = NULL)
```

## Arguments

- run_info_path:

  Path to run_info YAML/JSON file, or NULL

- training_data:

  Optional tsibble with training data (for building default)

- future_data:

  Optional tsibble with future data (for building default)

## Value

A list containing run_info fields
