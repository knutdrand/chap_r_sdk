# Convert Nested Format to Long Format

Converts predictions from nested list-column format to long format
suitable for use with scoringutils and other analysis tools. Each sample
becomes a separate row.

## Usage

``` r
predictions_to_long(nested_df, value_col = "prediction")
```

## Arguments

- nested_df:

  A tibble with a 'samples' list-column

- value_col:

  Name for the prediction value column (default: "prediction")

## Value

A tibble in long format with columns: time_period, location, sample_id,
and the prediction value column

## Examples

``` r
if (FALSE) { # \dontrun{
# Convert to long format for scoringutils
long_preds <- predictions_to_long(nested_preds)

# Use with scoringutils
scoringutils::score(long_preds, ...)
} # }
```
