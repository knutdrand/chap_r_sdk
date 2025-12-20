# Define a Boolean Schema Property

Creates a JSON Schema property definition for a boolean value.

## Usage

``` r
schema_boolean(description = NULL, default = NULL)
```

## Arguments

- description:

  Description of the parameter

- default:

  Default value if not provided

## Value

A list representing a JSON Schema boolean property

## Examples

``` r
schema_boolean(description = "Use cross-validation", default = TRUE)
#> $type
#> [1] "boolean"
#> 
#> $description
#> [1] "Use cross-validation"
#> 
#> $default
#> [1] TRUE
#> 
```
