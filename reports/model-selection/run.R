# Render the PFM Model Selection report.
#
# Usage (from repo root or this folder):
#   source("reports/model-selection/run.R")

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    modelDataFile = "data/modelData.RData",
    modelDir      = getPfmConfig("modelDir", "../../models"),
    cacheDir      = getPfmConfig("cacheDir", ""),
    gdxPath       = getPfmConfig("gdxPath", "../../fulldata.gdx"),
    outputFile    = "../../output/model_selection.html",
    assetDir      = "../../output/model_selection") {

  root        <- find_rstudio_root_file()
  rmd_path    <- file.path(root, "reports/model-selection/model-selection.Rmd")
  output_path <- file.path(root, outputFile)
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  
  rmarkdown::render(
    input       = rmd_path,
    output_file = output_path,
    envir       = new.env(parent = globalenv())
  )
  
  message("Report written to: ", output_path)
  invisible(output_path)
}

# Run immediately when sourced
render_report()
