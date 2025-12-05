# Get Configuration Parameter

Safely extracts a parameter from configuration with default fallback

## Usage

``` r
get_config_param(config, ..., .default = NULL)
```

## Arguments

- config:

  Configuration list

- ...:

  Path to parameter (passed to purrr::pluck)

- .default:

  Default value if parameter not found

## Value

Parameter value or default

## Examples

``` r
# Simple nested parameter extraction
config <- list(model = list(params = list(lr = 0.01)))
lr <- get_config_param(config, "model", "params", "lr", .default = 0.001)
print(lr)  # 0.01
#> [1] 0.01

# With default fallback
missing <- get_config_param(config, "model", "missing", .default = "default")
print(missing)  # "default"
#> [1] "default"

# Deep nesting
complex_config <- list(
  training = list(
    optimizer = list(
      type = "adam",
      params = list(lr = 0.001, beta1 = 0.9)
    )
  )
)
beta1 <- get_config_param(complex_config, "training", "optimizer", "params", "beta1")
print(beta1)  # 0.9
#> [1] 0.9
```
