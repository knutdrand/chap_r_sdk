# Initialize CHAP model environment

Sets up renv for reproducible R dependencies and creates chap.yml. Run
this once when creating a new model project.

## Usage

``` r
init_chap_env(r_version = NULL, include_chap_sdk = TRUE)
```

## Arguments

- r_version:

  R version to record (default: current R version)

- include_chap_sdk:

  Whether to include chap.r.sdk in dependencies (default: TRUE)

## Value

Invisible NULL

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize new project
init_chap_env()

# Initialize with specific R version
init_chap_env(r_version = "4.3.2")
} # }
```
