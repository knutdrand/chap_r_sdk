# Chap R sdk

This package will provide convenicence functionality for developing chap models and integrating existing models with chap.
The main functionality will be.

- Convenience functionality to create chap compatible command line interfaces from functions fulfilling the chap interface. This inclides
  - train(training_data, model_configuration) -> saved_model
  - predict(historic_data, future_data, saved_model, model_co/cnfiguration)
- Test suite to sanity check models i.e. ensure that prediction output is consistent with what is expected from chap
- Functionality to expose model configuration schemas to chap
- Some common functionality to extract common transformations for spatio-temporal data

The package is tidyverse oriented and most functionality should be consistent with best practices in R
