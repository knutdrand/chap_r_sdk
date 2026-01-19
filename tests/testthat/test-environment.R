# Tests for environment configuration functions

# ============================================================================
# read_renv_r_version Tests
# ============================================================================

test_that("read_renv_r_version extracts R version from lockfile", {
  # Create a temporary renv.lock file
  temp_lock <- tempfile(fileext = ".lock")
  lock_content <- list(
    R = list(
      Version = "4.3.2",
      Repositories = list(
        list(Name = "CRAN", URL = "https://cloud.r-project.org")
      )
    ),
    Packages = list(
      dplyr = list(
        Package = "dplyr",
        Version = "1.1.0",
        Source = "Repository"
      )
    )
  )
  jsonlite::write_json(lock_content, temp_lock, auto_unbox = TRUE)
  on.exit(unlink(temp_lock))

  version <- read_renv_r_version(temp_lock)
  expect_equal(version, "4.3.2")
})

test_that("read_renv_r_version errors when file not found", {
  expect_error(
    read_renv_r_version("nonexistent.lock"),
    "renv.lock not found"
  )
})

test_that("read_renv_r_version errors when R version missing", {
  temp_lock <- tempfile(fileext = ".lock")
  lock_content <- list(
    R = list(
      Repositories = list()
    ),
    Packages = list()
  )
  jsonlite::write_json(lock_content, temp_lock, auto_unbox = TRUE)
  on.exit(unlink(temp_lock))

  expect_error(
    read_renv_r_version(temp_lock),
    "R version not found"
  )
})

# ============================================================================
# get_environment_info Tests
# ============================================================================

test_that("get_environment_info returns defaults when no lockfile", {
  # Run from a temp directory without renv.lock
  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)
  on.exit(setwd(old_wd))

  info <- get_environment_info("nonexistent_renv.lock")

  expect_null(info$r_version)
  expect_false(info$has_renv_lock)
  expect_equal(info$system_deps, list())
})

test_that("get_environment_info extracts info from lockfile", {
  temp_lock <- tempfile(fileext = ".lock")
  lock_content <- list(
    R = list(Version = "4.2.1"),
    Packages = list()
  )
  jsonlite::write_json(lock_content, temp_lock, auto_unbox = TRUE)
  on.exit(unlink(temp_lock))

  info <- get_environment_info(temp_lock)

  expect_equal(info$r_version, "4.2.1")
  expect_true(info$has_renv_lock)
})

# ============================================================================
# write_default_chap_yml Tests
# ============================================================================

test_that("write_default_chap_yml creates config file", {
  temp_yml <- tempfile(fileext = ".yml")
  on.exit(unlink(temp_yml))

  write_default_chap_yml(r_version = "4.3.0", output_path = temp_yml)

  expect_true(file.exists(temp_yml))

  config <- yaml::read_yaml(temp_yml)
  expect_true("environment" %in% names(config))
  expect_null(config$environment$base_image)
  expect_equal(config$environment$extra_system_deps, list())
})

# ============================================================================
# read_chap_yml Tests
# ============================================================================

test_that("read_chap_yml returns defaults when file not found", {
  config <- read_chap_yml("nonexistent_chap.yml")

  expect_true("environment" %in% names(config))
  expect_null(config$environment$base_image)
})

test_that("read_chap_yml reads existing file", {
  temp_yml <- tempfile(fileext = ".yml")
  yaml::write_yaml(list(
    environment = list(
      base_image = "rocker/r-ver:4.3.0",
      extra_system_deps = list("libgdal-dev")
    )
  ), temp_yml)
  on.exit(unlink(temp_yml))

  config <- read_chap_yml(temp_yml)

  expect_equal(config$environment$base_image, "rocker/r-ver:4.3.0")
  # YAML reads single-element arrays as vectors, so check value matches
  expect_true("libgdal-dev" %in% unlist(config$environment$extra_system_deps))
})

# ============================================================================
# generate_dockerfile_content Tests
# ============================================================================

test_that("generate_dockerfile_content creates valid Dockerfile", {
  content <- generate_dockerfile_content(
    base_image = "rocker/r-ver:4.3.2",
    system_deps = c("libcurl4-openssl-dev", "libssl-dev"),
    python_version = "3.12",
    chapkit_spec = "chapkit"
  )

  expect_match(content, "FROM rocker/r-ver:4.3.2")
  expect_match(content, "libcurl4-openssl-dev")
  expect_match(content, "libssl-dev")
  expect_match(content, "pip install.*chapkit")
  expect_match(content, "renv::restore")
})

test_that("generate_dockerfile_content handles no system deps", {
  content <- generate_dockerfile_content(
    base_image = "rocker/r-ver:4.3.2",
    system_deps = character(0),
    python_version = "3.12",
    chapkit_spec = "chapkit"
  )

  expect_match(content, "No system dependencies detected")
  expect_false(grepl("apt-get install.*libcurl", content))
})

test_that("generate_dockerfile_content includes chapkit version", {
  content <- generate_dockerfile_content(
    base_image = "rocker/r-ver:4.3.2",
    system_deps = character(0),
    python_version = "3.12",
    chapkit_spec = "chapkit==0.1.0"
  )

  expect_match(content, "pip install.*chapkit==0.1.0")
})

# ============================================================================
# generate_dockerfile Tests
# ============================================================================

test_that("generate_dockerfile errors without renv.lock", {
  old_wd <- getwd()
  temp_dir <- tempdir()
  setwd(temp_dir)
  on.exit(setwd(old_wd))

  # Ensure no renv.lock exists
  if (file.exists("renv.lock")) unlink("renv.lock")

  expect_error(
    generate_dockerfile(),
    "renv.lock not found"
  )
})

test_that("generate_dockerfile creates Dockerfile", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  # Create minimal renv.lock
  lock_content <- list(
    R = list(Version = "4.3.2"),
    Packages = list()
  )
  jsonlite::write_json(lock_content, "renv.lock", auto_unbox = TRUE)

  # Create renv directory structure
  dir.create("renv", showWarnings = FALSE)
  writeLines("# activate.R", "renv/activate.R")
  writeLines("source('renv/activate.R')", ".Rprofile")

  # Generate Dockerfile
  result <- generate_dockerfile(output_path = "Dockerfile")

  expect_true(file.exists("Dockerfile"))
  expect_equal(result, "Dockerfile")

  dockerfile <- readLines("Dockerfile")
  expect_true(any(grepl("rocker/r-ver:4.3.2", dockerfile)))
})

# ============================================================================
# detect_system_deps Tests
# ============================================================================

test_that("detect_system_deps returns empty when pak unavailable", {
  # This test will work differently depending on whether pak is installed
  # If pak is not available, it should return empty with a warning
  temp_lock <- tempfile(fileext = ".lock")
  lock_content <- list(
    R = list(Version = "4.3.2"),
    Packages = list(
      curl = list(Package = "curl", Version = "5.0.0")
    )
  )
  jsonlite::write_json(lock_content, temp_lock, auto_unbox = TRUE)
  on.exit(unlink(temp_lock))

  # Should not error, returns character(0) if pak unavailable
  result <- detect_system_deps(temp_lock)
  expect_type(result, "character")
})

test_that("detect_system_deps returns empty for no packages", {
  temp_lock <- tempfile(fileext = ".lock")
  lock_content <- list(
    R = list(Version = "4.3.2"),
    Packages = list()
  )
  jsonlite::write_json(lock_content, temp_lock, auto_unbox = TRUE)
  on.exit(unlink(temp_lock))

  result <- detect_system_deps(temp_lock)
  expect_equal(result, character(0))
})

# ============================================================================
# schema_to_user_options Tests
# ============================================================================

test_that("schema_to_user_options returns NULL for NULL schema", {
  expect_null(schema_to_user_options(NULL))
})

test_that("schema_to_user_options returns NULL for schema without properties", {
  schema <- list(type = "object")
  expect_null(schema_to_user_options(schema))
})

test_that("schema_to_user_options returns NULL for empty properties", {
  schema <- list(type = "object", properties = list())
  expect_null(schema_to_user_options(schema))
})

test_that("schema_to_user_options maps integer type correctly", {
  schema <- list(
    type = "object",
    properties = list(
      n_samples = list(
        type = "integer",
        title = "Sample Count",
        description = "Number of samples",
        default = 100
      )
    )
  )

  result <- schema_to_user_options(schema)

  expect_equal(result$n_samples$type, "integer")
  expect_equal(result$n_samples$title, "Sample Count")
  expect_equal(result$n_samples$description, "Number of samples")
  expect_equal(result$n_samples$default, 100)
})

test_that("schema_to_user_options passes through number type", {
  schema <- list(
    type = "object",
    properties = list(
      learning_rate = list(
        type = "number",
        default = 0.01
      )
    )
  )

  result <- schema_to_user_options(schema)
  expect_equal(result$learning_rate$type, "number")
})

test_that("schema_to_user_options passes through string and boolean types", {
  schema <- list(
    type = "object",
    properties = list(
      method = list(type = "string", default = "ets"),
      verbose = list(type = "boolean", default = TRUE)
    )
  )

  result <- schema_to_user_options(schema)

  expect_equal(result$method$type, "string")
  expect_equal(result$method$default, "ets")
  expect_equal(result$verbose$type, "boolean")
  expect_equal(result$verbose$default, TRUE)
})

test_that("schema_to_user_options handles multiple properties", {
  schema <- list(
    type = "object",
    properties = list(
      param1 = list(type = "integer"),
      param2 = list(type = "string"),
      param3 = list(type = "number")
    )
  )

  result <- schema_to_user_options(schema)

  expect_equal(length(result), 3)
  expect_true(all(c("param1", "param2", "param3") %in% names(result)))
})

# ============================================================================
# generate_mlproject Tests
# ============================================================================

test_that("generate_mlproject creates basic MLproject file", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  result <- generate_mlproject(model_name = "test_model", output_path = "MLproject")

  expect_true(file.exists("MLproject"))
  expect_equal(result, "MLproject")

  mlproject <- yaml::read_yaml("MLproject")
  expect_equal(mlproject$name, "test_model")
  expect_equal(mlproject$renv_env, "renv.lock")
})

test_that("generate_mlproject includes entry points", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  generate_mlproject(model_name = "test_model")
  mlproject <- yaml::read_yaml("MLproject")

  # Check train entry point
  expect_true("train" %in% names(mlproject$entry_points))
  expect_true("train_data" %in% names(mlproject$entry_points$train$parameters))
  expect_true("model" %in% names(mlproject$entry_points$train$parameters))
  expect_match(mlproject$entry_points$train$command, "train --data")

  # Check predict entry point
  expect_true("predict" %in% names(mlproject$entry_points))
  expect_true("historic_data" %in% names(mlproject$entry_points$predict$parameters))
  expect_true("future_data" %in% names(mlproject$entry_points$predict$parameters))
  expect_true("out_file" %in% names(mlproject$entry_points$predict$parameters))
  expect_match(mlproject$entry_points$predict$command, "predict --historic")
})

test_that("generate_mlproject includes user_options from config_schema", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  config_schema <- list(
    type = "object",
    properties = list(
      n_samples = list(
        type = "integer",
        title = "Number of samples",
        default = 100
      )
    )
  )

  generate_mlproject(model_name = "test_model", config_schema = config_schema)
  mlproject <- yaml::read_yaml("MLproject")

  expect_true("user_options" %in% names(mlproject))
  expect_true("n_samples" %in% names(mlproject$user_options))
  expect_equal(mlproject$user_options$n_samples$type, "integer")
  expect_equal(mlproject$user_options$n_samples$default, 100)
})

test_that("generate_mlproject includes config parameter when schema provided", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  config_schema <- list(
    type = "object",
    properties = list(param1 = list(type = "string"))
  )

  generate_mlproject(model_name = "test_model", config_schema = config_schema)
  mlproject <- yaml::read_yaml("MLproject")

  # Config parameter should be in entry points
  expect_true("model_config" %in% names(mlproject$entry_points$train$parameters))
  expect_true("model_config" %in% names(mlproject$entry_points$predict$parameters))

  # Commands should include --config flag
  expect_match(mlproject$entry_points$train$command, "--config")
  expect_match(mlproject$entry_points$predict$command, "--config")
})

test_that("generate_mlproject excludes config parameter without schema", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  generate_mlproject(model_name = "test_model")
  mlproject <- yaml::read_yaml("MLproject")

  # Config parameter should NOT be in entry points
  expect_false("model_config" %in% names(mlproject$entry_points$train$parameters))
  expect_false("model_config" %in% names(mlproject$entry_points$predict$parameters))

  # Commands should not include --config flag
  expect_false(grepl("--config", mlproject$entry_points$train$command))
  expect_false(grepl("--config", mlproject$entry_points$predict$command))
})

test_that("generate_mlproject uses custom model script", {
  old_wd <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  generate_mlproject(model_script = "my_custom_model.R", model_name = "test_model")
  mlproject <- yaml::read_yaml("MLproject")

  expect_match(mlproject$entry_points$train$command, "my_custom_model.R")
  expect_match(mlproject$entry_points$predict$command, "my_custom_model.R")
})

test_that("generate_mlproject auto-detects model name from directory", {
  old_wd <- getwd()
  temp_dir <- tempfile(pattern = "my_model_dir_")
  dir.create(temp_dir)
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })

  generate_mlproject()
  mlproject <- yaml::read_yaml("MLproject")

  # Model name should match directory name
  expect_equal(mlproject$name, basename(temp_dir))
})
