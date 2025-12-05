# Check if Predictions Have Samples

Checks whether a predictions data frame contains sample data (either in
nested or wide format).

## Usage

``` r
has_prediction_samples(df)
```

## Arguments

- df:

  A data frame to check

## Value

Logical indicating whether samples are present

## Examples

``` r
if (FALSE) { # \dontrun{
if (has_prediction_samples(preds)) {
  preds <- predictions_to_wide(preds)
}
} # }
```
