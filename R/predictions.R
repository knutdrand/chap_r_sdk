#' Prediction Samples Format Conversion
#'
#' Functions for converting between different prediction sample formats.
#' The SDK uses a nested list-column format internally for efficiency,
#' with converters to/from wide (CHAP CSV), long (scoringutils), and
#' quantile formats.
#'
#' @name predictions
#' @keywords internal
NULL

#' Convert Wide Format Predictions to Nested Format
#'
#' Converts predictions from CHAP wide CSV format (one column per sample)
#' to nested list-column format (one row per forecast unit with samples
#' stored as a numeric vector in a list-column).
#'
#' @param wide_df A data frame with columns: time_period, location, and
#'   sample columns (sample_0, sample_1, ..., sample_N)
#'
#' @return A tibble with columns: time_period, location, samples (list-column
#'   containing numeric vectors of samples)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load wide format predictions
#' wide_preds <- read.csv("predictions.csv")
#' nested_preds <- predictions_from_wide(wide_preds)
#'
#' # Access samples for first forecast unit
#' nested_preds$samples[[1]]
#' }
predictions_from_wide <- function(wide_df) {
  # Identify sample columns (sample_0, sample_1, etc.)
  sample_cols <- grep("^sample_\\d+$", names(wide_df), value = TRUE)


  if (length(sample_cols) == 0) {
    stop("No sample columns found. Expected columns named 'sample_0', 'sample_1', etc.")
  }

  # Identify metadata columns (everything except samples)
  meta_cols <- setdiff(names(wide_df), sample_cols)

  # Sort sample columns numerically

  sample_nums <- as.integer(sub("^sample_", "", sample_cols))
  sample_cols <- sample_cols[order(sample_nums)]

  # Extract sample matrix
  sample_matrix <- as.matrix(wide_df[, sample_cols, drop = FALSE])

  # Create nested tibble
  result <- wide_df[, meta_cols, drop = FALSE]
  result <- tibble::as_tibble(result)
  result$samples <- lapply(seq_len(nrow(sample_matrix)), function(i) {
    as.numeric(sample_matrix[i, ])
  })

  result
}


#' Convert Nested Format Predictions to Wide Format
#'
#' Converts predictions from nested list-column format to CHAP wide CSV
#' format (one column per sample). This is the format expected by the
#' CHAP platform.
#'
#' @param nested_df A tibble with a 'samples' list-column containing numeric
#'   vectors of samples
#'
#' @return A data frame with columns: time_period, location, sample_0,
#'   sample_1, ..., sample_N
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Convert nested predictions to wide format for CHAP
#' wide_preds <- predictions_to_wide(nested_preds)
#' write.csv(wide_preds, "predictions.csv", row.names = FALSE)
#' }
predictions_to_wide <- function(nested_df) {
  if (!"samples" %in% names(nested_df)) {
    stop("Input must have a 'samples' column containing sample vectors")
  }

  # Get number of samples from first row
  n_samples <- length(nested_df$samples[[1]])

  # Verify all rows have same number of samples
  sample_lengths <- vapply(nested_df$samples, length, integer(1))
  if (!all(sample_lengths == n_samples)) {
    stop("All rows must have the same number of samples")
  }

  # Extract metadata columns (everything except samples)
  meta_cols <- setdiff(names(nested_df), "samples")
  result <- nested_df[, meta_cols, drop = FALSE]
  result <- as.data.frame(result)

  # Convert samples list to matrix and add as columns
  sample_matrix <- do.call(rbind, nested_df$samples)
  colnames(sample_matrix) <- paste0("sample_", seq_len(n_samples) - 1)

  cbind(result, sample_matrix)
}


#' Convert Nested Format to Long Format
#'
#' Converts predictions from nested list-column format to long format
#' suitable for use with scoringutils and other analysis tools.
#' Each sample becomes a separate row.
#'
#' @param nested_df A tibble with a 'samples' list-column
#' @param value_col Name for the prediction value column (default: "prediction")
#'
#' @return A tibble in long format with columns: time_period, location,
#'   sample_id, and the prediction value column
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Convert to long format for scoringutils
#' long_preds <- predictions_to_long(nested_preds)
#'
#' # Use with scoringutils
#' scoringutils::score(long_preds, ...)
#' }
predictions_to_long <- function(nested_df, value_col = "prediction") {
  if (!"samples" %in% names(nested_df)) {
    stop("Input must have a 'samples' column containing sample vectors")
  }

  # Get metadata columns
  meta_cols <- setdiff(names(nested_df), "samples")

  # Unnest samples with sample_id
  result <- nested_df |>
    dplyr::mutate(sample_id = purrr::map(samples, seq_along)) |>
    tidyr::unnest(c(samples, sample_id))

  # Rename samples column to specified value column
  names(result)[names(result) == "samples"] <- value_col

  result
}


#' Convert Long Format to Nested Format
#'
#' Converts predictions from long format (one row per sample) to nested
#' list-column format. This is useful for importing data from scoringutils
#' or other tools that use long format.
#'
#' @param long_df A data frame in long format with sample_id and prediction columns
#' @param value_col Name of the prediction value column (default: "prediction")
#' @param sample_col Name of the sample ID column (default: "sample_id")
#' @param group_cols Columns that define forecast units (default: c("time_period", "location"))
#'
#' @return A tibble with nested samples list-column
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Import long format data
#' nested_preds <- predictions_from_long(long_df)
#' }
predictions_from_long <- function(long_df,
                                   value_col = "prediction",
                                   sample_col = "sample_id",
                                   group_cols = c("time_period", "location")) {
  if (!value_col %in% names(long_df)) {
    stop(sprintf("Column '%s' not found in data", value_col))
  }

  # Group by forecast unit and nest samples
  long_df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      samples = list(.data[[value_col]]),
      .groups = "drop"
    )
}


#' Compute Quantiles from Prediction Samples
#'
#' Converts predictions from nested format to quantile format suitable
#' for forecast hub submissions. Computes specified quantiles from the
#' sample distribution.
#'
#' @param nested_df A tibble with a 'samples' list-column
#' @param probs Numeric vector of quantile probabilities (default: standard
#'   hub quantiles from 0.01 to 0.99)
#'
#' @return A tibble in long format with columns: time_period, location,
#'   quantile, value
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Compute standard quantiles
#' quantile_preds <- predictions_to_quantiles(nested_preds)
#'
#' # Compute specific quantiles
#' quantile_preds <- predictions_to_quantiles(
#'   nested_preds,
#'   probs = c(0.025, 0.25, 0.5, 0.75, 0.975)
#' )
#' }
predictions_to_quantiles <- function(nested_df,
                                      probs = c(0.01, 0.025, 0.05, 0.1, 0.15,
                                                0.2, 0.25, 0.3, 0.35, 0.4,
                                                0.45, 0.5, 0.55, 0.6, 0.65,
                                                0.7, 0.75, 0.8, 0.85, 0.9,
                                                0.95, 0.975, 0.99)) {
  if (!"samples" %in% names(nested_df)) {
    stop("Input must have a 'samples' column containing sample vectors")
  }

  # Get metadata columns
  meta_cols <- setdiff(names(nested_df), "samples")

  # Compute quantiles for each row
  nested_df |>
    dplyr::rowwise() |>
    dplyr::mutate(
      quantile_values = list(
        tibble::tibble(
          quantile = probs,
          value = quantile(samples, probs = probs, na.rm = TRUE)
        )
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-samples) |>
    tidyr::unnest(quantile_values)
}


#' Add Summary Statistics to Predictions
#'
#' Adds common summary statistics (mean, median, confidence intervals)
#' to a nested predictions tibble.
#'
#' @param nested_df A tibble with a 'samples' list-column
#' @param ci_levels Confidence interval levels (default: c(0.5, 0.9, 0.95))
#'
#' @return The input tibble with additional columns: mean, median, and
#'   lower/upper bounds for each CI level (e.g., lower_50, upper_50)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Add summary statistics
#' preds_with_summary <- predictions_summary(nested_preds)
#'
#' # View mean predictions
#' preds_with_summary$mean
#' }
predictions_summary <- function(nested_df, ci_levels = c(0.5, 0.9, 0.95)) {
  if (!"samples" %in% names(nested_df)) {
    stop("Input must have a 'samples' column containing sample vectors")
  }

  result <- nested_df |>
    dplyr::mutate(
      mean = purrr::map_dbl(samples, mean, na.rm = TRUE),
      median = purrr::map_dbl(samples, stats::median, na.rm = TRUE)
    )

  # Add confidence intervals

for (level in ci_levels) {
    lower_prob <- (1 - level) / 2
    upper_prob <- 1 - lower_prob
    level_pct <- as.integer(level * 100)

    lower_col <- paste0("lower_", level_pct)
    upper_col <- paste0("upper_", level_pct)

    result <- result |>
      dplyr::mutate(
        !!lower_col := purrr::map_dbl(samples, ~quantile(.x, lower_prob, na.rm = TRUE)),
        !!upper_col := purrr::map_dbl(samples, ~quantile(.x, upper_prob, na.rm = TRUE))
      )
  }

  result
}


#' Check if Predictions Have Samples
#'
#' Checks whether a predictions data frame contains sample data
#' (either in nested or wide format).
#'
#' @param df A data frame to check
#'
#' @return Logical indicating whether samples are present
#'
#' @export
#'
#' @examples
#' \dontrun{
#' if (has_prediction_samples(preds)) {
#'   preds <- predictions_to_wide(preds)
#' }
#' }
has_prediction_samples <- function(df) {
  # Check for nested format
 if ("samples" %in% names(df)) {
    return(TRUE)
  }

  # Check for wide format
  sample_cols <- grep("^sample_\\d+$", names(df), value = TRUE)
  if (length(sample_cols) > 0) {
    return(TRUE)
  }

  FALSE
}


#' Detect Prediction Sample Format
#'
#' Detects the format of prediction samples in a data frame.
#'
#' @param df A data frame to check
#'
#' @return Character string: "nested", "wide", "long", or "none"
#'
#' @export
#'
#' @examples
#' \dontrun{
#' format <- detect_prediction_format(preds)
#' if (format == "wide") {
#'   preds <- predictions_from_wide(preds)
#' }
#' }
detect_prediction_format <- function(df) {
  # Check for nested format (list-column named 'samples')
  if ("samples" %in% names(df) && is.list(df$samples)) {
    return("nested")
  }

  # Check for wide format (sample_0, sample_1, ... columns)
  sample_cols <- grep("^sample_\\d+$", names(df), value = TRUE)
  if (length(sample_cols) > 0) {
    return("wide")
  }

  # Check for long format (sample_id and prediction columns)
  if ("sample_id" %in% names(df) && "prediction" %in% names(df)) {
    return("long")
  }

  "none"
}
