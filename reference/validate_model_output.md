# Validate Model Output

Performs sanity checks on model prediction output to ensure it is
consistent with chap expectations

## Usage

``` r
validate_model_output(predictions, expected_schema)
```

## Arguments

- predictions:

  The prediction output to validate

- expected_schema:

  The expected schema for predictions

## Value

A list with validation results (pass/fail and any error messages)

## Examples

``` r
if (FALSE) { # \dontrun{
validate_model_output(predictions, schema)
} # }
```
