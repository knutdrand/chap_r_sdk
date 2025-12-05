# Run Model Test Suite

Runs a comprehensive test suite to sanity check a chap model

## Usage

``` r
run_model_tests(train_fn, predict_fn, test_data)
```

## Arguments

- train_fn:

  The training function to test

- predict_fn:

  The prediction function to test

- test_data:

  Test dataset for validation

## Value

A test results object with pass/fail status and details

## Examples

``` r
if (FALSE) { # \dontrun{
run_model_tests(my_train, my_predict, test_data)
} # }
```
