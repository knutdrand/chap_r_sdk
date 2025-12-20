# Extract –run-info argument from command line args

Separates the –run-info argument from positional arguments.

## Usage

``` r
extract_run_info_arg(args)
```

## Arguments

- args:

  Character vector of command line arguments

## Value

A list with:

- `positional`: Character vector of positional arguments

- `run_info_path`: Path to run_info file, or NULL if not provided
