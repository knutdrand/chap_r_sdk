# Detect period type from time values

Determines the temporal resolution of a time column based on its class.

## Usage

``` r
detect_period_type(time_values)
```

## Arguments

- time_values:

  Vector of time values

## Value

Character string: "month", "week", "quarter", "day", or "unknown"
