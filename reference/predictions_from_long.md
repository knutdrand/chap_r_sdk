# Convert Long Format to Nested Format

Converts predictions from long format (one row per sample) to nested
list-column format. This is useful for importing data from scoringutils
or other tools that use long format.

## Usage

``` r
predictions_from_long(
  long_df,
  value_col = "prediction",
  sample_col = "sample_id",
  group_cols = c("time_period", "location")
)
```

## Arguments

- long_df:

  A data frame in long format with sample_id and prediction columns

- value_col:

  Name of the prediction value column (default: "prediction")

- sample_col:

  Name of the sample ID column (default: "sample_id")

- group_cols:

  Columns that define forecast units (default: c("time_period",
  "location"))

## Value

A tibble with nested samples list-column

## Examples

``` r
if (FALSE) { # \dontrun{
# Import long format data
nested_preds <- predictions_from_long(long_df)
} # }
```
