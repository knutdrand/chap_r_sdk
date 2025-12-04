#' CLI Utility Functions
#'
#' Internal utility functions for the unified CHAP CLI infrastructure.
#' These functions handle file I/O, data parsing, and format conversion
#' automatically so model developers can focus on business logic.
#'
#' @name cli_utils
#' @keywords internal
NULL

#' Load CSV and convert to tsibble
#'
#' Automatically loads a CSV file and converts it to a tsibble by detecting
#' the time index column and spatial key columns.
#'
#' @param file_path Path to CSV file to load
#' @return A tsibble object with auto-detected index and key columns
#' @keywords internal
load_tsibble <- function(file_path) {
  # Load CSV
  df <- readr::read_csv(file_path, show_col_types = FALSE)

  # Auto-detect time column (time_period, date, week, month, etc.)
  time_col <- detect_time_column(df)

  # Auto-detect key columns (location, region, etc.)
  key_cols <- detect_key_columns(df)

  # Convert to tsibble
  if (is.null(key_cols) || length(key_cols) == 0) {
    # Univariate time series (no key columns)
    tsibble::as_tsibble(df, index = !!rlang::sym(time_col))
  } else {
    # Multivariate time series with spatial keys
    tsibble::as_tsibble(df, index = !!rlang::sym(time_col), key = dplyr::all_of(key_cols))
  }
}

#' Detect time column in data frame
#'
#' Searches for common time column names in the data frame.
#' Falls back to the first column if no standard names are found.
#'
#' @param df Data frame to search
#' @return Name of the detected time column
#' @keywords internal
detect_time_column <- function(df) {
  # Look for common time column names (in order of preference)
  time_candidates <- c("time_period", "date", "week", "month", "year", "time", "period")
  matches <- intersect(names(df), time_candidates)

  if (length(matches) > 0) {
    return(matches[1])
  }

  # Fall back to first column if none match
  warning("No standard time column found, using first column: ", names(df)[1])
  return(names(df)[1])
}

#' Detect key columns (spatial identifiers)
#'
#' Searches for common spatial identifier column names in the data frame.
#' Returns NULL if no key columns are found (univariate time series).
#'
#' @param df Data frame to search
#' @return Character vector of key column names, or NULL if none found
#' @keywords internal
detect_key_columns <- function(df) {
  # Look for common key column names
  key_candidates <- c("location", "region", "district", "area", "site", "id", "country", "province")
  matches <- intersect(names(df), key_candidates)

  if (length(matches) > 0) {
    return(matches)
  }

  # No key columns found - return NULL (univariate time series)
  return(NULL)
}

#' Load and parse configuration file
#'
#' Loads a YAML configuration file if it exists and is valid.
#' Returns an empty list if the path is NULL, empty, or the file doesn't exist.
#'
#' @param config_path Path to YAML configuration file (can be NULL or empty string)
#' @return Parsed configuration as a list, or empty list if no config
#' @keywords internal
load_config <- function(config_path) {
  # Return empty list if no config path provided
  if (is.null(config_path) || config_path == "" || !file.exists(config_path)) {
    return(list())
  }

  # Use the existing read_model_config function
  read_model_config(config_path, validate = FALSE)
}

#' Save model to RDS file
#'
#' Saves a trained model object to an RDS file with a status message.
#'
#' @param model Model object to save
#' @param output_path Path for output RDS file (default: "model.rds")
#' @return Path to the saved model file
#' @keywords internal
save_model <- function(model, output_path = "model.rds") {
  saveRDS(model, output_path)
  message("Model saved to: ", output_path)
  return(output_path)
}

#' Save predictions to CSV
#'
#' Saves prediction results to a CSV file with a status message.
#'
#' @param predictions Predictions data frame or tsibble
#' @param output_path Path for output CSV file
#' @return Path to the saved predictions file
#' @keywords internal
save_predictions <- function(predictions, output_path) {
  readr::write_csv(predictions, output_path)
  message("Predictions saved to: ", output_path)
  return(output_path)
}
