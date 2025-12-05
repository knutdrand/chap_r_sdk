# Convert time column to appropriate temporal type

Converts a time column from character to the appropriate tsibble
temporal type. Supports yearmonth (YYYY-MM), yearweek (YYYY-Www),
yearquarter (YYYY-Qq), and Date formats.

## Usage

``` r
convert_time_column(df, time_col)
```

## Arguments

- df:

  Data frame containing the time column

- time_col:

  Name of the time column to convert

## Value

Data frame with converted time column
