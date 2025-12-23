# Write default chap.yml configuration

Creates a default chap.yml file with environment configuration.

## Usage

``` r
write_default_chap_yml(r_version = NULL, output_path = "chap.yml")
```

## Arguments

- r_version:

  R version to use (default: read from renv.lock or current)

- output_path:

  Where to write chap.yml (default: "chap.yml")

## Value

Invisible path to created file
