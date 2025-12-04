#!/usr/bin/env Rscript
# Example script demonstrating get_example_data() function

# Load the package (when installed)
library(chap.r.sdk)

# Get example data for Laos with monthly frequency
data <- get_example_data('laos', 'M')

# Inspect the structure
cat("Example data loaded successfully!\n\n")

cat("Available datasets:\n")
cat("- training_data:", nrow(data$training_data), "rows\n")
cat("- historic_data:", nrow(data$historic_data), "rows\n")
cat("- future_data:", nrow(data$future_data), "rows\n")
cat("- predictions:", nrow(data$predictions), "rows\n\n")

# Show column names for each dataset
cat("Training data columns:\n")
print(names(data$training_data))

cat("\nFuture data columns:\n")
print(names(data$future_data))

cat("\nPredictions columns (first 10):\n")
print(head(names(data$predictions), 10))

# Example usage with a model
cat("\n\nExample usage pattern:\n")
cat("# Train a model\n")
cat("model <- train_my_model(data$training_data)\n\n")

cat("# Make predictions\n")
cat("predictions <- predict_my_model(\n")
cat("  data$historic_data,\n")
cat("  data$future_data,\n")
cat("  model\n")
cat(")\n")
