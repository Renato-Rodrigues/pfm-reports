# Standalone / diagnostic report render functions (ADR 0021). Thin wrappers over .renderRmd;
# the templates keep their own param defaults, so only the path-bearing params are overridden.

#' Render the single-model Adoption report
#'
#' Renders the template's built-in baseline specification. (The deliverable's adoption model is
#' reported by \code{\link{renderResultsAdoption}}; wiring a selected-models config into this
#' single-model template is a future enhancement.)
#'
#' @param modelDir,cachefolder,gdxFile Fit Cache / madrat cache / scenario gdx.
#' @param reportName Output filename suffix.
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderAdoptionModel <- function(modelDir = .defModel(), cachefolder = .defCache(),
                                gdxFile = .defGdx(), reportName = "default",
                                outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("adoption-model", sprintf("adoption_model_%s.html", reportName),
             params = list(reportName = reportName, cachefolder = cachefolder, gdxPath = gdxFile,
                           assetDir = file.path(.absPath(outputDir),
                                                paste0("adoption_model_", reportName))),
             outputDir = outputDir, verbose = verbose)
}

#' Render the single-model Stringency report
#'
#' @inheritParams renderAdoptionModel
#' @return Path to the rendered HTML (invisibly).
#' @export
renderStringencyModel <- function(modelDir = .defModel(), cachefolder = .defCache(),
                                  gdxFile = .defGdx(), reportName = "default",
                                  outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("stringency-model", sprintf("stringency_model_%s.html", reportName),
             params = list(reportName = reportName, cachefolder = cachefolder, gdxPath = gdxFile,
                           assetDir = file.path(.absPath(outputDir),
                                                paste0("stringency_model_", reportName))),
             outputDir = outputDir, verbose = verbose)
}

#' Render the per-country adoption decomposition report
#'
#' @param country ISO3 region code (e.g. \code{"BRA"}).
#' @param countryName Display name (default = \code{country}).
#' @param modelDir,cachefolder,gdxFile Fit Cache / madrat cache / scenario gdx.
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderCountryAdoption <- function(country = "BRA", countryName = country,
                                  modelDir = .defModel(), cachefolder = .defCache(),
                                  gdxFile = .defGdx(), outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("country-adoption", sprintf("country_adoption_%s.html", country),
             params = list(country = country, countryName = countryName,
                           cachefolder = cachefolder, gdxPath = gdxFile,
                           assetDir = file.path(.absPath(outputDir),
                                                paste0("country_adoption_", country))),
             outputDir = outputDir, verbose = verbose)
}

#' Render the IAM/PFM model-diagnostics report
#'
#' @param modelDir,cachefolder,gdxFile Fit Cache / madrat cache / scenario gdx.
#' @param modelDataFile Path to the consolidated \code{modelData.RData} cache.
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderModelDiagnostics <- function(modelDir = .defModel(), cachefolder = .defCache(),
                                   gdxFile = .defGdx(),
                                   modelDataFile = file.path(.defOutput(), "modelData.RData"),
                                   outputDir = .defOutput(), verbose = TRUE) {
  options(pfm.modelDir = .absPath(modelDir))
  .renderRmd("IAM_PFM_report", "IAM_PFM_report.html",
             params = list(modelDataFile = modelDataFile, modelDir = .absPath(modelDir),
                           cachefolder = cachefolder, gdxPath = gdxFile,
                           assetDir = file.path(.absPath(outputDir), "IAM_PFM_report")),
             outputDir = outputDir, verbose = verbose)
}

#' Render the assembled-panel report
#'
#' @param cachefolder,gdxFile madrat cache / scenario gdx.
#' @param reportName Output filename suffix.
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderPanelData <- function(cachefolder = .defCache(), gdxFile = .defGdx(),
                            reportName = "default", outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("panel-data", sprintf("panel_data_%s.html", reportName),
             params = list(cachefolder = cachefolder, gdxPath = gdxFile, reportName = reportName),
             outputDir = outputDir, verbose = verbose)
}

#' Render the raw panel-input report
#'
#' @inheritParams renderPanelData
#' @return Path to the rendered HTML (invisibly).
#' @export
renderPanelDataInput <- function(cachefolder = .defCache(), gdxFile = .defGdx(),
                                 outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("panel-data-input", "panel_data_input.html",
             params = list(cachefolder = cachefolder, gdxPath = gdxFile),
             outputDir = outputDir, verbose = verbose)
}

#' Render the REMIND downscaling report
#'
#' @inheritParams renderPanelData
#' @return Path to the rendered HTML (invisibly).
#' @export
renderDownscale <- function(cachefolder = .defCache(), gdxFile = .defGdx(),
                            outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("downscale", "downscale.html",
             params = list(cachefolder = cachefolder, gdxPath = gdxFile),
             outputDir = outputDir, verbose = verbose)
}

#' Render the CAPMF regional-coverage report
#'
#' @param cachefolder madrat cache.
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderCapmfCoverage <- function(cachefolder = .defCache(), outputDir = .defOutput(),
                                verbose = TRUE) {
  .renderRmd("capmf-coverage", "capmf_coverage.html",
             params = list(cachefolder = cachefolder),
             outputDir = outputDir, verbose = verbose)
}
