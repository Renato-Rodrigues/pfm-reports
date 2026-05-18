# Render the IAM-PFM model diagnostics report.
#
# Usage (from repo root or this folder):
#   source("reports/model-diagnostics/run.R")
#
# Or with custom paths:
#   source("reports/model-diagnostics/run.R")
#   # Edit the params list below before sourcing, or call render_report() directly.
#
# Parameters
# ----------
# modelDataFile : path to cached modelData.RData.
#                 If the file does not exist, the full pipeline is re-run and
#                 the result is saved here. Default: "data/modelData.RData".
# cacheDir      : madrat cache folder. Only needed when modelDataFile is absent.
#                 Example: "C:/Users/you/Desktop/Input Data/remind_inputdata/cache/default"
# gdxPath       : path to fulldata.gdx for scenario projections.
#                 Leave "" to skip projection sections.
#                 Example: "C:/Users/you/Desktop/Projects/Elevate/code/fulldata.gdx"
# outputFile    : path for the rendered HTML. Default: "output/IAM_PFM_report.html"
# assetDir      : folder for plots and other saved assets.
#                 Default: "output/IAM_PFM_report"

library(rmarkdown)
library(rprojroot)

render_report <- function(
    modelDataFile = "data/modelData.RData",
    cacheDir      = "",
    gdxPath       = "",
    outputFile    = "output/IAM_PFM_report.html",
    assetDir      = "output/IAM_PFM_report") {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/model-diagnostics/IAM_PFM_report.Rmd")

  # Resolve all paths relative to repo root so the Rmd is location-agnostic
  params <- list(
    modelData     = NULL,
    modelDataFile = file.path(root, modelDataFile),
    cacheDir      = cacheDir,
    gdxPath       = gdxPath,
    assetDir      = file.path(root, assetDir)
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

# Run immediately when sourced (edit params here or call render_report() with args)
render_report(
  modelDataFile = "data/modelData.RData",
  cacheDir      = "",   # <-- fill in your madrat cache path if recomputing
  gdxPath       = "",   # <-- fill in path to fulldata.gdx for projections
  outputFile    = "output/IAM_PFM_report.html",
  assetDir      = "output/IAM_PFM_report"
)
