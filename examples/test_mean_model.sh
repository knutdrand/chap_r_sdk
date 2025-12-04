#!/bin/bash

# Example script showing how to use the CHAP R SDK unified CLI
# This demonstrates training and prediction with the mean model

set -e

echo "=== CHAP R SDK Mean Model Example ==="
echo ""

# Set paths
SCRIPT="examples/mean_model/model.R"
TRAIN_DATA="examples/mean_model/example_data.csv"
FUTURE_DATA="examples/mean_model/future_data.csv"
MODEL_OUTPUT="model.rds"
PREDICTIONS_OUTPUT="model_predictions.csv"

# Step 1: Display model info
echo "Step 1: Display model information..."
Rscript "$SCRIPT" info

echo ""

# Step 2: Train the model
echo "Step 2: Training model..."
Rscript "$SCRIPT" train "$TRAIN_DATA"

echo ""
echo "Model saved to: $MODEL_OUTPUT"
echo ""

# Step 3: Generate predictions
echo "Step 3: Generating predictions..."
Rscript "$SCRIPT" predict \
  "$TRAIN_DATA" \
  "$FUTURE_DATA" \
  "$MODEL_OUTPUT"

echo ""
echo "Predictions saved to: $PREDICTIONS_OUTPUT"
echo ""

echo "=== Example complete! ==="
echo ""
echo "To view the model in R:"
echo "  model <- readRDS('$MODEL_OUTPUT')"
echo "  print(model)"
echo ""
echo "To view predictions in R:"
echo "  predictions <- read.csv('$PREDICTIONS_OUTPUT')"
echo "  print(predictions)"
echo ""
