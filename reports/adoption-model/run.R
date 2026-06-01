# Render the PFM Adoption Model report.
#
# Usage (from repo root or this folder):
#   source("reports/adoption-model/run.R")
#   Rscript reports/adoption-model/run.R
#   Rscript reports/adoption-model/run.R --reportName=rule-of-law
#
# The output file is named adoption_model_<reportName>.html so different
# configurations never overwrite each other.
#
# Parameters
# ----------
# reportName        : short label appended to the output filename.
#                     Default: "default" → adoption_model_default.html
# cacheDir          : madrat cache folder.
# gdxPath           : path to fulldata.gdx for scenario projections (or "").
# modelName         : display name shown in the report title/header.
# instQualityDrivers: character vector of IQ driver names.
# controlDrivers    : character vector of control variable names.
# regionMappingFE   : region mapping CSV filename for fixed effects (or "").
# includeLagged     : logical; include lagged adoption as a predictor.
# adoptionThreshold : numeric [0, 1]; probability threshold for adoption.
# snapshotYears     : integer vector of years for probability snapshot maps.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    reportName         = getPfmConfig("reportName", "default"),
    cacheDir           = getPfmConfig("cacheDir", ""),
    gdxPath            = getPfmConfig("gdxPath", "data/fulldata.gdx"),
    modelName          = getPfmConfig("modelName", "Baseline + Rule of Law"),
    instQualityDrivers = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    controlDrivers     = c("GDP per Capita"),
    regionMappingFE    = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    includeLagged      = getPfmConfig("includeLagged", FALSE),
    adoptionThreshold  = getPfmConfig("adoptionThreshold", 0.5),
    snapshotYears      = c(2030L, 2040L, 2050L, 2070L, 2100L)) {

  root        <- find_rstudio_root_file()
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
      cacheDir           = cacheDir,
      gdxPath            = gdxPath,
      assetDir           = asset_dir,
      modelName          = modelName,
      instQualityDrivers = instQualityDrivers,
      controlDrivers     = controlDrivers,
      regionMappingFE    = regionMappingFE,
      includeLagged      = includeLagged,
      adoptionThreshold  = adoptionThreshold,
      snapshotYears      = snapshotYears,
      reportName         = reportName
    ),
    envir = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

# ── CLI argument parsing ───────────────────────────────────────────────────────
args           <- commandArgs(trailingOnly = TRUE)
report_name_arg <- NULL
for (a in args) {
  if (startsWith(a, "--reportName="))
    report_name_arg <- sub("^--reportName=", "", a)
}

render_report(
  reportName = if (!is.null(report_name_arg)) report_name_arg
               else getPfmConfig("reportName", "default")
)
