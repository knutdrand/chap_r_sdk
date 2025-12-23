# Get environment information for info command

Returns environment information for inclusion in the info –format json
output. Called by build_info_json() in cli.R.

## Usage

``` r
get_environment_info(lockfile_path = "renv.lock")
```

## Arguments

- lockfile_path:

  Path to renv.lock (default: "renv.lock")

## Value

List with environment information
