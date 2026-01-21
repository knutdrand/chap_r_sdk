# Create a Model Configuration Schema

Creates a JSON Schema for validating model configuration. The schema
defines what configuration options a model accepts, their types,
constraints, and default values.

## Usage

``` r
create_config_schema(
  title = NULL,
  description = NULL,
  properties = list(),
  required = character(0),
  additional_properties = TRUE
)
```

## Arguments

- title:

  Title for the schema (typically the model name)

- description:

  Description of the configuration

- properties:

  Named list of property definitions created with
  [`schema_integer()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_integer.md),
  [`schema_number()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_number.md),
  [`schema_string()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_string.md),
  [`schema_boolean()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_boolean.md),
  [`schema_enum()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_enum.md),
  or
  [`schema_array()`](https://dhis2-chap.github.io/chap_r_sdk/reference/schema_array.md)

- required:

  Character vector of required property names

- additional_properties:

  Whether to allow properties not defined in schema (default: TRUE for
  flexibility)

## Value

A list representing a complete JSON Schema object

## Examples

``` r
# Define a configuration schema
my_schema <- create_config_schema(
  title = "My Forecasting Model",
  description = "Configuration for disease case forecasting",
  properties = list(
    n_samples = schema_integer(
      description = "Number of Monte Carlo samples for predictions",
      default = 100L,
      minimum = 1L,
      maximum = 10000L
    ),
    learning_rate = schema_number(
      description = "Learning rate for model optimization",
      default = 0.01,
      minimum = 0,
      maximum = 1
    ),
    method = schema_enum(
      values = c("arima", "ets", "prophet"),
      description = "Forecasting method to use",
      default = "arima"
    ),
    use_covariates = schema_boolean(
      description = "Whether to include additional covariates",
      default = TRUE
    )
  ),
  required = c("n_samples")
)

# Use with create_chap_cli
if (FALSE) { # \dontrun{
create_chap_cli(train_fn, predict_fn, model_config_schema = my_schema)
} # }
```
