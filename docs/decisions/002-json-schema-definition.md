# ADR 002: JSON Schema Definition Approach for CHAP R SDK

**Status:** Proposed
**Date:** 2025-12-04
**Decision Makers:** CHAP R SDK Team
**Related Jira:** [CLIM-210](https://dhis2.atlassian.net/browse/CLIM-210), [CLIM-204](https://dhis2.atlassian.net/browse/CLIM-204)

## Context

The CHAP R SDK needs a way for R programmers to define JSON schemas for model configurations. These schemas serve multiple purposes:

1. **Validation**: Ensure configuration files provided by users meet expected structure and constraints
2. **Documentation**: Auto-generate documentation about available configuration options
3. **Integration**: Expose configuration schemas to the CHAP platform for UI generation
4. **Type Safety**: Provide clear contracts between models and the platform

### Requirements

1. R programmers should be able to define schemas in a natural, R-idiomatic way
2. Schemas should be convertible to standard JSON Schema format
3. Support validation of YAML/JSON configuration files
4. Enable automatic documentation generation
5. Be maintainable and easy to update
6. Support common data types, nested structures, and constraints
7. Low learning curve for R developers

## Options Considered

### Option 1: Manual JSON Schema Files

**Description:** Write JSON Schema files directly in JSON format, store them in `inst/schemas/`, and load them at runtime.

**Example:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "learning_rate": {
      "type": "number",
      "minimum": 0,
      "maximum": 1,
      "description": "Learning rate for model training"
    },
    "max_iterations": {
      "type": "integer",
      "minimum": 1,
      "description": "Maximum training iterations"
    }
  },
  "required": ["learning_rate"]
}
```

**Pros:**
- Standard JSON Schema format, widely supported
- Can use any JSON Schema validator (e.g., `jsonvalidate` package)
- Clear separation between schema definition and code
- Can be version-controlled easily

**Cons:**
- **Not R-idiomatic** - requires learning JSON Schema syntax
- Manual editing is error-prone
- No type checking when writing schemas
- Redundant with R function parameter documentation
- Difficult to maintain consistency between code and schema

**Use Case Fit:** Works but not ideal for R programmers who want to define schemas in R code.

**References:**
- [JSON Schema Documentation](https://json-schema.org/understanding-json-schema/about)
- [JSON Schema Reference](https://json-schema.org/understanding-json-schema/reference)

---

### Option 2: R Lists as Schema Definitions (Recommended)

**Description:** Define schemas as R lists with a specific structure, then convert to JSON Schema format. Provide helper functions to make schema definition more ergonomic.

**Example:**
```r
config_schema <- function() {
  list(
    type = "object",
    properties = list(
      learning_rate = list(
        type = "number",
        minimum = 0,
        maximum = 1,
        description = "Learning rate for model training"
      ),
      max_iterations = list(
        type = "integer",
        minimum = 1,
        description = "Maximum training iterations"
      ),
      continuous_covariates = list(
        type = "array",
        items = list(type = "string"),
        description = "Names of continuous covariates to include"
      )
    ),
    required = c("learning_rate")
  )
}

# Convert to JSON Schema
schema_json <- jsonlite::toJSON(config_schema(), auto_unbox = TRUE, pretty = TRUE)

# Validate config against schema
jsonvalidate::json_validate(config_json, schema_json, engine = "ajv")
```

**With helper functions:**
```r
# Helper functions for cleaner syntax
schema_number <- function(description, minimum = NULL, maximum = NULL, default = NULL) {
  schema <- list(type = "number", description = description)
  if (!is.null(minimum)) schema$minimum <- minimum
  if (!is.null(maximum)) schema$maximum <- maximum
  if (!is.null(default)) schema$default <- default
  schema
}

schema_integer <- function(description, minimum = NULL, maximum = NULL, default = NULL) {
  schema <- list(type = "integer", description = description)
  if (!is.null(minimum)) schema$minimum <- minimum
  if (!is.null(maximum)) schema$maximum <- maximum
  if (!is.null(default)) schema$default <- default
  schema
}

schema_string <- function(description, enum = NULL, default = NULL) {
  schema <- list(type = "string", description = description)
  if (!is.null(enum)) schema$enum <- enum
  if (!is.null(default)) schema$default <- default
  schema
}

schema_array <- function(description, items, default = NULL) {
  schema <- list(type = "array", items = items, description = description)
  if (!is.null(default)) schema$default <- default
  schema
}

schema_object <- function(properties, required = NULL, description = NULL) {
  schema <- list(type = "object", properties = properties)
  if (!is.null(required)) schema$required <- required
  if (!is.null(description)) schema$description <- description
  schema
}

# Cleaner schema definition
config_schema <- function() {
  schema_object(
    properties = list(
      learning_rate = schema_number(
        "Learning rate for model training",
        minimum = 0, maximum = 1
      ),
      max_iterations = schema_integer(
        "Maximum training iterations",
        minimum = 1, default = 100
      ),
      optimizer = schema_string(
        "Optimization algorithm",
        enum = c("adam", "sgd", "rmsprop"),
        default = "adam"
      ),
      continuous_covariates = schema_array(
        "Names of continuous covariates to include",
        items = list(type = "string"),
        default = list()
      )
    ),
    required = c("learning_rate")
  )
}
```

**Pros:**
- **R-idiomatic** - uses familiar R list syntax
- Type-safe when using helper functions
- Can be programmatically generated or modified
- Easy to maintain alongside R code
- Helper functions reduce boilerplate
- Can validate during package development
- Compatible with standard JSON Schema validators

**Cons:**
- Requires writing helper functions (one-time cost)
- Still somewhat verbose for complex schemas
- Need to convert to JSON for use with validators

**Use Case Fit:** Excellent fit for CHAP R SDK. Balances R idioms with JSON Schema compatibility.

**References:**
- [jsonlite documentation](https://cran.r-project.org/web/packages/jsonlite/vignettes/json-aaquickstart.html)
- [jsonvalidate vignette](https://cran.r-project.org/web/packages/jsonvalidate/vignettes/jsonvalidate.html)

---

### Option 3: S3 Classes with Validation Methods

**Description:** Define configuration as S3 classes with built-in validation, then derive JSON Schema from class structure.

**Example:**
```r
new_model_config <- function(learning_rate, max_iterations = 100, optimizer = "adam") {
  stopifnot(is.numeric(learning_rate), learning_rate >= 0, learning_rate <= 1)
  stopifnot(is.integer(max_iterations), max_iterations >= 1)
  stopifnot(optimizer %in% c("adam", "sgd", "rmsprop"))

  structure(
    list(
      learning_rate = learning_rate,
      max_iterations = max_iterations,
      optimizer = optimizer
    ),
    class = "model_config"
  )
}

validate_model_config <- function(x) {
  if (!is.numeric(x$learning_rate) || x$learning_rate < 0 || x$learning_rate > 1) {
    stop("learning_rate must be between 0 and 1")
  }
  # ... additional validation
  x
}

# Define schema generator
as_json_schema.model_config <- function(x) {
  list(
    type = "object",
    properties = list(
      learning_rate = list(type = "number", minimum = 0, maximum = 1),
      max_iterations = list(type = "integer", minimum = 1),
      optimizer = list(type = "string", enum = c("adam", "sgd", "rmsprop"))
    ),
    required = c("learning_rate")
  )
}
```

**Pros:**
- Very R-idiomatic with S3 classes
- Validation logic lives with the class
- Strong coupling between code and schema
- Can use R's existing documentation (roxygen2)

**Cons:**
- **More complex** - requires understanding S3 system
- Redundant validation (both in constructor and schema)
- Schema generation requires reflection/introspection
- Harder to maintain
- Not as flexible for configuration-only use cases
- Steeper learning curve

**Use Case Fit:** Over-engineered for this use case. Better suited for complex domain objects.

**References:**
- [Advanced R: S3 Classes](https://adv-r.hadley.nz/s3.html)
- [R S3 Class Examples](https://www.datamentor.io/r-programming/s3-class)

---

### Option 4: Schema Inference from Example Config

**Description:** Provide example configurations and automatically infer schemas using `tidyjson::json_schema()`.

**Example:**
```r
library(tidyjson)

# Example configuration
example_config <- '{
  "learning_rate": 0.01,
  "max_iterations": 100,
  "optimizer": "adam",
  "continuous_covariates": ["rainfall", "temperature"]
}'

# Infer schema
inferred_schema <- example_config %>% json_schema()
```

**Pros:**
- Minimal code - just provide examples
- Automatically infers types
- Good for prototyping

**Cons:**
- **Cannot infer constraints** (min/max, enum values, etc.)
- No descriptions or documentation
- Inferred schemas are often too permissive
- Not suitable for strict validation
- Requires examples to be comprehensive

**Use Case Fit:** Useful for quick prototyping but insufficient for production schemas with constraints.

**References:**
- [tidyjson json_schema](https://rdrr.io/cran/tidyjson/man/json_schema.html)
- [tidyjson introduction](https://cran.r-project.org/web/packages/tidyjson/vignettes/introduction-to-tidyjson.html)

---

### Option 5: Roxygen2-style Documentation Tags

**Description:** Define schema constraints using roxygen2-style tags in comments, then parse to generate JSON Schema.

**Example:**
```r
#' Model Configuration
#'
#' @field learning_rate numeric Learning rate (0-1)
#' @constraint learning_rate >= 0 && learning_rate <= 1
#' @field max_iterations integer Maximum iterations (>= 1)
#' @constraint max_iterations >= 1
#' @field optimizer string Optimization algorithm
#' @constraint optimizer %in% c("adam", "sgd", "rmsprop")
#' @required learning_rate
config_schema <- function() {
  # Schema generated from above comments
}
```

**Pros:**
- Familiar syntax for R package developers
- Documentation and schema in one place
- Could integrate with roxygen2 workflow

**Cons:**
- **Requires custom parser** - significant implementation effort
- Non-standard use of roxygen2
- Limited flexibility
- No existing tooling support
- Maintenance burden

**Use Case Fit:** Interesting idea but requires too much custom tooling.

**References:**
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [R Packages: Function documentation](https://r-pkgs.org/man.html)

---

## Decision

**We will use R lists with helper functions (Option 2) for defining JSON schemas in the CHAP R SDK.**

### Rationale

1. **R-Idiomatic**: R developers work with lists naturally; no need to learn JSON Schema syntax directly
2. **Helper Functions**: Reduce boilerplate and make schemas more readable
3. **Flexible**: Can be programmatically generated or composed
4. **Standard Compatible**: Converts directly to JSON Schema via `jsonlite::toJSON()`
5. **Validation Ready**: Works with `jsonvalidate` package (using ajv engine)
6. **Maintainable**: Easy to update and version control
7. **Low Complexity**: Doesn't require custom parsers or complex S3 infrastructure
8. **Documentation**: Schema descriptions can be extracted for auto-documentation

### Implementation Strategy

The CHAP R SDK will provide:

1. **Helper functions** for common schema types:
   - `schema_number()`, `schema_integer()`, `schema_string()`
   - `schema_boolean()`, `schema_array()`, `schema_object()`
   - `schema_enum()`, `schema_oneof()` for advanced cases

2. **Validation utilities**:
   ```r
   validate_config <- function(config_json, schema_function) {
     schema_json <- jsonlite::toJSON(
       schema_function(),
       auto_unbox = TRUE,
       pretty = TRUE
     )
     jsonvalidate::json_validate(
       config_json,
       schema_json,
       engine = "ajv",
       verbose = TRUE
     )
   }
   ```

3. **Schema export functions**:
   ```r
   export_schema <- function(schema_function, filepath) {
     schema_json <- jsonlite::toJSON(
       schema_function(),
       auto_unbox = TRUE,
       pretty = TRUE
     )
     writeLines(schema_json, filepath)
   }
   ```

4. **Documentation generators**:
   ```r
   schema_to_markdown <- function(schema) {
     # Convert schema to human-readable markdown documentation
   }
   ```

### Example: Complete CHAP Model Schema

```r
library(chapr)

# Define model configuration schema
my_model_config_schema <- function() {
  schema_object(
    description = "Configuration for my CHAP model",
    properties = list(
      # Core model parameters
      learning_rate = schema_number(
        description = "Learning rate for gradient descent",
        minimum = 0.0001,
        maximum = 1.0,
        default = 0.01
      ),

      max_iterations = schema_integer(
        description = "Maximum number of training iterations",
        minimum = 1,
        maximum = 10000,
        default = 1000
      ),

      # Model options
      model_type = schema_string(
        description = "Type of model to use",
        enum = c("linear", "glm", "gam"),
        default = "glm"
      ),

      include_seasonality = schema_boolean(
        description = "Include seasonal effects",
        default = TRUE
      ),

      # Covariates
      continuous_covariates = schema_array(
        description = "List of continuous covariate names",
        items = list(type = "string"),
        default = list("rainfall", "temperature")
      ),

      # Advanced options
      optimization = schema_object(
        description = "Optimization algorithm settings",
        properties = list(
          algorithm = schema_string(
            description = "Optimization algorithm",
            enum = c("adam", "sgd", "lbfgs"),
            default = "adam"
          ),
          tolerance = schema_number(
            description = "Convergence tolerance",
            minimum = 1e-10,
            maximum = 1e-1,
            default = 1e-6
          )
        ),
        required = NULL
      )
    ),
    required = c("learning_rate", "max_iterations")
  )
}

# Export schema to JSON file
export_schema(my_model_config_schema, "inst/schemas/my_model_config.json")

# Validate a config file
config_yaml <- yaml::read_yaml("config.yaml")
config_json <- jsonlite::toJSON(config_yaml, auto_unbox = TRUE)

is_valid <- validate_config(config_json, my_model_config_schema)

if (!is_valid) {
  errors <- attr(is_valid, "errors")
  stop("Configuration validation failed:\n", paste(errors, collapse = "\n"))
}
```

## Consequences

### Positive

- R developers can define schemas using familiar syntax
- Schemas are type-safe and programmatically verifiable
- Compatible with standard JSON Schema validators
- Easy to extend and maintain
- Can generate documentation from schemas
- Lower barrier to entry than learning JSON Schema directly

### Negative

- Requires writing and maintaining helper functions
- Still somewhat verbose for very complex schemas
- Conversion step needed (R list → JSON)
- Need to educate developers about helper function API

### Neutral

- Schemas defined in R code rather than separate files
- Requires `jsonlite` and `jsonvalidate` dependencies

## Validation Package Choice

We will use **`jsonvalidate`** with the **`ajv` engine** for validation:

- `jsonvalidate` is actively maintained (v1.5.0, July 2025)
- `ajv` engine supports JSON Schema Draft-07 and many advanced features
- Provides clear error messages for validation failures
- Pure R solution with minimal dependencies

**References:**
- [jsonvalidate package](https://cran.r-project.org/web/packages/jsonvalidate/jsonvalidate.pdf)
- [jsonvalidate vignette](https://cran.r-project.org/web/packages/jsonvalidate/vignettes/jsonvalidate.html)
- [ajv package](https://cran.r-project.org/web/packages/ajv/ajv.pdf)

## Next Steps

1. Implement schema helper functions in CHAP R SDK
2. Create example model configuration schemas
3. Write validation utilities
4. Document schema definition patterns
5. Create schema-to-markdown documentation generator
6. Write tests for schema validation
7. Update model template to include schema definition

## References

- [JSON Schema: What is JSON Schema?](https://json-schema.org/overview/what-is-jsonschema)
- [JSON Schema Reference](https://json-schema.org/understanding-json-schema/reference)
- [jsonlite: Getting started with JSON and jsonlite](https://cran.r-project.org/web/packages/jsonlite/vignettes/json-aaquickstart.html)
- [jsonvalidate: Introduction to jsonvalidate](https://cran.r-project.org/web/packages/jsonvalidate/vignettes/jsonvalidate.html)
- [jsonvalidate package (v1.5.0)](https://cran.r-project.org/web/packages/jsonvalidate/jsonvalidate.pdf)
- [tidyjson: json_schema function](https://rdrr.io/cran/tidyjson/man/json_schema.html)
- [Advanced R: S3 Classes](https://adv-r.hadley.nz/s3.html)
- [R Packages: Function documentation](https://r-pkgs.org/man.html)
- [The MockUp: Parsing JSON in R with jsonlite and purrr](https://themockup.blog/posts/2020-05-22-parsing-json-in-r-with-jsonlite/)
- [Stack Overflow: R Plumber API JSON schema](https://stackoverflow.com/questions/72655895/r-plumber-api-programmatically-specify-json-schema-for-request)
- [Stack Overflow: Using JSON schema in R package](https://stackoverflow.com/questions/79774519/using-json-schema-in-an-r-package)
