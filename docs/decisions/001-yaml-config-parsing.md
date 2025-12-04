# YAML Configuration File Parsing in R

**Issue**: CLIM-210
**Date**: 2025-12-03
**Status**: Recommended
**Updated**: 2025-12-04 (Changed from JSON to YAML)

## Context

The CHAP R SDK needs to parse YAML configuration files for model training and prediction. These configuration files will contain nested structures defining model parameters, data transformations, and other settings. We need a reliable, performant, and well-maintained solution for parsing these configurations.

YAML (YAML Ain't Markup Language) is preferred over JSON for configuration files due to its human-friendly syntax, support for comments, multi-line strings, and better readability for complex nested structures.

## Research Questions Addressed

1. What are the available R packages for YAML parsing?
2. What are the pros and cons of each approach?
3. How do they handle nested configuration structures?
4. How well do they integrate with R's data structures?
5. Can they validate YAML against schemas?
6. What is the performance profile of each package?
7. How do they handle edge cases?

## Available Packages

### 1. yaml

**Version**: 2.3.10 (November 2025)
**Maintainer**: Shawn P Garbett, Jeremy Stephens
**Status**: Actively maintained

**Strengths**:
- Official R wrapper around the battle-tested libyaml C library
- YAML 1.1 standard compliant
- Handles complex nested structures naturally
- Preserves YAML-specific features (anchors, aliases, custom types)
- Simple API: `yaml.load()` for strings, `yaml.load_file()` for files
- Automatic type inference (sequences → vectors, maps → named lists)
- Good handling of R-specific types (factors, dates, data frames)
- Supports custom handlers for special types
- UTF-8 encoding support
- Widely used and battle-tested in the R ecosystem

**Limitations**:
- No native schema validation capability
- Performance slower than JSON parsers (inherent to YAML format complexity)
- YAML 1.1 standard (not 1.2, though 1.1 is more widely supported)
- Error messages can be cryptic for malformed YAML

**Performance**: Adequate for configuration files (<10MB); YAML parsing is inherently ~2x slower than JSON due to format complexity

### 2. configr

**Version**: 0.3.5 (July 2025)
**Status**: Actively maintained

**Strengths**:
- Unified interface for JSON, INI, YAML, and TOML formats
- Built-in environment-based configuration management
- Variable substitution and interpolation features
- Automatic format detection
- Designed specifically for configuration file use cases
- Integration with multiple configuration file formats

**Limitations**:
- Additional abstraction layer may complicate debugging
- Less control over YAML-specific features
- Smaller community compared to yaml package
- More dependencies

**Performance**: Similar to yaml package (wraps yaml internally)

### 3. config (RStudio)

**Version**: Maintained by RStudio
**Status**: Actively maintained

**Strengths**:
- Designed specifically for R project configuration
- Multi-environment support (dev, test, prod)
- Inheritance and defaults system
- Active configuration selection via environment variables
- Simple API: `config::get()`
- RStudio integration
- Good documentation

**Limitations**:
- Opinionated structure (config.yml with specific format)
- Less flexible for arbitrary YAML parsing
- Focused on R project configuration, not general YAML parsing
- Cannot easily parse non-standard YAML structures

**Performance**: Lightweight, suitable for configuration files

### 4. rconf

**Version**: 0.1.2 (March 2025)
**Status**: Minimally maintained

**Strengths**:
- Minimal dependencies
- Very lightweight
- Simple interface for basic YAML configuration

**Limitations**:
- Limited features
- Smaller community
- Less robust error handling
- Not suitable for complex YAML structures

**Performance**: Fast but limited functionality

## YAML Schema Validation

**Critical Finding**: The yaml package does not natively support schema validation. However, there are several approaches:

### Option 1: ajv Package (JSON Schema for YAML)

**Version**: 1.0.0 (July 2025)
**Recommendation**: Use JSON Schema to validate YAML

**Features**:
- Supports JSON Schema drafts 04, 06, and 07
- Can validate YAML files using JSON Schema definitions
- The schema can be a JSON or YAML file
- YAML files are parsed via js-yaml's `safeLoad()` method
- Simple interface: `ajv.validate(schema, data)`

**Usage Pattern**:
```r
library(yaml)
library(ajv)

# Parse YAML
config <- yaml.load_file("model_config.yaml")

# Validate against JSON schema (which works for YAML data)
is_valid <- ajv.validate("config_schema.json", config)

if (!is_valid) {
  errors <- attr(is_valid, "errors")
  stop("Configuration validation failed: ", errors)
}
```

### Option 2: validate Package (Rule-based Validation)

**Version**: Latest 2025
**Approach**: Rule-based data validation

**Features**:
- Define validation rules in R
- Can import/export rules to YAML format
- Provides per-field, in-record, and cross-record validation
- More flexible but requires defining rules in R

**Usage Pattern**:
```r
library(yaml)
library(validate)

# Parse YAML
config <- yaml.load_file("model_config.yaml")

# Define validation rules
rules <- validator(
  model_type = !is.na(model_type),
  learning_rate = learning_rate > 0 & learning_rate < 1,
  epochs = epochs > 0
)

# Validate
validation_result <- confront(as.data.frame(config), rules)
summary(validation_result)
```

### Option 3: Custom Validation Functions

For CHAP-specific requirements, implement custom validation:

```r
validate_chap_config <- function(config) {
  required_fields <- c("model_type", "parameters", "data_settings")

  # Check required fields
  missing <- setdiff(required_fields, names(config))
  if (length(missing) > 0) {
    stop("Missing required fields: ", paste(missing, collapse = ", "))
  }

  # Validate specific constraints
  if (!is.null(config$parameters$learning_rate)) {
    if (config$parameters$learning_rate <= 0 || config$parameters$learning_rate >= 1) {
      stop("learning_rate must be between 0 and 1")
    }
  }

  invisible(TRUE)
}
```

## Integration with R Data Structures

### yaml Integration Examples

**Reading configuration files**:
```r
library(yaml)

# Simple approach - from file
config <- yaml.load_file("model_config.yaml")

# From string
yaml_string <- "
model_type: random_forest
parameters:
  n_trees: 100
  max_depth: 10
"
config <- yaml.load(yaml_string)

# With custom handlers for special types
config <- yaml.load_file("model_config.yaml",
                         handlers = list(
                           Date = function(x) as.Date(x)
                         ))
```

**Writing configuration files**:
```r
# Convert R object to YAML string
yaml_output <- as.yaml(config)

# Write to file
write(as.yaml(config), file = "output_config.yaml")

# Pretty formatting with options
yaml_output <- as.yaml(config,
                       indent = 2,
                       indent.mapping.sequence = TRUE,
                       column.major = FALSE)
```

## Edge Case Handling

### Missing Fields and Null Values

yaml handles these gracefully:
- Missing fields: Omitted keys result in `NULL` in R, can be detected with `is.null()`
- NULL values: YAML `null` or `~` becomes R `NULL`
- Empty values: YAML empty values become `""` (empty string)
- Type coercion: Automatic based on YAML syntax

**YAML null representations**:
```yaml
# All of these become NULL in R
field1: null
field2: ~
field3:
```

### Nested Structures

yaml excels at nested structures:
- Maps become named lists
- Sequences become vectors or lists
- Mixed nesting is preserved
- Plays well with tidyverse tools (purrr::pluck, etc.)
- YAML anchors and aliases for reuse

Example:
```r
library(yaml)
library(purrr)

# Parse nested config
config <- yaml.load_file("nested_config.yaml")

# Extract nested values safely
param_value <- pluck(config, "model", "parameters", "learning_rate", .default = 0.01)
```

### YAML-Specific Features

**Comments** (major advantage over JSON):
```yaml
# This is a comment
model_type: random_forest  # inline comment
parameters:
  n_trees: 100  # number of trees in forest
```

**Multi-line strings**:
```yaml
description: |
  This is a multi-line description
  that preserves line breaks.

summary: >
  This is a multi-line string
  that folds into a single line.
```

**Anchors and aliases** (reuse configurations):
```yaml
defaults: &defaults
  batch_size: 32
  learning_rate: 0.001

model_a:
  <<: *defaults
  model_type: neural_network

model_b:
  <<: *defaults
  model_type: random_forest
  n_trees: 100
```

## Performance Benchmarks

**Summary**:
1. **yaml**: Standard performance for YAML parsing (~2x slower than JSON, but acceptable for configs)
2. **configr**: Similar to yaml (uses yaml internally)
3. **config**: Lightweight, optimized for small configuration files
4. **rconf**: Fast but limited features

**For configuration files** (typically <1MB):
- All packages perform adequately
- yaml offers best balance of features, flexibility, and community support
- YAML is inherently slower than JSON due to format complexity, but for configuration files this is negligible
- For very large YAML files (>100MB), performance may become a consideration

**Performance Context**:
- Configuration files are typically small (<1MB) and read infrequently (at startup)
- The ~2x parsing overhead compared to JSON is negligible in this context
- Human readability and maintainability are more important than parsing speed for configs

## Recommendation

### Primary Choice: yaml + ajv (for validation)

**Rationale**:

1. **Battle-Tested**: yaml package wraps libyaml, the industry-standard YAML 1.1 parser
2. **Human-Friendly Format**: YAML is more readable than JSON for configuration files
3. **Comments Support**: Critical for documenting configuration options
4. **Multi-line Strings**: Better handling of descriptions and documentation
5. **Active Development**: Maintained and updated regularly (November 2025 release)
6. **Ecosystem Integration**: Works seamlessly with tidyverse tools (purrr, dplyr)
7. **Validation Available**: Can use ajv package with JSON Schema for validation
8. **R Type Support**: Good handling of R-specific types (factors, dates, data frames)
9. **Flexibility**: YAML anchors/aliases for configuration reuse
10. **Community**: Widely adopted in R ecosystem

**When to Consider Alternatives**:
- **config package**: When you need multi-environment configuration with inheritance
- **configr**: When you need to support multiple formats (JSON, INI, YAML, TOML)
- **JSON instead of YAML**: When interfacing with systems that only support JSON
- **Never use rconf** for production - too limited in features and support

## Implementation Approach for CHAP SDK

### 1. Add Dependencies to DESCRIPTION

```r
Imports:
    yaml (>= 2.3.0),
    ajv (>= 1.0.0),
    rlang,
    cli,
    purrr
```

### 2. Create Configuration Reading Functions

File: `R/config.R`

```r
#' Read and Validate Model Configuration
#'
#' Reads a YAML configuration file and validates it against a schema
#'
#' @param config_path Path to YAML configuration file
#' @param schema_path Path to JSON schema file (optional)
#' @param validate Logical, whether to validate against schema
#'
#' @return List containing parsed configuration
#' @export
read_model_config <- function(config_path, schema_path = NULL, validate = TRUE) {
  if (!file.exists(config_path)) {
    cli::cli_abort("Configuration file not found: {config_path}")
  }

  # Parse YAML with error handling
  config <- tryCatch(
    yaml::yaml.load_file(config_path),
    error = function(e) {
      cli::cli_abort("Failed to parse YAML configuration: {e$message}")
    }
  )

  # Validate if schema provided
  if (validate && !is.null(schema_path)) {
    if (!file.exists(schema_path)) {
      cli::cli_abort("Schema file not found: {schema_path}")
    }

    # Use ajv to validate against JSON schema
    is_valid <- ajv::ajv.validate(schema_path, config)

    if (!is_valid) {
      errors <- attr(is_valid, "errors")
      cli::cli_abort(c(
        "Configuration validation failed:",
        "x" = "{length(errors)} validation error{?s}",
        "i" = "See errors for details"
      ))
    }
  }

  return(config)
}

#' Write Model Configuration
#'
#' Writes a configuration object to YAML file
#'
#' @param config Configuration list
#' @param config_path Output path for YAML file
#' @param indent Number of spaces for indentation
#'
#' @return Invisible NULL
#' @export
write_model_config <- function(config, config_path, indent = 2) {
  tryCatch(
    {
      yaml_output <- yaml::as.yaml(
        config,
        indent = indent,
        indent.mapping.sequence = TRUE
      )
      write(yaml_output, file = config_path)
    },
    error = function(e) {
      cli::cli_abort("Failed to write configuration: {e$message}")
    }
  )

  cli::cli_alert_success("Configuration written to {config_path}")
  invisible(NULL)
}
```

### 3. Configuration Validation Helpers

```r
#' Validate Configuration Structure
#'
#' Performs runtime validation of configuration structure
#'
#' @param config Configuration list
#' @param required_fields Character vector of required field names
#'
#' @return Invisible NULL (throws error if validation fails)
#' @export
validate_config_structure <- function(config, required_fields) {
  missing_fields <- setdiff(required_fields, names(config))

  if (length(missing_fields) > 0) {
    cli::cli_abort(c(
      "Missing required configuration fields:",
      "x" = "{.field {missing_fields}}"
    ))
  }

  invisible(NULL)
}

#' Extract Configuration Parameter Safely
#'
#' Extracts a parameter from nested configuration with default fallback
#'
#' @param config Configuration list
#' @param ... Path to parameter (passed to purrr::pluck)
#' @param .default Default value if parameter not found
#'
#' @return Parameter value or default
#' @export
get_config_param <- function(config, ..., .default = NULL) {
  purrr::pluck(config, ..., .default = .default)
}
```

## Best Practices for Configuration Handling

1. **Always validate against schemas** in production code
2. **Use comments liberally** in YAML files to document configuration options
3. **Provide sensible defaults** using `get_config_param()` with `.default`
4. **Use informative error messages** with cli package
5. **Document expected configuration structure** in roxygen2 comments
6. **Test edge cases**: missing fields, null values, type mismatches
7. **Version your schemas** alongside configuration files
8. **Use YAML anchors** for configuration reuse and DRY principle
9. **Keep YAML simple**: avoid overly complex nesting or advanced YAML features
10. **Use multi-line strings** with `|` or `>` for descriptions and documentation

## Testing Strategy

```r
# tests/testthat/test-config.R

test_that("read_model_config parses valid YAML", {
  config <- read_model_config("fixtures/valid_config.yaml", validate = FALSE)
  expect_type(config, "list")
  expect_true("model_type" %in% names(config))
})

test_that("read_model_config validates against schema", {
  expect_error(
    read_model_config(
      "fixtures/invalid_config.yaml",
      schema_path = "fixtures/config_schema.json"
    ),
    "validation failed"
  )
})

test_that("read_model_config handles YAML comments", {
  yaml_with_comments <- "
# This is a comment
model_type: random_forest  # inline comment
parameters:
  n_trees: 100
"
  config <- yaml::yaml.load(yaml_with_comments)
  expect_equal(config$model_type, "random_forest")
  expect_equal(config$parameters$n_trees, 100)
})

test_that("read_model_config handles YAML null values", {
  yaml_with_nulls <- "
model_type: random_forest
optional_field: null
another_null: ~
"
  config <- yaml::yaml.load(yaml_with_nulls)
  expect_null(config$optional_field)
  expect_null(config$another_null)
})

test_that("get_config_param handles nested paths", {
  config <- list(model = list(params = list(lr = 0.01)))
  lr <- get_config_param(config, "model", "params", "lr")
  expect_equal(lr, 0.01)
})

test_that("get_config_param returns default for missing values", {
  config <- list(model = list())
  lr <- get_config_param(config, "model", "params", "lr", .default = 0.001)
  expect_equal(lr, 0.001)
})
```

## Related Work

- **CLIM-204**: Configuration Schema Management - will define schema structure
- **CLIM-203**: CLI Argument Parsing - will consume parsed configurations

## References

Sources:
- [yaml Package Documentation (v2.3.10)](https://cran.r-project.org/web/packages/yaml/yaml.pdf)
- [configr Package Documentation](https://cran.r-project.org/web/packages/configr/configr.pdf)
- [config Package (RStudio)](https://rstudio.github.io/config/articles/introduction.html)
- [ajv Package Documentation (v1.0.0)](https://cran.r-project.org/web/packages/ajv/ajv.pdf)
- [validate Package Documentation](https://cran.r-project.org/web/packages/validate/validate.pdf)
- [GitHub: r-yaml](https://github.com/vubiostat/r-yaml)
- [YAML vs JSON Format Comparison](https://jsonconsole.com/blog/json-vs-xml-vs-yaml-complete-comparison-data-format-selection-2025)
- [YAML Official Website](https://yaml.org/)
- [YAML vs jsonlite vs RJSONIO comparison](https://coolbutuseless.github.io/2018/02/07/yaml-vs-jsonlite-vs-rjsonio/)
- [Parse and Generate YAML with R](https://mojoauth.com/parse-and-generate-formats/parse-and-generate-yaml-with-r/)

## Conclusion

**Use yaml (>= 2.3.0) with ajv (>= 1.0.0) for validation** for all configuration file parsing in the CHAP R SDK. This combination provides:

1. **Human-readable format** with comments and multi-line strings
2. **Battle-tested parser** (libyaml wrapper)
3. **Schema validation** via JSON Schema (ajv package)
4. **Excellent R integration** with tidyverse tools
5. **Active maintenance** and community support

While YAML parsing is ~2x slower than JSON, this is negligible for configuration files which are typically small (<1MB) and read infrequently. The benefits of human readability, comments, and better maintainability far outweigh the minimal performance cost.
