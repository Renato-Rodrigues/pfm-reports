# Render the PFM Adoption Model report.
#
# Usage (from repo root or this folder):
#   source("reports/adoption-model/run.R")
#   Rscript reports/adoption-model/run.R
#   Rscript reports/adoption-model/run.R --reportName=my-run
#   Rscript reports/adoption-model/run.R --modelConfig=model-configs/selected-models.yml
#
# When --modelConfig is supplied, both "Adoption: Bulk" and "Adoption: Diffuse"
# entries are loaded so each sector can use its own specification. The Bulk entry
# drives the report name and model name when defaults are in effect.
# If only one sector entry exists in the YAML the other falls back to Bulk.
# Old single-sector YAMLs (loaded via --sector=) are still supported.
#
# Parameters
# ----------
# reportName               : short label appended to the output filename.
# cacheDir                 : madrat cache folder.
# gdxPath                  : path to fulldata.gdx for scenario projections (or "").
# modelName                : display name shown in the report title/header.
# modelConfigFile          : path to a YAML file with model_type entries (or NULL).
# sector                   : fallback sector for old single-entry YAMLs ("Bulk" / "Diffuse").
# instQualityDrivers       : default IQ drivers (used when no sector-specific override exists).
# controlDrivers           : default control variables.
# regionMappingFE          : default region mapping CSV.
# includeLagged            : default lagged adoption flag.
# actorPowerDrivers        : default actor power drivers.
# actorPowerIndex          : default actor power index.
# *Bulk / *Diffuse variants: sector-specific overrides passed directly to the Rmd.
# adoptionThreshold        : numeric [0, 1]; probability threshold for adoption.
# snapshotYears            : integer vector of years for probability snapshot maps.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    reportName                = getPfmConfig("reportName", "default"),
    cacheDir                  = getPfmConfig("cacheDir", ""),
    gdxPath                   = getPfmConfig("gdxPath", "data/fulldata.gdx"),
    modelName                 = getPfmConfig("modelName", "Baseline + Rule of Law"),
    modelConfigFile           = getPfmConfig("adoptionModelConfig",
                                             "reports/model-selection/model-configs/selected-models-v2.yml"),
    sector                    = "Bulk",
    # Single-sector defaults (backward compat — used when no *Bulk/*Diffuse override)
    instQualityDrivers        = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    controlDrivers            = c("GDP per Capita"),
    regionMappingFE           = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    includeLagged             = getPfmConfig("includeLagged", FALSE),
    actorPowerDrivers         = NULL,
    actorPowerIndex           = "Actor Power Index",
    # Per-sector overrides (NULL → fall back to single-sector defaults above)
    instQualityDriversBulk    = NULL,
    controlDriversBulk        = NULL,
    regionMappingFEBulk       = NULL,
    includeLaggedBulk         = NULL,
    logisticTimeTrendBulk     = NULL,
    actorPowerDriversBulk     = NULL,
    actorPowerIndexBulk       = NULL,
    instQualityDriversDiffuse = NULL,
    controlDriversDiffuse     = NULL,
    regionMappingFEDiffuse    = NULL,
    includeLaggedDiffuse       = NULL,
    logisticTimeTrendDiffuse   = NULL,
    actorPowerDriversDiffuse   = NULL,
    actorPowerIndexDiffuse    = NULL,
    adoptionThreshold         = getPfmConfig("adoptionThreshold", 0.5),
    snapshotYears             = c(2030L, 2040L, 2050L, 2070L, 2100L),
    timelineClassification    = getPfmConfig("timelineClassification", "five_groups")) {

  root <- find_rstudio_root_file()

  apply_cfg <- function(cfg, is_bulk) {
    if (is.null(cfg)) return()
    prefix <- if (is_bulk) "Bulk" else "Diffuse"
    message(sprintf("[config] Loaded 'Adoption: %s' from %s", prefix, basename(modelConfigFile)))
    if (!is.null(cfg$instQualityDrivers))
      assign(paste0("instQualityDrivers", prefix), cfg$instQualityDrivers, envir = parent.env(environment()))
    if (!is.null(cfg$controlDrivers))
      assign(paste0("controlDrivers",     prefix), cfg$controlDrivers,     envir = parent.env(environment()))
    if (!is.null(cfg$regionMappingFixedEffects))
      assign(paste0("regionMappingFE",    prefix),
             if (is.null(cfg$regionMappingFixedEffects)) "" else cfg$regionMappingFixedEffects,
             envir = parent.env(environment()))
    if (!is.null(cfg$includeLagged))
      assign(paste0("includeLagged",      prefix), isTRUE(cfg$includeLagged),       envir = parent.env(environment()))
    if (!is.null(cfg$logisticTimeTrend))
      assign(paste0("logisticTimeTrend",  prefix), isTRUE(cfg$logisticTimeTrend),   envir = parent.env(environment()))
    if (!is.null(cfg$actorPowerDrivers))
      assign(paste0("actorPowerDrivers",  prefix), cfg$actorPowerDrivers,   envir = parent.env(environment()))
    if (!is.null(cfg$actorPowerIndex))
      assign(paste0("actorPowerIndex",    prefix), cfg$actorPowerIndex,     envir = parent.env(environment()))
  }

  # ── Load from YAML config if supplied ─────────────────────────────────────────
  if (!is.null(modelConfigFile) && nzchar(modelConfigFile)) {
    cfg_bulk    <- loadPfmModelConfig(modelConfigFile, "Adoption: Bulk")
    cfg_diffuse <- loadPfmModelConfig(modelConfigFile, "Adoption: Diffuse")

    if (!is.null(cfg_bulk)) {
      apply_cfg(cfg_bulk, is_bulk = TRUE)
      if (!is.null(cfg_bulk$name) && reportName == "default")
        reportName <- gsub("[^A-Za-z0-9_-]", "_", tolower(cfg_bulk$name))
      if (!is.null(cfg_bulk$name) && modelName == "Baseline + Rule of Law")
        modelName <- cfg_bulk$name
    }

    if (!is.null(cfg_diffuse)) {
      apply_cfg(cfg_diffuse, is_bulk = FALSE)
      if (is.null(cfg_bulk) && !is.null(cfg_diffuse$name) && reportName == "default")
        reportName <- gsub("[^A-Za-z0-9_-]", "_", tolower(cfg_diffuse$name))
    }

    # Backward compat: try old single-sector entry if neither Bulk nor Diffuse found
    if (is.null(cfg_bulk) && is.null(cfg_diffuse)) {
      cfg_single <- loadPfmModelConfig(modelConfigFile, paste0("Adoption: ", sector))
      if (!is.null(cfg_single)) {
        message(sprintf("[config] Loaded 'Adoption: %s' (single-sector) from %s",
                        sector, basename(modelConfigFile)))
        if (!is.null(cfg_single$instQualityDrivers)) instQualityDrivers <- cfg_single$instQualityDrivers
        if (!is.null(cfg_single$controlDrivers))     controlDrivers     <- cfg_single$controlDrivers
        if (!is.null(cfg_single$regionMappingFixedEffects))
          regionMappingFE <- if (is.null(cfg_single$regionMappingFixedEffects)) ""
                            else cfg_single$regionMappingFixedEffects
        if (!is.null(cfg_single$includeLagged))      includeLagged     <- isTRUE(cfg_single$includeLagged)
        if (!is.null(cfg_single$actorPowerDrivers))  actorPowerDrivers <- cfg_single$actorPowerDrivers
        if (!is.null(cfg_single$actorPowerIndex))    actorPowerIndex   <- cfg_single$actorPowerIndex
        if (!is.null(cfg_single$name) && reportName == "default")
          reportName <- gsub("[^A-Za-z0-9_-]", "_", tolower(cfg_single$name))
        if (!is.null(cfg_single$name) && modelName == "Baseline + Rule of Law")
          modelName <- cfg_single$name
      } else {
        warning(sprintf("[config] No 'Adoption: Bulk', 'Adoption: Diffuse', or 'Adoption: %s' entry found in %s",
                        sector, modelConfigFile))
      }
    }
  }

  rmd_path    <- file.path(root, "reports/adoption-model/adoption-model.Rmd")
  output_stem <- paste0("adoption_model_", reportName)
  output_path <- file.path(root, "output", paste0(output_stem, ".html"))
  asset_dir   <- file.path(root, "output", output_stem)

  if (nchar(gdxPath) > 0 && !is_absolute_path(gdxPath))
    gdxPath <- file.path(root, gdxPath)
  if (nchar(cacheDir) > 0 && !is_absolute_path(cacheDir))
    cacheDir <- file.path(root, cacheDir)

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input       = rmd_path,
    output_file = output_path,
    params      = list(
      cacheDir                  = cacheDir,
      gdxPath                   = gdxPath,
      assetDir                  = asset_dir,
      modelName                 = modelName,
      reportName                = reportName,
      instQualityDrivers        = instQualityDrivers,
      controlDrivers            = controlDrivers,
      regionMappingFE           = if (is.null(regionMappingFE)) "" else regionMappingFE,
      includeLagged             = isTRUE(includeLagged),
      actorPowerDrivers         = actorPowerDrivers,
      actorPowerIndex           = actorPowerIndex,
      instQualityDriversBulk    = instQualityDriversBulk,
      controlDriversBulk        = controlDriversBulk,
      regionMappingFEBulk       = if (is.null(regionMappingFEBulk)) "" else regionMappingFEBulk,
      includeLaggedBulk         = includeLaggedBulk,
      logisticTimeTrendBulk     = logisticTimeTrendBulk,
      actorPowerDriversBulk     = actorPowerDriversBulk,
      actorPowerIndexBulk       = actorPowerIndexBulk,
      instQualityDriversDiffuse = instQualityDriversDiffuse,
      controlDriversDiffuse     = controlDriversDiffuse,
      regionMappingFEDiffuse    = if (is.null(regionMappingFEDiffuse)) "" else regionMappingFEDiffuse,
      includeLaggedDiffuse      = includeLaggedDiffuse,
      logisticTimeTrendDiffuse  = logisticTimeTrendDiffuse,
      actorPowerDriversDiffuse  = actorPowerDriversDiffuse,
      actorPowerIndexDiffuse    = actorPowerIndexDiffuse,
      adoptionThreshold         = as.numeric(adoptionThreshold),
      snapshotYears             = as.integer(snapshotYears),
      timelineClassification    = timelineClassification
    ),
    envir = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

# ── CLI argument parsing ───────────────────────────────────────────────────────
args                        <- commandArgs(trailingOnly = TRUE)
report_name_arg             <- NULL
model_config_arg            <- NULL
sector_arg                  <- "Bulk"
timeline_classification_arg <- NULL

for (a in args) {
  if (startsWith(a, "--reportName="))             report_name_arg             <- sub("^--reportName=",             "", a)
  if (startsWith(a, "--modelConfig="))            model_config_arg            <- sub("^--modelConfig=",            "", a)
  if (startsWith(a, "--sector="))                 sector_arg                  <- sub("^--sector=",                 "", a)
  if (startsWith(a, "--timelineClassification=")) timeline_classification_arg <- sub("^--timelineClassification=", "", a)
}

render_report_args <- list(
  reportName      = if (!is.null(report_name_arg)) report_name_arg
                    else getPfmConfig("reportName", "default"),
  modelConfigFile = if (!is.null(model_config_arg)) model_config_arg
                    else if (!is.null(report_name_arg) && report_name_arg == "best")
                      "reports/model-selection/model-configs/selected-models-best.yml"
                    else if (!is.null(report_name_arg) && report_name_arg == "best-prediction")
                      "reports/model-selection/model-configs/selected-models-v2-prediction.yml"
                    else NULL,
  sector          = sector_arg
)
if (!is.null(timeline_classification_arg)) {
  render_report_args$timelineClassification <- timeline_classification_arg
}
do.call(render_report, render_report_args)
