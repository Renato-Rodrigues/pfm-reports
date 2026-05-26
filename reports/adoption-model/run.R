# Render the PFM Adoption Model report.
#
# Usage (from repo root or this folder):
#   source("reports/adoption-model/run.R")
#
# Or with custom params:
#   source("reports/adoption-model/run.R")
#   # Edit render_report() call below, or call it directly with named arguments.
#
# Parameters
# ----------
# cacheDir          : madrat cache folder.
#                     Example: "C:/Users/you/Desktop/Input Data/remind_inputdata/cache/default"
# gdxPath           : path to fulldata.gdx for scenario projections.
#                     Leave "" to skip all projection sections.
# outputFile        : path for the rendered HTML. Default: "output/adoption_model.html"
# assetDir          : folder for saved plots. Default: "output/adoption_model"
# modelName         : display name for the model (shown in report title/header).
# instQualityDrivers: character vector of IQ driver names.
# controlDrivers    : character vector of control variable names.
# regionMappingFE   : filename of the region mapping CSV for fixed effects (or "").
# includeLagged     : logical; include lagged adoption as a predictor.
# adoptionThreshold : numeric [0, 1]; probability threshold for adoption classification.
# snapshotYears     : integer vector of years for probability snapshot maps.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    cacheDir           = getPfmConfig("cacheDir", ""),
    gdxPath            = getPfmConfig("gdxPath", "../../fulldata.gdx"),
    outputFile         = "output/adoption_model.html",
    assetDir           = "output/adoption_model",
    modelName          = getPfmConfig("modelName", "Baseline + Rule of Law"),
    instQualityDrivers = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    controlDrivers     = c("GDP per Capita"),
    regionMappingFE    = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    includeLagged      = getPfmConfig("includeLagged", FALSE),
    adoptionThreshold  = getPfmConfig("adoptionThreshold", 0.5),
    snapshotYears      = c(2030L, 2040L, 2050L, 2070L, 2100L)) {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/adoption-model/adoption-model.Rmd")

  params <- list(
    cacheDir           = cacheDir,
    gdxPath            = gdxPath,
    assetDir           = file.path(root, assetDir),
    modelName          = modelName,
    instQualityDrivers = instQualityDrivers,
    controlDrivers     = controlDrivers,
    regionMappingFE    = regionMappingFE,
    includeLagged      = includeLagged,
    adoptionThreshold  = adoptionThreshold,
    snapshotYears      = snapshotYears
  )

  output_path <- file.path(root, outputFile)
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input       = rmd_path,
    output_file = output_path,
    params      = params,
    envir       = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

# Run immediately when sourced
render_report()
