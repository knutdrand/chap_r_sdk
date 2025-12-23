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
