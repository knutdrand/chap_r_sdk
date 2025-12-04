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

library(INLA)
library(chap.r.sdk)
source('lib.R')

#' Train CHAP Model
#'
#' This model does not perform training in the traditional sense.
#' All training and prediction happens in the predict step.
#'
#' @param training_data Path to training data CSV file
#' @param model_configuration Optional path to model configuration YAML file
#' @return Path to saved model file (empty in this case)
train_chap <- function(training_data, model_configuration = NULL){
  # This model does not train in the traditional sense
  # All training happens in the predict step
  # Return NULL to indicate no model file is created
  return(NULL)
}

# Use chap.r.sdk CLI wrapper
if (!interactive()) {
  create_train_cli(train_chap)
}

