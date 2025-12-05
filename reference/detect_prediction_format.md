# Detect Prediction Sample Format

Detects the format of prediction samples in a data frame.

## Usage

``` r
detect_prediction_format(df)
```

## Arguments

- df:

  A data frame to check

## Value

Character string: "nested", "wide", "long", or "none"

## Examples

``` r
if (FALSE) { # \dontrun{
format <- detect_prediction_format(preds)
if (format == "wide") {
  preds <- predictions_from_wide(preds)
}
} # }
```
