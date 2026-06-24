#!/usr/bin/env Rscript
# PFM run launcher (ADR 0020). Runs a model group locally or as a PIK SLURM job, optionally
# rendering the reports afterwards. Run from the pfm-reports working directory.
#
# Examples:
#   Rscript start.R                                   # exhaustive sweep, 32 cores (defaults)
#   Rscript start.R --nCores=128 --steps=sweep,robustness,temporal,subnational --render
#   Rscript start.R --group=guided --mode=guided --cluster=local
#   Rscript start.R --group=no-fe54 --qos=medium --time=2-00:00:00 --selectFE=H12,OECDp,Mundlak
#   Rscript start.R --selectFE=all                    # lift the FE constraint (allow pooled noFE)
#
# Paths (relative paths are resolved against the current working directory):
#   madrat data cache : --cachefolder= | config cachefolder/cacheDir | default data/cache
#   Fit Cache (models): --modelDir=    | config modelDir              | default output
#   Results Root      : --resultsDir=  | config resultsDir            | default output
#   scenario gdx      : --gdxFile=     | config gdxPath               | default data/fulldata.gdx
# Other defaults: group=exhaustive, mode=exhaustive, steps=sweep, nCores=32. SLURM vs local is
# auto-detected (override with --cluster=slurm|local).
suppressMessages(library(pfm))

args <- commandArgs(trailingOnly = TRUE)
getArg  <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
}
hasFlag <- function(name) any(args == paste0("--", name))

cfg <- list()
if (file.exists("config.yml") && requireNamespace("yaml", quietly = TRUE)) {
  cfg <- tryCatch(yaml::read_yaml("config.yml"), error = function(e) list())
}
`%||%` <- function(a, b) if (is.null(a)) b else a
# config value (NULL/"" -> fallback). For the madrat cache, accept the legacy `cacheDir` key too.
def <- function(key, fb) { v <- cfg[[key]]; if (is.null(v) || !nzchar(as.character(v))) fb else v }
defCache <- function(fb) {
  v <- cfg[["cachefolder"]] %||% cfg[["cacheDir"]]
  if (is.null(v) || !nzchar(as.character(v))) fb else v
}
absify <- function(p) if (is.null(p) || grepl("^([A-Za-z]:|/|\\\\)", p)) p else normalizePath(file.path(getwd(), p), winslash = "/", mustWork = FALSE)

nCoresArg <- getArg("nCores", NULL)
cachefolder <- absify(getArg("cachefolder", defCache("data/cache")))
gdx <- absify(getArg("gdxFile", def("gdxPath", "data/fulldata.gdx")))
if (!is.null(gdx) && !file.exists(gdx)) {
  message("[start] scenario gdx not found (", gdx, ") — Projection-Sanity gate will be skipped.")
  gdx <- NULL
}
render   <- hasFlag("render")
selectFE <- getArg("selectFE", NULL)

callArgs <- list(
  group           = getArg("group", "exhaustive"),
  steps           = strsplit(getArg("steps", "sweep"), ",")[[1]],
  mode            = getArg("mode", "exhaustive"),
  selectionMethod = getArg("selectionMethod", "levels-first"),
  resultsDir      = absify(getArg("resultsDir", def("resultsDir", "output"))),
  modelDir        = absify(getArg("modelDir",   def("modelDir",   "output"))),
  cachefolder     = cachefolder,
  gdxFile         = gdx,
  nCores          = as.integer(if (is.null(nCoresArg)) "32" else nCoresArg),
  cluster         = getArg("cluster", "auto"),
  qos             = getArg("qos", "short"),
  partition       = getArg("partition", "standard"),
  time            = getArg("time", "24:00:00"),
  account         = getArg("account", NULL),
  mem             = getArg("mem", NULL),
  outputDir       = absify(getArg("outputDir", def("outputDir", "output"))),
  render          = render,
  forceRefit      = hasFlag("forceRefit")
)
# Forwarded to runSweep -> runChannelsWorkflow. Default (arg omitted) leaves selectFE unset, so the
# workflow's own default applies: c("H12","OECDp","Mundlak") — a real region-FE/Mundlak deliverable
# is required and pooled `noFE` is never auto-selected. `--selectFE=all|none|off` lifts the constraint.
if (!is.null(selectFE)) {
  if (tolower(selectFE) %in% c("all", "none", "off")) {
    callArgs["selectFE"] <- list(NULL)            # explicit NULL (not list-element deletion): lift it
  } else {
    callArgs$selectFE <- strsplit(selectFE, ",")[[1]]
  }
}
do.call(pfm::startRun, callArgs)
