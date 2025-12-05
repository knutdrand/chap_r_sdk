# Save predictions to CSV

Saves prediction results to a CSV file with a status message.
Predictions must have a samples list-column which is automatically
converted to wide format (sample_0, sample_1, ...) for CHAP
compatibility.

## Usage

``` r
save_predictions(predictions, output_path)
```

## Arguments

- predictions:

  Predictions tibble with samples list-column

- output_path:

  Path for output CSV file

## Value

Path to the saved predictions file
