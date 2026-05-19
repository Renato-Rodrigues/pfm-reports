library(pfm)

#' Load or compute model data for IAM-PFM reports
#'
#' Checks whether a cached modelData file exists. If it does, loads it. If not,
#' runs the full mrPEM pipeline (panel data, correlation matrices, model
#' selection workflows, scenario projections) and saves the result.
#'
#' @param params A list with the following named elements:
#'   \describe{
#'     \item{modelDataFile}{Path to the cached .RData file. Default: "data/modelData.RData"}
#'     \item{cacheDir}{madrat cache folder path. Required when recomputing.}
#'     \item{gdxPath}{Path to fulldata.gdx for scenario projections. Optional.}
#'   }
#'
#' @return A named list with elements: panelData, cor_df_AP, cor_df_IQ,
#'   cor_df_ctrl, md, md2, md3, md4, future_mag, future_df_bulk,
#'   future_df_diffuse.
loadModelData <- function(params) {
  modelDataFile <- params$modelDataFile %||% "data/modelData.RData"

  if (file.exists(modelDataFile)) {
    load(modelDataFile)
    return(modelData)
  }

  # Configure madrat cache
  if (!is.null(params$cacheDir) && nchar(params$cacheDir) > 0) {
    madrat::setConfig(forcecache = TRUE, cachefolder = params$cacheDir)
  }

  # --- Panel data ---
  panelData <- panelDataHistorical(
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
  controlDrivers              <- c("GDP per Capita", "Population")

  # --- Model selection workflows ---
  md <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = actorPowerDrivers,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_EU_OECDp.csv"
  )

  md2 <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = NULL,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_EU_OECDp.csv"
  )

  md3 <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = NULL,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_54.csv"
  )

  md4 <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = NULL,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_EU_OECDp.csv",
    includeLaggedECP = TRUE
  )

  # V-Dem alternative IQ: Rule of Law + Vertical Accountability
  md5 <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = NULL,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers_vdem,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_EU_OECDp.csv"
  )

  # Combined WGI + V-Dem: Government Effectiveness (WGI) + Rule of Law (VDem)
  md6 <- modelSelectionWorkflow(
    panelData = panelData,
    outputRegionMappingFile = "regionmapping_54.csv",
    actorPowerDrivers = NULL,
    actorPowerIndex = "Actor Power Index",
    instQualityDrivers = instQualityDrivers_combined,
    controlDrivers = controlDrivers,
    regionMappingFixedEffects = "regionmapping_EU_OECDp.csv"
  )

  # --- Scenario projections ---
  gdx_path <- params$gdxPath %||% ""
  future_mag <- if (nchar(gdx_path) > 0 && file.exists(gdx_path)) {
    panelDataScenario(gdxFile = gdx_path, outputRegionMappingFile = "regionmapping_54.csv")
  } else {
    NULL
  }

  future_df_bulk    <- NULL
  future_df_diffuse <- NULL

  if (!is.null(future_mag)) {
    future_df_bulk <- preparePanelData(
      data = future_mag, sector = "Bulk",
      actorPowerDrivers = ext_actorPowerDrivers, actorPowerIndex = "Actor Power Index",
      instQualityDrivers = ext_instQualityDrivers_all, controlDrivers = ext_controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1
    )
    future_df_diffuse <- preparePanelData(
      data = future_mag, sector = "Diffuse",
      actorPowerDrivers = ext_actorPowerDrivers, actorPowerIndex = "Actor Power Index",
      instQualityDrivers = ext_instQualityDrivers_all, controlDrivers = ext_controlDrivers,
      regionMappingFixedEffects = "regionmapping_EU_OECDp.csv", lag = 1
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

# Null-coalescing helper (base R has no %||% before 4.4)
`%||%` <- function(x, y) if (!is.null(x) && nchar(as.character(x)) > 0) x else y
