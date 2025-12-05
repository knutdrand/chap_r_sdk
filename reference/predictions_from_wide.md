# Convert Wide Format Predictions to Nested Format

Converts predictions from CHAP wide CSV format (one column per sample)
to nested list-column format (one row per forecast unit with samples
stored as a numeric vector in a list-column).

## Usage

``` r
predictions_from_wide(wide_df)
```

## Arguments

- wide_df:

  A data frame with columns: time_period, location, and sample columns
  (sample_0, sample_1, ..., sample_N)

## Value

A tibble with columns: time_period, location, samples (list-column
containing numeric vectors of samples)

## Examples

``` r
if (FALSE) { # \dontrun{
# Load wide format predictions
wide_preds <- read.csv("predictions.csv")
nested_preds <- predictions_from_wide(wide_preds)

# Access samples for first forecast unit
nested_preds$samples[[1]]
} # }
```
