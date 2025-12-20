# Define a String Schema Property

Creates a JSON Schema property definition for a string value.

## Usage

``` r
schema_string(
  description = NULL,
  default = NULL,
  min_length = NULL,
  max_length = NULL,
  pattern = NULL
)
```

## Arguments

- description:

  Description of the parameter

- default:

  Default value if not provided

- min_length:

  Minimum string length

- max_length:

  Maximum string length

- pattern:

  Regular expression pattern the string must match

## Value

A list representing a JSON Schema string property

## Examples

``` r
# Simple string
schema_string(description = "Model name", default = "my_model")
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Model name"
#> 
#> $default
#> [1] "my_model"
#> 

# String with pattern constraint
schema_string(
  description = "Date format",
  pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
)
#> $type
#> [1] "string"
#> 
#> $description
#> [1] "Date format"
#> 
#> $pattern
#> [1] "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
#> 
```
