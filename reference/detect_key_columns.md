# Detect key columns (spatial identifiers)

Searches for common spatial identifier column names in the data frame.
Returns NULL if no key columns are found (univariate time series).

## Usage

``` r
detect_key_columns(df)
```

## Arguments

- df:

  Data frame to search

## Value

Character vector of key column names, or NULL if none found
