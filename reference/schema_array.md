# Define an Array Schema Property

Creates a JSON Schema property definition for an array of values.

## Usage

``` r
schema_array(
  items,
  description = NULL,
  default = NULL,
  min_items = NULL,
  max_items = NULL,
  unique_items = NULL
)
```

## Arguments

- items:

  Schema for array items (e.g., `list(type = "string")`)

- description:

  Description of the parameter

- default:

  Default value if not provided

- min_items:

  Minimum number of items

- max_items:

  Maximum number of items

- unique_items:

  Whether items must be unique

## Value

A list representing a JSON Schema array property

## Examples

``` r
# Array of strings
schema_array(
  items = list(type = "string"),
  description = "List of covariate names",
  default = list("rainfall", "temperature")
)
#> $type
#> [1] "array"
#> 
#> $items
#> $items$type
#> [1] "string"
#> 
#> 
#> $description
#> [1] "List of covariate names"
#> 
#> $default
#> $default[[1]]
#> [1] "rainfall"
#> 
#> $default[[2]]
#> [1] "temperature"
#> 
#> 

# Array of integers with constraints
schema_array(
  items = list(type = "integer"),
  description = "Lag values to use",
  min_items = 1,
  max_items = 10
)
#> $type
#> [1] "array"
#> 
#> $items
#> $items$type
#> [1] "integer"
#> 
#> 
#> $description
#> [1] "Lag values to use"
#> 
#> $minItems
#> [1] 1
#> 
#> $maxItems
#> [1] 10
#> 
```
