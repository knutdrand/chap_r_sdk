# Define an Integer Schema Property

Creates a JSON Schema property definition for an integer value.

## Usage

``` r
schema_integer(
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

  Description of the parameter (displayed to users)

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

A list representing a JSON Schema integer property

## Examples

``` r
# Simple integer with default
schema_integer(description = "Number of samples", default = 100L)
#> $type
#> [1] "integer"
#> 
#> $description
#> [1] "Number of samples"
#> 
#> $default
#> [1] 100
#> 

# Integer with range constraints
schema_integer(
  description = "Lag periods",
  default = 3L,
  minimum = 1L,
  maximum = 12L
)
#> $type
#> [1] "integer"
#> 
#> $description
#> [1] "Lag periods"
#> 
#> $default
#> [1] 3
#> 
#> $minimum
#> [1] 1
#> 
#> $maximum
#> [1] 12
#> 
```
