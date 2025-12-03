# ADR 001: Command Line Interface Approach for CHAP R SDK

**Status:** Proposed
**Date:** 2025-12-03
**Decision Makers:** CHAP R SDK Team
**Related Jira:** [CLIM-209](https://dhis2.atlassian.net/browse/CLIM-209)

## Context

The CHAP R SDK needs to provide a standardized way to expose R modeling functions (`train()` and `predict()`) through command-line interfaces. This enables integration with the CHAP platform and allows models to be executed in various deployment environments.

### Requirements

1. Parse command-line arguments for both `train()` and `predict()` functions
2. Handle complex argument types (file paths, nested configurations, lists)
3. Support JSON configuration files as input
4. Generate helpful usage messages automatically
5. Minimize external dependencies
6. Maintain good performance
7. Be developer-friendly and easy to use
8. Work across different operating systems

## Options Considered

### Option 1: Base R `commandArgs()`

**Description:** Use R's built-in `commandArgs()` function for parsing command-line arguments.

**Pros:**
- No additional dependencies
- Maximum portability
- Lightweight and fast
- Built into base R

**Cons:**
- Requires manual parsing logic
- No automatic help generation
- More boilerplate code for developers
- Limited validation capabilities
- No type coercion

**Use Case Fit:** Suitable only for very simple argument structures. Not ideal for CHAP's requirements with complex configurations.

---

### Option 2: `argparse` Package

**Description:** R wrapper around Python's argparse library, providing rich argument parsing capabilities.

**Pros:**
- Rich positional argument support
- Feature-complete with subcommands, argument groups, etc.
- Automatic help generation
- Type validation

**Cons:**
- **Requires Python installation** (Python 3.2+ with argparse and json modules)
- Cross-language dependency increases complexity
- **Significantly slower performance** due to Python bridge
- More fragile deployment (Python version compatibility issues)
- Not pure R solution

**Use Case Fit:** While feature-rich, the Python dependency is a dealbreaker for portability and introduces unnecessary complexity.

**References:**
- [Stack Overflow: Parsing command line arguments in R scripts](https://stackoverflow.com/questions/3433603/parsing-command-line-arguments-in-r-scripts)
- [GitHub: r-argparse](https://github.com/trevorld/r-argparse)

---

### Option 3: `optparse` Package (Recommended)

**Description:** Pure R command line parser inspired by Python's optparse library, designed for use with Rscript.

**Pros:**
- **Pure R implementation** - no external dependencies beyond getopt
- Fast performance (no cross-language bridge)
- Automatic help generation
- Support for short and long flags
- Type coercion (logical, integer, double, complex, character)
- Default values
- Simple and intuitive API
- Well-maintained on CRAN
- Works seamlessly with `#!/usr/bin/env Rscript` shebang scripts

**Cons:**
- Limited positional argument support (but sufficient for CHAP use case)
- Slightly less feature-rich than argparse

**Use Case Fit:** Excellent fit for CHAP R SDK. Supports all required features without external dependencies.

**Example Usage:**
```r
library(optparse)

option_list <- list(
  make_option(c("-c", "--config"), type="character", default=NULL,
              help="Path to JSON configuration file", metavar="FILE"),
  make_option(c("-d", "--data"), type="character", default=NULL,
              help="Path to training data", metavar="FILE"),
  make_option(c("-o", "--output"), type="character", default="model.rds",
              help="Output path for saved model [default= %default]", metavar="FILE")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)
```

**References:**
- [CRAN: optparse package](https://cran.r-project.org/web/packages/optparse/readme/README.html)
- [GitHub: r-optparse](https://github.com/trevorld/r-optparse)

---

### Option 4: `docopt` Package

**Description:** Command-line interface description language - define CLI by writing documentation.

**Pros:**
- Elegant approach - write help message, get parser for free
- Very readable and maintainable
- Pure R implementation
- Automatic parsing from docstring

**Cons:**
- Less explicit control over parsing
- Steeper learning curve for developers
- Less popular/mature than optparse
- Magic behavior may be less predictable

**Use Case Fit:** Interesting approach but less conventional. Could be harder for team members unfamiliar with docopt style.

**References:**
- [GitHub: docopt.R](https://github.com/docopt/docopt.R)
- [docopt vs argparse comparison](https://dmerej.info/blog/post/docopt-v-argparse/)

---

### Option 5: `arrg` Package

**Description:** Flexible argument parsing designed for R scripts with minimal boilerplate.

**Pros:**
- Very minimal syntax
- Flexible and modern approach
- Pure R implementation

**Cons:**
- Less mature/less widely adopted
- Smaller community
- Less documentation

**Use Case Fit:** Too new and unproven for production use in CHAP.

**References:**
- [GitHub: arrg](https://github.com/jonclayden/arrg)

---

## Decision

**We will use the `optparse` package for creating command-line interfaces in the CHAP R SDK.**

### Rationale

1. **Pure R Solution:** No external language dependencies (Python, Perl) ensures maximum portability and simpler deployment
2. **Performance:** Fast execution without cross-language bridging overhead
3. **Feature Completeness:** Provides all necessary features for CHAP use case:
   - Named arguments with short/long forms
   - Type validation and coercion
   - Default values
   - Automatic help generation
4. **Maturity:** Well-established CRAN package with active maintenance
5. **Developer Experience:** Simple, intuitive API that's easy to learn
6. **Community Adoption:** Widely used in the R community

### Implementation Strategy

The CHAP R SDK will provide:

1. **Wrapper functions** to reduce boilerplate:
   ```r
   chap_train_cli <- function(train_fn) {
     # Generate optparse configuration from train_fn signature
     # Handle JSON config parsing
     # Call train_fn with parsed arguments
   }
   ```

2. **Standard argument patterns:**
   - `--config` / `-c`: Path to JSON configuration file
   - `--data` / `-d`: Path to input data
   - `--output` / `-o`: Path for output (trained model or predictions)
   - Additional function-specific arguments as needed

3. **JSON integration:** Use `jsonlite::fromJSON()` to parse configuration files

4. **Template generator:** Provide helper function to scaffold CLI scripts

### Example: CHAP Model CLI Structure

```r
#!/usr/bin/env Rscript

library(optparse)
library(jsonlite)
library(chapr)  # CHAP R SDK

# Define the training function
my_train <- function(training_data, model_config) {
  # Model training logic
  model <- list(...)
  return(model)
}

# Use CHAP SDK to create CLI
option_list <- list(
  make_option(c("-d", "--data"), type="character",
              help="Path to training data CSV", metavar="FILE"),
  make_option(c("-c", "--config"), type="character",
              help="Path to model configuration JSON", metavar="FILE"),
  make_option(c("-o", "--output"), type="character", default="model.rds",
              help="Output path for trained model")
)

opt_parser <- OptionParser(
  usage = "%prog train [options]",
  option_list = option_list,
  description = "Train CHAP model"
)

opt <- parse_args(opt_parser)

# Validate arguments
if (is.null(opt$data) || is.null(opt$config)) {
  print_help(opt_parser)
  stop("Both --data and --config are required")
}

# Load data and config
training_data <- read.csv(opt$data)
model_config <- fromJSON(opt$config)

# Train model
model <- my_train(training_data, model_config)

# Save model
saveRDS(model, opt$output)
cat(sprintf("Model saved to %s\n", opt$output))
```

## Consequences

### Positive

- Clean, maintainable command-line interfaces
- No external language dependencies to manage
- Fast performance
- Easy for R developers to learn and use
- Consistent patterns across all CHAP models

### Negative

- Limited positional argument support (mitigated by using named arguments)
- Need to write some boilerplate (can be reduced with SDK helper functions)

### Neutral

- Team needs to learn optparse API (but it's simple and well-documented)

## References

- [Stack Overflow: Parsing command line arguments in R scripts](https://stackoverflow.com/questions/3433603/parsing-command-line-arguments-in-r-scripts)
- [CRAN: optparse package](https://cran.r-project.org/web/packages/optparse/readme/README.html)
- [GitHub: r-optparse](https://github.com/trevorld/r-optparse)
- [Learn to Write Command Line Utilities in R](https://blog.sellorm.com/2017/12/30/command-line-utilities-in-r-pt-6/)
- [Parse command-line arguments comparison](https://jokergoo.github.io/2020/06/06/parse-command-line-arguments/)
- [CRAN: configr package for config files](https://cran.r-project.org/web/packages/configr/vignettes/configr.html)

## Next Steps

1. Create wrapper functions in CHAP R SDK to simplify optparse usage
2. Document CLI patterns and best practices
3. Create example implementations for train and predict functions
4. Write tests for CLI argument parsing
5. Create CLI script generator/template tool
