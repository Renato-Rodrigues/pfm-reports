# Render the PFM Panel Data input-diagnostics report (pure consumer, ADR 0006).
#
# Usage (from repo root or this folder):
#   Rscript reports/panel-data/run.R
#   Rscript reports/panel-data/run.R --reportName=mylabel --gdxPath=data/fulldata.gdx

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    reportName = getPfmConfig("reportName", "default"),
    cacheDir   = getPfmConfig("cacheDir", ""),
    gdxPath    = getPfmConfig("gdxPath", "data/fulldata.gdx")) {

  root <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/panel-data/panel-data.Rmd")
  output_file <- file.path(root, "output", paste0("panel_data_", reportName, ".html"))
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input = rmd_path,
    output_file = output_file,
    params = list(cacheDir = cacheDir, gdxPath = gdxPath, reportName = reportName),
    envir = new.env(parent = globalenv())
  )
  message("Report written to: ", output_file)
  invisible(output_file)
}

args <- commandArgs(trailingOnly = TRUE)
report_name_arg <- NULL
gdx_arg <- NULL
for (a in args) {
  if (startsWith(a, "--reportName=")) report_name_arg <- sub("^--reportName=", "", a)
  if (startsWith(a, "--gdxPath="))    gdx_arg         <- sub("^--gdxPath=", "", a)
}
render_report(
  reportName = if (!is.null(report_name_arg)) report_name_arg else getPfmConfig("reportName", "default"),
  gdxPath    = if (!is.null(gdx_arg)) gdx_arg else getPfmConfig("gdxPath", "data/fulldata.gdx")
)
