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
  # Returns: data frame/tsibble with disease_cases column
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

Your predictions must include a `disease_cases` column with the
forecasted values.

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
#> [1] "Predictions missing required column: disease_cases"
```

The validation tells us exactly what’s missing: the `disease_cases`
column in predictions.

## Step 4: Implement a Simple Mean Model

Now let’s implement a minimal model that predicts the historical mean
for each location:

``` r
train_fn <- function(training_data, model_configuration = list()) {
  means <- training_data |>
    as_tibble() |>
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
  list(means = means)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data |>
    as_tibble() |>
    left_join(saved_model$means, by = "location") |>
    mutate(disease_cases = mean_cases) |>
    select(-mean_cases)
}
```

That’s it! Just 12 lines of actual model logic. We convert to tibble
before grouping to avoid tsibble key conflicts.

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
    group_by(location) |>
    summarise(mean_cases = mean(disease_cases, na.rm = TRUE))
  list(means = means)
}

predict_fn <- function(historic_data, future_data, saved_model,
                       model_configuration = list()) {
  future_data |>
    as_tibble() |>
    left_join(saved_model$means, by = "location") |>
    mutate(disease_cases = mean_cases) |>
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
- Writing predictions to CSV

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
