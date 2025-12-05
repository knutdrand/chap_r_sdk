# Add Summary Statistics to Predictions

Adds common summary statistics (mean, median, confidence intervals) to a
nested predictions tibble.

## Usage

``` r
predictions_summary(nested_df, ci_levels = c(0.5, 0.9, 0.95))
```

## Arguments

- nested_df:

  A tibble with a 'samples' list-column

- ci_levels:

  Confidence interval levels (default: c(0.5, 0.9, 0.95))

## Value

The input tibble with additional columns: mean, median, and lower/upper
bounds for each CI level (e.g., lower_50, upper_50)

## Examples

``` r
if (FALSE) { # \dontrun{
# Add summary statistics
preds_with_summary <- predictions_summary(nested_preds)

# View mean predictions
preds_with_summary$mean
} # }
```
