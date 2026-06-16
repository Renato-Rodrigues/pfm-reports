# Render the PFM Publication Report.
#
# Usage (from repo root or this folder):
#   source("reports/publication/run.R")
#   Rscript reports/publication/run.R
#   Rscript reports/publication/run.R --reportName=v1
#   Rscript reports/publication/run.R --theoryConfig=model-configs/selected-models-v2.yml
#   Rscript reports/publication/run.R --predictionConfig=model-configs/selected-models-v2-prediction.yml
#
# The report loads theory-optimal and prediction-optimal models from two YAML
# files (theoryConfigFile and predictionConfigFile) and produces a self-contained
# HTML report suitable for peer-review presentation.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    reportName         = getPfmConfig("reportName",   "default"),
    cacheDir           = getPfmConfig("cacheDir",     ""),
    gdxPath            = getPfmConfig("gdxPath",      "data/fulldata.gdx"),
    theoryConfigFile   = "model-configs/selected-models-v2.yml",
    predictionConfigFile = "model-configs/selected-models-v2-prediction.yml",
    modelDir           = getPfmConfig("modelDir",     "cache"),
    outputDir          = "output") {

  root         <- rprojroot::find_rstudio_root_file()
  report_path  <- file.path(root, "reports/publication/publication-report.Rmd")
  output_dir   <- file.path(root, outputDir)
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  output_file  <- file.path(output_dir, paste0("publication_report_", reportName, ".html"))

  rmarkdown::render(
    input       = report_path,
    output_file = output_file,
    params      = list(
      cacheDir             = cacheDir,
      gdxPath              = gdxPath,
      theoryConfigFile     = theoryConfigFile,
      predictionConfigFile = predictionConfigFile,
      modelDir             = modelDir,
      assetDir             = file.path(outputDir, paste0("publication_", reportName))
    ),
    envir = new.env(parent = globalenv())
  )

  message("Publication report written to: ", output_file)
  invisible(output_file)
}

# ── CLI argument parsing ───────────────────────────────────────────────────────
args                <- commandArgs(trailingOnly = TRUE)
report_name_arg     <- NULL
theory_cfg_arg      <- NULL
prediction_cfg_arg  <- NULL

for (a in args) {
  if (startsWith(a, "--reportName="))       report_name_arg    <- sub("^--reportName=",       "", a)
  if (startsWith(a, "--theoryConfig="))     theory_cfg_arg     <- sub("^--theoryConfig=",     "", a)
  if (startsWith(a, "--predictionConfig=")) prediction_cfg_arg <- sub("^--predictionConfig=", "", a)
}

render_args <- list(
  reportName           = if (!is.null(report_name_arg))    report_name_arg    else getPfmConfig("reportName", "default"),
  theoryConfigFile     = if (!is.null(theory_cfg_arg))     theory_cfg_arg
                         else if (!is.null(report_name_arg) && report_name_arg == "best")
                           "reports/model-selection/model-configs/selected-models-best.yml"
                         else "reports/model-selection/model-configs/selected-models-v2.yml",
  predictionConfigFile = if (!is.null(prediction_cfg_arg)) prediction_cfg_arg
                         else "reports/model-selection/model-configs/selected-models-v2-prediction.yml"
)
do.call(render_report, render_args)
