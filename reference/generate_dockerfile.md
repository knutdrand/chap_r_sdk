# Generate Dockerfile for Chap model

Creates a Dockerfile that builds a container with R, renv packages,
Python, and chapkit. The generated image can run the complete service.

## Usage

``` r
generate_dockerfile(
  chapkit_version = NULL,
  python_version = "3.12",
  output_path = "Dockerfile",
  lockfile_path = "renv.lock",
  os = "ubuntu",
  os_release = "22.04"
)
```

## Arguments

- chapkit_version:

  Version of chapkit to install (default: latest)

- python_version:

  Python version to install (default: "3.12")

- output_path:

  Where to write Dockerfile (default: "Dockerfile")

- lockfile_path:

  Path to renv.lock (default: "renv.lock")

- os:

  Operating system for system deps (default: "ubuntu")

- os_release:

  OS release for system deps (default: "22.04")

## Value

Invisible path to created Dockerfile

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate with defaults
generate_dockerfile()

# Generate with specific versions
generate_dockerfile(chapkit_version = "0.1.0", python_version = "3.11")
} # }
```
