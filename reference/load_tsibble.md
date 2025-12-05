# Load CSV and convert to tsibble

Automatically loads a CSV file and converts it to a tsibble by detecting
the time index column and spatial key columns.

## Usage

``` r
load_tsibble(file_path)
```

## Arguments

- file_path:

  Path to CSV file to load

## Value

A tsibble object with auto-detected index and key columns
