# Prediction Samples Format Conversion

Functions for converting between different prediction sample formats.
The SDK uses a nested list-column format internally for efficiency, with
converters to/from wide (CHAP CSV), long (scoringutils), and quantile
formats.
