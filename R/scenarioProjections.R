# Report-side consumer of the per-scenario feasibility projections (ADR 0035). The compute layer
# (pfm::runProjection) fans the deployed model over the Policy Scenario Registry and writes one
# projections/<id>.rds per scenario (rows tagged scenario/scenarioName) plus the legacy
# projection.rds. Reports read those artifacts here rather than re-projecting per scenario.

#' Load a Run-Group's per-scenario feasibility projections (ADR 0035)
#'
#' Pure consumer: reads every \code{<dir>/<id>.rds} (one per Policy Scenario),
#' row-binds them, and guarantees \code{scenario}/\code{scenarioName} columns. When
#' the per-scenario directory is absent/empty it falls back to the legacy single
#' \code{projection.rds} one level up (tagged as a single \code{"scenario"}).
#'
#' @param dir Path to the group's \code{projections/} directory (e.g.
#'   \code{file.path(dirname(modelConfig), "projections")}).
#' @return A \code{data.frame} (\code{region, year, sector, prob, price, ...,
#'   scenario, scenarioName}) combining all scenarios, or \code{NULL} when nothing
#'   is found.
#' @seealso \code{pfm::runProjection}, \code{\link{scenarioOrder}}
#' @export
loadGroupProjections <- function(dir) {
  files <- if (!is.null(dir) && dir.exists(dir)) list.files(dir, pattern = "\\.rds$", full.names = TRUE) else character(0)
  tag <- function(x, sid) {
    if (is.null(x) || !nrow(x)) return(NULL)
    if (is.null(x$scenario))     x$scenario     <- sid
    if (is.null(x$scenarioName)) x$scenarioName <- x$scenario
    x
  }
  df <- NULL
  if (length(files)) {
    df <- do.call(rbind, lapply(files, function(f)
      tag(tryCatch(readRDS(f), error = function(e) NULL), sub("\\.rds$", "", basename(f)))))
  }
  if (is.null(df) && !is.null(dir)) {                       # legacy fallback: <group>/projection.rds
    legacy <- file.path(dirname(dir), "projection.rds")
    if (file.exists(legacy)) df <- tag(tryCatch(readRDS(legacy), error = function(e) NULL), "scenario")
  }
  df
}

#' Order scenarios from least to most ambitious by mean P(adoption) (ADR 0035)
#'
#' A stable left-to-right ordering for side-by-side scenario exhibits: ascending
#' mean adoption probability at \code{atYear} (the milder pathway first), without
#' hard-coding scenario ids.
#'
#' @param proj A combined projection \code{data.frame} from
#'   \code{\link{loadGroupProjections}}.
#' @param atYear Year to rank at (snapped to the nearest available). Default 2050.
#' @return A character vector of scenario ids in ascending-ambition order.
#' @export
scenarioOrder <- function(proj, atYear = 2050) {
  if (is.null(proj) || !nrow(proj)) return(character(0))
  yy <- proj$year[which.min(abs(unique(proj$year) - atYear))][1]
  if (length(unique(proj$year))) yy <- unique(proj$year)[which.min(abs(unique(proj$year) - atYear))]
  d <- proj[proj$year == yy, ]
  ag <- stats::aggregate(prob ~ scenario, data = d, FUN = mean)
  ag$scenario[order(ag$prob)]
}
