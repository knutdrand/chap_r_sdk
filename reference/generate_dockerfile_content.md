# Generate Dockerfile content

Internal function to generate the Dockerfile content string.

## Usage

``` r
generate_dockerfile_content(
  base_image,
  system_deps,
  python_version,
  chapkit_spec
)
```

## Arguments

- base_image:

  Base Docker image

- system_deps:

  Character vector of apt packages

- python_version:

  Python version

- chapkit_spec:

  Chapkit pip specification

## Value

Character string with Dockerfile content
