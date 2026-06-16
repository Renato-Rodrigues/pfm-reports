# Render the PFM Results — Adoption report (pure consumer, ADR 0006).
#
# Usage:
#   Rscript reports/results-adoption/run.R
#   Rscript reports/results-adoption/run.R --reportName=channels-exhaustive \
#     --modelConfig=reports/model-selection/model-configs/selected-models-channels.yml

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    modelConfig = getPfmConfig("resultsModelConfig",
                               "reports/model-selection/model-configs/selected-models-channels.yml"),
    reportName  = getPfmConfig("reportName", "default"),
    gdxPath     = getPfmConfig("gdxPath", "data/fulldata.gdx"),
    cacheDir    = getPfmConfig("cacheDir", "")) {

  root <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/results-adoption/results-adoption.Rmd")
  output_file <- file.path(root, "output", paste0("results_adoption_", reportName, ".html"))
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input = rmd_path,
    output_file = output_file,
    params = list(modelConfig = modelConfig, reportName = reportName,
                  gdxPath = gdxPath, cacheDir = cacheDir),
    envir = new.env(parent = globalenv())
  )
  message("Report written to: ", output_file)
  invisible(output_file)
}

args <- commandArgs(trailingOnly = TRUE)
cfg_arg <- NULL
name_arg <- NULL
for (a in args) {
  if (startsWith(a, "--modelConfig=")) cfg_arg <- sub("^--modelConfig=", "", a)
  if (startsWith(a, "--reportName=")) name_arg <- sub("^--reportName=", "", a)
}
render_report(
  modelConfig = if (!is.null(cfg_arg)) cfg_arg else
    getPfmConfig("resultsModelConfig", "reports/model-selection/model-configs/selected-models-channels.yml"),
  reportName = if (!is.null(name_arg)) name_arg else getPfmConfig("reportName", "default")
)
