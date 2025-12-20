# Define an Enum Schema Property

Creates a JSON Schema property definition for a value from a fixed set
of options.

## Usage

``` r
schema_enum(values, description = NULL, default = NULL)
```

## Arguments

- values:

  Character vector of allowed values

- description:

  Description of the parameter

- default:

  Default value if not provided (must be one of `values`)

## Value

A list representing a JSON Schema enum property

## Examples

``` r
schema_enum(
  values = c("arima", "ets", "prophet"),
  description = "Forecasting method",
  default = "arima"
)
#> $type
#> [1] "string"
#> 
#> $enum
#> $enum[[1]]
#> [1] "arima"
#> 
#> $enum[[2]]
#> [1] "ets"
#> 
#> $enum[[3]]
#> [1] "prophet"
#> 
#> 
#> $description
#> [1] "Forecasting method"
#> 
#> $default
#> [1] "arima"
#> 
```
