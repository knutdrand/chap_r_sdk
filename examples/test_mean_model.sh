#!/bin/bash

# Example script showing how to use the CHAP R SDK CLI
# This demonstrates training and prediction with the mean model

set -e

echo "=== CHAP R SDK Mean Model Example ==="
echo ""

# Set paths
TRAIN_DATA="inst/testdata/ewars_example/monthly/training_data.csv"
FUTURE_DATA="inst/testdata/ewars_example/monthly/future_data.csv"
HISTORIC_DATA="inst/testdata/ewars_example/monthly/historic_data.csv"
CONFIG="inst/testdata/ewars_example/monthly/config.yaml"
MODEL_OUTPUT="output/trained_model.rds"
PREDICTIONS_OUTPUT="output/predictions.csv"

# Create output directory
mkdir -p output

# Step 1: Train the model
echo "Step 1: Training model..."
Rscript inst/scripts/train_cli.R \
  --data "$TRAIN_DATA" \
  --config "$CONFIG" \
  --output "$MODEL_OUTPUT"

echo ""
echo "Model saved to: $MODEL_OUTPUT"
echo ""

# Step 2: Generate predictions
echo "Step 2: Generating predictions..."
Rscript inst/scripts/predict_cli.R \
  --model "$MODEL_OUTPUT" \
  --historic "$HISTORIC_DATA" \
  --future "$FUTURE_DATA" \
  --config "$CONFIG" \
  --output "$PREDICTIONS_OUTPUT"

echo ""
echo "Predictions saved to: $PREDICTIONS_OUTPUT"
echo ""

echo "=== Example complete! ==="
echo ""
echo "To view the model:"
echo "  readRDS('$MODEL_OUTPUT')"
echo ""
echo "To view predictions:"
echo "  read.csv('$PREDICTIONS_OUTPUT')"
