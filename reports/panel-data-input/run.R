# Render the PFM Panel Data Input report.
#
# Usage (from repo root or this folder):
#   source("reports/panel-data-input/run.R")
#
# Or with custom paths:
#   source("reports/panel-data-input/run.R")
#
# Parameters
# ----------
# cacheDir      : madrat cache folder.
#                 Example: "C:/Users/you/Desktop/Input Data/remind_inputdata/cache/default"
# gdxPath       : path to fulldata.gdx for scenario projections.
#                 Example: "C:/Users/you/Desktop/Projects/Elevate/code/fulldata.gdx"
# outputFile    : path for the rendered HTML. Default: "output/panel_data_input.html"

library(rmarkdown)
library(rprojroot)

render_report <- function(
    cacheDir      = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/cache/default",
    gdxPath       = "c:/Users/renatoro/Desktop/Projects/Elevate/code/fulldata.gdx",
    outputFile    = "output/panel_data_input.html") {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/panel-data-input/panel-data-input.Rmd")

  # Resolve all paths relative to repo root
  params <- list(
    cacheDir      = cacheDir,
    gdxPath       = gdxPath
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
render_report(
  cacheDir      = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/cache/default",
  gdxPath       = "c:/Users/renatoro/Desktop/Projects/Elevate/code/fulldata.gdx",
  outputFile    = "output/panel_data_input.html"
)
