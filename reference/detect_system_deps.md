# Detect system dependencies from renv packages

Parses renv.lock and queries package metadata to find required system
libraries (apt packages) using pak.

## Usage

``` r
detect_system_deps(
  lockfile_path = "renv.lock",
  os = "ubuntu",
  os_release = "22.04"
)
```

## Arguments

- lockfile_path:

  Path to renv.lock (default: "renv.lock")

- os:

  Operating system (default: "ubuntu")

- os_release:

  OS release version (default: "22.04")

## Value

Character vector of apt package names

## Examples

``` r
if (FALSE) { # \dontrun{
detect_system_deps()
detect_system_deps(os = "ubuntu", os_release = "24.04")
} # }
```
