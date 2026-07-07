# Policy Stringency Model (PSM) report renders (ADR 0036). Pure consumers of the
# PSM Run-Group artifacts written by pfm::runPSMSweep / runPSMProjection /
# runPSMEstimatorAgreement.

#' Render the PSM Results report (consumes a PSM Run-Group)
#'
#' One comprehensive report for a Policy Stringency Model Run-Group: sweep +
#' maximin selection, the bounded-index Projection-Sanity trace, the deployed
#' spec's coefficients, the estimator-agreement exhibit (satP engine /
#' fractional-logit headline / beta / levels), and the scenario fan-out
#' projections with the Implementability Factor. Every section degrades
#' gracefully when its artifact is missing, so the report can be rendered at any
#' pipeline stage.
#'
#' @param group PSM Run-Group name (e.g. \code{"psm-exhaustive"}).
#' @param resultsDir Results Root containing the Run-Group.
#' @param reportName Output filename suffix. Default = \code{group}.
#' @param indexMax Index ceiling used at fit time (CAPMF: 10).
#' @param outputDir Directory for the rendered HTML.
#' @param verbose Logical.
#' @return Path to the rendered HTML (invisibly).
#' @export
renderPSMResults <- function(group = getPfmConfig("group", "psm-exhaustive"),
                             resultsDir = .defResults(), reportName = group,
                             indexMax = 10, outputDir = .defOutput(), verbose = TRUE) {
  .renderRmd("psm-results", sprintf("psm_results_%s.html", reportName),
             params = list(
               sweepRds = runGroupArtifact("sweep.rds", group, resultsDir),
               selectedConfig = runGroupArtifact("selected-models-psm.yml", group, resultsDir),
               agreementRds = runGroupArtifact("estimator-agreement.rds", group, resultsDir),
               projectionsDir = runGroupArtifact("projections", group, resultsDir),
               manifestJson = runGroupArtifact("manifest.json", group, resultsDir),
               temporalRds = runGroupArtifact("temporal-validation.rds", group, resultsDir),
               frontierRds = runGroupArtifact("frontier.rds", group, resultsDir),
               reportName = reportName, indexMax = indexMax
             ),
             outputDir = outputDir, verbose = verbose)
}
