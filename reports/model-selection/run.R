# Render the PFM Model Selection report.
#
# Usage (from repo root or this folder):
#   source("reports/model-selection/run.R")
#   Rscript reports/model-selection/run.R
#   Rscript reports/model-selection/run.R --modelConfig=model-configs/vdem-focus.yml
#   Rscript reports/model-selection/run.R --modelConfig=/abs/path/to/my-config.yml
#
# The output file is named model_selection_<config-stem>.html so different
# config runs never overwrite each other.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    modelConfigFile = getPfmConfig("modelConfigFile", "model-configs/default.yml"),
    cacheDir        = getPfmConfig("cacheDir", ""),
    outputDir       = "output") {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/model-selection/model-selection.Rmd")

  config_stem <- tools::file_path_sans_ext(basename(modelConfigFile))
  output_file <- file.path(root, outputDir,
                           paste0("model_selection_", config_stem, ".html"))
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input       = rmd_path,
    output_file = output_file,
    params      = list(modelConfigFile = modelConfigFile),
    envir       = new.env(parent = globalenv())
  )

  message("Report written to: ", output_file)
  invisible(output_file)
}

# ── CLI argument parsing ───────────────────────────────────────────────────────
args        <- commandArgs(trailingOnly = TRUE)
config_arg  <- NULL
for (a in args) {
  if (startsWith(a, "--modelConfig=")) {
    config_arg <- sub("^--modelConfig=", "", a)
  }
}

render_report(
  modelConfigFile = if (!is.null(config_arg)) config_arg
                    else getPfmConfig("modelConfigFile", "model-configs/default.yml")
)
