# Render the PFM Stringency Model report.
#
# Usage (from repo root or this folder):
#   source("reports/stringency-model/run.R")
#   Rscript reports/stringency-model/run.R
#   Rscript reports/stringency-model/run.R --reportName=vdem-bulk
#   Rscript reports/stringency-model/run.R --modelConfig=model-configs/best-green-models.yml
#
# When --modelConfig is supplied, Bulk and Diffuse sector params are loaded
# from the YAML entries with model_type "Stringency: Bulk" and
# "Stringency: Diffuse" respectively. Explicitly passed parameters take
# precedence over YAML values.
#
# Per-sector configuration:
#   Bulk params are always used. Diffuse params fall back to the Bulk config
#   when omitted (NULL / empty vector).

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    reportName                 = getPfmConfig("reportName",  "default"),
    cacheDir                   = getPfmConfig("cacheDir",    ""),
    gdxPath                    = getPfmConfig("gdxPath",     "data/fulldata.gdx"),
    modelName                  = getPfmConfig("modelName",   "Baseline + Rule of Law"),
    modelConfigFile            = NULL,
    # Bulk stringency config
    instQualityDriversBulk     = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    controlDriversBulk         = c("GDP per Capita", "Hydro Nuclear Share"),
    regionMappingFEBulk        = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    includeLaggedBulk          = getPfmConfig("includeLagged", FALSE),
    actorPowerDriversBulk      = NULL,
    actorPowerIndexBulk        = "Actor Power Index",
    # Diffuse stringency config (NULL → fall back to Bulk values)
    instQualityDriversDiffuse  = NULL,
    controlDriversDiffuse      = NULL,
    regionMappingFEDiffuse     = NULL,
    includeLaggedDiffuse       = NULL,
    actorPowerDriversDiffuse   = NULL,
    actorPowerIndexDiffuse     = NULL,
    # Adoption model config (for projection gating)
    adoptionInstQualityDrivers = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    adoptionControlDrivers     = c("GDP per Capita", "Hydro Nuclear Share"),
    adoptionRegionMappingFE    = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    adoptionThreshold          = getPfmConfig("adoptionThreshold", 0.5),
    snapshotYears              = c(2030L, 2040L, 2050L, 2070L, 2100L)) {

  root <- find_rstudio_root_file()

  # ── Load from YAML config if supplied ─────────────────────────────────────────
  if (!is.null(modelConfigFile) && nzchar(modelConfigFile)) {
    cfg_bulk    <- loadPfmModelConfig(modelConfigFile, "Stringency: Bulk")
    cfg_diffuse <- loadPfmModelConfig(modelConfigFile, "Stringency: Diffuse")

    apply_cfg <- function(cfg, prefix) {
      if (is.null(cfg)) return()
      message(sprintf("[config] Loaded '%s' from %s", cfg$model_type, basename(modelConfigFile)))
      if (!is.null(cfg$instQualityDrivers)) assign(paste0("instQualityDrivers", prefix), cfg$instQualityDrivers, envir = parent.env(environment()))
      if (!is.null(cfg$controlDrivers))     assign(paste0("controlDrivers",     prefix), cfg$controlDrivers,     envir = parent.env(environment()))
      if (!is.null(cfg$regionMappingFixedEffects))
        assign(paste0("regionMappingFE", prefix),
               if (is.null(cfg$regionMappingFixedEffects)) NULL else cfg$regionMappingFixedEffects,
               envir = parent.env(environment()))
      if (!is.null(cfg$includeLagged))
        assign(paste0("includeLagged", prefix), isTRUE(cfg$includeLagged), envir = parent.env(environment()))
    }

    # Apply Bulk config
    if (!is.null(cfg_bulk)) {
      if (!is.null(cfg_bulk$instQualityDrivers)) instQualityDriversBulk    <- cfg_bulk$instQualityDrivers
      if (!is.null(cfg_bulk$controlDrivers))     controlDriversBulk        <- cfg_bulk$controlDrivers
      if (!is.null(cfg_bulk$regionMappingFixedEffects))
        regionMappingFEBulk <- cfg_bulk$regionMappingFixedEffects
      if (!is.null(cfg_bulk$includeLagged))       includeLaggedBulk        <- isTRUE(cfg_bulk$includeLagged)
      if (!is.null(cfg_bulk$actorPowerDrivers))  actorPowerDriversBulk    <- cfg_bulk$actorPowerDrivers
      if (!is.null(cfg_bulk$actorPowerIndex))    actorPowerIndexBulk      <- cfg_bulk$actorPowerIndex
      if (!is.null(cfg_bulk$name) && reportName == "default")
        reportName <- gsub("[^A-Za-z0-9_-]", "_", tolower(sub("Best Green — ", "", cfg_bulk$name)))
      if (!is.null(cfg_bulk$name) && modelName == "Baseline + Rule of Law")
        modelName <- sub("Best Green — ", "", cfg_bulk$name)
    }

    # Apply Diffuse config
    if (!is.null(cfg_diffuse)) {
      if (!is.null(cfg_diffuse$instQualityDrivers)) instQualityDriversDiffuse <- cfg_diffuse$instQualityDrivers
      if (!is.null(cfg_diffuse$controlDrivers))     controlDriversDiffuse     <- cfg_diffuse$controlDrivers
      if (!is.null(cfg_diffuse$regionMappingFixedEffects))
        regionMappingFEDiffuse <- cfg_diffuse$regionMappingFixedEffects
      if (!is.null(cfg_diffuse$includeLagged))       includeLaggedDiffuse      <- isTRUE(cfg_diffuse$includeLagged)
      if (!is.null(cfg_diffuse$actorPowerDrivers))  actorPowerDriversDiffuse  <- cfg_diffuse$actorPowerDrivers
      if (!is.null(cfg_diffuse$actorPowerIndex))    actorPowerIndexDiffuse    <- cfg_diffuse$actorPowerIndex
    }

    if (is.null(cfg_bulk) && is.null(cfg_diffuse))
      warning(sprintf("[config] No Stringency entries found in %s", modelConfigFile))
  }

  rmd_path    <- file.path(root, "reports/stringency-model/stringency-model.Rmd")
  output_stem <- paste0("stringency_model_", reportName)
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
      cacheDir                   = cacheDir,
      gdxPath                    = gdxPath,
      assetDir                   = asset_dir,
      modelName                  = modelName,
      reportName                 = reportName,
      instQualityDriversBulk     = instQualityDriversBulk,
      controlDriversBulk         = controlDriversBulk,
      regionMappingFEBulk        = if (is.null(regionMappingFEBulk)) "" else regionMappingFEBulk,
      includeLaggedBulk          = isTRUE(includeLaggedBulk),
      actorPowerDriversBulk      = actorPowerDriversBulk,
      actorPowerIndexBulk        = actorPowerIndexBulk,
      instQualityDriversDiffuse  = instQualityDriversDiffuse,
      controlDriversDiffuse      = controlDriversDiffuse,
      regionMappingFEDiffuse     = regionMappingFEDiffuse,
      includeLaggedDiffuse       = includeLaggedDiffuse,
      actorPowerDriversDiffuse   = actorPowerDriversDiffuse,
      actorPowerIndexDiffuse     = actorPowerIndexDiffuse,
      adoptionInstQualityDrivers = adoptionInstQualityDrivers,
      adoptionControlDrivers     = adoptionControlDrivers,
      adoptionRegionMappingFE    = if (is.null(adoptionRegionMappingFE)) "" else adoptionRegionMappingFE,
      adoptionThreshold          = as.numeric(adoptionThreshold),
      snapshotYears              = as.integer(snapshotYears)
    ),
    envir = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

# ── CLI argument parsing ───────────────────────────────────────────────────────
args             <- commandArgs(trailingOnly = TRUE)
report_name_arg  <- NULL
model_config_arg <- NULL

for (a in args) {
  if (startsWith(a, "--reportName="))  report_name_arg  <- sub("^--reportName=",  "", a)
  if (startsWith(a, "--modelConfig=")) model_config_arg <- sub("^--modelConfig=", "", a)
}

render_report(
  reportName      = if (!is.null(report_name_arg)) report_name_arg
                    else getPfmConfig("reportName", "default"),
  modelConfigFile = model_config_arg
)
