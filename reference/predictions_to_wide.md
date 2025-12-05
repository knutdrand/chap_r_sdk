# Convert Nested Format Predictions to Wide Format

Converts predictions from nested list-column format to CHAP wide CSV
format (one column per sample). This is the format expected by the CHAP
platform.

## Usage

``` r
predictions_to_wide(nested_df)
```

## Arguments

- nested_df:

  A tibble with a 'samples' list-column containing numeric vectors of
  samples

## Value

A data frame with columns: time_period, location, sample_0, sample_1,
..., sample_N

## Examples

``` r
if (FALSE) { # \dontrun{
# Convert nested predictions to wide format for CHAP
wide_preds <- predictions_to_wide(nested_preds)
write.csv(wide_preds, "predictions.csv", row.names = FALSE)
} # }
```
