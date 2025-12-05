# Aggregate Spatial Data

Aggregates spatial data to a coarser resolution or different spatial
unit

## Usage

``` r
aggregate_spatial(data, method = "mean", spatial_units)
```

## Arguments

- data:

  A data frame containing spatial data

- method:

  Aggregation method (e.g., "sum", "mean", "weighted_mean")

- spatial_units:

  The target spatial units for aggregation

## Value

Aggregated spatial data

## Examples

``` r
if (FALSE) { # \dontrun{
aggregated <- aggregate_spatial(data, "mean", target_units)
} # }
```
