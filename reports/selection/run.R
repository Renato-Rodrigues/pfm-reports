# Render the PFM Selection report (pure consumer of the workflow RDS, ADR 0006).
#
# Usage (from repo root or this folder):
#   Rscript reports/selection/run.R
#   Rscript reports/selection/run.R --workflowRds=output/channels_workflow_exhaustive.rds --reportName=channels-exhaustive

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    workflowRds = getPfmConfig("workflowRds", "output/channels_workflow_exhaustive.rds"),
    reportName  = getPfmConfig("reportName", "default")) {

  root <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/selection/selection.Rmd")
  output_file <- file.path(root, "output", paste0("selection_", reportName, ".html"))
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input = rmd_path,
    output_file = output_file,
    params = list(workflowRds = workflowRds, reportName = reportName),
    envir = new.env(parent = globalenv())
  )
  message("Report written to: ", output_file)
  invisible(output_file)
}

args <- commandArgs(trailingOnly = TRUE)
rds_arg <- NULL
report_name_arg <- NULL
for (a in args) {
  if (startsWith(a, "--workflowRds=")) rds_arg <- sub("^--workflowRds=", "", a)
  if (startsWith(a, "--reportName=")) report_name_arg <- sub("^--reportName=", "", a)
}
render_report(
  workflowRds = if (!is.null(rds_arg)) rds_arg else getPfmConfig("workflowRds", "output/channels_workflow_exhaustive.rds"),
  reportName  = if (!is.null(report_name_arg)) report_name_arg else getPfmConfig("reportName", "default")
)
