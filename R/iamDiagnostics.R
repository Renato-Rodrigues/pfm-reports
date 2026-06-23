# Legacy IAM/PFM diagnostics helpers (ADR 0021): the only consumers of the pre-Run-Group
# pfm::modelSelectionWorkflow, serving inst/rmd/IAM_PFM_report.Rmd. Isolated here so the legacy
# workflow coupling is explicit and the cluster is trivially removable if that report is retired.

#' Extract best-model coefficients as a data frame
#'
#' @param wf A \code{pfm::modelSelectionWorkflow} result object.
#' @param sector Character. \code{"Bulk"} or \code{"Diffuse"}.
#' @param stage Character. \code{"adoption"} or \code{"stringency"}.
#' @return Data frame with columns \code{term, estimate, stdError, statistic, pValue}.
#' @export
get_best_coefs <- function(wf, sector, stage) {
  comboName <- paste(sector, stage, sep = "_")
  sel <- wf$selections[[comboName]]
  if (is.null(sel) || is.null(sel$bestModel)) {
    return(data.frame(term = character(), estimate = numeric(), stdError = numeric(),
                      statistic = numeric(), pValue = numeric()))
  }
  pfm::coeftestToDataFrame(sel$bestModel$coeftest)
}

#' Extract best-model diagnostics
#'
#' @param wf A \code{pfm::modelSelectionWorkflow} result object.
#' @param sector Character. \code{"Bulk"} or \code{"Diffuse"}.
#' @param stage Character. \code{"adoption"} or \code{"stringency"}.
#' @return The \code{bestModel} list element, or a list of NAs if missing.
#' @export
get_best_diag <- function(wf, sector, stage) {
  comboName <- paste(sector, stage, sep = "_")
  sel <- wf$selections[[comboName]]
  if (is.null(sel) || is.null(sel$bestModel)) {
    return(list(pseudoR2 = NA, aic = NA, nSignificant = 0, nPredictors = 0))
  }
  sel$bestModel
}

#' Load or compute the consolidated model-data cache for the IAM/PFM diagnostics report
#'
#' Checks whether a cached \code{modelData} file exists; if so, loads it. Otherwise runs the pfm
#' pipeline (panel data, correlation matrices, the six model-selection workflow variants, and
#' scenario projections) and saves the result. Used by the model-diagnostics report.
#'
#' @param params A named list with optional elements: \code{modelDataFile} (default
#'   \code{"data/modelData.RData"}), \code{modelDir} (Fit Cache / model store),
#'   \code{cachefolder} (madrat data cache), \code{gdxPath} (scenario gdx).
#' @return A named list: \code{panelData}, the \code{cor_df_*} matrices, \code{md}..\code{md6},
#'   \code{future_mag}, \code{future_df_bulk}, \code{future_df_diffuse}.
#' @importFrom utils modifyList
#' @export
loadModelData <- function(params) {
  modelDataFile <- params$modelDataFile %||% "data/modelData.RData"

  modelDir <- .absPath(params$modelDir %||% getPfmConfig("modelDir", "output"))
  options(pfm.modelDir = modelDir)
  message("PFM model store: ", normalizePath(modelDir, mustWork = FALSE))

  if (file.exists(modelDataFile)) {
    modelData <- NULL
    load(modelDataFile)              # defines `modelData`
    return(modelData)
  }

  cacheDir <- params$cachefolder %||% getPfmConfig("cachefolder", getPfmConfig("cacheDir"))
  mappingDir <- gsub("cache/default", "mappings", cacheDir)
  madrat::setConfig(forcecache = TRUE, cachefolder = cacheDir, mappingfolder = mappingDir)

  panelData <- getPanelDataHistoricalCached(aggregate = TRUE, y = 2000:2022,
                                            outputRegionMappingFile = "regionmapping_54.csv")

  cor_df_AP   <- pfm::computeCorrelationMatrix(panelData, ext_actorPowerDrivers)
  cor_df_IQ   <- pfm::computeCorrelationMatrix(panelData, ext_instQualityDrivers)
  cor_df_vdem <- pfm::computeCorrelationMatrix(panelData, ext_instQualityDrivers_all)
  cor_df_ctrl <- pfm::computeCorrelationMatrix(panelData, ext_controlDrivers)

  actorPowerDrivers <- ext_actorPowerDrivers
  instQualityDrivers          <- c("Government Effectiveness (WGI)")
  instQualityDrivers_vdem     <- c("Rule of Law (VDem)", "Vertical Accountability (VDem)")
  instQualityDrivers_combined <- c("Government Effectiveness (WGI)", "Rule of Law (VDem)")
  controlDrivers              <- c("GDP per Capita", "Population", "Hydro Nuclear Share")

  wfArgs <- function(...) {
    defaults <- list(
      panelData = panelData, outputRegionMappingFile = "regionmapping_54.csv",
      actorPowerIndex = "Actor Power Index", controlDrivers = controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", modelDir = modelDir
    )
    utils::modifyList(defaults, list(...))
  }

  md  <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = actorPowerDrivers,
                        instQualityDrivers = instQualityDrivers))
  md2 <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = NULL, instQualityDrivers = instQualityDrivers))
  md3 <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = NULL, instQualityDrivers = instQualityDrivers,
                        regionMappingFixedEffects = "regionmapping_54.csv"))
  md4 <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = NULL, instQualityDrivers = instQualityDrivers,
                        includeLaggedECP = TRUE))
  md5 <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = NULL, instQualityDrivers = instQualityDrivers_vdem))
  md6 <- do.call(pfm::modelSelectionWorkflow,
                 wfArgs(actorPowerDrivers = NULL,
                        instQualityDrivers = instQualityDrivers_combined))

  gdxPath <- params$gdxPath %||% getPfmConfig("gdxPath", "")
  future_mag <- if (nchar(gdxPath) > 0 && file.exists(gdxPath)) {
    getPanelDataScenarioCached(gdxFile = gdxPath, aggregate = TRUE,
                               outputRegionMappingFile = "regionmapping_54.csv")
  } else {
    NULL
  }

  future_df_bulk <- NULL
  future_df_diffuse <- NULL
  if (!is.null(future_mag)) {
    freezeScale <- function(sec) {
      hp <- pfm::preparePanelData(
        data = panelData, sector = sec, actorPowerDrivers = ext_actorPowerDrivers,
        actorPowerIndex = "Actor Power Index", instQualityDrivers = ext_instQualityDrivers_all,
        controlDrivers = ext_controlDrivers,
        regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1
      )
      attr(hp, "driverScaling")
    }
    lastHistYr <- max(magclass::getYears(panelData, as.integer = TRUE))
    mkFuture <- function(sec) {
      pfm::preparePanelData(
        data = future_mag, sector = sec, actorPowerDrivers = ext_actorPowerDrivers,
        actorPowerIndex = "Actor Power Index", instQualityDrivers = ext_instQualityDrivers_all,
        controlDrivers = ext_controlDrivers,
        regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1,
        driverScaling = freezeScale(sec), trendFreezeYear = lastHistYr
      )
    }
    future_df_bulk <- mkFuture("Bulk")
    future_df_diffuse <- mkFuture("Diffuse")
  }

  modelData <- list(
    panelData = panelData, cor_df_AP = cor_df_AP, cor_df_IQ = cor_df_IQ,
    cor_df_vdem = cor_df_vdem, cor_df_ctrl = cor_df_ctrl,
    md = md, md2 = md2, md3 = md3, md4 = md4, md5 = md5, md6 = md6,
    future_mag = future_mag, future_df_bulk = future_df_bulk,
    future_df_diffuse = future_df_diffuse
  )
  dir.create(dirname(modelDataFile), showWarnings = FALSE, recursive = TRUE)
  save(modelData, file = modelDataFile)
  modelData
}
