#' Environment configuration for CHAP models.

#' Read R version from renv.lock
#'
#' Parses the renv.lock file and extracts the R version.
#'
#' @param lockfile_path Path to renv.lock (default: "renv.lock")
#' @return Character string with R version (e.g., "4.3.2")
#' @export
#'
#' @examples
#' \dontrun{
#' read_renv_r_version()
#' read_renv_r_version("path/to/renv.lock")
#' }
read_renv_r_version <- function(lockfile_path = "renv.lock") {
  if (!file.exists(lockfile_path)) {
    stop("renv.lock not found at: ", lockfile_path)
  }

  lock <- jsonlite::fromJSON(lockfile_path)

  if (is.null(lock$R$Version)) {
    stop("R version not found in renv.lock")
  }

  lock$R$Version
}


#' Detect system dependencies from renv packages
#'
#' Parses renv.lock and queries package metadata to find required
#' system libraries (apt packages) using pak.
#'
#' @param lockfile_path Path to renv.lock (default: "renv.lock")
#' @param os Operating system (default: "ubuntu")
#' @param os_release OS release version (default: "22.04")
#' @return Character vector of apt package names
#' @export
#'
#' @examples
#' \dontrun{
#' detect_system_deps()
#' detect_system_deps(os = "ubuntu", os_release = "24.04")
#' }
detect_system_deps <- function(lockfile_path = "renv.lock",
                                os = "ubuntu",
                                os_release = "22.04") {
  if (!file.exists(lockfile_path)) {
    stop("renv.lock not found at: ", lockfile_path)
  }

  # Check if pak is available

if (!requireNamespace("pak", quietly = TRUE)) {
    warning("pak package not available. Cannot auto-detect system dependencies.")
    return(character(0))
  }

  # Read packages from renv.lock
  lock <- jsonlite::fromJSON(lockfile_path)
  packages <- names(lock$Packages)

  if (length(packages) == 0) {
    return(character(0))
  }

  # Query system requirements using pak::pkg_sysreqs
  tryCatch({
    sysreqs <- pak::pkg_sysreqs(packages, sysreqs_platform = paste0(os, "-", os_release))

    # Extract install scripts and parse apt package names
    if (is.null(sysreqs$install_scripts) || length(sysreqs$install_scripts) == 0) {
      return(character(0))
    }

    # Parse apt-get install commands to extract package names
    scripts <- unlist(sysreqs$install_scripts)
    apt_packages <- character(0)

    for (script in scripts) {
      # Match apt-get install or apt install commands
      if (grepl("apt-get install|apt install", script)) {
        # Extract package names after install -y
        matches <- regmatches(script, gregexpr("(?<=install -y )\\S+", script, perl = TRUE))
        apt_packages <- c(apt_packages, unlist(matches))
      }
    }

    unique(apt_packages)
  }, error = function(e) {
    warning("Failed to detect system dependencies: ", e$message)
    character(0)
  })
}


#' Write default chap.yml configuration
#'
#' Creates a default chap.yml file with environment configuration.
#'
#' @param r_version R version to use (default: read from renv.lock or current)
#' @param output_path Where to write chap.yml (default: "chap.yml")
#' @return Invisible path to created file
#' @keywords internal
write_default_chap_yml <- function(r_version = NULL, output_path = "chap.yml") {
  if (is.null(r_version)) {
    if (file.exists("renv.lock")) {
      r_version <- read_renv_r_version()
    } else {
      r_version <- paste(R.version$major, R.version$minor, sep = ".")
    }
  }

  config <- list(
    environment = list(
      base_image = NULL,
      extra_system_deps = list(),
      chapkit_version = NULL
    )
  )

  yaml::write_yaml(config, output_path)
  message("Created ", output_path)

  invisible(output_path)
}


#' Read chap.yml configuration
#'
#' Reads and parses the chap.yml configuration file.
#'
#' @param config_path Path to chap.yml (default: "chap.yml")
#' @return List with configuration, or empty list with defaults if file not found
#' @keywords internal
read_chap_yml <- function(config_path = "chap.yml") {
  if (!file.exists(config_path)) {
    return(list(
      environment = list(
        base_image = NULL,
        extra_system_deps = list(),
        chapkit_version = NULL
      )
    ))
  }

  yaml::read_yaml(config_path)
}


#' Initialize CHAP model environment
#'
#' Sets up renv for reproducible R dependencies and creates chap.yml.
#' Run this once when creating a new model project.
#'
#' @param r_version R version to record (default: current R version)
#' @param include_chap_sdk Whether to include chap.r.sdk in dependencies (default: TRUE)
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize new project
#' init_chap_env()
#'
#' # Initialize with specific R version
#' init_chap_env(r_version = "4.3.2")
#' }
init_chap_env <- function(r_version = NULL, include_chap_sdk = TRUE) {
  # Check if renv is available
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package is required. Install with: install.packages('renv')")
  }

  # 1. Initialize renv if not present
  if (!file.exists("renv.lock")) {
    message("Initializing renv...")
    renv::init(bare = TRUE)
  }

  # 2. Add chap.r.sdk to dependencies if requested
  if (include_chap_sdk) {
    message("Adding chap.r.sdk to dependencies...")
    tryCatch({
      renv::install("chap.r.sdk")
    }, error = function(e) {
      message("Note: chap.r.sdk not found in repositories. ",
              "Install manually or from GitHub.")
    })
  }

  # 3. Snapshot current dependencies
  message("Creating renv.lock snapshot...")
  renv::snapshot()

  # 4. Create default chap.yml
  write_default_chap_yml(r_version)

  message("\nCHAP environment initialized!")
  message("Next steps:")
  message("  1. Install any additional R packages with renv::install()")
  message("  2. Run renv::snapshot() to update renv.lock")
  message("  3. Run generate_dockerfile() to create Dockerfile")

  invisible(NULL)
}


#' Generate Dockerfile for CHAP model
#'
#' Creates a Dockerfile that builds a container with R, renv packages,
#' Python, and chapkit. The generated image can run the complete service.
#'
#' @param chapkit_version Version of chapkit to install (default: latest)
#' @param python_version Python version to install (default: "3.12")
#' @param output_path Where to write Dockerfile (default: "Dockerfile")
#' @param lockfile_path Path to renv.lock (default: "renv.lock")
#' @param os Operating system for system deps (default: "ubuntu")
#' @param os_release OS release for system deps (default: "22.04")
#' @return Invisible path to created Dockerfile
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate with defaults
#' generate_dockerfile()
#'
#' # Generate with specific versions
#' generate_dockerfile(chapkit_version = "0.1.0", python_version = "3.11")
#' }
generate_dockerfile <- function(chapkit_version = NULL,
                                 python_version = "3.12",
                                 output_path = "Dockerfile",
                                 lockfile_path = "renv.lock",
                                 os = "ubuntu",
                                 os_release = "22.04") {

  if (!file.exists(lockfile_path)) {
    stop("renv.lock not found. Run init_chap_env() first.")
  }

  # Read R version from renv.lock
  r_version <- read_renv_r_version(lockfile_path)
  message("R version from renv.lock: ", r_version)

  # Read chap.yml for overrides
  chap_config <- read_chap_yml()

  # Determine base image
  base_image <- chap_config$environment$base_image
  if (is.null(base_image)) {
    base_image <- paste0("rocker/r-ver:", r_version)
  }
  message("Base image: ", base_image)

  # Detect system dependencies
  message("Detecting system dependencies...")
  system_deps <- detect_system_deps(lockfile_path, os, os_release)

  # Add extra system deps from chap.yml
  extra_deps <- chap_config$environment$extra_system_deps
  if (!is.null(extra_deps) && length(extra_deps) > 0) {
    system_deps <- unique(c(system_deps, unlist(extra_deps)))
  }

  if (length(system_deps) > 0) {
    message("System dependencies: ", paste(system_deps, collapse = ", "))
  } else {
    message("No system dependencies detected")
  }

  # Determine chapkit version
  chapkit_spec <- if (!is.null(chapkit_version)) {
    paste0("chapkit==", chapkit_version)
  } else if (!is.null(chap_config$environment$chapkit_version)) {
    paste0("chapkit", chap_config$environment$chapkit_version)
  } else {
    "chapkit"
  }

  # Generate Dockerfile content
  dockerfile <- generate_dockerfile_content(
    base_image = base_image,
    system_deps = system_deps,
    python_version = python_version,
    chapkit_spec = chapkit_spec
  )

  # Write Dockerfile
  writeLines(dockerfile, output_path)
  message("\nDockerfile generated: ", output_path)
  message("\nBuild with:")
  message("  docker build -t my-chap-model .")
  message("\nRun with:")
  message("  docker run -p 8000:8000 my-chap-model")

  invisible(output_path)
}


#' Generate Dockerfile content
#'
#' Internal function to generate the Dockerfile content string.
#'
#' @param base_image Base Docker image
#' @param system_deps Character vector of apt packages
#' @param python_version Python version
#' @param chapkit_spec Chapkit pip specification
#' @return Character string with Dockerfile content
#' @keywords internal
generate_dockerfile_content <- function(base_image,
                                         system_deps,
                                         python_version,
                                         chapkit_spec) {

  # System deps installation command
  system_deps_cmd <- if (length(system_deps) > 0) {
    paste0(
      "# Install system dependencies (auto-detected from renv)\n",
      "RUN apt-get update && apt-get install -y --no-install-recommends \\\n",
      "    ", paste(system_deps, collapse = " \\\n    "), " \\\n",
      "    && rm -rf /var/lib/apt/lists/*\n"
    )
  } else {
    "# No system dependencies detected\n"
  }

  # Build Dockerfile content
  paste0(
    "# Generated by chap.r.sdk::generate_dockerfile()\n",
    "# This Dockerfile creates a container with R, renv packages, Python, and chapkit\n",
    "\n",
    "# Stage 1: R environment with packages\n",
    "FROM ", base_image, " AS r-env\n",
    "\n",
    "WORKDIR /model\n",
    "\n",
    system_deps_cmd,
    "\n",
    "# Copy renv files first for layer caching\n",
    "COPY renv.lock renv.lock\n",
    "COPY .Rprofile .Rprofile\n",
    "COPY renv/activate.R renv/activate.R\n",
    "\n",
    "# Install renv and restore packages\n",
    "RUN R -e \"install.packages('renv', repos='https://cloud.r-project.org')\" \\\n",
    "    && R -e \"renv::restore()\"\n",
    "\n",
    "# Stage 2: Add Python + chapkit\n",
    "FROM r-env AS runtime\n",
    "\n",
    "# Install Python\n",
    "RUN apt-get update && apt-get install -y --no-install-recommends \\\n",
    "    python3 \\\n",
    "    python3-pip \\\n",
    "    python3-venv \\\n",
    "    && rm -rf /var/lib/apt/lists/*\n",
    "\n",
    "# Create and activate virtual environment\n",
    "ENV VIRTUAL_ENV=/opt/venv\n",
    "RUN python3 -m venv $VIRTUAL_ENV\n",
    "ENV PATH=\"$VIRTUAL_ENV/bin:$PATH\"\n",
    "\n",
    "# Install chapkit\n",
    "RUN pip install --no-cache-dir ", chapkit_spec, "\n",
    "\n",
    "# Copy model code\n",
    "COPY . .\n",
    "\n",
    "# Expose default port\n",
    "EXPOSE 8000\n",
    "\n",
    "# Run the service\n",
    "CMD [\"python\", \"-m\", \"uvicorn\", \"main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\"]\n"
  )
}


#' Get environment information for info command
#'
#' Returns environment information for inclusion in the info --format json output.
#' Called by build_info_json() in cli.R.
#'
#' @param lockfile_path Path to renv.lock (default: "renv.lock")
#' @return List with environment information
#' @keywords internal
get_environment_info <- function(lockfile_path = "renv.lock") {
  has_renv_lock <- file.exists(lockfile_path)

  if (!has_renv_lock) {
    return(list(
      r_version = NULL,
      has_renv_lock = FALSE,
      system_deps = list()
    ))
  }

  r_version <- tryCatch(
    read_renv_r_version(lockfile_path),
    error = function(e) NULL
  )

  system_deps <- tryCatch(
    as.list(detect_system_deps(lockfile_path)),
    error = function(e) list()
  )

  list(
    r_version = r_version,
    has_renv_lock = TRUE,
    system_deps = system_deps
  )
}


#' Convert JSON Schema to chap-core user_options format
#'
#' Converts a JSON Schema properties object to the user_options format
#' expected by chap-core's MLproject files. JSON Schema types are passed
#' through directly as they match chap-core's expected types.
#'
#' @param config_schema A JSON Schema object with properties
#' @return A list in chap-core user_options format, or NULL if no schema
#' @keywords internal
schema_to_user_options <- function(config_schema) {
  if (is.null(config_schema) || is.null(config_schema$properties)) {
    return(NULL)
  }

  properties <- config_schema$properties
  if (length(properties) == 0) {
    return(NULL)
  }

  user_options <- list()

  for (param_name in names(properties)) {
    prop <- properties[[param_name]]

    option <- list(type = prop$type)

    # Add title if present
    if (!is.null(prop$title)) {
      option$title <- prop$title
    }

    # Add description if present
    if (!is.null(prop$description)) {
      option$description <- prop$description
    }

    # Add default if present
    if (!is.null(prop$default)) {
      option$default <- prop$default
    }

    user_options[[param_name]] <- option
  }

  user_options
}


#' Generate MLproject file for chap-core compatibility
#'
#' Creates an MLproject file that allows chap-core to run R models directly
#' using renv for environment management. The generated file follows chap-core's
#' expected format with train and predict entry points.
#'
#' @param model_script Path to the R model script (default: "model.R")
#' @param model_name Name of the model. If NULL, auto-detected from the
#'   directory name
#' @param config_schema Optional JSON Schema for model configuration.
#'   Will be converted to chap-core's user_options format
#' @param output_path Where to write the MLproject file (default: "MLproject")
#' @param include_config Whether to include config parameter in entry points
#'   (default: TRUE if config_schema is provided)
#' @return Invisible path to created MLproject file
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate basic MLproject
#' generate_mlproject()
#'
#' # Generate with model name and config schema
#' config_schema <- list(
#'   type = "object",
#'   properties = list(
#'     n_samples = list(
#'       type = "integer",
#'       title = "Number of samples",
#'       description = "Number of Monte Carlo samples",
#'       default = 100
#'     )
#'   )
#' )
#' generate_mlproject(model_name = "my_arima_model", config_schema = config_schema)
#' }
#'
#' @seealso \code{\link{create_chapkit_cli}} for creating the CLI that this
#'   MLproject file will invoke
generate_mlproject <- function(model_script = "model.R",
                                model_name = NULL,
                                config_schema = NULL,
                                output_path = "MLproject",
                                include_config = !is.null(config_schema)) {

  # Auto-detect model name from directory if not provided
  if (is.null(model_name)) {
    model_name <- basename(getwd())
  }

  # Convert config_schema to user_options format
  user_options <- schema_to_user_options(config_schema)

  # Build MLproject content
  mlproject <- list(
    name = model_name,
    renv_env = "renv.lock"
  )

  # Add user_options if present
  if (!is.null(user_options)) {
    mlproject$user_options <- user_options
  }

  # Build entry points
  # Train entry point
  train_params <- list(
    train_data = "str",
    model = "str"
  )

  train_command <- sprintf("Rscript %s train --data {train_data} --model {model}",
                            model_script)

  if (include_config) {
    train_params$model_config <- list(type = "str", default = "")
    train_command <- sprintf("%s --config {model_config}", train_command)
  }

  # Predict entry point
  predict_params <- list(
    historic_data = "str",
    future_data = "str",
    model = "str",
    out_file = "str"
  )

  predict_command <- sprintf(
    "Rscript %s predict --historic {historic_data} --future {future_data} --model {model} --output {out_file}",
    model_script
  )

  if (include_config) {
    predict_params$model_config <- list(type = "str", default = "")
    predict_command <- sprintf("%s --config {model_config}", predict_command)
  }

  mlproject$entry_points <- list(
    train = list(
      parameters = train_params,
      command = train_command
    ),
    predict = list(
      parameters = predict_params,
      command = predict_command
    )
  )

  # Write MLproject file as YAML
  yaml::write_yaml(mlproject, output_path)

  message("Generated MLproject: ", output_path)
  message("\nThe MLproject file enables chap-core to run this model via:")
  message("  chap evaluate --model-name ./ --dataset-csv data.csv")

  invisible(output_path)
}
