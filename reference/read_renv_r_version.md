# Environment configuration for Chap models. Read R version from renv.lock

Parses the renv.lock file and extracts the R version.

## Usage

``` r
read_renv_r_version(lockfile_path = "renv.lock")
```

## Arguments

- lockfile_path:

  Path to renv.lock (default: "renv.lock")

## Value

Character string with R version (e.g., "4.3.2")

## Examples

``` r
if (FALSE) { # \dontrun{
read_renv_r_version()
read_renv_r_version("path/to/renv.lock")
} # }
```
