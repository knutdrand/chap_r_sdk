# Building Your First CHAP Model

This tutorial walks you through building a CHAP-compatible model
step-by-step, using a validation-first approach to ensure your model
works correctly before deploying it.

## Setup

``` r
library(chap.r.sdk)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## Step 1: Understand the Function Interface

Every CHAP model requires two functions:

**Training function:**

``` r
train_fn <- function(training_data, model_configuration = list()) {
  # training_data: tsibble with time_period index, location key,
  #                disease_cases, and covariates
  # model_configuration: optional list of parameters
  # Returns: any model object (list, fitted model, etc.)
}
```

**Prediction function:**

``` r
predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  # historic_data: tsibble with historical observations
  # future_data: tsibble with time periods to predict
  # saved_model: the object returned by train_fn
  # Returns: tibble with samples list-column containing numeric vectors
  #   - For deterministic models: single sample per row (e.g., samples = list(c(42)))
  #   - For probabilistic models: multiple samples per row (e.g., 1000 samples)
  #
  # IMPORTANT: historic_data may contain more recent data than training_data.
  # For time series models, you should refit to historic_data before forecasting.
  # Use saved_model for hyperparameters/structure, not the fitted model itself.
  # See examples/arima_model/ for a demonstration of this pattern.
}
```

## Step 2: Explore the Example Data

The SDK provides example datasets for testing. Let’s examine the Laos
monthly data:

``` r
data <- get_example_data('laos', 'M')
#> New names:
#> Registered S3 method overwritten by 'tsibble': method from as_tibble.grouped_df
#> dplyr
#> New names:
#> New names:
#> • `` -> `...1`
names(data)
#> [1] "training_data" "historic_data" "future_data"   "predictions"
```

The example data contains four tsibbles. Each has `time_period` as the
index and `location` as the key:

**Training data** - what your model learns from:

``` r
data$training_data
#> # A tsibble: 1,057 x 13 [1M]
#> # Key:       location [7]
#>     ...1 time_period rainfall mean_temperature disease_cases population parent
#>    <dbl>       <mth>    <dbl>            <dbl>         <dbl>      <dbl> <chr> 
#>  1     0    2000 Jul   430.               23.4             0     58503. -     
#>  2     1    2000 Aug   322.               23.8             0     58503. -     
#>  3     2    2000 Sep   265.               22.7             0     58503. -     
#>  4     3    2000 Oct   103.               22.6             0     58503. -     
#>  5     4    2000 Nov    19.7              20.3             0     58503. -     
#>  6     5    2000 Dec    26.0              19.1             0     58503. -     
#>  7     6    2001 Jan    17.6              19.8             0     60157. -     
#>  8     7    2001 Feb     7.28             22.0             0     60157. -     
#>  9     8    2001 Mar   123.               22.6             0     60157. -     
#> 10     9    2001 Apr    29.6              27.5             0     60157. -     
#> # ℹ 1,047 more rows
#> # ℹ 6 more variables: location <chr>, Cases <dbl>, E <dbl>, month <dbl>,
#> #   ID_year <dbl>, ID_spat <chr>
```

**Future data** - time periods to predict (no `disease_cases`):

``` r
data$future_data
#> # A tsibble: 21 x 11 [1M]
#> # Key:       location [7]
#>     ...1 time_period rainfall mean_temperature population parent location      E
#>    <dbl>       <mth>    <dbl>            <dbl>      <dbl> <chr>  <chr>     <dbl>
#>  1     0    2013 Apr     39.5             26.8     80014. -      Bokeo    8.00e4
#>  2     1    2013 May    170.              25.8     80014. -      Bokeo    8.00e4
#>  3     2    2013 Jun    231.              24.7     80014. -      Bokeo    8.00e4
#>  4     0    2013 Apr    152.              27.2    731598. -      Champas… 7.32e5
#>  5     1    2013 May    236.              26.3    731598. -      Champas… 7.32e5
#>  6     2    2013 Jun    327.              25.1    731598. -      Champas… 7.32e5
#>  7     0    2013 Apr     58.8             25.1    124396. -      LouangN… 1.24e5
#>  8     1    2013 May    162.              24.7    124396. -      LouangN… 1.24e5
#>  9     2    2013 Jun    184.              24.0    124396. -      LouangN… 1.24e5
#> 10     0    2013 Apr     72.5             25.0    282683. -      Oudomxai 2.83e5
#> # ℹ 11 more rows
#> # ℹ 3 more variables: month <dbl>, ID_year <dbl>, ID_spat <chr>
```

**Example predictions** - what your model should output:

``` r
data$predictions
#> # A tibble: 21 × 3
#>    time_period location     samples      
#>    <chr>       <chr>        <list>       
#>  1 2013-04     Bokeo        <dbl [1,000]>
#>  2 2013-05     Bokeo        <dbl [1,000]>
#>  3 2013-06     Bokeo        <dbl [1,000]>
#>  4 2013-04     Champasak    <dbl [1,000]>
#>  5 2013-05     Champasak    <dbl [1,000]>
#>  6 2013-06     Champasak    <dbl [1,000]>
#>  7 2013-04     LouangNamtha <dbl [1,000]>
#>  8 2013-05     LouangNamtha <dbl [1,000]>
#>  9 2013-06     LouangNamtha <dbl [1,000]>
#> 10 2013-04     Oudomxai     <dbl [1,000]>
#> # ℹ 11 more rows
```

The predictions tibble has a `samples` list-column where each element is
a numeric vector. Let’s look at the structure:

``` r
# Each row has a vector of samples
data$predictions$samples[[1]]
#>    [1]  9  5 46  5  3  8  1  9  9 14  3  7  6  7  3 10 11  2 17 13 12  0  3  1
#>   [25] 10 38 19  7 15  0  1 11  1  8  7 43 11  3  4  8  1  4  3  7 24  4  1  6
#>   [49] 11  3  9  0  0 16  0 11 17  1  3  8 13  5  5 22  2  1  5 26 11 31  4  3
#>   [73] 10  7  4  6  9 13  1  5 14 13 14  8  4  1  0  7 31  6  6  2 16 12  2  9
#>   [97]  1  5  7  3  6  4 22  1  3 10  1  0  3  7 10  3  0  8 30  8  7  1 17 14
#>  [121] 10  8  4  8  2  5 20  3 11  7  6 11  2  0  4  3  4  5  3  8  4 21  5  7
#>  [145] 15  8 17  8  9 12  6  1 11  3 21  4 10  2  3  4 17  2  1 11 33  6 10  2
#>  [169] 25 12  3  0  3  1  5 16 22  0  2 24 15 13  3  1  4  0  6  2  8  1  2  1
#>  [193] 21 17  0  6  8  9  8  2  0  3 21  3 14  5  4  6  5 18 14 17  4  2 10  9
#>  [217]  7  2  3  2  3  3  1  4  3  5  3  8  1 15  4  5 11 16  8 26  0  6  3 10
#>  [241]  4 10  2  3  0  8  3 18  2  8  2  1  4  2  6  5 10 13 10  8  9  3  1  1
#>  [265]  6  7  7  9 13  8  1  7 28 23  6  7 12  8  1  4  1  6  1  2  0  6  2 16
#>  [289] 44  2 20 24 14  9  2  4 12  7  6 23 39 16 17  5 27 17  2  4  7  3  1  0
#>  [313]  6  1 10  3  6 19  2  3  6 13 14  5  8  1 14  6 15  5  4  3 30  7  9  4
#>  [337] 17  3  4  4  1  6 11 15  4 11 15  1  3  8  4 15 15  0  7 13 14 26  6  1
#>  [361]  5 15  1 21 13  6 22  6  1 19  7  0 11 13 10  1  0  2  1  7 13  1  1  9
#>  [385] 12 24  7  2  8  9  2  0  5  0  2  2  2  7 15 10 15 10  7  1 26  2 20 11
#>  [409] 41 15 13  4  7  1  8  3  4 16 27  0  1  2  3 22 20  8  3  9  7  9  3 44
#>  [433]  0 17  5  1  8 17 18  8 27 16  4  7  1  4  1 13 22  0  7  2 12 18 49  9
#>  [457]  1  1  2 16  2  5  2 12  3  8  3  5  1  1  0 28 22  1  4  6 11  5 13 24
#>  [481]  4  2 13  1  5  1  5 12  6  5  6  5 14  9  2 15  2 27 25  9  5  5  3  6
#>  [505]  3 25  9 16  2 14  6  5 25 11  4 10  2 11  5  6 16  3  2  6  3  4  5 18
#>  [529]  9  2  8  6  3 11  7 16 22  4  0  3  3 19 10  3  2  5  3 10  4 18  1  6
#>  [553]  5 19  3  1  8  2  6  5 12 15 11  1  0  0 22  6  7  2 40 21 20  2  9  9
#>  [577] 11  0  0  2  6 12  6  5 19  8 17  7  3 39  0  6 11  8  9  8 10  6  5  2
#>  [601]  3 11  3 18  0  3  5  5  1  5  2  1 37 15  7  1  0  3  1 17  1 19  3 20
#>  [625] 12 11  8  2  3  2  2  0  9  1 17 14  4 10 10 13  5 12  8  0  5  9 41  9
#>  [649] 38  8 13  6 15  7  8  4 17  1  3  9  1 33  9  5 21 27  3 22 10 16  6 21
#>  [673]  0 12 22  1  8 22  1  1 62 13 17 13 15  6 37  2 19  5  3  6  3  1  1 15
#>  [697] 31  7  3  7 15  6  1  4  5  3  6  9 17  0  5  5  1  9  5  2  0 26  1  4
#>  [721]  0  1 14  8 10  4  2  7  3  4 17  3  2 93  6  7 11  1  5 16  7 11  5 15
#>  [745]  7 15  6  4  3 38  0  3 17  4  1  0 13  5  2 10  7  2  1  8  8  6  3  0
#>  [769]  2  1  9  0  7 13  5  4  2 11  5  4  6  3  9 18  2  7  2 16  3  2  5 26
#>  [793]  3  5 18  4 25  5 12  8  2 14 15  1  5 19 14 21  0  3 26  3  2 17 39 14
#>  [817] 21 21  3 10 19 12  3  1  6  0  3 24 59  2 15 12  3  9  7 16  3 16  6  6
#>  [841]  0 15  8 12 17  6  3 12  2  2 15 10 11  1  1  1 16  2  7  0 11 39  6  2
#>  [865]  5  6 13  4 11  2  4  4  9 38  1  8 16 15 21 15  7 16  2  3 10 33  9  7
#>  [889]  4  2  6 12  9  1 16  4  5  7  3  3  4  1  3  5  9  5  9 14 23  3 21  2
#>  [913]  4  6  6 26  5 11  0  7  5  4  9  2 26  5  5 10 16 17 30  2  8 10  5 25
#>  [937]  1  1 47  7  2  4  2  0  7  0 20  1 19  2  6  5 15  5 14  5  7  7  4  2
#>  [961]  0  9  3  3 15  0  2  0  5 14  1 44 16  0 14  2  1 15  4 29 10 21  6  6
#>  [985]  0  6 24  7 16  0 12  5  2  6  5 31  9 14  0  3
```

For probabilistic models, each vector contains multiple Monte Carlo
samples (e.g., 1000). For deterministic models, use a single sample per
row: `samples = list(c(42))`.

## Step 3: Validate Before Implementing

Before writing any model logic, let’s see what the validation expects.
Start with stub functions:

``` r
train_fn <- function(training_data, model_configuration = list()) {
  list(dummy = 1)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data
}

result <- validate_model_io(train_fn, predict_fn, data)
result$success
#> [1] FALSE
result$errors
#> [1] "Predictions must have a 'samples' list-column containing numeric vectors"
```

The validation tells us exactly what’s missing: the `samples`
list-column in predictions.

## Step 4: Implement a Simple Mean Model

Now let’s implement a minimal model that predicts the historical mean
for each location. Since all models must return a `samples` list-column,
we wrap the single prediction value in a list:

``` r
train_fn <- function(training_data, model_configuration = list()) {
  means <- training_data |>
    as_tibble() |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
  list(means = means)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)
}
```

Note: We use
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
in the training function because `summarise(.by = ...)` needs a tibble
to collapse across the time dimension. The prediction function works
directly on tsibbles since
[`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
and [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
preserve tsibble structure.

## Step 5: Validate the Implementation

``` r
result <- validate_model_io(train_fn, predict_fn, data)
result$success
#> [1] TRUE
result$n_predictions
#> [1] 21
```

The validation passes and we generated 21 predictions.

## Step 6: Validate Against All Datasets

The SDK can validate against all available example datasets:

``` r
result <- validate_model_io_all(train_fn, predict_fn)
#> New names:
#> New names:
#> New names:
#> • `` -> `...1`
result$success
#> [1] TRUE
names(result$results)
#> [1] "laos_M"
```

## Step 7: Create the CLI

Once validation passes, wrap your model in a CLI. Create a file called
`model.R`:

``` r
library(chap.r.sdk)
library(dplyr)

train_fn <- function(training_data, model_configuration = list()) {
  means <- training_data |>
    as_tibble() |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE), .by = location)
  list(means = means)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data |>
    left_join(saved_model$means, by = "location") |>
    mutate(samples = purrr::map(mean_cases, ~c(.x))) |>
    select(-mean_cases)
}

if (!interactive()) {
  create_chap_cli(train_fn, predict_fn)
}
```

## Step 8: Use the CLI

Your model is now ready for command-line use:

``` bash
# Train the model
Rscript model.R train training_data.csv

# Generate predictions
Rscript model.R predict historic.csv future.csv model.rds

# Display model info
Rscript model.R info
```

The CLI automatically handles:

- Loading CSV files
- Converting to tsibbles
- Saving the model as RDS
- Writing predictions to CSV (converting nested samples to wide format)

## Probabilistic Models

For probabilistic forecasting, include multiple Monte Carlo samples
instead of a single value:

``` r
predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  n_samples <- 1000

  future_data |>
    left_join(saved_model$means, by = "location") |>
    rowwise() |>
    mutate(
      # Generate 1000 samples from Poisson distribution
      samples = list(rpois(n_samples, lambda = mean_cases))
    ) |>
    ungroup() |>
    select(-mean_cases)
}
```

The `samples` column is a list-column where each element is a numeric
vector. The CLI automatically converts this to wide CSV format
(`sample_0`, `sample_1`, …) for CHAP.

## Working with Samples

The SDK provides utility functions for working with sample-based
predictions:

``` r
# Convert nested samples to wide format
wide_preds <- predictions_to_wide(nested_preds)

# Convert to long format for scoringutils
long_preds <- predictions_to_long(nested_preds)

# Compute quantiles for hub submissions
quantile_preds <- predictions_to_quantiles(nested_preds)

# Add summary statistics (mean, median, CIs)
preds_with_summary <- predictions_summary(nested_preds)
```

## Summary

The development workflow is:

1.  **Explore** example data with
    [`get_example_data()`](https://knutdrand.github.io/chap_r_sdk/reference/get_example_data.md)
2.  **Validate** with stubs using
    [`validate_model_io()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_model_io.md)
    to understand requirements
3.  **Implement** your train and predict functions
4.  **Validate** the implementation
5.  **Test** against all datasets with
    [`validate_model_io_all()`](https://knutdrand.github.io/chap_r_sdk/reference/validate_model_io_all.md)
6.  **Deploy** with
    [`create_chap_cli()`](https://knutdrand.github.io/chap_r_sdk/reference/create_chap_cli.md)

## Next Steps

- See `examples/ewars_model/` for a more complex example with
  configuration
- Read about configuration schemas in
  [`?create_config_schema`](https://knutdrand.github.io/chap_r_sdk/reference/create_config_schema.md)
- Explore spatial-temporal utilities in
  [`?aggregate_temporal`](https://knutdrand.github.io/chap_r_sdk/reference/aggregate_temporal.md)
