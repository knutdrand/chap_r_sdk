# JSON Configuration File Parsing in R

**Issue**: CLIM-210
**Date**: 2025-12-03
**Status**: Recommended

## Context

The CHAP R SDK needs to parse JSON configuration files for model training and prediction. These configuration files will contain nested structures defining model parameters, data transformations, and other settings. We need a reliable, performant, and well-maintained solution for parsing these configurations.

## Research Questions Addressed

1. What are the available R packages for JSON parsing?
2. What are the pros and cons of each approach?
3. How do they handle nested configuration structures?
4. How well do they integrate with R's data structures?
5. Can they validate JSON against schemas?
6. What is the performance profile of each package?
7. How do they handle edge cases?

## Available Packages

### 1. jsonlite

**Version**: 2.0.0 (July 2025)
**Maintainer**: Jeroen Ooms
**Status**: Actively maintained

**Strengths**:
- Modern, robust, and user-friendly design
- Excellent data frame handling - automatically converts JSON to/from data frames
- Preserves metadata (row names, column names, dimensions)
- Strong type safety: `all.equal(mtcars, fromJSON(toJSON(mtcars)))` returns TRUE
- Handles complex nested structures with `flatten = TRUE` parameter
- Compatible with web APIs and cross-language interoperability
- Built-in JSON validation (syntax checking)
- Flexible simplification control with `simplifyVector` parameter
- Good performance for most use cases
- Comprehensive documentation and widespread adoption

**Limitations**:
- Named vectors are not converted to key-value paired JSON objects by default
- For very large files (>25GB), performance can be a bottleneck
- Does not natively support JSON schema validation (requires separate package)

**Performance**: Reasonably fast for statistical data, can be optimized by calling internal functions directly (~6x speedup for large files)

### 2. rjson

**Version**: Older package (circa 2013)
**Status**: Maintained but less actively developed

**Strengths**:
- Fast performance (fastest among the three for basic operations)
- Lightweight and simple
- Retains key-value pairing in JSON objects

**Limitations**:
- Loses structure information from data frames
- No type safety guarantees
- Less sophisticated handling of nested data
- Always simplifies vectors (no control over simplification)
- Limited data frame support
- Does not support precision control for numeric values

**Performance**: Fastest for basic toJSON operations but at the cost of metadata preservation

### 3. RJSONIO

**Version**: Legacy package
**Status**: Less actively maintained

**Strengths**:
- Offers control over vector simplification
- Has precision handling options (uses significant digits)

**Limitations**:
- Slowest performance among the three
- Less consistent API
- Lexical error handling issues reported
- Smaller user base and community support

**Performance**: Slowest for toJSON operations

## JSON Schema Validation

**Critical Finding**: None of the JSON parsing packages natively support JSON schema validation. For schema validation, you must use:

### jsonvalidate Package

**Version**: 1.5.0 (July 2025)
**Recommendation**: Use with `ajv` engine

**Features**:
- Supports JSON Schema drafts 04, 06, and 07
- Two validation engines:
  - `imjv` (is-my-json-valid): Default for backward compatibility
  - `ajv` (Another JSON Schema Validator): **Recommended for all new code**
- Integrates seamlessly with jsonlite
- Simple interface: `json_validate(json, schema, engine = "ajv")`

**Usage Pattern**:
```r
library(jsonlite)
library(jsonvalidate)

# Parse JSON
config <- fromJSON("model_config.json", simplifyVector = FALSE)

# Validate against schema
schema <- json_schema("config_schema.json", engine = "ajv")
is_valid <- schema(config)
```

## Integration with R Data Structures

### jsonlite Integration Examples

**Reading configuration files**:
```r
# Simple approach - automatic simplification
config <- fromJSON("model_config.json")

# Fine-grained control
config <- fromJSON("model_config.json", simplifyVector = FALSE)

# Flatten nested structures
config <- fromJSON("model_config.json", flatten = TRUE)

# Use read_json for direct file reading
config <- read_json("model_config.json", simplifyVector = TRUE)
```

**Converting to JSON**:
```r
# Write configuration
toJSON(config, pretty = TRUE, auto_unbox = TRUE)

# Save to file
write_json(config, "output_config.json", pretty = TRUE)
```

## Edge Case Handling

### Missing Fields and Null Values

jsonlite handles these gracefully:
- Missing fields: Can be detected with standard R `is.null()` or using purrr utilities
- NULL values: Preserved as `null` in JSON, become `NULL` in R
- Type coercion: Controlled via `simplifyVector`, `simplifyDataFrame`, `simplifyMatrix` parameters

### Nested Structures

jsonlite excels at nested structures:
- Nested data frames are preserved
- `flatten()` function available for denormalization
- Plays well with tidyverse tools (purrr::map, etc.)

Example:
```r
library(jsonlite)
library(purrr)

# Parse nested config
config <- fromJSON("nested_config.json")

# Extract nested values safely
param_value <- pluck(config, "model", "parameters", "learning_rate", .default = 0.01)
```

## Performance Benchmarks

**Summary** (toJSON operations):
1. **rjson**: Fastest (but loses metadata)
2. **jsonlite**: Second fastest (preserves metadata)
3. **RJSONIO**: Slowest

**For configuration files** (typically <10MB):
- All three packages perform adequately
- jsonlite offers best balance of speed and data integrity
- For very large configs (>100MB), consider streaming approaches or Apache Drill

## Recommendation

### Primary Choice: jsonlite + jsonvalidate

**Rationale**:

1. **Robust and Modern**: jsonlite (v2.0.0, 2025) is actively maintained with modern R best practices
2. **Data Integrity**: Preserves data frame structure and metadata, critical for configuration management
3. **Ecosystem Integration**: Works seamlessly with tidyverse tools (dplyr, purrr, tibble)
4. **Schema Validation**: Combined with jsonvalidate (ajv engine), provides comprehensive validation
5. **Community Support**: Widely adopted, excellent documentation, active development
6. **Flexibility**: Offers fine-grained control over parsing behavior
7. **Performance**: Good enough for configuration files (typically <10MB)

**When to Consider Alternatives**:
- **Never use rjson** for configuration management - metadata loss is unacceptable
- **Never use RJSONIO** - outdated with performance issues
- For streaming very large JSON files (>100MB), consider specialized tools like Apache Drill

## Implementation Approach for CHAP SDK

### 1. Add Dependencies to DESCRIPTION

```r
Imports:
    jsonlite (>= 2.0.0),
    jsonvalidate (>= 1.5.0),
    rlang,
    cli
```

### 2. Create Configuration Reading Functions

File: `R/config.R`

```r
#' Read and Validate Model Configuration
#'
#' Reads a JSON configuration file and validates it against a schema
#'
#' @param config_path Path to JSON configuration file
#' @param schema_path Path to JSON schema file (optional)
#' @param validate Logical, whether to validate against schema
#'
#' @return List containing parsed configuration
#' @export
read_model_config <- function(config_path, schema_path = NULL, validate = TRUE) {
  if (!file.exists(config_path)) {
    cli::cli_abort("Configuration file not found: {config_path}")
  }

  # Parse JSON with error handling
  config <- tryCatch(
    jsonlite::fromJSON(config_path, simplifyVector = FALSE),
    error = function(e) {
      cli::cli_abort("Failed to parse JSON configuration: {e$message}")
    }
  )

  # Validate if schema provided
  if (validate && !is.null(schema_path)) {
    if (!file.exists(schema_path)) {
      cli::cli_abort("Schema file not found: {schema_path}")
    }

    validator <- jsonvalidate::json_schema(schema_path, engine = "ajv")
    is_valid <- validator(config_path, verbose = TRUE, greedy = TRUE)

    if (!is_valid) {
      errors <- attr(is_valid, "errors")
      cli::cli_abort(c(
        "Configuration validation failed:",
        "x" = "{nrow(errors)} validation error{?s}",
        "i" = "See errors: {.code attr(is_valid, 'errors')}"
      ))
    }
  }

  return(config)
}

#' Write Model Configuration
#'
#' Writes a configuration object to JSON file
#'
#' @param config Configuration list
#' @param config_path Output path for JSON file
#' @param pretty Logical, whether to pretty-print JSON
#'
#' @return Invisible NULL
#' @export
write_model_config <- function(config, config_path, pretty = TRUE) {
  tryCatch(
    jsonlite::write_json(
      config,
      config_path,
      pretty = pretty,
      auto_unbox = TRUE
    ),
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
2. **Use `simplifyVector = FALSE`** for configuration files to maintain full control
3. **Provide sensible defaults** using `get_config_param()` with `.default`
4. **Use informative error messages** with cli package
5. **Document expected configuration structure** in roxygen2 comments
6. **Test edge cases**: missing fields, null values, type mismatches
7. **Version your schemas** alongside configuration files

## Testing Strategy

```r
# tests/testthat/test-config.R

test_that("read_model_config parses valid JSON", {
  config <- read_model_config("fixtures/valid_config.json", validate = FALSE)
  expect_type(config, "list")
  expect_true("model_type" %in% names(config))
})

test_that("read_model_config validates against schema", {
  expect_error(
    read_model_config(
      "fixtures/invalid_config.json",
      schema_path = "fixtures/config_schema.json"
    ),
    "validation failed"
  )
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
- [Stack Overflow: jsonlite vs rjson fundamentals](https://stackoverflow.com/questions/53379940/what-is-the-fundamental-difference-between-jsonlite-and-rjson-packages)
- [Biased comparison of JSON packages in R](https://rstudio-pubs-static.s3.amazonaws.com/31702_9c22e3d1a0c44968a4a1f9656f1800ab.html)
- [GeeksforGeeks: jsonlite vs rjson](https://www.geeksforgeeks.org/fundamental-difference-between-jsonlite-and-rjson-packages/)
- [jsonlite Package Documentation (v2.0.0)](https://cran.r-project.org/web/packages/jsonlite/jsonlite.pdf)
- [jsonvalidate Package Documentation (v1.5.0)](https://cran.r-project.org/web/packages/jsonvalidate/jsonvalidate.pdf)
- [Introduction to jsonvalidate](https://docs.ropensci.org/jsonvalidate/articles/jsonvalidate.html)
- [GitHub: jsonlite](https://github.com/jeroen/jsonlite)
- [Stack Overflow: jsonlite performance on large files](https://stackoverflow.com/questions/73424215/r-jsonlite-fromjson-very-slow-on-large-files-is-this-expected)

## Conclusion

**Use jsonlite (>= 2.0.0) with jsonvalidate (>= 1.5.0, ajv engine)** for all JSON configuration parsing in the CHAP R SDK. This combination provides the best balance of performance, data integrity, validation capabilities, and ecosystem integration.
