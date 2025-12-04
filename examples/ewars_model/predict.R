# left side is the names used in the code, right side is the internal names in CHAP
# Cases = number of cases
# E = population
# week = week
# month = month
# ID_year = year
# ID_spat = location
# rainsum = rainfall
# meantemperature = mean_temperature
#note: The model uses either weeks or months
library(yaml)
library(jsonlite)
library(INLA)
library(dlnm)
library(dplyr)
library(chap.r.sdk)
library(purrr)
source("lib.R")

#for spatial effects
library(sf)
library(spdep)

#' Parse Model Configuration
#'
#' Reads and parses YAML configuration file for the EWARS model
#'
#' @param file_path Path to YAML configuration file
#' @return List with user_option_values and additional_continuous_covariates
parse_model_configuration <- function(file_path) {
  if (is.null(file_path) || file_path == "") {
    return(list(
      user_option_values = list(),
      additional_continuous_covariates = character()
    ))
  }

  # Use chap.r.sdk config reading function
  config <- read_model_config(file_path, validate = FALSE)

  # Ensure fields exist and provide defaults if missing
  user_option_values <- pluck(config, "user_option_values", .default = list())
  additional_continuous_covariates <- pluck(config, "additional_continuous_covariates", .default = character())

  # Return the structured list
  list(
    user_option_values = user_option_values,
    additional_continuous_covariates = additional_continuous_covariates
  )
}

generate_bacic_model <- function(df, covariates, nlag) {
  formula_str <- paste(
    "Cases ~ 1 +",
    "f(ID_spat, model='iid', replicate=ID_year) +",
    "f(ID_time_cyclic, model='rw1', cyclic=TRUE, scale.model=TRUE)"
  )
  model_formula <- as.formula(formula_str)

  return(list(formula = model_formula, data = df))
}

generate_lagged_model <- function(df, covariates, nlag) {
  basis_list <- list()

  for (cov in covariates) {
    var_data <- df[[cov]]
    basis <- crossbasis(
      var_data, lag = nlag,
      argvar = list(fun = "ns", knots = equalknots(var_data, 2)),
      arglag = list(fun = "ns", knots = nlag / 2),
      group = df$ID_spat
    )
    basis_name <- paste0("basis_", cov)
    colnames(basis) <- paste0(basis_name, ".", colnames(basis))
    basis_list[[basis_name]] <- basis
  }

  # Combine basis matrices into one data frame
  basis_df <- do.call(cbind, basis_list)

  # Merge with the original dataframe
  model_data <- cbind(df, basis_df)

  # Get all new column names added
  basis_columns <- colnames(basis_df)

  # Generate formula string using column names directly
  basis_terms <- paste(basis_columns, collapse = " + ")
  print(basis_terms)
  formula_str <- paste(
    "Cases ~ 1 +",
    "f(ID_spat, model='iid', replicate=ID_year) +",
    "f(ID_time_cyclic, model='rw1', cyclic=TRUE, scale.model=TRUE) +",
    basis_terms
  )

  model_formula <- as.formula(formula_str)

  return(list(formula = model_formula, data = model_data))
}

#' Predict with EWARS Model
#'
#' This model trains and predicts in a single step.
#' It combines historic and future data, trains an INLA model, and generates predictions.
#'
#' @param historic_data Path to historic data CSV file
#' @param future_data Path to future data CSV file
#' @param saved_model Path to saved model file (will be created)
#' @param model_configuration Path to model configuration YAML file (optional)
#' @return Path to predictions CSV file
predict_chap <- function(historic_data, future_data, saved_model, model_configuration = NULL){
  # Parse configuration
  if (!is.null(model_configuration) && model_configuration != "") {
    cat("Loading model configuration from YAML file...\n")
    cat("Config file:", model_configuration, "\n")
    config <- parse_model_configuration(model_configuration)
    covariate_names <- config$additional_continuous_covariates
    nlag <- get_config_param(config$user_option_values, "n_lag", .default = 3)
    precision <- get_config_param(config$user_option_values, "precision", .default = 0.01)
  } else {
    covariate_names <- c("rainfall", "mean_temperature")
    nlag <- 3
    precision <- 0.01
  }

  # Read and prepare data
  df <- read.csv(future_data)
  df$Cases <- rep(NA, nrow(df))
  df$disease_cases <- rep(NA, nrow(df)) #so we can rowbind it with historic

  historic_df <- read.csv(historic_data)
  df <- rbind(historic_df, df)

  if( "week" %in% colnames(df)){ # for a weekly model
    df <- mutate(df, ID_time_cyclic = week)
    df <- offset_years_and_weeks(df)
    nlag <- 12
  } else{ # for a monthly model
    df <- mutate(df, ID_time_cyclic = month)
    df <- offset_years_and_months(df)
    nlag <- 3
  }

  df$ID_year <- df$ID_year - min(df$ID_year) + 1 #makes the years 1, 2, ...

  if (length(covariate_names) == 0) {
    generated <- generate_bacic_model(df, covariate_names, nlag)
  } else {
    generated <- generate_lagged_model(df, covariate_names, nlag)
  }
  lagged_formula <- generated$formula
  cat("Generated model formula:", as.character(lagged_formula), "\n")
  df <- generated$data

  model <- inla(formula = lagged_formula, data = df, family = "nbinomial", offset = log(E),
                control.inla = list(strategy = 'adaptive'),
                control.compute = list(dic = TRUE, config = TRUE, cpo = TRUE, return.marginals = FALSE),
                control.fixed = list(correlation.matrix = TRUE, prec.intercept = 1e-4, prec = precision),
                control.predictor = list(link = 1, compute = TRUE),
                verbose = FALSE, safe=FALSE)

  casestopred <- df$Cases # response variable

  # Predict only for the cases where the response variable is missing
  idx.pred <- which(is.na(casestopred)) #this then also predicts for historic values that are NA, not ideal
  mpred <- length(idx.pred)
  s <- 1000
  y.pred <- matrix(NA, mpred, s)
  # Sample parameters of the model
  xx <- inla.posterior.sample(s, model)  # This samples parameters of the model
  xx.s <- inla.posterior.sample.eval(function(idx.pred) c(theta[1], Predictor[idx.pred]), xx, idx.pred = idx.pred) # This extracts the expected value and hyperparameters from the samples

  # Sample predictions
  for (s.idx in 1:s){
    xx.sample <- xx.s[, s.idx]
    y.pred[, s.idx] <- rnbinom(mpred,  mu = exp(xx.sample[-1]), size = xx.sample[1])
  }

  # make a dataframe where first column is the time points, second column is the location, rest is the samples
  # rest of columns should be called sample_0, sample_1, etc
  new.df <- data.frame(time_period = df$time_period[idx.pred], location = df$location[idx.pred], y.pred)
  colnames(new.df) <- c('time_period', 'location', paste0('sample_', 0:(s-1)))

  # Generate predictions output file path
  preds_fn <- sub("\\.rds$", "_predictions.csv", saved_model)

  # Write new dataframe to file, and save the model
  write.csv(new.df, preds_fn, row.names = FALSE)
  saveRDS(model, file = saved_model)

  cat("Predictions saved to:", preds_fn, "\n")
  cat("Model saved to:", saved_model, "\n")

  return(preds_fn)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_predict_cli(predict_chap)
}

