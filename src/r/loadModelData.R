library(pfm)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

# Null-coalescing helper (base R has no %||% before 4.4)
`%||%` <- function(x, y) if (!is.null(x) && nchar(as.character(x)) > 0) x else y

#' Load or compute model data for IAM-PFM reports
#'
#' Checks whether a cached modelData file exists. If it does, loads it. If not,
#' runs the full pfm pipeline (panel data, correlation matrices, model
#' selection workflows, scenario projections) and saves the result.
#'
#' @param params A list with the following named elements:
#'   \describe{
#'     \item{modelDataFile}{Path to the cached .RData file. Default: "data/modelData.RData"}
#'     \item{modelDir}{Directory for per-model .rds files (PFM model store).
#'       Default: "models". Sets pfm.modelDir option so models are cached to disk
#'       and reloaded on subsequent runs with the same formula + data.}
#'     \item{cacheDir}{madrat cache folder path. Required when recomputing.}
#'     \item{gdxPath}{Path to fulldata.gdx for scenario projections. Optional.}
#'   }
#'
#' @return A named list with elements: panelData, cor_df_AP, cor_df_IQ,
#'   cor_df_vdem, cor_df_ctrl, md, md2, md3, md4, md5, md6,
#'   future_mag, future_df_bulk, future_df_diffuse.
loadModelData <- function(params) {
  modelDataFile <- params$modelDataFile %||% "data/modelData.RData"

  # Set pfm.modelDir unconditionally so loadPFMModel() / listPFMModels() work
  # regardless of whether we load from the modelData cache or recompute.
  modelDir <- params$modelDir %||% getPfmConfig("modelDir", "cache")
  if (!is_absolute_path(modelDir)) {
    modelDir <- file.path(rprojroot::find_rstudio_root_file(), modelDir)
  }
  options(pfm.modelDir = modelDir)
  message("PFM model store: ", normalizePath(modelDir, mustWork = FALSE))

  if (file.exists(modelDataFile)) {
    load(modelDataFile)
    return(modelData)
  }

  # Configure madrat cache
  cache_dir <- params$cacheDir %||% getPfmConfig("cacheDir")
  mapping_dir <- gsub("cache/default", "mappings", cache_dir)
  madrat::setConfig(forcecache = TRUE, cachefolder = cache_dir, mappingfolder = mapping_dir)

  # --- Panel data ---
  panelData <- getPanelDataHistoricalCached(
    aggregate = TRUE, y = 2000:2022,
    outputRegionMappingFile = "regionmapping_54.csv"
  )

  # --- Correlation matrices ---
  cor_df_AP   <- computeCorrelationMatrix(panelData, ext_actorPowerDrivers)
  cor_df_IQ   <- computeCorrelationMatrix(panelData, ext_instQualityDrivers)
  cor_df_vdem <- computeCorrelationMatrix(panelData, ext_instQualityDrivers_all)
  cor_df_ctrl <- computeCorrelationMatrix(panelData, ext_controlDrivers)

  # --- Selected drivers ---
  actorPowerDrivers <- c(
    "VRE share", "Electrification",
    "Coal primary energy share", "Oil/Gas primary energy share",
    "Fossil share in Industry"
  )
  instQualityDrivers          <- c("Government Effectiveness (WGI)")
  instQualityDrivers_vdem     <- c("Rule of Law (VDem)", "Vertical Accountability (VDem)")
  instQualityDrivers_combined <- c("Government Effectiveness (WGI)", "Rule of Law (VDem)")
  controlDrivers              <- c("GDP per Capita", "Population", "Hydro Nuclear Share")

  # Common workflow arguments shared across all six model variants
  .wfArgs <- function(...) {
    defaults <- list(
      panelData                 = panelData,
      outputRegionMappingFile   = "regionmapping_54.csv",
      actorPowerIndex           = "Actor Power Index",
      controlDrivers            = controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv",
      modelDir                  = modelDir
    )
    utils::modifyList(defaults, list(...))
  }

  # --- Model selection workflows ---
  # md: full AP drivers (individual VRE/coal/etc.) + WGI IQ
  md <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers  = actorPowerDrivers,
    instQualityDrivers = instQualityDrivers
  ))

  # md2: Actor Power Index composite + WGI IQ (recommended for projection)
  md2 <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers  = NULL,
    instQualityDrivers = instQualityDrivers
  ))

  # md3: API + WGI IQ + 54-region fixed effects
  md3 <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers         = NULL,
    instQualityDrivers        = instQualityDrivers,
    regionMappingFixedEffects = "regionmapping_54.csv"
  ))

  # md4: API + WGI IQ + lagged ECP in stringency
  md4 <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers  = NULL,
    instQualityDrivers = instQualityDrivers,
    includeLaggedECP   = TRUE
  ))

  # md5: API + V-Dem IQ (Rule of Law + Vertical Accountability)
  md5 <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers  = NULL,
    instQualityDrivers = instQualityDrivers_vdem
  ))

  # md6: API + combined WGI + V-Dem IQ
  md6 <- do.call(modelSelectionWorkflow, .wfArgs(
    actorPowerDrivers  = NULL,
    instQualityDrivers = instQualityDrivers_combined
  ))

  # --- Scenario projections ---
  gdx_path <- params$gdxPath %||% getPfmConfig("gdxPath", "")
  future_mag <- if (nchar(gdx_path) > 0 && file.exists(gdx_path)) {
    getPanelDataScenarioCached(gdxFile = gdx_path, aggregate = TRUE, outputRegionMappingFile = "regionmapping_54.csv")
  } else {
    NULL
  }

  future_df_bulk    <- NULL
  future_df_diffuse <- NULL

  if (!is.null(future_mag)) {
    # Reuse the driver-standardization mean/sd FROZEN on the historical panel
    # (ADR 0007): the scenario design must share the historical reference, or the
    # fitted coefficients no longer apply (biased/exploding projections).
    .freezeScale <- function(sec) {
      hp <- preparePanelData(
        data = panelData, sector = sec,
        actorPowerDrivers = ext_actorPowerDrivers, actorPowerIndex = "Actor Power Index",
        instQualityDrivers = ext_instQualityDrivers_all, controlDrivers = ext_controlDrivers,
        regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1
      )
      attr(hp, "driverScaling")
    }
    .lastHistYr <- max(magclass::getYears(panelData, as.integer = TRUE))
    future_df_bulk <- preparePanelData(
      data = future_mag, sector = "Bulk",
      actorPowerDrivers = ext_actorPowerDrivers, actorPowerIndex = "Actor Power Index",
      instQualityDrivers = ext_instQualityDrivers_all, controlDrivers = ext_controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1,
      driverScaling = .freezeScale("Bulk"), trendFreezeYear = .lastHistYr
    )
    future_df_diffuse <- preparePanelData(
      data = future_mag, sector = "Diffuse",
      actorPowerDrivers = ext_actorPowerDrivers, actorPowerIndex = "Actor Power Index",
      instQualityDrivers = ext_instQualityDrivers_all, controlDrivers = ext_controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1,
      driverScaling = .freezeScale("Diffuse"), trendFreezeYear = .lastHistYr
    )
  }

  modelData <- list(
    panelData         = panelData,
    cor_df_AP         = cor_df_AP,
    cor_df_IQ         = cor_df_IQ,
    cor_df_vdem       = cor_df_vdem,
    cor_df_ctrl       = cor_df_ctrl,
    md                = md,
    md2               = md2,
    md3               = md3,
    md4               = md4,
    md5               = md5,
    md6               = md6,
    future_mag        = future_mag,
    future_df_bulk    = future_df_bulk,
    future_df_diffuse = future_df_diffuse
  )

  dir.create(dirname(modelDataFile), showWarnings = FALSE, recursive = TRUE)
  save(modelData, file = modelDataFile)

  modelData
}
