# Define a Number Schema Property

Creates a JSON Schema property definition for a numeric (float) value.

## Usage

``` r
schema_number(
  description = NULL,
  default = NULL,
  minimum = NULL,
  maximum = NULL,
  exclusive_minimum = NULL,
  exclusive_maximum = NULL
)
```

## Arguments

- description:

  Description of the parameter

- default:

  Default value if not provided

- minimum:

  Minimum allowed value (inclusive)

- maximum:

  Maximum allowed value (inclusive)

- exclusive_minimum:

  Minimum value (exclusive)

- exclusive_maximum:

  Maximum value (exclusive)

## Value

A list representing a JSON Schema number property

## Examples

``` r
# Learning rate with constraints
schema_number(
  description = "Learning rate",
  default = 0.01,
  minimum = 0,
  maximum = 1
)
#> $type
#> [1] "number"
#> 
#> $description
#> [1] "Learning rate"
#> 
#> $default
#> [1] 0.01
#> 
#> $minimum
#> [1] 0
#> 
#> $maximum
#> [1] 1
#> 
```
