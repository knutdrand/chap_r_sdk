# Working with Spatio-Temporal Data

This tutorial shows how to work with spatio-temporal data in CHAP models
using established R packages. Rather than reinventing the wheel, we
leverage the excellent tidyverse ecosystem.

## Recommended Packages

| Package        | Purpose                              | Install                          |
|----------------|--------------------------------------|----------------------------------|
| **tsibble**    | Temporal data structures             | `install.packages("tsibble")`    |
| **fabletools** | Temporal aggregation, reconciliation | `install.packages("fabletools")` |
| **sf**         | Spatial data and operations          | `install.packages("sf")`         |
| **cubble**     | Spatio-temporal data wrangling       | `install.packages("cubble")`     |

``` r
library(chap.r.sdk)
library(dplyr)
library(tidyr)
library(tsibble)
```

## Working with CHAP Example Data

Let’s start with the example data from the SDK:

``` r
data <- get_example_data('laos', 'M')
training_data <- data$training_data

# Examine the structure
training_data
#> # A tsibble: 1,057 x 13 [1M]
#> # Key:       location [7]
#>     ...1 time_period rainfall mean_temperature disease_cases population parent
#>    <dbl>       <mth>    <dbl>            <dbl>         <dbl>      <dbl> <chr> 
#>  1     0    2000 Jul   430.               23.4             0     58503. -     
#>  2     1    2000 Aug   322.               23.8             0     58503. -     
#>  3     2    2000 Sep   265.               22.7             0     58503. -     
#>  4     3    2000 Oct   103.               22.6             0     58503. -     
#>  5     4    2000 Nov    19.7              20.3             0     58503. -     
#>  6     5    2000 Dec    26.0              19.1             0     58503. -     
#>  7     6    2001 Jan    17.6              19.8             0     60157. -     
#>  8     7    2001 Feb     7.28             22.0             0     60157. -     
#>  9     8    2001 Mar   123.               22.6             0     60157. -     
#> 10     9    2001 Apr    29.6              27.5             0     60157. -     
#> # ℹ 1,047 more rows
#> # ℹ 6 more variables: location <chr>, Cases <dbl>, E <dbl>, month <dbl>,
#> #   ID_year <dbl>, ID_spat <chr>
```

The data is already a tsibble with: - `time_period` as the temporal
index (monthly) - `location` as the spatial key - `disease_cases` as the
target variable - Various covariates (rainfall, temperature, population)

## Temporal Operations with tsibble

### Lag Features

Create lagged versions of variables for time series modeling:

``` r
# Add lagged disease cases (1 and 2 months ago)
training_with_lags <- training_data |>
  group_by_key() |>
  mutate(
    cases_lag1 = lag(disease_cases, 1),
    cases_lag2 = lag(disease_cases, 2),
    rainfall_lag1 = lag(rainfall, 1)
  ) |>
  ungroup()

training_with_lags |>
  select(time_period, location, disease_cases, cases_lag1, cases_lag2) |>
  head(10)
#> # A tsibble: 10 x 5 [1M]
#> # Key:       location [1]
#>    time_period location disease_cases cases_lag1 cases_lag2
#>          <mth> <chr>            <dbl>      <dbl>      <dbl>
#>  1    2000 Jul Bokeo                0         NA         NA
#>  2    2000 Aug Bokeo                0          0         NA
#>  3    2000 Sep Bokeo                0          0          0
#>  4    2000 Oct Bokeo                0          0          0
#>  5    2000 Nov Bokeo                0          0          0
#>  6    2000 Dec Bokeo                0          0          0
#>  7    2001 Jan Bokeo                0          0          0
#>  8    2001 Feb Bokeo                0          0          0
#>  9    2001 Mar Bokeo                0          0          0
#> 10    2001 Apr Bokeo                0          0          0
```

### Rolling Window Statistics

Calculate moving averages and other rolling statistics using the slider
package:

``` r
# Rolling mean of disease cases (3-month window)
training_with_rolling <- training_data |>
  group_by_key() |>
  mutate(
    cases_ma3 = slider::slide_dbl(disease_cases, mean, .before = 2, .complete = TRUE),
    cases_max3 = slider::slide_dbl(disease_cases, max, .before = 2, .complete = TRUE)
  ) |>
  ungroup()

training_with_rolling |>
  select(time_period, location, disease_cases, cases_ma3, cases_max3) |>
  filter(location == "Bokeo") |>
  head(10)
#> # A tsibble: 10 x 5 [1M]
#> # Key:       location [1]
#>    time_period location disease_cases cases_ma3 cases_max3
#>          <mth> <chr>            <dbl>     <dbl>      <dbl>
#>  1    2000 Jul Bokeo                0        NA         NA
#>  2    2000 Aug Bokeo                0        NA         NA
#>  3    2000 Sep Bokeo                0         0          0
#>  4    2000 Oct Bokeo                0         0          0
#>  5    2000 Nov Bokeo                0         0          0
#>  6    2000 Dec Bokeo                0         0          0
#>  7    2001 Jan Bokeo                0         0          0
#>  8    2001 Feb Bokeo                0         0          0
#>  9    2001 Mar Bokeo                0         0          0
#> 10    2001 Apr Bokeo                0         0          0
```

### Differencing

Remove trends with differencing:

``` r
training_diff <- training_data |>
  group_by_key() |>
  mutate(
    cases_diff = difference(disease_cases, 1),
    cases_diff12 = difference(disease_cases, 12)  # Seasonal difference
  ) |>
  ungroup()

training_diff |>
  select(time_period, location, disease_cases, cases_diff, cases_diff12) |>
  filter(location == "Bokeo") |>
  head(15)
#> # A tsibble: 15 x 5 [1M]
#> # Key:       location [1]
#>    time_period location disease_cases cases_diff cases_diff12
#>          <mth> <chr>            <dbl>      <dbl>        <dbl>
#>  1    2000 Jul Bokeo                0         NA           NA
#>  2    2000 Aug Bokeo                0          0           NA
#>  3    2000 Sep Bokeo                0          0           NA
#>  4    2000 Oct Bokeo                0          0           NA
#>  5    2000 Nov Bokeo                0          0           NA
#>  6    2000 Dec Bokeo                0          0           NA
#>  7    2001 Jan Bokeo                0          0           NA
#>  8    2001 Feb Bokeo                0          0           NA
#>  9    2001 Mar Bokeo                0          0           NA
#> 10    2001 Apr Bokeo                0          0           NA
#> 11    2001 May Bokeo                0          0           NA
#> 12    2001 Jun Bokeo                1          1           NA
#> 13    2001 Jul Bokeo                1          0            1
#> 14    2001 Aug Bokeo                1          0            1
#> 15    2001 Sep Bokeo                1          0            1
```

### Handling Missing Values

tsibble provides tools for gap detection and filling:

``` r
# Check for gaps in the time series
has_gaps(training_data)
#> # A tibble: 7 × 2
#>   location              .gaps
#>   <chr>                 <lgl>
#> 1 Bokeo                 FALSE
#> 2 Champasak             FALSE
#> 3 LouangNamtha          FALSE
#> 4 Oudomxai              FALSE
#> 5 Savannakhet           FALSE
#> 6 Vientiane[prefecture] FALSE
#> 7 Xiangkhoang           FALSE

# Count gaps per location
count_gaps(training_data)
#> # A tibble: 0 × 4
#> # ℹ 4 variables: location <chr>, .from <mth>, .to <mth>, .n <int>
```

``` r
# If there were gaps, fill them:
filled_data <- training_data |>
  fill_gaps() |>
  group_by_key() |>
  tidyr::fill(disease_cases, .direction = "down") |>
  ungroup()
```

## Temporal Aggregation with fabletools

### Aggregate to Quarterly Data

``` r
library(fabletools)

# Convert monthly to quarterly
quarterly_data <- training_data |>
  index_by(quarter = yearquarter(time_period)) |>
  group_by(location) |>
  summarise(
    disease_cases = sum(disease_cases, na.rm = TRUE),
    rainfall = mean(rainfall, na.rm = TRUE),
    mean_temperature = mean(mean_temperature, na.rm = TRUE),
    population = mean(population, na.rm = TRUE)
  )

quarterly_data
#> # A tsibble: 357 x 6 [1Q]
#> # Key:       location [7]
#>    location quarter disease_cases rainfall mean_temperature population
#>    <chr>      <qtr>         <dbl>    <dbl>            <dbl>      <dbl>
#>  1 Bokeo    2000 Q3             0    339.              23.3     58503.
#>  2 Bokeo    2000 Q4             0     49.7             20.7     58503.
#>  3 Bokeo    2001 Q1             0     49.4             21.4     60157.
#>  4 Bokeo    2001 Q2             1    253.              24.8     60157.
#>  5 Bokeo    2001 Q3             3    337.              23.5     60157.
#>  6 Bokeo    2001 Q4             1     67.2             19.9     60157.
#>  7 Bokeo    2002 Q1             0     33.0             21.0     61812.
#>  8 Bokeo    2002 Q2             2    276.              24.6     61812.
#>  9 Bokeo    2002 Q3             1    370.              23.2     61812.
#> 10 Bokeo    2002 Q4             1    107.              20.0     61812.
#> # ℹ 347 more rows
```

### Aggregate to Yearly Data

``` r
yearly_data <- training_data |>
  as_tibble() |>
  mutate(year = lubridate::year(time_period)) |>
  group_by(location, year) |>
  summarise(
    total_cases = sum(disease_cases, na.rm = TRUE),
    mean_rainfall = mean(rainfall, na.rm = TRUE),
    .groups = "drop"
  )

yearly_data
#> # A tibble: 98 × 4
#>    location  year total_cases mean_rainfall
#>    <chr>    <dbl>       <dbl>         <dbl>
#>  1 Bokeo     2000           0          194.
#>  2 Bokeo     2001           5          177.
#>  3 Bokeo     2002           4          197.
#>  4 Bokeo     2003          20          147.
#>  5 Bokeo     2004           0          185.
#>  6 Bokeo     2005           4          175.
#>  7 Bokeo     2006           6          173.
#>  8 Bokeo     2007           1          170.
#>  9 Bokeo     2008         218          205.
#> 10 Bokeo     2009         709          160.
#> # ℹ 88 more rows
```

## Spatial Aggregation

### Aggregate Across Locations

Sometimes you need national-level totals from regional data:

``` r
# Aggregate all locations to national level
national_data <- training_data |>
  as_tibble() |>
  group_by(time_period) |>
  summarise(
    total_cases = sum(disease_cases, na.rm = TRUE),
    total_population = sum(population, na.rm = TRUE),
    mean_rainfall = weighted.mean(rainfall, population, na.rm = TRUE),
    mean_temperature = weighted.mean(mean_temperature, population, na.rm = TRUE)
  )

national_data |> head(10)
#> # A tibble: 10 × 5
#>    time_period total_cases total_population mean_rainfall mean_temperature
#>          <mth>       <dbl>            <dbl>         <dbl>            <dbl>
#>  1    2000 Jul         159         2269893.        389.               24.2
#>  2    2000 Aug         135         2269893.        380.               24.4
#>  3    2000 Sep         124         2269893.        294.               23.6
#>  4    2000 Oct          87         2269893.        143.               23.4
#>  5    2000 Nov          31         2269893.         22.4              21.5
#>  6    2000 Dec          25         2269893.         12.3              21.3
#>  7    2001 Jan          11         2304144.         11.7              22.3
#>  8    2001 Feb          19         2304144.          8.11             23.1
#>  9    2001 Mar          37         2304144.        119.               24.0
#> 10    2001 Apr          36         2304144.         54.6              27.5
```

### Hierarchical Aggregation

Create data at multiple levels for hierarchical forecasting:

``` r
# Assume we have a parent column for regional grouping
# Create hierarchical structure
hierarchical_data <- training_data |>
  as_tibble() |>
  group_by(time_period, parent) |>
  summarise(
    regional_cases = sum(disease_cases, na.rm = TRUE),
    regional_pop = sum(population, na.rm = TRUE),
    .groups = "drop"
  )

hierarchical_data |> head(10)
#> # A tibble: 10 × 4
#>    time_period parent regional_cases regional_pop
#>          <mth> <chr>           <dbl>        <dbl>
#>  1    2000 Jul -                 159     2269893.
#>  2    2000 Aug -                 135     2269893.
#>  3    2000 Sep -                 124     2269893.
#>  4    2000 Oct -                  87     2269893.
#>  5    2000 Nov -                  31     2269893.
#>  6    2000 Dec -                  25     2269893.
#>  7    2001 Jan -                  11     2304144.
#>  8    2001 Feb -                  19     2304144.
#>  9    2001 Mar -                  37     2304144.
#> 10    2001 Apr -                  36     2304144.
```

## Working with Spatial Data (sf)

If your data includes geographic coordinates or boundaries:

``` r
library(sf)

# Example: Create spatial features from coordinates
locations_sf <- tibble(
  location = c("Bokeo", "Luangprabang", "Oudomxay"),
  lon = c(100.5, 102.1, 101.5),
  lat = c(20.2, 19.9, 20.7)
) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

# Spatial join with administrative boundaries
# admin_boundaries <- st_read("boundaries.geojson")
# joined <- st_join(locations_sf, admin_boundaries)

# Calculate distances between locations
# distances <- st_distance(locations_sf)
```

## Spatio-Temporal Data with cubble

For more complex spatio-temporal analyses, the cubble package provides a
unified structure:

``` r
library(cubble)

# Create a cubble from separate spatial and temporal data
cb <- as_cubble(
  data = training_data,
  key = location,
  index = time_period,
  coords = c(lon, lat)  # if coordinates available
)

# Switch between spatial and temporal views
cb_temporal <- cb |> face_temporal()
cb_spatial <- cb |> face_spatial()

# Useful for linking maps with time series plots
```

## Feature Engineering for CHAP Models

Here’s a complete example of preparing features for a CHAP model:

``` r
prepare_features <- function(data) {
  data |>
    group_by_key() |>
    mutate(
      # Lag features
      cases_lag1 = lag(disease_cases, 1),
      cases_lag2 = lag(disease_cases, 2),
      cases_lag3 = lag(disease_cases, 3),
      rainfall_lag1 = lag(rainfall, 1),

      # Rolling statistics
      cases_ma3 = slider::slide_dbl(disease_cases, mean, .before = 2, .complete = TRUE),
      rainfall_ma3 = slider::slide_dbl(rainfall, mean, .before = 2, .complete = TRUE),

      # Seasonal features
      month = lubridate::month(time_period),

      # Year-over-year change
      cases_yoy = disease_cases - lag(disease_cases, 12)
    ) |>
    ungroup() |>
    # Remove rows with NA from lagging
    filter(!is.na(cases_lag3))
}

# Apply to training data
features <- prepare_features(training_data)
features |>
  select(time_period, location, disease_cases, cases_lag1, cases_ma3, month) |>
  head(10)
#> # A tsibble: 10 x 6 [1M]
#> # Key:       location [1]
#>    time_period location disease_cases cases_lag1 cases_ma3 month
#>          <mth> <chr>            <dbl>      <dbl>     <dbl> <dbl>
#>  1    2000 Oct Bokeo                0          0     0        10
#>  2    2000 Nov Bokeo                0          0     0        11
#>  3    2000 Dec Bokeo                0          0     0        12
#>  4    2001 Jan Bokeo                0          0     0         1
#>  5    2001 Feb Bokeo                0          0     0         2
#>  6    2001 Mar Bokeo                0          0     0         3
#>  7    2001 Apr Bokeo                0          0     0         4
#>  8    2001 May Bokeo                0          0     0         5
#>  9    2001 Jun Bokeo                1          0     0.333     6
#> 10    2001 Jul Bokeo                1          1     0.667     7
```

## Using Features in a CHAP Model

``` r
library(chap.r.sdk)

train_fn <- function(training_data, model_configuration = list()) {
  # Prepare features
  features <- prepare_features(training_data)

  # Fit a simple linear model per location
  models <- features |>
    group_by(location) |>
    group_map(~ lm(disease_cases ~ cases_lag1 + cases_ma3 + rainfall_lag1, data = .x))

  names(models) <- unique(features$location)
  list(models = models)
}

predict_fn <- function(historic_data, future_data, saved_model, model_configuration = list()) {
  # Prepare features from historic data
  features <- prepare_features(historic_data)

  # Get the last known values for prediction
  last_values <- features |>
    group_by(location) |>
    slice_max(time_period, n = 1)

  # Generate predictions
  future_data |>
    left_join(last_values |> select(location, cases_lag1, cases_ma3, rainfall_lag1),
              by = "location") |>
    rowwise() |>
    mutate(
      pred = predict(saved_model$models[[location]], newdata = cur_data()),
      samples = list(c(pred))
    ) |>
    ungroup() |>
    select(-pred, -cases_lag1, -cases_ma3, -rainfall_lag1)
}
```

## Summary

For spatio-temporal data in CHAP:

1.  **tsibble** - Use for all temporal data structures and operations
2.  **fabletools** - Use for temporal aggregation and hierarchical
    forecasting
3.  **sf** - Use for spatial operations (joins, distances, boundaries)
4.  **cubble** - Use for complex spatio-temporal analysis with linked
    views
5.  **slider** - Use for rolling window calculations

These packages integrate seamlessly with the tidyverse and work well
with the CHAP SDK’s tsibble-based data format.

## Further Reading

- [tsibble documentation](https://tsibble.tidyverts.org/)
- [fabletools reference](https://fabletools.tidyverts.org/)
- [sf package](https://r-spatial.github.io/sf/)
- [cubble paper (Journal of Statistical
  Software)](https://www.jstatsoft.org/article/view/v110i07)
- [CRAN Task View: Spatio-Temporal
  Data](https://cran.r-project.org/view=SpatioTemporal)
