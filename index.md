# chap.r.sdk

The CHAP R SDK provides tools for building disease forecasting models
compatible with the [CHAP platform](https://github.com/dhis2/chap-core).
It handles CLI creation, data loading, validation, and prediction format
conversion.

## Installation

You can install the development version of chap.r.sdk from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("knutdrand/chap_r_sdk")
```

## Building Your First CHAP Model

This tutorial walks you through building a CHAP-compatible model
step-by-step, using a validation-first approach.

### Setup

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

### Step 1: Understand the Function Interface

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
}
```

### Step 2: Explore the Example Data

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
#> # A tsibble: 1,071 x 13 [1M]
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
#> # ℹ 1,061 more rows
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
#>    [1] 15  7  3  9  7 19  2  2 11  5  5  3  9 24  0 18  4  3  6 62  3  0  4  4
#>   [25] 13  0 44  2  4 19  1  5  3 27  5  0  1  4  7  5  3 11  7 17 16  3 10  1
#>   [49] 12  2  0  4  4  2 20  4  7  3  8 11  5  3 16 22  9  7  3  3  0  2  4 12
#>   [73]  9  6  3  6  4 12  2  0  6  8 16  5 14  3  0 10  5 10  5  1  0  1  0  3
#>   [97]  3  6  4  1  0  3 18 13  6  9  9 19  7  8  1  5 13  3  8 18  1 19  0 23
#>  [121]  4 30  2  2 11  0  0  5  7  0  7 10  4  1  8  4 13  1 21 11  1  9 13  3
#>  [145] 14  4  2 28 17  1  7  7  9 19 12  3  2  4  6  4  3  0  0  9  0  7  6  4
#>  [169]  6  3 17 11  8 15  3  5  3 13 18  4  0 11  2 48  7  5 26  5  5  3  5  2
#>  [193]  4  4 16  9 15  9  6  2  2 10  7  7  3  8 11 17  6  6 10  0  8  6  4 27
#>  [217]  1 37  0  2  0 14  1 29  8  1 16  9  2  9  6  6  7 10  5 28 15  1  7  1
#>  [241]  1 17 12  3  6  8 10 35 22  7  2  0 13  4  1  6 20  3  1  7  1  7 11  4
#>  [265] 37  1 13  2 31  1 47  6  1  0  3  1  0 11  8 12  1  7  4  5  3 16  7 14
#>  [289]  2 15  1  7  1  2 13  2 10  3  2 10  0  1 17  5  1  2  1 17 23  2  8  2
#>  [313]  7  2  2  4  1  3  5  6  0  1 11  4  4  7 22  7 10  7 10 12 31 10  1  2
#>  [337] 16  0 11  2  0  0  6 18  1  2  6  0  3  1  3 23 15  9  0  1 21 14  0  4
#>  [361]  1  2 17  5 25  0 14  3 13  0  0  8  3 14  3  3  2  7  7  2  3  3  2 12
#>  [385]  2  5  8  8 14 12 11  9  1  3 26  5  9 12  3  8 15  0  5  2 10  8  6  3
#>  [409] 15  3  3  3 13 27  0  5 11  4  5  6  3  4  6 28  5 11  4  0  0  0  1  1
#>  [433] 11 29  0  6  1 10  8  5  1  2  0  4  1 13  9  5  6  0 11  1  9 18  7  8
#>  [457]  3  0  2 10  3  5 10  1 16 74  3  2  1 14  1  2  0  0  6  3 12  7  6 10
#>  [481] 10  9  3  6  4 16  0  2  2  1 16  9  6  2  7  3 10 10  1  3  2  6  8  6
#>  [505] 13  2 18  3  2  0 40  1  7  4  5  2 10  2  2 16  4  0 10  7  5 12 15  3
#>  [529] 11 10  2  0  4  1  2 18  0  0 12  4  2  3 10 13  6 17 17  7 19  4  5  2
#>  [553]  7 31  0 14  1  5  8 11 14 40 19  5  0  5  5  9  0 20  0  4  2  1  3 18
#>  [577]  0  1  1 22  0 24  7  0  3 10 21 12 15  7  0  0  2 14  0  4 29 25  5  7
#>  [601]  2  0  5  2  2  3  1  2 10  1 10  4  3  7  1 15  5  6  6 25  2  2  5 52
#>  [625]  1  7  1 23  8  4  3 17  9 10  6  6 10  9  6  0  1  4  0 17  2  7 49  7
#>  [649]  8  8  1 12 45  1  9  1  2  4  0  2 10 10  0  3 22  2  4 16  8  0  3  8
#>  [673]  4 11  8  7  2  7 19  7  5 13  3 11  2  2 23  7  2  8  2 17  4  1  2  4
#>  [697]  0 11  8  0  8  8  3  5  6  7  7  1  1  9  7 13  5 12 10 17  8  2  2  5
#>  [721]  8  0  0  2 15 14  6  4  5 29 13  9  3  3 16  2  2  7  2  1  7  1  0 26
#>  [745]  7  2  4  0  5 11  4 12  8  0 11  1  1  3  2 12  3  3  1 10 12  7  2 15
#>  [769]  4  2  3  1  5  2  1  5  1 11 17  2  2  3  7  5 23  9 14  0 27 35  0  2
#>  [793]  1  0  2  3  1 10  6  5  0 13 16  4 11  1  5  0  1  1  3  3 14  4  5 16
#>  [817]  7  4 10  0  6  1 22 14 12  0  1  5  0  1 40 11  4  8  0  4  9  3  8  1
#>  [841]  5  9  6 13  0  5 22  1  7  2  7  6  3  2  5  3  5  6  6  2  2  5  0  1
#>  [865]  4  4  4 15 60  5  5 14  6 14 12  3 22  7  3  5  7 10  4 35 11 17 17  4
#>  [889] 11  4 12  7 21 30  8  2 21  6 17  9  4 24 11  0  3 28 14  3  3  4  1  9
#>  [913] 30 10 10  7  5  4  2  1 10 13 12  9  3 13  1  1 13  4  8 11  1  8  8  2
#>  [937] 11  5 17  2 12  0  3 13  8  7  2  3  4 17  2  3  4  4  4 16  4  3  8 10
#>  [961]  0  4  2  5  3  1  4  2  3  4  5  3  4 12 14  3  4 15  2  3 23  7 13  5
#>  [985]  4 13 17  0 11 13 15  6 11  1 20 23  2 12 11  2
```

For probabilistic models, each vector contains multiple Monte Carlo
samples (e.g., 1000). For deterministic models, use a single sample per
row: `samples = list(c(42))`.

### Step 3: Validate Before Implementing

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

### Step 4: Implement a Simple Mean Model

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
to collapse across the time dimension.

### Step 5: Validate the Implementation

``` r
result <- validate_model_io(train_fn, predict_fn, data)
result$success
#> [1] TRUE
result$n_predictions
#> [1] 21
```

### Step 6: Create the CLI

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

**Usage:**

``` bash
# Train the model
Rscript model.R train training_data.csv

# Generate predictions
Rscript model.R predict historic.csv future.csv model.rds

# Display model info
Rscript model.R info
```

The CLI automatically handles CSV loading, tsibble conversion, model
saving, and prediction output.

## Probabilistic Models

For probabilistic forecasting, include multiple Monte Carlo samples:

``` r
predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  n_samples <- 1000

  future_data |>
    left_join(saved_model$means, by = "location") |>
    rowwise() |>
    mutate(
      samples = list(rpois(n_samples, lambda = mean_cases))
    ) |>
    ungroup() |>
    select(-mean_cases)
}
```

## Working with Samples

The SDK provides utility functions for sample-based predictions:

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

## Learn More

- [Full documentation](https://knutdrand.github.io/chap_r_sdk/)
- [Model development
  tutorial](https://knutdrand.github.io/chap_r_sdk/articles/model-development-tutorial.html)
- [Function
  reference](https://knutdrand.github.io/chap_r_sdk/reference/index.html)
