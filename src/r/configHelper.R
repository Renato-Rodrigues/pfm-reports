# Configuration & Data Caching Helper for PFM Reports
#
# Reads from local ignored "config.yml" at project root, or falls back to
# committed "config.yml.example" to resolve directories and parameters.
#
# Also provides cached data loading functions for historical and scenario panel data.

library(yaml)
library(rprojroot)
library(pfm)

.pfm_config <- local({
  root <- find_rstudio_root_file()
  config_path <- file.path(root, "config.yml")
  example_path <- file.path(root, "config.yml.example")
  
  if (file.exists(config_path)) {
    yaml::read_yaml(config_path)
  } else if (file.exists(example_path)) {
    yaml::read_yaml(example_path)
  } else {
    list()
  }
})

#' Retrieve a user configuration parameter
#'
#' @param key Character. The configuration key to retrieve.
#' @param default Any. Fallback if the key is missing or empty.
#' @return The configuration value, or default.
#' @export
getPfmConfig <- function(key, default = NULL) {
  val <- .pfm_config[[key]]
  if (is.null(val) || (is.character(val) && nchar(as.character(val)) == 0)) {
    return(default)
  }
  return(val)
}

#' Build a display-name lookup for the 54 panel regions
#'
#' Reads the region mapping used by panelDataHistorical, returns a named
#' character vector (names = region codes, values = display names). Single-country
#' regions use the country name from the mapping; the 14 aggregate regions use
#' hardcoded descriptive labels.
#'
#' @param regionMappingFile Character. Mapping file passed to toolGetMapping.
#' @return Named character vector: region_code → display_name.
#' @export
getRegionNames <- function(regionMappingFile = "regionmapping_54.csv") {
  aggregate_labels <- c(
    AFC_other = "Sub-Saharan Africa (Other)",
    ANZ       = "Australia & New Zealand",
    BELUX     = "Belgium & Luxembourg",
    CAS       = "Central Asia",
    CHA       = "China & Periphery",
    ECE_other = "Central Eastern Europe (Other)",
    ECS       = "South-Eastern Europe",
    MEA_other = "Middle East (Other)",
    NAF_other = "North Africa (Other)",
    NEN_other = "Non-EU Northern Europe",
    NES_EU    = "Non-EU Southern Europe",
    OAS_other = "Other Asia",
    OLA       = "Other Latin America",
    SEA_other = "Southeast Asia (Other)"
  )

  # Override verbose ISO names for specific single-country regions
  name_overrides <- c(
    COD = "DR Congo",
    IRN = "Iran",
    KOR = "South Korea",
    RUS = "Russia",
    VNM = "Vietnam"
  )

  m <- tryCatch(
    madrat::toolGetMapping(regionMappingFile, type = "regional", where = "mappingfolder"),
    error = function(e) NULL
  )
  if (is.null(m)) return(aggregate_labels)

  single <- m[m$CountryCode == m$RegionCode, c("RegionCode", "X")]
  single_vec <- stats::setNames(single$X, single$RegionCode)

  region_codes <- sort(unique(m$RegionCode))
  result <- stats::setNames(
    ifelse(region_codes %in% names(aggregate_labels),
           aggregate_labels[region_codes],
           single_vec[region_codes]),
    region_codes
  )
  # Apply friendly overrides for verbose ISO country names
  override_idx <- names(result) %in% names(name_overrides)
  result[override_idx] <- name_overrides[names(result)[override_idx]]
  result
}

#' Check whether a file path is absolute
#'
#' @param path Character. The path to check.
#' @return Logical. TRUE if absolute, FALSE if relative.
#' @export
is_absolute_path <- function(path) {
  if (is.null(path) || nchar(path) == 0) return(FALSE)
  grepl("^[A-Za-z]:", path) || grepl("^/", path) || grepl("^\\\\", path)
}

#' Retrieve the current state of local/installed PFM libraries
#'
#' Evaluates the installed package versions of pfm and mrpfm, as well as the
#' modification times of the local source code (.R files) if the packages exist
#' in the development workspace. This serves as a highly robust cache-invalidation token.
#'
#' @return A list representing the current package/code state.
#' @export
get_library_state <- function() {
  root <- rprojroot::find_rstudio_root_file()
  parent_dir <- dirname(root) # This is the _code/ workspace directory
  
  # 1. Package versions
  pfm_ver <- tryCatch(as.character(packageVersion("pfm")), error = function(e) "0.0.0")
  mrpfm_ver <- tryCatch(as.character(packageVersion("mrpfm")), error = function(e) "0.0.0")
  
  # 2. Local source code modification times (for developer hot-reloading)
  local_mtimes <- list()
  for (pkg in c("pfm", "mrpfm")) {
    pkg_r_dir <- file.path(parent_dir, pkg, "R")
    if (dir.exists(pkg_r_dir)) {
      r_files <- list.files(pkg_r_dir, pattern = "\\.[Rr]$", full.names = TRUE)
      if (length(r_files) > 0) {
        mtimes <- file.info(r_files)$mtime
        local_mtimes[[pkg]] <- max(mtimes, na.rm = TRUE)
      }
    }
  }
  
  list(
    pfm_version   = pfm_ver,
    mrpfm_version = mrpfm_ver,
    local_mtimes  = local_mtimes
  )
}

#' Load or compute historical panel data with local caching
#'
#' Checks whether a cached panelDataHistorical.rds file exists under the data/ folder.
#' If it does, loads and validates its library state. If both match, returns the cached data.
#' If not, calls panelDataHistorical(...) from the pfm package, caches the data alongside
#' the library state as an RDS file, and returns it.
#'
#' @param aggregate Logical. Passed to panelDataHistorical.
#' @param y Integer vector of years. Passed to panelDataHistorical.
#' @param outputRegionMappingFile Character. Passed to panelDataHistorical.
#' @param forceRecompute Logical. If TRUE, bypasses cache and recomputes.
#' @return A magpie object.
#' @export
getPanelDataHistoricalCached <- function(
    aggregate = TRUE,
    y = 2000:2022,
    outputRegionMappingFile = "regionmapping_54.csv",
    movingAverage = 5,
    forceRecompute = FALSE) {

  root <- rprojroot::find_rstudio_root_file()

  # Check if we are running standard parameters to use cache, else recompute directly
  is_standard <- aggregate && identical(y, 2000:2022) &&
    outputRegionMappingFile == "regionmapping_54.csv" && identical(movingAverage, 5)

  if (!is_standard) {
    return(pfm::panelDataHistorical(
      aggregate = aggregate,
      y = y,
      outputRegionMappingFile = outputRegionMappingFile,
      movingAverage = movingAverage
    ))
  }
  
  cache_file <- file.path(root, "data", "panelDataHistorical.rds")
  current_state <- get_library_state()
  
  if (!forceRecompute && file.exists(cache_file)) {
    cache_obj <- tryCatch(readRDS(cache_file), error = function(e) NULL)
    
    # If the cache file contains our structured state list and states are identical, load!
    if (is.list(cache_obj) && !is.null(cache_obj$state) && !is.null(cache_obj$data)) {
      if (identical(cache_obj$state, current_state)) {
        message("Loading historical panel data from cache: ", cache_file)
        return(cache_obj$data)
      } else {
        message("Local pfm/mrpfm code or package versions changed. Invalidating cache...")
      }
    } else if (!is.null(cache_obj)) {
      message("Older raw cache file format detected. Upgrading and invalidating cache...")
    }
  }
  
  message("Computing historical panel data (running panelDataHistorical)...")
  data <- pfm::panelDataHistorical(
    aggregate = aggregate,
    y = y,
    outputRegionMappingFile = outputRegionMappingFile,
    movingAverage = movingAverage
  )
  
  # Ensure the directory exists
  dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(list(data = data, state = current_state), file = cache_file)
  message("Saved historical panel data cache to: ", cache_file)
  
  return(data)
}

#' Load or compute scenario panel data with local caching
#'
#' Checks whether a cached panelDataScenario.rds file exists under the data/ folder.
#' If it does and both its timestamp is newer than the source GDX and its library state is
#' identical, loads and returns the cached data. If not, recomputes, caches, and returns it.
#'
#' @param gdxFile Character. Path to the fulldata.gdx file.
#' @param aggregate Logical. Passed to panelDataScenario.
#' @param outputRegionMappingFile Character. Passed to panelDataScenario.
#' @param forceRecompute Logical. If TRUE, bypasses cache and recomputes.
#' @return A magpie object.
#' @export
getPanelDataScenarioCached <- function(
    gdxFile,
    aggregate = TRUE,
    outputRegionMappingFile = "regionmapping_54.csv",
    forceRecompute = FALSE) {
  
  if (is.null(gdxFile) || nchar(gdxFile) == 0 || !file.exists(gdxFile)) {
    return(NULL)
  }
  
  root <- rprojroot::find_rstudio_root_file()
  
  # Check standard parameters
  is_standard <- aggregate && outputRegionMappingFile == "regionmapping_54.csv"
  
  if (!is_standard) {
    return(pfm::panelDataScenario(
      gdxFile = gdxFile,
      aggregate = aggregate,
      outputRegionMappingFile = outputRegionMappingFile
    ))
  }
  
  cache_file <- file.path(root, "data", "panelDataScenario.rds")
  gdx_mtime <- file.info(gdxFile)$mtime
  current_state <- get_library_state()
  
  if (!forceRecompute && file.exists(cache_file)) {
    cache_mtime <- file.info(cache_file)$mtime
    
    # Check both timestamp and library versions/code state
    if (!is.na(cache_mtime) && !is.na(gdx_mtime) && cache_mtime > gdx_mtime) {
      cache_obj <- tryCatch(readRDS(cache_file), error = function(e) NULL)
      
      if (is.list(cache_obj) && !is.null(cache_obj$state) && !is.null(cache_obj$data)) {
        if (identical(cache_obj$state, current_state)) {
          message("Loading scenario panel data from cache: ", cache_file)
          return(cache_obj$data)
        } else {
          message("Local pfm/mrpfm code or package versions changed. Invalidating cache...")
        }
      } else if (!is.null(cache_obj)) {
        message("Older raw cache file format detected. Upgrading and invalidating cache...")
      }
    } else {
      message("GDX file has been modified or cache is missing. Recomputing scenario data...")
    }
  }
  
  message("Computing scenario panel data from GDX: ", gdxFile)
  data <- pfm::panelDataScenario(
    gdxFile = gdxFile,
    aggregate = aggregate,
    outputRegionMappingFile = outputRegionMappingFile
  )
  
  # Ensure the directory exists
  dir.create(dirname(cache_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(list(data = data, state = current_state), file = cache_file)
  message("Saved scenario panel data cache to: ", cache_file)
  
  return(data)
}
