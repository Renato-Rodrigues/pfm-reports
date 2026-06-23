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
  if (isTRUE(verbose)) message("[pfmreports] rendering ", name, " -> ",
                               file.path(outputDir, outputFile))
  rmarkdown::render(
    input = tmpl, output_file = outputFile, output_dir = outputDir,
    intermediates_dir = tempfile("pfmreports-"), knit_root_dir = knitWd,
    params = params, envir = new.env(parent = globalenv()), quiet = !verbose
  )
  invisible(file.path(outputDir, outputFile))
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
#' @return Named list of rendered HTML paths (invisibly).
#' @export
renderGroup <- function(group = getPfmConfig("group", "exhaustive"),
                        reports = NULL, resultsDir = .defResults(), modelDir = .defModel(),
                        cachefolder = .defCache(), gdxFile = .defGdx(), reportName = group,
                        outputDir = .defOutput(), verbose = TRUE) {
  all <- c("selection", "model-selection", "results-adoption", "results-stringency",
           "publication", "robustness", "subnational")
  reports <- if (is.null(reports)) all else intersect(all, reports)
  fns <- list(
    "selection" = function() renderSelection(group, resultsDir, reportName, outputDir, verbose),
    "model-selection" = function() renderModelSelection(group, resultsDir, reportName,
                                                        outputDir = outputDir, verbose = verbose),
    "results-adoption" = function() renderResultsAdoption(group, resultsDir, modelDir, cachefolder,
                                                          gdxFile, reportName, outputDir, verbose),
    "results-stringency" = function() renderResultsStringency(group, resultsDir, modelDir,
                                                              cachefolder, gdxFile, reportName,
                                                              outputDir, verbose),
    "publication" = function() renderPublication(group, resultsDir, modelDir, cachefolder, gdxFile,
                                                 reportName, outputDir, verbose),
    "robustness" = function() renderRobustness(group, resultsDir, reportName, outputDir, verbose),
    "subnational" = function() renderSubnational(group, resultsDir, reportName, outputDir, verbose)
  )
  out <- list()
  for (r in reports) {
    out[[r]] <- tryCatch(fns[[r]](), error = function(e) {
      message("[pfmreports] report '", r, "' FAILED: ", conditionMessage(e)); NULL
    })
  }
  invisible(out)
}
