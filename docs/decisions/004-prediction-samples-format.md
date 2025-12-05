# ADR 004: Prediction Samples Data Format

**Status:** Accepted
**Date:** 2025-12-05
**Decision Makers:** CHAP R SDK Team
**Related Jira:** CLIM-201 (CHAP R SDK Development)

## Context

CHAP models typically produce probabilistic forecasts represented as Monte Carlo samples (e.g., 1000 samples per time period × location combination). The SDK needs to define how these prediction samples should be represented in R, balancing:

1. Memory efficiency for large sample sizes
2. Compatibility with tidyverse/tsibble ecosystem
3. Ease of downstream analysis (quantiles, scoring, visualization)
4. Integration with existing epidemiological forecasting tools
5. Consistency with the current CHAP platform expectations

### Current State

The existing CHAP predictions CSV format uses a **wide format**:

```
time_period,location,sample_0,sample_1,sample_2,...,sample_999
2013-04,Bokeo,15,7,3,...,2
2013-05,Bokeo,20,36,8,...,35
```

This format has:
- One row per (time_period, location) combination
- 1000 columns for samples (`sample_0` through `sample_999`)
- Compact row count but wide column structure

### EWARS Model Internal Flow

Looking at `examples/ewars_model/predict.R`, the current workflow uses:

1. **Input:** Standard `data.frame` from CSV
2. **Computation:** Samples stored as `matrix(NA, n_forecast_units, 1000)`
3. **INLA sampling:** `inla.posterior.sample()` returns parameter samples
4. **Prediction:** Loop fills matrix column-by-column with `rnbinom()` samples
5. **Output:** Matrix converted to wide `data.frame` for CSV

```r
# Internal matrix format (efficient for computation)
y.pred <- matrix(NA, mpred, s)  # mpred rows × 1000 columns
for (s.idx in 1:s) {
  y.pred[, s.idx] <- rnbinom(mpred, mu = exp(xx.sample[-1]), size = xx.sample[1])
}

# Convert to wide data.frame for output
new.df <- data.frame(time_period, location, y.pred)
colnames(new.df) <- c('time_period', 'location', paste0('sample_', 0:(s-1)))
```

This reveals that **internally, samples are already stored as vectors/matrices** - the nested list-column format is essentially a tidyverse-friendly wrapper around this natural representation.

## Options Considered

### Option 1: Wide Format (Current CHAP Format)

**Structure:**
```r
tibble(
  time_period = c("2013-04", "2013-05"),
  location = c("Bokeo", "Bokeo"),
  sample_0 = c(15, 20),
  sample_1 = c(7, 36),
  # ... sample_2 through sample_999
)
```

**Pros:**
- Already used by CHAP platform (no format conversion needed)
- Compact row count (N rows for N forecast units)
- Easy to compute row-wise statistics (mean, quantiles per forecast unit)
- Efficient storage in CSV files
- Simple mental model for epidemiologists familiar with spreadsheets

**Cons:**
- Awkward for tidyverse operations (need `pivot_longer` for most analyses)
- Column names are not self-documenting (sample_0 vs sample index)
- Harder to subset specific samples
- tsibble can't use samples as key (too many columns)
- Reading/writing 1000+ columns can be slow

**Memory:** ~8 bytes × 1000 samples × N forecast units

---

### Option 2: Long Format (scoringutils Style)

**Structure:**
```r
tibble(
  time_period = rep("2013-04", 1000),
  location = rep("Bokeo", 1000),
  sample_id = 1:1000,
  prediction = c(15, 7, 3, ...)
)
```

**Pros:**
- Native tidyverse compatibility (group_by, filter, etc.)
- Direct integration with scoringutils package for forecast evaluation
- Explicit sample identification
- Easy to subset specific samples
- Standard format for hubverse/CDC forecast hubs
- Simple to understand and manipulate

**Cons:**
- Memory intensive: 1000× more rows than wide format
- Example: 21 forecast units × 1000 samples = 21,000 rows (vs 21 rows wide)
- Requires conversion from current CHAP format
- Slower for row-wise operations across samples

**Memory:** ~32 bytes × 1000 samples × N forecast units (due to repeated metadata)

---

### Option 3: Nested List-Column Format

**Structure:**
```r
tibble(
  time_period = c("2013-04", "2013-05"),
  location = c("Bokeo", "Bokeo"),
  samples = list(
    c(15, 7, 3, ...),  # numeric vector of 1000 samples
    c(20, 36, 8, ...)
  )
)
```

**Pros:**
- Compact representation (N rows)
- Tidyverse compatible with `map()` operations
- Samples grouped naturally by forecast unit
- Memory efficient (no repeated metadata)
- Clean separation of metadata and samples
- Can be converted to tsibble

**Cons:**
- Requires understanding of list-columns
- Need `unnest()` for some tidyverse operations
- Not standard in epidemiological forecasting
- Custom code needed for scoring/visualization

**Memory:** ~8 bytes × 1000 samples × N forecast units + small overhead

---

### Option 4: Distributional Objects (fable/distributional Package)

**Structure:**
```r
library(distributional)

tibble(
  time_period = yearmonth(c("2013-04", "2013-05")),
  location = c("Bokeo", "Bokeo"),
  .distribution = dist_sample(list(
    c(15, 7, 3, ...),
    c(20, 36, 8, ...)
  ))
)
```

**Pros:**
- Native integration with fable forecasting ecosystem
- Clean API for extracting quantiles, generating samples
- Excellent visualization support with ggdist
- Type-safe distribution objects
- Supports both parametric and sample-based distributions
- Memory efficient

**Cons:**
- Requires learning distributional package API
- Additional dependency (distributional, fable)
- Samples are opaque (hidden inside objects)
- Not standard in epidemiological forecasting
- Conversion needed for scoringutils

**Memory:** Similar to nested list-column

---

### Option 5: Quantile Format (Hub Standard)

**Structure:**
```r
tibble(
  time_period = rep("2013-04", 7),
  location = rep("Bokeo", 7),
  quantile = c(0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975),
  value = c(2, 3, 7, 12, 18, 35, 45)
)
```

**Pros:**
- Extremely compact (23 rows vs 1000 samples)
- Standard format for CDC, European forecast hubs
- Direct use for interval forecasts
- Compatible with most scoring functions
- Efficient storage and transmission

**Cons:**
- **Information loss** - cannot recover original samples
- Cannot compute arbitrary statistics (e.g., P(cases > threshold))
- Cannot preserve sample dependencies across locations/horizons
- Quantile levels must be pre-specified
- Not suitable when full distribution is needed

**Memory:** ~32 bytes × 23 quantiles × N forecast units

---

## Comparative Analysis

| Criterion | Wide | Long | Nested | Distributional | Quantile |
|-----------|------|------|--------|----------------|----------|
| Memory efficiency | Good | Poor | Good | Good | Excellent |
| Tidyverse compatibility | Moderate | Excellent | Good | Good | Good |
| scoringutils integration | Moderate | Excellent | Moderate | Moderate | Good |
| Visualization (ggdist) | Moderate | Good | Moderate | Excellent | Good |
| CHAP compatibility | Excellent | Moderate | Moderate | Moderate | Moderate |
| Sample manipulation | Poor | Excellent | Good | Moderate | N/A |
| Row-wise statistics | Excellent | Moderate | Good | Excellent | N/A |
| Learning curve | Low | Low | Moderate | High | Low |

**Rows for 21 forecast units × 1000 samples:**
- Wide: 21 rows (1002 columns)
- Long: 21,000 rows (4 columns)
- Nested: 21 rows (3 columns)
- Distributional: 21 rows (3 columns)
- Quantile: 483 rows (4 columns, 23 quantiles)

## Recommendation

### Primary Decision: Nested List-Column Format (Internal)

For the CHAP R SDK internal representation, use **nested list-columns**:

```r
predictions <- tibble(
  time_period = yearmonth(c("2013-04", "2013-05", "2013-06")),
  location = c("Bokeo", "Bokeo", "Bokeo"),
  samples = list(
    c(15, 7, 3, 9, ...),   # 1000 numeric values
    c(20, 36, 8, 21, ...),
    c(124, 15, 18, 40, ...)
  )
) |>
  as_tsibble(index = time_period, key = location)
```

**Rationale:**
1. **Memory efficient** - no repeated metadata
2. **Tidyverse compatible** - works with dplyr, purrr
3. **tsibble compatible** - can use as forecast table
4. **Flexible** - easy conversion to other formats
5. **Clear semantics** - samples are explicitly grouped

### Secondary Decision: Provide Format Converters

The SDK should provide conversion functions for interoperability:

```r
# Convert from CHAP wide CSV format to nested format
predictions_from_wide <- function(wide_df) {

# Read sample columns, nest into list-column
}

# Convert to CHAP wide CSV format for output
predictions_to_wide <- function(nested_df) {
# Unnest samples into separate columns
}

# Convert to long format for scoringutils
predictions_to_long <- function(nested_df) {
# Unnest with sample_id column
}

# Convert to quantiles for hub submission
predictions_to_quantiles <- function(nested_df, probs = c(0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975)) {
# Compute quantiles from samples
}

# Compute summary statistics
predictions_summary <- function(nested_df) {
# Add mean, median, CI columns
}
```

### Tertiary Decision: Update CLI to Handle Samples

The `create_chap_cli()` predict handler should:

1. **Output wide format** (current CHAP expectation) by default
2. Support `--output-format` flag for alternative formats
3. Automatically detect nested list-column output from predict functions
4. Convert to wide CSV for file output

## Implementation Plan

### Phase 1: Core Data Structures

1. Define `chap_predictions` S3 class with nested samples
2. Implement validation for prediction structure
3. Add to existing validation framework

### Phase 2: Format Converters

1. `predictions_from_wide()` - load CHAP CSV format
2. `predictions_to_wide()` - save to CHAP CSV format
3. `predictions_to_long()` - convert for scoringutils
4. `predictions_to_quantiles()` - compute quantile summary

### Phase 3: CLI Integration

1. Update `handle_predict()` to detect sample output
2. Add format conversion on output
3. Support `--output-format` option

### Phase 4: Documentation & Examples

1. Update tutorial vignette with sample handling
2. Add examples to function documentation
3. Document format conversion workflows

## Example Usage

### Model Producing Samples

```r
predict_fn <- function(historic_data, future_data, model, config = list()) {
  n_samples <- 1000

  future_data |>
    as_tibble() |>
    rowwise() |>
    mutate(
      samples = list(rpois(n_samples, lambda = model$mean_by_location[[location]]))
    ) |>
    ungroup()
}
```

### Computing Quantiles

```r
predictions |>
  mutate(
    mean = map_dbl(samples, mean),
    median = map_dbl(samples, median),
    q025 = map_dbl(samples, ~quantile(.x, 0.025)),
    q975 = map_dbl(samples, ~quantile(.x, 0.975))
  )
```

### Converting to Long Format for Scoring

```r
predictions_long <- predictions |>
  mutate(sample_id = map(samples, seq_along)) |>
  unnest(c(samples, sample_id)) |>
  rename(prediction = samples)

# Use with scoringutils
scoringutils::score(predictions_long, ...)
```

## Consequences

### Positive

- Clean internal representation that works with tidyverse
- Memory efficient for large sample sizes
- Flexible conversion to any output format
- Maintains compatibility with CHAP platform
- Enables rich downstream analysis

### Negative

- Developers need to understand list-columns
- Extra conversion step when interfacing with other tools
- Some boilerplate for format conversion

### Neutral

- Adds several new functions to the package
- Requires documentation of format conventions

## References

- [scoringutils package](https://epiforecasts.io/scoringutils/)
- [distributional package](https://pkg.mitchelloharawild.com/distributional/)
- [fable package](https://fable.tidyverts.org/)
- [Hubverse model output format](https://docs.hubverse.io/en/latest/user-guide/model-output.html)
- [CDC COVID-19 Forecast Hub](https://github.com/CDCgov/covid19-forecast-hub)
- [tidyr nested data](https://tidyr.tidyverse.org/articles/nest.html)
- [ggdist package](https://mjskay.github.io/ggdist/)

## Change Log

- 2025-12-05: Initial investigation and decision document
- 2025-12-05: Accepted. All models must use samples format (even deterministic models with single sample)
