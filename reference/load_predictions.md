# Load predictions from CSV

Loads a predictions CSV file and optionally converts from wide sample
format to nested list-column format for easier manipulation.

## Usage

``` r
load_predictions(file_path, convert_samples = TRUE)
```

## Arguments

- file_path:

  Path to predictions CSV file

- convert_samples:

  Whether to convert wide sample columns to nested format (default:
  TRUE)

## Value

A tibble with predictions. If convert_samples is TRUE and sample columns
are detected, returns nested format with a 'samples' list-column.
