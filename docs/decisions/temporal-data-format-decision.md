# Temporal Data Format Decision: Weekly and Monthly Data in R

**Date:** 2025-12-03
**Status:** Decided
**Issue:** CLIM-208
**Related:** CLIM-205 (Spatio-Temporal Data Transformations)

## Context

The CHAP R SDK needs to handle spatio-temporal data at various temporal resolutions, including weekly and monthly aggregations. This decision document addresses how to represent temporal data in R tibbles for these resolutions.

## Research Questions

1. What should be the format of the date/time column in tibbles for weekly data?
2. What should be the format of the date/time column in tibbles for monthly data?
3. Should we use Date, POSIXct, or specialized temporal classes?
4. How do common R packages handle these temporal resolutions?
5. What are the trade-offs between different approaches?

## Background: Available Temporal Classes in R

### Base R Classes

#### 1. Date
- **Storage:** Number of days since January 1, 1970
- **Use case:** Date-only data without time components
- **Pros:** Simple, lightweight, widely supported
- **Cons:** Treats all months/weeks as having irregular day counts (28-31 days)

#### 2. POSIXct (Calendar Time)
- **Storage:** Number of seconds since January 1, 1970
- **Use case:** Date-time data with timezone support
- **Pros:** Efficient storage, standard format
- **Cons:** More complex than needed for date-only data, irregular month/week lengths

#### 3. POSIXlt (Local Time)
- **Storage:** List with components (second, minute, hour, day, month, year, etc.)
- **Use case:** When you need direct access to time components
- **Pros:** Direct component access
- **Cons:** Computationally expensive in data frames, not recommended for tibbles

### Specialized Classes (tsibble package)

The `tsibble` package from the tidyverts ecosystem provides specialized temporal classes designed for regular time series:

#### 4. yearweek
- **Storage:** Weeks counted from a reference point
- **Use case:** Weekly time series data
- **Standard:** Based on ISO 8601
- **Pros:** Ensures regularity (52-53 weeks per year), proper week boundaries

#### 5. yearmonth
- **Storage:** Months counted from a reference point
- **Use case:** Monthly time series data
- **Pros:** Ensures regularity (exactly 12 months per year), proper month boundaries

#### 6. yearquarter
- **Storage:** Quarters counted from a reference point
- **Use case:** Quarterly time series data
- **Pros:** Ensures regularity (exactly 4 quarters per year)

## Analysis

### The Regularity Problem

A critical issue with using `Date` or `POSIXct` for monthly/weekly data is **irregular temporal spacing**:

- **Months:** Range from 28 to 31 days, creating irregular intervals when stored as dates
- **Weeks:** Can span across month/year boundaries in inconsistent ways
- **Impact:** Affects time series operations, aggregations, and forecasting algorithms that assume regular intervals

The tsibble package documentation explicitly addresses this:

> "For a `tbl_ts` of regular interval, a choice of index representation has to be made. For example, a monthly data should correspond to time index created by `yearmonth`, instead of Date or POSIXct. Because months in a year ensures the regularity, 12 months every year. However, if using Date, a month containing days ranges from 28 to 31 days, which results in irregular time space."

### Package Ecosystem Considerations

The tidyverts ecosystem provides comprehensive tools for tidy time series analysis:

- **tsibble:** Temporal data structures with `yearweek`, `yearmonth`, `yearquarter`
- **feasts:** Visualization and feature extraction
- **fable:** Forecasting methods (ARIMA, ETS, etc.)
- **lubridate integration:** Works seamlessly with `index_by()` for aggregation

This ecosystem is actively maintained and follows tidyverse design principles, making it a natural fit for the CHAP R SDK.

## Decision

### For Weekly Data: Use `tsibble::yearweek`

**Recommendation:** Use `tsibble::yearweek` for all weekly temporal data in the CHAP R SDK.

**Rationale:**
1. **Regularity:** Ensures proper weekly intervals (52-53 weeks/year)
2. **ISO 8601 compliance:** Follows international standard for week numbering
3. **Tidyverse compatibility:** Integrates seamlessly with dplyr and tidyr operations
4. **Time series operations:** Designed for regular time series analysis and forecasting
5. **Visualization:** Native ggplot2 scales (`scale_x_yearweek()`)

**Format:** `YYYY Wxx` (e.g., "2024 W01", "2024 W52")

### For Monthly Data: Use `tsibble::yearmonth`

**Recommendation:** Use `tsibble::yearmonth` for all monthly temporal data in the CHAP R SDK.

**Rationale:**
1. **Regularity:** Ensures exactly 12 months per year
2. **Consistency:** Each month is treated as a unit regardless of day count
3. **Tidyverse compatibility:** Works with standard dplyr operations
4. **Time series operations:** Designed for monthly time series and forecasting
5. **Aggregation:** Simplifies monthly aggregation from daily/weekly data
6. **Visualization:** Native ggplot2 scales (`scale_x_yearmonth()`)

**Format:** `YYYY Mon` (e.g., "2024 Jan", "2024 Dec")

### Alternative: When to Use Date or POSIXct

There are specific scenarios where base R classes remain appropriate:

**Use `Date` when:**
- Working with daily data
- Interfacing with systems that require standard date formats
- Converting between temporal resolutions (as an intermediate step)
- Storage in databases that don't support custom classes

**Use `POSIXct` when:**
- Working with sub-daily data (hourly, minute-level)
- Timezone handling is critical
- Timestamps are more important than temporal aggregation

**Note:** Even in these cases, consider converting to `yearweek`/`yearmonth` for time series operations.

## Implementation Guidelines

### Dependencies

Add to `DESCRIPTION`:

```r
Imports:
    tsibble (>= 1.1.0),
    lubridate (>= 1.9.0)
```

### Creating Temporal Indices

#### Weekly Data

```r
library(tsibble)
library(lubridate)
library(dplyr)

# From dates
dates <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "week")
weekly_index <- yearweek(dates)

# From character strings
weekly_index <- yearweek("2024 W01")

# From year and week components
weekly_index <- yearweek(year = 2024, week = 1)

# Create a tsibble with weekly data
weekly_data <- tibble(
  week = yearweek(dates),
  location_id = rep(c("A", "B"), each = length(dates)),
  cases = rpois(length(dates) * 2, lambda = 10)
) %>%
  as_tsibble(key = location_id, index = week)
```

#### Monthly Data

```r
# From dates
dates <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "month")
monthly_index <- yearmonth(dates)

# From character strings
monthly_index <- yearmonth("2024 Jan")

# From year and month components
monthly_index <- yearmonth(year = 2024, month = 1)

# Create a tsibble with monthly data
monthly_data <- tibble(
  month = yearmonth(dates),
  location_id = rep(c("A", "B"), each = length(dates)),
  cases = rpois(length(dates) * 2, lambda = 100)
) %>%
  as_tsibble(key = location_id, index = month)
```

### Aggregating to Weekly/Monthly

#### Daily to Weekly

```r
library(tsibble)

daily_data <- tibble(
  date = seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day"),
  location_id = "A",
  cases = rpois(366, lambda = 5)
) %>%
  as_tsibble(key = location_id, index = date)

# Aggregate to weekly
weekly_data <- daily_data %>%
  index_by(week = yearweek(date)) %>%
  summarise(
    cases = sum(cases),
    .groups = "drop"
  )
```

#### Daily to Monthly

```r
# Aggregate to monthly
monthly_data <- daily_data %>%
  index_by(month = yearmonth(date)) %>%
  summarise(
    cases = sum(cases),
    .groups = "drop"
  )
```

#### Weekly to Monthly

```r
# Convert weekly to monthly
# Note: Handle week-to-month boundaries appropriately for your use case
weekly_to_monthly <- weekly_data %>%
  mutate(month = yearmonth(week)) %>%
  index_by(month) %>%
  summarise(
    cases = sum(cases),
    .groups = "drop"
  )
```

### Working with Temporal Data

#### Arithmetic Operations

```r
# Add/subtract months
current_month <- yearmonth("2024 Jan")
next_month <- current_month + 1  # 2024 Feb
last_year_same_month <- current_month - 12  # 2023 Jan

# Add/subtract weeks
current_week <- yearweek("2024 W01")
next_week <- current_week + 1  # 2024 W02
four_weeks_ago <- current_week - 4  # 2023 W50
```

#### Sequences

```r
# Monthly sequence
month_seq <- seq(
  yearmonth("2024 Jan"),
  yearmonth("2024 Dec"),
  by = 1
)

# Weekly sequence
week_seq <- seq(
  yearweek("2024 W01"),
  yearweek("2024 W52"),
  by = 1
)
```

#### Conversion and Formatting

```r
# Convert to Date (first day of period)
as.Date(yearmonth("2024 Jan"))  # 2024-01-01
as.Date(yearweek("2024 W01"))   # 2024-01-01

# Format for display
format(yearmonth("2024 Jan"), format = "%Y-%m")  # "2024-01"
format(yearweek("2024 W01"), format = "%Y-W%V")  # "2024-W01"

# Extract components
yw <- yearweek("2024 W15")
year(yw)   # 2024
week(yw)   # 15
```

### Visualization with ggplot2

```r
library(ggplot2)

# Monthly data visualization
ggplot(monthly_data, aes(x = month, y = cases)) +
  geom_line() +
  scale_x_yearmonth(date_labels = "%Y %b") +
  labs(title = "Monthly Cases", x = "Month", y = "Cases")

# Weekly data visualization
ggplot(weekly_data, aes(x = week, y = cases)) +
  geom_line() +
  scale_x_yearweek(date_labels = "%Y W%V") +
  labs(title = "Weekly Cases", x = "Week", y = "Cases")
```

### Converting Between Formats

When interfacing with external systems or databases that require standard date formats:

```r
# tsibble to Date (for export)
monthly_data_export <- monthly_data %>%
  mutate(date_export = as.Date(month))

# Date to tsibble (for import)
imported_data <- read_csv("data.csv") %>%
  mutate(month = yearmonth(date)) %>%
  select(-date) %>%
  as_tsibble(key = location_id, index = month)
```

## Trade-offs and Considerations

### Advantages of yearweek/yearmonth

✅ **Regularity:** Ensures consistent temporal spacing for time series operations
✅ **Type safety:** Prevents mixing of temporal resolutions
✅ **Tidyverse integration:** Works seamlessly with dplyr, tidyr, ggplot2
✅ **Time series tools:** Designed for forecasting and time series analysis
✅ **Clear semantics:** Makes temporal resolution explicit in code
✅ **ISO standards:** Follows international standards (ISO 8601 for weeks)

### Potential Challenges

⚠️ **Learning curve:** Developers need to learn tsibble classes
⚠️ **External compatibility:** May need conversion when interfacing with non-R systems
⚠️ **Dependency:** Adds tsibble as a required dependency
⚠️ **Storage:** Some databases may not natively support these classes (requires conversion)

### Mitigation Strategies

1. **Documentation:** Provide clear examples and conversion utilities
2. **Helper functions:** Create SDK functions for common conversions
3. **Validation:** Include checks to ensure proper temporal class usage
4. **Testing:** Comprehensive tests for temporal operations and conversions

## Impact on CHAP R SDK

### Affected Components

1. **CLI Interface Creation** (CLIM-202)
   - Input data validation should check for proper temporal classes
   - Conversion utilities for train/predict functions

2. **Model Validation** (CLIM-203)
   - Test suite should verify temporal regularity
   - Validate temporal index consistency

3. **Spatio-temporal Data Utilities** (CLIM-205)
   - Core transformations will use yearweek/yearmonth
   - Aggregation functions will leverage index_by()

4. **Configuration Schema** (CLIM-206)
   - Schema should specify temporal resolution
   - Validation of temporal format consistency

### Implementation Priorities

1. **High Priority:**
   - Add tsibble to package dependencies
   - Document temporal format requirements
   - Create conversion helper functions

2. **Medium Priority:**
   - Implement aggregation utilities using index_by()
   - Add temporal validation to model validation suite
   - Create examples for common temporal operations

3. **Low Priority:**
   - Advanced temporal features (lag, differencing, etc.)
   - Integration with forecasting packages (fable)

## Code Examples

### Complete Example: Processing Spatio-Temporal Data

```r
library(tidyverse)
library(tsibble)
library(lubridate)

# Simulate daily disease surveillance data
set.seed(42)
daily_surveillance <- tibble(
  date = rep(seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day"), times = 3),
  location_id = rep(c("Region_A", "Region_B", "Region_C"), each = 366),
  cases = rpois(366 * 3, lambda = 10),
  population = rep(c(100000, 150000, 120000), each = 366)
) %>%
  as_tsibble(key = location_id, index = date)

# Convert to weekly data
weekly_surveillance <- daily_surveillance %>%
  index_by(week = yearweek(date)) %>%
  summarise(
    cases = sum(cases),
    population = first(population),  # Assuming constant population
    .groups = "drop"
  ) %>%
  mutate(
    incidence_rate = (cases / population) * 100000
  )

# Convert to monthly data
monthly_surveillance <- daily_surveillance %>%
  index_by(month = yearmonth(date)) %>%
  summarise(
    cases = sum(cases),
    population = first(population),
    .groups = "drop"
  ) %>%
  mutate(
    incidence_rate = (cases / population) * 100000
  )

# Calculate 4-week moving average
weekly_ma <- weekly_surveillance %>%
  group_by(location_id) %>%
  mutate(
    cases_ma4 = slider::slide_dbl(cases, mean, .before = 3, .complete = TRUE)
  ) %>%
  ungroup()

# Visualize weekly trends
ggplot(weekly_surveillance, aes(x = week, y = incidence_rate, color = location_id)) +
  geom_line() +
  scale_x_yearweek(date_labels = "%Y W%V", date_breaks = "8 weeks") +
  labs(
    title = "Weekly Disease Incidence by Region",
    x = "Week",
    y = "Incidence Rate (per 100,000)",
    color = "Region"
  ) +
  theme_minimal()
```

### Example: CHAP Model Integration

```r
# Example model training function compatible with CHAP
train_model <- function(training_data, model_configuration) {
  # Validate temporal format
  if (!inherits(index(training_data), "yearweek") &&
      !inherits(index(training_data), "yearmonth")) {
    stop("Training data must use yearweek or yearmonth temporal index")
  }

  # Ensure data is a tsibble
  if (!is_tsibble(training_data)) {
    stop("Training data must be a tsibble")
  }

  # Model training logic here
  # ...

  return(model)
}

# Example prediction function
predict_model <- function(historic_data, future_data, saved_model, model_configuration) {
  # Validate temporal consistency
  if (class(index(historic_data)) != class(index(future_data))) {
    stop("Historic and future data must have the same temporal class")
  }

  # Ensure temporal continuity
  last_historic <- max(index(historic_data))
  first_future <- min(index(future_data))

  if (first_future != last_historic + 1) {
    warning("Gap or overlap detected between historic and future data")
  }

  # Prediction logic here
  # ...

  return(predictions)
}
```

## Recommendations for CHAP R SDK

### 1. Enforce Temporal Classes

The SDK should:
- Require `yearweek` for weekly data
- Require `yearmonth` for monthly data
- Allow `Date` only for daily data
- Provide clear error messages when incorrect classes are used

### 2. Provide Conversion Utilities

```r
# Suggested helper functions for the SDK

#' Convert data to weekly tsibble
#' @export
to_weekly_tsibble <- function(data, date_col, key_vars = NULL) {
  data %>%
    mutate(week = yearweek({{ date_col }})) %>%
    select(-{{ date_col }}) %>%
    as_tsibble(key = all_of(key_vars), index = week)
}

#' Convert data to monthly tsibble
#' @export
to_monthly_tsibble <- function(data, date_col, key_vars = NULL) {
  data %>%
    mutate(month = yearmonth({{ date_col }})) %>%
    select(-{{ date_col }}) %>%
    as_tsibble(key = all_of(key_vars), index = month)
}

#' Validate temporal data format
#' @export
validate_temporal_format <- function(data, expected_class = c("yearweek", "yearmonth", "Date")) {
  if (!is_tsibble(data)) {
    stop("Data must be a tsibble")
  }

  idx_class <- class(index(data))[1]
  expected_class <- match.arg(expected_class)

  if (idx_class != expected_class) {
    stop(sprintf("Expected temporal index of class '%s', got '%s'",
                 expected_class, idx_class))
  }

  invisible(TRUE)
}
```

### 3. Documentation Standards

All CHAP R SDK functions should:
- Explicitly document expected temporal classes in `@param` tags
- Include examples with `yearweek`/`yearmonth` usage
- Provide guidance on when to use each temporal class
- Show conversion examples for common scenarios

### 4. Validation Tests

The validation test suite (CLIM-203) should include:
- Tests for temporal regularity
- Tests for temporal continuity
- Tests for proper class usage
- Tests for conversion correctness

## Conclusion

The CHAP R SDK should standardize on `tsibble::yearweek` and `tsibble::yearmonth` for weekly and monthly temporal data, respectively. This decision:

1. **Ensures regularity:** Critical for time series operations and forecasting
2. **Follows best practices:** Aligns with modern R time series ecosystem (tidyverts)
3. **Provides type safety:** Makes temporal resolution explicit and prevents errors
4. **Enables powerful tools:** Unlocks the full tidyverts ecosystem for time series analysis
5. **Maintains tidyverse compatibility:** Works seamlessly with dplyr, ggplot2, and other tidyverse packages

While this requires learning new classes and adds a dependency, the benefits for time series operations and data integrity far outweigh the costs. The SDK should provide clear documentation, conversion utilities, and validation functions to ease adoption.

## References

### Documentation
- [tsibble package documentation](https://tsibble.tidyverts.org/)
- [Forecasting: Principles and Practice - tsibbles](https://otexts.com/fpp3/tsibbles.html)
- [Introduction to tsibble vignette](https://cran.rstudio.com/web/packages/tsibble/vignettes/intro-tsibble.html)
- [yearweek documentation](https://tsibble.tidyverts.org/reference/year-week.html)
- [yearmonth documentation](https://tsibble.tidyverts.org/reference/year-month.html)

### Related Packages
- [tsibble on CRAN](https://cloud.r-project.org/web/packages/tsibble/)
- [feasts (Feature Extraction And Statistics for Time Series)](https://feasts.tidyverts.org/)
- [fable (Forecasting Models for Tidy Time Series)](https://fable.tidyverts.org/)
- [lubridate documentation](https://lubridate.tidyverse.org/)

### Time Classes in R
- [R for Data Science - Dates and times](https://r4ds.had.co.nz/dates-and-times.html)
- [NEON Tutorial: Dates & Times in R](https://www.neonscience.org/resources/learning-hub/tutorials/dc-convert-date-time-posix-r)
- [UC Berkeley: Dates and Times in R](https://www.stat.berkeley.edu/~s133/dates.html)
- [CRAN Task View: Time Series Analysis](https://cran.rstudio.com/web/views/TimeSeries.html)

### Stack Overflow Discussions
- [Aggregate data frame to typical year/week](https://stackoverflow.com/questions/53800461/aggregate-data-frame-to-typical-year-week)
- [Earth Data Science: Aggregate Time Series Data in R](https://earthdatascience.org/courses/earth-analytics/time-series-data/aggregate-time-series-data-r/)

## Change Log

- 2025-12-03: Initial decision document created (CLIM-208)
