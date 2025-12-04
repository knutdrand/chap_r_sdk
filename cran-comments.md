## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Test environments

* local: macOS Sonoma 14.5, R 4.3.2
* GitHub Actions (ubuntu-latest): R-release, R-devel
* win-builder: R-release, R-devel

## Downstream dependencies

There are currently no downstream dependencies for this package.

## Notes to CRAN

This is the initial submission of chap.r.sdk. The package provides infrastructure for developing CHAP-compatible disease forecasting models.

### Package Name

The package name uses dots (chap.r.sdk) following the convention of other R SDK packages. This is intentional.

### Examples

Some examples are wrapped in \dontrun{} because they require:
- External data files to be present
- Model training which takes time
- File system I/O operations

Small demonstrative examples are provided where feasible (e.g., `get_config_param()`).

### Suggested Packages

The 'ajv' package in Suggests is used for optional JSON schema validation of YAML configuration files. The package works without it (with a warning message).
