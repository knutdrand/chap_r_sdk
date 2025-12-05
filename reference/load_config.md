# Load and parse configuration file

Loads a YAML configuration file if it exists and is valid. Returns an
empty list if the path is NULL, empty, or the file doesn't exist.

## Usage

``` r
load_config(config_path)
```

## Arguments

- config_path:

  Path to YAML configuration file (can be NULL or empty string)

## Value

Parsed configuration as a list, or empty list if no config
