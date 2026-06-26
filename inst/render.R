#!/usr/bin/env Rscript
# pfmreports render CLI (ADR 0021). Renders a Run-Group's consumer reports (or a chosen subset)
# from the installed package. Run from the working directory that holds config.yml.
#
#   Rscript render.R --group=exhaustive
#   Rscript render.R --group=guided --reports=selection,robustness
#   Rscript render.R --group=exhaustive --outputDir=output --reportName=channels-exhaustive
#
# Paths resolve from config.yml / options when flags are omitted (see DESCRIPTION / ADR 0021).
suppressPackageStartupMessages(library(pfmreports))

args <- commandArgs(trailingOnly = TRUE)
getArg <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
}

group   <- parseGroupArg(args)
reports <- getArg("reports", NULL)
reports <- if (is.null(reports)) NULL else strsplit(reports, ",")[[1]]

invisible(renderGroup(
  group       = group,
  reports     = reports,
  resultsDir  = getArg("resultsDir", getOption("pfm.resultsDir", getPfmConfig("resultsDir", "output"))),
  modelDir    = getArg("modelDir",   getOption("pfm.modelDir",   getPfmConfig("modelDir",   "output"))),
  cachefolder = getArg("cachefolder", getPfmConfig("cachefolder", getPfmConfig("cacheDir", "data/cache"))),
  gdxFile     = getArg("gdxFile",    getPfmConfig("gdxPath", "data/fulldata.gdx")),
  reportName  = getArg("reportName", group),
  outputDir   = getArg("outputDir",  getPfmConfig("outputDir", ".")),
  nCores      = as.integer(getArg("nCores", getArg("renderCores", NULL)))
))
