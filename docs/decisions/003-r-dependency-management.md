# R Dependency Management System

**Date**: 2025-12-04
**Status**: Decided
**Decision**: Use renv (may add pak later if speed becomes critical)
**Context**: Finding an R equivalent to Python's uv for dependency management

## Context

The CHAP R SDK needs a robust dependency management system for R packages, similar to how Python uses `uv` for fast, reliable package management. We need to ensure reproducible environments, manage dependencies across projects, and provide a smooth developer experience for both package development and model deployment.

Python's `uv` has set a new standard with 10-100x faster package installation, comprehensive project management, and a "Cargo for Python" vision. This document investigates R's ecosystem to find the closest equivalent or best combination of tools.

## Research Questions Addressed

1. What are the modern R dependency management tools available?
2. Which tools provide lock files and reproducible environments?
3. What are the pros/cons of each tool?
4. Which tool is most similar to uv in philosophy (fast, modern, reliable)?
5. What is the community adoption and maturity level?
6. How do these tools integrate with package development workflows?
7. What about R version management?

## Available Tools

### 1. renv (Posit/RStudio)

**Version**: Latest release July 24, 2025
**Maintainer**: Kevin Ushey (Posit)
**Status**: Industry standard, actively maintained

**Philosophy**: Project-level dependency isolation and reproducibility

**Strengths**:
- Industry standard with excellent documentation
- Creates `renv.lock` files with exact package versions and sources
- Tracks CRAN, Bioconductor, GitHub, GitLab, BitBucket packages
- JSON format with comprehensive metadata
- Project-local libraries completely isolated
- Snapshot and restore workflow
- Integrated with Posit ecosystem (RStudio, Posit Connect)
- Docker integration well-documented
- Works with multiple package sources
- Active development and support

**Limitations**:
- Moderate speed (20+ seconds for medium projects)
- Sequential installation by default
- Steeper learning curve
- Requires project structure
- Doesn't track R version itself

**Lock File Format** (renv.lock):
```json
{
  "R": {
    "Version": "4.3.2",
    "Repositories": [
      {
        "Name": "CRAN",
        "URL": "https://cran.rstudio.com"
      }
    ]
  },
  "Packages": {
    "dplyr": {
      "Package": "dplyr",
      "Version": "1.1.4",
      "Source": "Repository",
      "Repository": "CRAN",
      "Hash": "fedd9d00c2944ff00a0e2696ccf048ec"
    }
  }
}
```

**Performance**: Moderate (improves significantly with pak backend)

**Community Adoption**: Very high - default in RStudio IDE, enterprise standard

### 2. pak (r-lib)

**Version**: Latest release July 23, 2025
**Maintainer**: r-lib team
**Status**: Actively maintained, growing adoption

**Philosophy**: Fast, safe, and convenient package installation

**Strengths**:
- Extremely fast parallel installation (10-20x faster than standard)
- Parallel HTTP operations for metadata and downloads
- Local caching of metadata and packages
- Dependency solver prevents version conflicts upfront
- Works as renv backend (since renv 1.0.0)
- Available on CRAN
- Simple API: `pak::pak("package_name")`
- "VAST difference in Docker build times" (user reports)

**Limitations**:
- Not a complete project management solution
- Lock file machinery less mature than renv
- Has its own lockfile format (not directly compatible with renv.lock)
- Cannot handle certain GitHub dependency edge cases
- pak integration with renv has cache compatibility issues
- May rebuild from source rather than using cache when enabled in renv

**Lock File Support**: Has `pak::lockfile_create()` and `pak::lockfile_install()` but own format

**Performance**: Excellent - designed for speed

**Community Adoption**: Growing, especially in CI/CD contexts (769 GitHub stars)

**Integration with renv**:
```r
# Enable pak as renv backend
options(renv.config.pak.enabled = TRUE)
# or
Sys.setenv(RENV_CONFIG_PAK_ENABLED = "TRUE")
```

### 3. groundhog

**Version**: 3.2.3 (July 2025)
**Status**: Actively maintained, academic favorite

**Philosophy**: Date-based package versioning for minimal friction

**Strengths**:
- Zero learning curve
- No project structure required
- Works with individual scripts
- Just change `library(pkg)` to `groundhog.library(pkg, "2025-01-01")`
- Works across R versions and operating systems
- Keeps multiple versions of same package
- Ideal for sharing standalone R scripts
- Popular in psychological research

**Limitations**:
- No explicit lockfile
- Date-based approach less precise than explicit versions
- No explicit dependency resolution
- Not designed for team workflows
- Less control than lockfile-based approaches

**Performance**: Moderate - standard installation speeds, no parallelization

**Community Adoption**: Strong in academic/research, especially psychology

**Usage**:
```r
library(groundhog)
groundhog.library("dplyr", "2025-01-01")
groundhog.library("ggplot2", "2025-01-01")
```

### 4. jetpack

**Version**: Available on CRAN
**Status**: Maintenance uncertain

**Philosophy**: Inspired by Yarn, Bundler, Pipenv - lightweight and simple

**Strengths**:
- Lightweight - only 3 files added to project
- Uses familiar DESCRIPTION file format (like R packages)
- Uses renv.lock for version locking
- Built on top of renv
- Simple CLI and R interface
- Good for R package developers

**Limitations**:
- "New and rough around the edges"
- "Scant documentation"
- Less mature than renv
- Smaller community
- Depends on renv backend

**Performance**: Moderate (same as renv)

**Community Adoption**: Low - niche tool

**Usage**:
```r
# Uses DESCRIPTION file for dependencies
jetpack::init()     # Initialize project
jetpack::install()  # Install dependencies
jetpack::update()   # Update and lock
```

### 5. capsule

**Version**: Active on GitHub
**Status**: Actively developed, emerging tool

**Philosophy**: "Inversion of renv for low effort reproducible R package libraries"

**Strengths**:
- Simpler workflow than renv
- Very fast snapshot creation (1-2 seconds)
- Creates renv.lock files (compatible format)
- Designed for integration into build pipelines
- Uses local library approach

**Limitations**:
- Newer tool, less mature
- Smaller community
- Less documentation
- Limited adoption

**Performance**: Excellent for snapshot creation

**Community Adoption**: Low but growing

### 6. rig (R Installation Manager)

**Version**: 0.7.1 (May 2025)
**Maintainer**: r-lib team
**Status**: Actively maintained

**Philosophy**: Fast R version switching (like pyenv for Python)

**Note**: This is NOT a dependency manager but an R version manager

**Strengths**:
- Written in Rust (like uv!)
- Fast R version switching
- Cross-platform (macOS, Windows, Linux)
- Actively maintained
- Simple CLI

**Usage**:
```bash
rig add 4.3.2       # Install R version
rig default 4.3.2   # Set default
rig list            # List installed versions
```

**Why It Matters**: None of the dependency tools manage R version itself. rig fills this gap.

## Comparison Matrix

| Feature | renv | pak | renv+pak | groundhog | jetpack | capsule |
|---------|------|-----|----------|-----------|---------|---------|
| **Lock Files** | ✅ Excellent | ⚠️ Own format | ✅ Excellent | ❌ None | ✅ Good | ✅ Good |
| **Speed** | ⚠️ Moderate | ✅ Excellent | ✅ Very Good | ⚠️ Moderate | ⚠️ Moderate | ✅ Very Good |
| **Reproducibility** | ✅ Excellent | ⚠️ Moderate | ✅ Excellent | ✅ Good | ✅ Good | ✅ Good |
| **Project Isolation** | ✅ Yes | ❌ No | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Learning Curve** | ⚠️ Moderate | ✅ Easy | ⚠️ Moderate | ✅ Very Easy | ✅ Easy | ✅ Easy |
| **CI/CD Integration** | ✅ Excellent | ✅ Excellent | ✅ Excellent | ⚠️ Moderate | ⚠️ Good | ⚠️ Good |
| **Docker Support** | ✅ Excellent | ✅ Good | ✅ Excellent | ⚠️ Moderate | ⚠️ Good | ⚠️ Good |
| **Community Size** | ✅ Very Large | ⚠️ Growing | ✅ Large | ⚠️ Moderate | ❌ Small | ❌ Small |
| **Enterprise** | ✅ High | ⚠️ Moderate | ✅ High | ❌ Low | ❌ Low | ❌ Low |
| **Academic** | ✅ High | ⚠️ Moderate | ⚠️ Moderate | ✅ High | ❌ Low | ❌ Low |
| **Maintenance** | ✅ Active | ✅ Active | ✅ Active | ✅ Active | ⚠️ Uncertain | ✅ Active |
| **Package Sources** | ✅ Multiple | ✅ Multiple | ✅ Multiple | ✅ Multiple | ✅ Multiple | ✅ Multiple |
| **Parallel Install** | ❌ No | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Dependency Solver** | ⚠️ Basic | ✅ Advanced | ✅ Advanced | ❌ No | ⚠️ Basic | ⚠️ Basic |
| **Single Script** | ❌ No | ✅ Yes | ⚠️ Partial | ✅ Yes | ❌ No | ❌ No |
| **R Version Mgmt** | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No |

## Python uv Comparison

### What Makes uv Special:
- **10-100x faster** than pip (8x without cache, 80-115x with warm cache)
- Written in **Rust** for performance
- **Single binary** that replaces multiple tools
- **"Cargo for Python"** vision - comprehensive project manager
- **Parallel downloads** and dependency resolution
- **Drop-in replacement** for existing workflows

### R Tools Ranked by uv Philosophy Match:

1. **pak (70% match)** - Closest to uv's speed/performance focus
   - ✅ Fast parallel operations
   - ✅ Modern design
   - ✅ Safe (dependency solver)
   - ❌ Not a complete project manager
   - ❌ No Rust implementation

2. **renv + pak (85% match)** - Best combined solution
   - ✅ Fast installation (pak)
   - ✅ Complete project management (renv)
   - ✅ Lock files (renv)
   - ✅ Reproducibility (renv)
   - ⚠️ Two tools, not one
   - ⚠️ Integration has rough edges

3. **renv alone (60% match)** - Comprehensive but slower
   - ✅ Complete project management
   - ✅ Excellent lock files
   - ✅ Industry standard
   - ❌ Slower performance

4. **rig + pak + renv (90% match conceptually)** - "Cargo for R"
   - ✅ R version management (rig)
   - ✅ Fast installation (pak)
   - ✅ Project management (renv)
   - ⚠️ Three separate tools
   - ⚠️ Requires coordination

## Recommendation

### Decision: Start with renv, Consider pak Later

**Current Decision**: Use **renv alone** for CHAP R SDK

**Rationale for Starting with renv**:

1. **Industry Standard**: renv is the de facto standard, backed by Posit
2. **Proven Stability**: Mature, well-tested, and reliable
3. **Complete Solution**: Lock files, reproducibility, project isolation
4. **Excellent Documentation**: Comprehensive guides and community support
5. **Enterprise Ready**: Widely adopted in production environments
6. **KISS Principle**: Start simple, add complexity only when needed
7. **Active Development**: Regular updates and maintenance
8. **No Integration Issues**: Avoid pak+renv integration rough edges initially

**Current Speed Assessment**: For package development and moderate usage, renv's speed is acceptable. Installation times of 20-30 seconds for medium projects are not blockers for developer productivity.

**Future Consideration**: If speed becomes a critical issue (e.g., frequent Docker rebuilds, large CI/CD pipelines, or user feedback about slow installation), we can enable pak as a backend:

```r
# Future optimization if needed
options(renv.config.pak.enabled = TRUE)
```

This provides a clear upgrade path without committing to the complexity and potential issues of pak integration upfront.

**Implementation (Current)**:

```r
# Initialize project with renv
renv::init()

# Install packages
renv::install("package_name")

# Create lockfile snapshot
renv::snapshot()

# Restore from lockfile
renv::restore()
```

**For CHAP R SDK Development**:

```r
# DESCRIPTION file already specifies dependencies
# Use renv for development environment

# .Rprofile in project root (if using renv)
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
  # Note: NOT enabling pak initially
  # options(renv.config.pak.enabled = TRUE)  # Add later if needed
}
```

### When to Consider pak Integration

Enable pak backend if any of these conditions arise:

1. **Docker Build Times**: If Docker builds take >5 minutes due to package installation
2. **CI/CD Bottlenecks**: If CI/CD pipelines are consistently slow due to package restoration
3. **Developer Feedback**: If multiple developers complain about installation speed
4. **Large Dependency Tree**: If the project grows to 50+ direct dependencies
5. **Frequent Rebuilds**: If the workflow involves frequent clean installs

**Migration Path**: Enabling pak is trivial - just add one line to configuration:
```r
options(renv.config.pak.enabled = TRUE)
```

### Alternative Recommendations (For Reference)

**For Speed-Only (Installation Without Project Management)**:
→ **Use pak alone**

```r
pak::pak("dplyr")
pak::pak("tidyverse/dplyr")  # From GitHub
```

**For Academic/Individual Scripts**:
→ **Use groundhog**

```r
library(groundhog)
groundhog.library("dplyr", "2025-01-01")
```

**For Maximum Reproducibility (Conservative)**:
→ **Use renv without pak** (if stability is critical over speed)

```r
renv::init()
renv::snapshot()
renv::restore()
```

## R Version Management

**Important**: None of the dependency tools manage R version itself.

**Recommendation**: Use **rig** for R version management

```bash
# Install multiple R versions
rig add 4.3.2
rig add 4.4.0

# Switch versions
rig default 4.3.2

# List installed versions
rig list
```

**Complete uv-like Workflow**:
```
rig (R versions) + renv (projects/deps) + pak (fast install)
```

## Best Practices

### 1. Project Initialization

```r
# Create new project with renv
renv::init()

# Enable pak backend
options(renv.config.pak.enabled = TRUE)

# Add to .Rprofile
cat('options(renv.config.pak.enabled = TRUE)\n',
    file = ".Rprofile", append = TRUE)
```

### 2. Adding Dependencies

```r
# Install and add to lock file
renv::install("dplyr")
renv::snapshot()

# Install from GitHub
renv::install("tidyverse/dplyr")
renv::snapshot()

# Install with specific version
renv::install("dplyr@1.1.4")
renv::snapshot()
```

### 3. Docker Integration

```dockerfile
FROM rocker/r-ver:4.3.2

# Enable pak for faster installation
ENV RENV_CONFIG_PAK_ENABLED=TRUE

# Copy renv lock file
COPY renv.lock /app/renv.lock

# Install renv
RUN R -e "install.packages('renv')"

# Restore from lock file (uses pak automatically)
WORKDIR /app
RUN R -e "renv::restore()"

# Copy application code
COPY . /app

CMD ["Rscript", "app.R"]
```

### 4. CI/CD Integration

```yaml
# GitHub Actions example
- name: Install R dependencies
  run: |
    install.packages('renv')
    Sys.setenv(RENV_CONFIG_PAK_ENABLED = "TRUE")
    renv::restore()
  shell: Rscript {0}
```

### 5. Team Workflow

```r
# Team member clones repo

# Restore environment
renv::restore()  # Uses renv.lock

# Work on project...

# Update dependencies
renv::install("new_package")
renv::snapshot()  # Updates renv.lock

# Commit renv.lock to version control
git add renv.lock
git commit -m "Add new_package dependency"
```

## Migration Strategy

### For Existing Projects

**From No Dependency Management**:
```r
# Initialize renv in existing project
renv::init()

# renv will detect installed packages and create lock file
renv::snapshot()

# Enable pak for future installs
options(renv.config.pak.enabled = TRUE)
```

**From Base R package.json (if applicable)**:
```r
# renv can discover dependencies from DESCRIPTION
renv::init()
```

**From groundhog**:
```r
# No direct migration - renv uses different approach
# Recommendation: Initialize fresh renv environment
renv::init()

# Install needed packages with specific versions
renv::install("dplyr@1.1.4")
```

## Known Issues and Workarounds

### pak + renv Integration Issues

**Issue**: Cache compatibility problems between pak and renv
**Status**: Known issue (#1846 in renv GitHub)
**Workaround**:
```r
# Clear cache if issues occur
renv::purge()

# Or disable pak temporarily
options(renv.config.pak.enabled = FALSE)
```

**Issue**: pak may rebuild from source instead of using cache
**Status**: Integration rough edges
**Workaround**: Accept rebuild or disable pak for specific installs

### renv.lock Reading

**Issue**: pak cannot directly read renv.lock files
**Status**: Known limitation (#343 in pak GitHub)
**Workaround**: Use renv::restore() which can use pak backend

## Testing Strategy

```r
# tests/testthat/test-dependencies.R

test_that("renv lock file is valid", {
  expect_true(file.exists("renv.lock"))

  lock <- jsonlite::read_json("renv.lock")
  expect_true("R" %in% names(lock))
  expect_true("Packages" %in% names(lock))
})

test_that("all dependencies can be restored", {
  # In CI/CD
  skip_if_not(Sys.getenv("CI") == "true")

  expect_silent(renv::restore())
})

test_that("pak backend is enabled", {
  expect_true(getOption("renv.config.pak.enabled", FALSE))
})
```

## Performance Benchmarks

**renv alone**:
- Initial setup: ~30-60 seconds (medium project)
- Package installation: Sequential, 20+ seconds
- Restore from lock: Depends on cache, 30-120 seconds

**renv + pak**:
- Initial setup: ~30-60 seconds (same)
- Package installation: Parallel, 2-5 seconds (10-20x faster)
- Restore from lock: 5-15 seconds (significantly faster)
- Docker builds: "VAST difference" reported by users

**pak alone**:
- Package installation: 1-3 seconds (extremely fast)
- No project isolation overhead

## Community Statistics

**CRAN Ecosystem**:
- ~19,000 packages on CRAN
- ~80% of packages with URLs use GitHub
- Average 21 new/updated packages per day

**Tool Adoption**:
- **renv**: Default in RStudio, enterprise standard, very high adoption
- **pak**: 769 GitHub stars, growing in CI/CD
- **groundhog**: Strong academic following, especially psychology
- **jetpack**: Niche adoption
- **capsule**: Emerging tool

## Related Work

- **CLIM-210**: YAML Configuration Parsing - complementary configuration management
- **CLIM-203**: CLI Argument Parsing - integrates with environment setup

## References

### renv:
- [renv Introduction](https://rstudio.github.io/renv/articles/renv.html)
- [renv CRAN Package](https://cran.r-project.org/web/packages/renv/renv.pdf)
- [renv Docker Integration](https://rstudio.github.io/renv/articles/docker.html)
- [renv Changelog](https://rstudio.github.io/renv/news/index.html)

### pak:
- [pak Official Site](https://pak.r-lib.org/)
- [pak GitHub Repository](https://github.com/r-lib/pak)
- [pak CRAN Package](https://cran.r-project.org/web/packages/pak/pak.pdf)
- [pak 0.6.0 Release](https://tidyverse.org/blog/2023/09/pak-0-6-0/)

### groundhog:
- [Groundhog Official Site](https://groundhogr.com/)
- [groundhog CRAN Package](https://cran.r-project.org/package=groundhog)
- [RENV: comparing groundhog with renv](https://groundhogr.com/renv/)

### jetpack:
- [jetpack GitHub Repository](https://github.com/ankane/jetpack)
- [jetpack CRAN Package](https://cran.r-project.org/web/packages/jetpack/index.html)

### capsule:
- [capsule GitHub Repository](https://github.com/MilesMcBain/capsule)

### rig:
- [rig GitHub Repository](https://github.com/r-lib/rig)

### Comparisons:
- [The Require approach, comparing pak and renv](https://require.predictiveecology.org/articles/Require.html)
- [renv vs groundhog vs jetpack](https://www.brodrigues.co/blog/2023-10-05-repro_overview/)
- [pak and renv integration issues](https://github.com/rstudio/renv/issues/1846)

### Python uv (for comparison):
- [Python UV: The Ultimate Guide](https://www.datacamp.com/tutorial/python-uv)
- [uv GitHub Repository](https://github.com/astral-sh/uv)
- [uv vs pip Performance](https://realpython.com/uv-vs-pip/)

## Conclusion

**Use renv for CHAP R SDK** as the dependency management solution. This provides:

1. **Reproducibility**: Excellent lock file support (renv.lock)
2. **Industry Standard**: renv is the de facto choice, backed by Posit
3. **Complete Solution**: Project isolation, dependency tracking, version locking
4. **Proven Stability**: Mature, well-tested implementation
5. **CI/CD Ready**: Works seamlessly in automated environments and Docker
6. **Active Maintenance**: Regularly updated and supported
7. **Clear Documentation**: Comprehensive guides and community resources

**Current Implementation**:
```r
# Initialize renv for project
renv::init()

# Standard workflow
renv::install("package_name")
renv::snapshot()
renv::restore()
```

**Future Speed Optimization**: If installation speed becomes a bottleneck (Docker builds >5min, CI/CD slowdowns, developer complaints), we can easily enable pak as a backend:
```r
options(renv.config.pak.enabled = TRUE)
```

This provides a 10-20x speedup while maintaining the same renv workflow.

**For R Version Management**: Use **rig** alongside renv to complete the toolchain:
```
rig (R versions) + renv (projects) [+ pak if needed (speed)] = "Cargo for R"
```

**Decision Summary**: Start with renv alone for simplicity and stability. The option to add pak remains available as a straightforward optimization if speed becomes critical. This pragmatic approach avoids premature optimization while maintaining a clear upgrade path.
