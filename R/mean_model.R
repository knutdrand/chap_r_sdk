#' Train a simple mean model
#'
#' Trains a model that predicts the mean disease cases for each location
#'
#' @param training_data A tsibble with columns: time_period, location, disease_cases, and covariates
#' @param model_config A list containing model configuration options
#'
#' @return A list containing the trained model (mean values per location)
#' @export
train_mean_model <- function(training_data, model_config = list()) {

  # Validate that we have a tsibble
  if (!tsibble::is_tsibble(training_data)) {
    stop("training_data must be a tsibble")
  }

  # Check for required columns
  required_cols <- c("location", "disease_cases")
  missing_cols <- setdiff(required_cols, names(training_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  # Calculate mean disease cases per location
  location_means <- training_data |>
    dplyr::group_by(location) |>
    dplyr::summarise(
      mean_cases = mean(disease_cases, na.rm = TRUE),
      n_obs = dplyr::n()
    ) |>
    dplyr::collect()

  # Create model object
  model <- list(
    location_means = location_means,
    config = model_config,
    trained_at = Sys.time(),
    model_type = "mean_model"
  )

  class(model) <- c("chap_mean_model", "chap_model")

  return(model)
}


#' Predict using mean model
#'
#' Generates predictions by returning the mean disease cases for each location
#'
#' @param historic_data A tsibble with historical data (not used by mean model, but kept for interface consistency)
#' @param future_data A tsibble with future time periods and locations to predict for
#' @param model The trained model object from train_mean_model()
#' @param model_config A list containing model configuration options (optional)
#'
#' @return A tsibble with columns: time_period, location, disease_cases (predicted)
#' @export
predict_mean_model <- function(historic_data, future_data, model, model_config = list()) {

  # Validate inputs
  if (!inherits(model, "chap_mean_model")) {
    stop("model must be a chap_mean_model object")
  }

  if (!tsibble::is_tsibble(future_data)) {
    stop("future_data must be a tsibble")
  }

  # Check for required columns
  if (!"location" %in% names(future_data)) {
    stop("future_data must have a 'location' column")
  }

  # Get the time index and key from future_data
  time_col <- tsibble::index_var(future_data)
  key_cols <- tsibble::key_vars(future_data)

  # Join mean predictions with future data
  predictions <- future_data |>
    dplyr::left_join(
      model$location_means |> dplyr::select(location, mean_cases),
      by = "location"
    ) |>
    dplyr::mutate(
      disease_cases = dplyr::coalesce(mean_cases, 0)
    ) |>
    dplyr::select(-mean_cases)

  # Ensure it's still a tsibble with same structure
  predictions <- tsibble::as_tsibble(
    predictions,
    index = !!rlang::sym(time_col),
    key = !!rlang::syms(key_cols)
  )

  return(predictions)
}
