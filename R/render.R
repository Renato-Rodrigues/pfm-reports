# Report render functions (ADR 0021). Each render<Report>() is a thin wrapper that locates its
# shipped template via system.file("rmd/<name>.Rmd") and renders it with rmarkdown, directing
# all writes to outputDir (templates live read-only in the installed library). renderGroup()
# renders the Run-Group-consuming set; renderAll-style use is via the inst/render.R CLI.

# ── shared default resolvers (options first, then config.yml, then a sensible fallback) ──
.defResults <- function() getOption("pfm.resultsDir", getPfmConfig("resultsDir", "output"))
.defModel   <- function() getOption("pfm.modelDir",   getPfmConfig("modelDir",   "output"))
.defCache   <- function() getPfmConfig("cachefolder", getPfmConfig("cacheDir", "data/cache"))
.defGdx     <- function() getPfmConfig("gdxPath", "data/fulldata.gdx")
.defOutput  <- function() getOption("pfmreports.outputDir", getPfmConfig("outputDir", "."))

# Internal: render a shipped template to outputDir without writing into the installed library.
#' @importFrom rmarkdown render
#' @keywords internal
.renderRmd <- function(name, outputFile, params = list(), outputDir = .defOutput(),
                       verbose = TRUE) {
  tmpl <- system.file("rmd", paste0(name, ".Rmd"), package = "pfmreports")
  if (!nzchar(tmpl) || !file.exists(tmpl)) {
    stop("pfmreports: template not found in package: rmd/", name, ".Rmd", call. = FALSE)
  }
  # Force `params` NOW, while the working directory is still the caller's: the path-bearing
  # params (e.g. runGroupArtifact(...)) call .absPath against getwd(), and rmarkdown::render
  # otherwise forces this promise only after it has setwd() into the template's directory —
  # which would resolve every relative path against the installed library (lazy-eval trap).
  force(params)
  # Knit in the caller's working directory (not the read-only template dir, and not outputDir):
  # absolute artifact params then stay correct, and relative inputs (e.g. the "data"/"data/cache"
  # panel-cache + madrat folders) resolve against the project root the user ran from. Intermediates
  # and output go to writable locations so nothing is written into the installed library.
  knitWd <- getwd()
  outputDir <- .absPath(outputDir)
  dir.create(outputDir, showWarnings = FALSE, recursive = TRUE)
  # Anchor the report panel cache to an ABSOLUTE location (under outputDir), so it is never
  # written cwd-relative into the run-group folder during a cluster render (2026-06-24). A
  # user/config override (pfmreports.panelCacheDir) still wins.
  if (!nzchar(getOption("pfmreports.panelCacheDir", ""))) {
    options(pfmreports.panelCacheDir = file.path(outputDir, "panel-cache"))
  }
  if (isTRUE(verbose)) message("[pfmreports] rendering ", name, " -> ",
                               file.path(outputDir, outputFile))
  t0 <- Sys.time()
  # Inject the shared wide-layout CSS into every report (one place; no per-Rmd YAML edits).
  cssFile <- system.file("rmd", "pfm-report.css", package = "pfmreports")
  outOpts <- if (nzchar(cssFile) && file.exists(cssFile)) list(css = cssFile) else NULL
  interDir <- tempfile("pfmreports-")
  dir.create(interDir, showWarnings = FALSE, recursive = TRUE)   # render does not always create it
  rmarkdown::render(
    input = tmpl, output_file = outputFile, output_dir = outputDir,
    intermediates_dir = interDir, knit_root_dir = knitWd,
    params = params, envir = new.env(parent = globalenv()), quiet = !verbose,
    output_options = outOpts
  )
  # Completion marker (parsed by pfm::runStatus for the per-report render checklist, ADR 0030).
  if (isTRUE(verbose)) message("[pfmreports] done ", name, " (",
                               .fmtRenderDur(as.numeric(difftime(Sys.time(), t0, units = "secs"))), ")")
  invisible(file.path(outputDir, outputFile))
}

# Internal: compact render duration for the done-marker, e.g. 4 -> "4s", 95 -> "1m 35s".
#' @keywords internal
.fmtRenderDur <- function(secs) {
  s <- round(secs)
  if (s >= 60) sprintf("%dm %02ds", s %/% 60, s %% 60) else paste0(s, "s")
}

# ── Run-Group consumer reports ──────────────────────────────────────────────────

#' Render the Selection report (consumes \code{sweep.rds})
#'
#' @param group,resultsDir Run-Group locators.
#' @param reportName Output filename suffix (default = \code{group}).
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderSelection <- function(group = getPfmConfig("group", "exhaustive"),
                            resultsDir = .defResults(), reportName = group,
                            outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("selection", sprintf("selection_%s.html", reportName),
             params = list(workflowRds = runGroupArtifact("sweep.rds", group, resultsDir),
                           reportName = reportName),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Model-Selection sweep report (consumes \code{sweep.rds})
#'
#' @inheritParams renderSelection
#' @param topN Rows per heat-mapped ranking table.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderModelSelection <- function(group = getPfmConfig("group", "exhaustive"),
                                 resultsDir = .defResults(), reportName = group, topN = 40,
                                 outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("model-selection", sprintf("model_selection_%s.html", reportName),
             params = list(workflowRds = runGroupArtifact("sweep.rds", group, resultsDir),
                           reportName = reportName, topN = topN),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Results — Adoption report (consumes \code{selected-models.yml})
#'
#' @inheritParams renderSelection
#' @param modelDir,cachefolder,gdxFile Fit Cache / madrat cache / scenario gdx.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderResultsAdoption <- function(group = getPfmConfig("group", "exhaustive"),
                                  resultsDir = .defResults(), modelDir = .defModel(),
                                  cachefolder = .defCache(), gdxFile = .defGdx(),
                                  reportName = group, outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("results-adoption", sprintf("results_adoption_%s.html", reportName),
             params = list(modelConfig = runGroupArtifact("selected-models.yml", group, resultsDir),
                           reportName = reportName, gdxPath = gdxFile, cachefolder = cachefolder),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Results — Stringency report (consumes \code{selected-models.yml})
#'
#' @inheritParams renderResultsAdoption
#' @return Path to the rendered HTML (invisibly).
#' @export
renderResultsStringency <- function(group = getPfmConfig("group", "exhaustive"),
                                    resultsDir = .defResults(), modelDir = .defModel(),
                                    cachefolder = .defCache(), gdxFile = .defGdx(),
                                    reportName = group, outputDir = .defOutput(),
                                    verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("results-stringency", sprintf("results_stringency_%s.html", reportName),
             params = list(modelConfig = runGroupArtifact("selected-models.yml", group, resultsDir),
                           reportName = reportName, gdxPath = gdxFile, cachefolder = cachefolder),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Publication report (consumes \code{selected-models.yml})
#'
#' @inheritParams renderResultsAdoption
#' @return Path to the rendered HTML (invisibly).
#' @export
renderPublication <- function(group = getPfmConfig("group", "exhaustive"),
                              resultsDir = .defResults(), modelDir = .defModel(),
                              cachefolder = .defCache(), gdxFile = .defGdx(),
                              reportName = group, outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  sel <- runGroupArtifact("selected-models.yml", group, resultsDir)
  .renderRmd("publication-report", sprintf("publication_report_%s.html", reportName),
             params = list(cachefolder = cachefolder, gdxPath = gdxFile,
                           theoryConfigFile = sel, predictionConfigFile = sel,
                           modelDir = .absPath(modelDir),
                           assetDir = file.path(.absPath(outputDir),
                                                paste0("publication_", reportName))),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Robustness report (consumes \code{robustness.rds} + sweep/temporal/difference-first)
#'
#' @inheritParams renderSelection
#' @return Path to the rendered HTML (invisibly).
#' @export
renderRobustness <- function(group = getPfmConfig("group", "exhaustive"),
                             resultsDir = .defResults(), reportName = group,
                             outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("robustness", sprintf("robustness_%s.html", reportName),
             params = list(
               robustnessRds = runGroupArtifact("robustness.rds", group, resultsDir),
               workflowRds = runGroupArtifact("sweep.rds", group, resultsDir),
               difRds = runGroupArtifact("difference-first.rds", group, resultsDir),
               temporalRds = runGroupArtifact("temporal-split.rds", group, resultsDir)),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Selection-Stability report (consumes \code{selection-bootstrap.rds})
#'
#' @inheritParams renderSelection
#' @return Path to the rendered HTML (invisibly).
#' @export
renderSelectionStability <- function(group = getPfmConfig("group", "exhaustive"),
                                     resultsDir = .defResults(), reportName = group,
                                     outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("selection-stability", sprintf("selection_stability_%s.html", reportName),
             params = list(bootstrapRds = runGroupArtifact("selection-bootstrap.rds", group, resultsDir),
                           reportName = reportName),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Subnational sensitivity report (consumes \code{subnational.rds})
#'
#' @inheritParams renderSelection
#' @return Path to the rendered HTML (invisibly).
#' @export
renderSubnational <- function(group = getPfmConfig("group", "exhaustive"),
                              resultsDir = .defResults(), reportName = group,
                              outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("subnational", sprintf("subnational_%s.html", reportName),
             params = list(rds = runGroupArtifact("subnational.rds", group, resultsDir)),
             outputDir = outputDir, verbose = verbose)
}

#' Render the Run-Group's consumer reports
#'
#' Renders the standard set of reports that consume a Run-Group. \code{reports = NULL} renders
#' the default set; pass a subset to limit it.
#'
#' @param group,resultsDir,modelDir,cachefolder,gdxFile,outputDir,reportName,verbose See the
#'   individual render functions.
#' @param reports Character vector subset of
#'   \code{c("selection","model-selection","results-adoption","results-stringency",
#'   "publication","robustness","subnational")}, or \code{NULL} for all.
#' @param nCores Integer. Reports to render in parallel (ADR 0030). Default
#'   \code{min(length(reports), 4)} — the reports are independent; the panel cache is pre-warmed
#'   once so workers only read it. \code{1} = sequential. Override with a larger value on a big node.
#' @return Named list of rendered HTML paths (invisibly).
#' @export
renderGroup <- function(group = getPfmConfig("group", "exhaustive"),
                        reports = NULL, resultsDir = .defResults(), modelDir = .defModel(),
                        cachefolder = .defCache(), gdxFile = .defGdx(), reportName = group,
                        outputDir = .defOutput(), verbose = TRUE, nCores = NULL) {
  all <- c("selection", "model-selection", "results-adoption", "results-stringency",
           "publication", "robustness", "subnational", "selection-stability",
           "psm-results")
  # "psm-results" (ADR 0036) is requestable but NOT in the NULL-default set: the default is
  # the carbon-price report bundle, while the PSM report targets a PSM Run-Group.
  reports <- if (is.null(reports)) setdiff(all, "psm-results") else intersect(all, reports)
  fns <- list(
    "selection" = function() renderSelection(group, resultsDir, reportName, outputDir, verbose),
    "model-selection" = function() renderModelSelection(group, resultsDir, reportName,
                                                        outputDir = outputDir, verbose = verbose),
    "selection-stability" = function() renderSelectionStability(group, resultsDir, reportName,
                                                               outputDir, verbose),
    "results-adoption" = function() renderResultsAdoption(group, resultsDir, modelDir, cachefolder,
                                                          gdxFile, reportName, outputDir, verbose),
    "results-stringency" = function() renderResultsStringency(group, resultsDir, modelDir,
                                                              cachefolder, gdxFile, reportName,
                                                              outputDir, verbose),
    "publication" = function() renderPublication(group, resultsDir, modelDir, cachefolder, gdxFile,
                                                 reportName, outputDir, verbose),
    "robustness" = function() renderRobustness(group, resultsDir, reportName, outputDir, verbose),
    "subnational" = function() renderSubnational(group, resultsDir, reportName, outputDir, verbose),
    "psm-results" = function() renderPSMResults(group, resultsDir, reportName,
                                                outputDir = outputDir, verbose = verbose)
  )
  if (is.null(nCores)) nCores <- min(length(reports), 4L)
  nCores <- max(1L, as.integer(nCores))
  runOne <- function(r) tryCatch(fns[[r]](), error = function(e) {
    message("[pfmreports] report '", r, "' FAILED: ", conditionMessage(e)); NULL
  })

  useParallel <- nCores > 1L && length(reports) > 1L &&
    requireNamespace("future", quietly = TRUE) && requireNamespace("future.apply", quietly = TRUE)
  if (useParallel) {
    # Pre-warm the panel caches ONCE in the master so parallel workers only READ panel-cache/*.rds
    # (avoids the cold-cache write race; ADR 0030) — but only when a panel-consuming report is in
    # the set (selection/model-selection read the sweep rds, not the panel). Anchor the cache dir
    # the workers will derive.
    panelReports <- c("results-adoption", "results-stringency", "publication")
    if (length(intersect(reports, panelReports))) {
      if (!nzchar(getOption("pfmreports.panelCacheDir", ""))) {
        options(pfmreports.panelCacheDir = file.path(.absPath(outputDir), "panel-cache"))
      }
      if (nzchar(cachefolder)) try(madrat::setConfig(cachefolder = cachefolder), silent = TRUE)
      try(madrat::setConfig(forcecache = TRUE), silent = TRUE)
      try(getPanelDataHistoricalCached(aggregate = TRUE, y = 2000:2022,
          outputRegionMappingFile = "regionmapping_54.csv"), silent = TRUE)
      if (!is.null(gdxFile) && nzchar(gdxFile) && file.exists(gdxFile)) {
        try(getPanelDataScenarioCached(gdxFile = gdxFile, aggregate = TRUE,
            outputRegionMappingFile = "regionmapping_54.csv"), silent = TRUE)
      }
    }
    workers <- min(nCores, length(reports))
    oplan <- future::plan(); on.exit(future::plan(oplan), add = TRUE)
    if (identical(.Platform$OS.type, "windows")) {
      future::plan(future::multisession, workers = workers)
    } else {
      future::plan(future::multicore, workers = workers)
    }
    if (isTRUE(verbose)) message("[pfmreports] rendering ", length(reports),
                                 " reports across ", workers, " worker(s) ...")
    out <- future.apply::future_lapply(reports, runOne, future.seed = TRUE,
      future.packages = c("pfmreports", "pfm", "madrat", "magclass"))
    names(out) <- reports
  } else {
    out <- stats::setNames(lapply(reports, runOne), reports)
  }
  invisible(out)
}
