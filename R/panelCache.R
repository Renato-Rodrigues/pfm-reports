# Report-side panel loading with a local rds cache (ADR 0018/0021). These wrap the pfm panel
# builders and memoise the result so a render does not rebuild the panel every time — a report
# convenience, not compute logic (no estimation/selection here).

#' Installed pfm/mrpfm versions (panel-cache invalidation token)
#'
#' @return A list with \code{pfm_version} and \code{mrpfm_version}.
#' @importFrom utils packageVersion
#' @export
get_library_state <- function() {
  pkgver <- function(p) tryCatch(as.character(packageVersion(p)), error = function(e) "0.0.0")
  list(pfm_version = pkgver("pfm"), mrpfm_version = pkgver("mrpfm"))
}

#' Load or compute the historical panel data with local caching
#'
#' Returns the pfm historical panel, cached to \code{<panelCacheDir>/panelDataHistorical.rds}
#' keyed on the installed pfm/mrpfm versions. Non-standard parameters bypass the cache.
#'
#' @param aggregate,y,outputRegionMappingFile,movingAverage Passed to
#'   \code{pfm::panelDataHistorical}.
#' @param forceRecompute Logical. Bypass the cache.
#' @param panelCacheDir Character. Directory for the cached rds. Default
#'   \code{getOption("pfmreports.panelCacheDir", file.path(getwd(), "data"))}.
#' @return A magpie object.
#' @export
getPanelDataHistoricalCached <- function(aggregate = TRUE, y = 2000:2022,
                                         outputRegionMappingFile = "regionmapping_54.csv",
                                         movingAverage = 5, forceRecompute = FALSE,
                                         panelCacheDir = getOption("pfmreports.panelCacheDir",
                                                                   file.path(getwd(), "data"))) {
  isStandard <- aggregate && identical(y, 2000:2022) &&
    outputRegionMappingFile == "regionmapping_54.csv" && identical(movingAverage, 5)
  if (!isStandard) {
    return(pfm::panelDataHistorical(aggregate = aggregate, y = y,
                                    outputRegionMappingFile = outputRegionMappingFile,
                                    movingAverage = movingAverage))
  }
  cacheFile <- file.path(panelCacheDir, "panelDataHistorical.rds")
  currentState <- get_library_state()
  if (!forceRecompute && file.exists(cacheFile)) {
    cacheObj <- tryCatch(readRDS(cacheFile), error = function(e) NULL)
    if (is.list(cacheObj) && !is.null(cacheObj$state) && !is.null(cacheObj$data) &&
        identical(cacheObj$state, currentState)) {
      message("Loading historical panel data from cache: ", cacheFile)
      return(cacheObj$data)
    }
  }
  message("Computing historical panel data (running panelDataHistorical) ...")
  data <- pfm::panelDataHistorical(aggregate = aggregate, y = y,
                                   outputRegionMappingFile = outputRegionMappingFile,
                                   movingAverage = movingAverage)
  dir.create(panelCacheDir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(list(data = data, state = currentState), file = cacheFile)
  data
}

#' Load or compute the scenario panel data with local caching
#'
#' @param gdxFile Character. Path to \code{fulldata.gdx}.
#' @param aggregate,outputRegionMappingFile Passed to \code{pfm::panelDataScenario}.
#' @param forceRecompute Logical. Bypass the cache.
#' @param panelCacheDir Character. Directory for the cached rds (see
#'   \code{\link{getPanelDataHistoricalCached}}).
#' @return A magpie object, or \code{NULL} when \code{gdxFile} is missing.
#' @export
getPanelDataScenarioCached <- function(gdxFile, aggregate = TRUE,
                                       outputRegionMappingFile = "regionmapping_54.csv",
                                       forceRecompute = FALSE,
                                       panelCacheDir = getOption("pfmreports.panelCacheDir",
                                                                 file.path(getwd(), "data"))) {
  if (is.null(gdxFile) || nchar(gdxFile) == 0 || !file.exists(gdxFile)) {
    return(NULL)
  }
  isStandard <- aggregate && outputRegionMappingFile == "regionmapping_54.csv"
  if (!isStandard) {
    return(pfm::panelDataScenario(gdxFile = gdxFile, aggregate = aggregate,
                                  outputRegionMappingFile = outputRegionMappingFile))
  }
  cacheFile <- file.path(panelCacheDir, "panelDataScenario.rds")
  gdxMtime <- file.info(gdxFile)$mtime
  currentState <- get_library_state()
  if (!forceRecompute && file.exists(cacheFile)) {
    cacheMtime <- file.info(cacheFile)$mtime
    if (!is.na(cacheMtime) && !is.na(gdxMtime) && cacheMtime > gdxMtime) {
      cacheObj <- tryCatch(readRDS(cacheFile), error = function(e) NULL)
      if (is.list(cacheObj) && !is.null(cacheObj$state) && !is.null(cacheObj$data) &&
          identical(cacheObj$state, currentState)) {
        message("Loading scenario panel data from cache: ", cacheFile)
        return(cacheObj$data)
      }
    }
  }
  message("Computing scenario panel data from GDX: ", gdxFile)
  data <- pfm::panelDataScenario(gdxFile = gdxFile, aggregate = aggregate,
                                 outputRegionMappingFile = outputRegionMappingFile)
  dir.create(panelCacheDir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(list(data = data, state = currentState), file = cacheFile)
  data
}
