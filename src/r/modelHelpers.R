library(pfm)

#' Convert a model-matrix term name to a plain-text label (for ggplot2 axes)
#'
#' Handles interactions, (WGI)/(VDem) suffixes, regionFE prefix, timeTrend,
#' Actor.Power.Index → API, and replaces dots with spaces.
#'
#' @param t Character scalar — raw R term name.
#' @return Cleaned plain-text string.
clean_term_plain <- function(t) {
  if (grepl("_x_", t)) {
    pts <- strsplit(t, "_x_")[[1]]
    return(paste0(clean_term_plain(pts[1]), " × ", clean_term_plain(pts[2])))
  }
  if (grepl(":", t)) {
    pts <- strsplit(t, ":")[[1]]
    return(paste0(clean_term_plain(pts[1]), " × ", clean_term_plain(pts[2])))
  }
  if (grepl("^regionFE", t)) return(paste0("FE: ", sub("^regionFE", "", t)))
  t <- gsub("Actor\\.Power\\.Index", "API",         t)
  t <- gsub("timeTrend",              "Time Trend",  t)
  t <- gsub("\\(Intercept\\)",        "Intercept",   t)
  t <- gsub("\\.\\.(WGI)\\.",  " (WGI)",  t)
  t <- gsub("\\.\\.(VDem)\\.", " (VDem)", t)
  t <- gsub("\\.",             " ",       t)
  t <- gsub(" {2,}",           " ",       trimws(t))
  t
}

#' Convert a model-matrix term name to an HTML label (for kable tables with escape = FALSE)
#'
#' Like clean_term_plain() but wraps interactions with HTML <br> and uses
#' <small>×</small> for the operator; regionFE gets a <br> separator.
#'
#' @param t Character scalar — raw R term name.
#' @return Cleaned HTML string.
clean_term <- function(t) {
  if (grepl("_x_", t)) {
    pts <- strsplit(t, "_x_")[[1]]
    return(paste0(clean_term(pts[1]), "<br><small>×</small><br>", clean_term(pts[2])))
  }
  if (grepl(":", t)) {
    pts <- strsplit(t, ":")[[1]]
    return(paste0(clean_term(pts[1]), "<br><small>×</small><br>", clean_term(pts[2])))
  }
  if (grepl("^regionFE", t)) return(paste0("FE:<br>", sub("^regionFE", "", t)))
  t <- gsub("Actor\\.Power\\.Index", "API",         t)
  t <- gsub("timeTrend",              "Time Trend",  t)
  t <- gsub("\\(Intercept\\)",        "Intercept",   t)
  t <- gsub("\\.\\.(WGI)\\.",  " (WGI)",  t)
  t <- gsub("\\.\\.(VDem)\\.", " (VDem)", t)
  t <- gsub("\\.",             " ",       t)
  t <- gsub(" {2,}",           " ",       trimws(t))
  t
}

#' Extract best model coefficients as a data frame
#'
#' @param wf A modelSelectionWorkflow result object.
#' @param sector Character. "Bulk" or "Diffuse".
#' @param stage Character. "adoption" or "stringency".
#' @return Data frame with columns: term, estimate, stdError, statistic, pValue.
get_best_coefs <- function(wf, sector, stage) {
  comboName <- paste(sector, stage, sep = "_")
  sel <- wf$selections[[comboName]]
  if (is.null(sel) || is.null(sel$bestModel)) {
    return(data.frame(
      term = character(), estimate = numeric(),
      stdError = numeric(), statistic = numeric(), pValue = numeric()
    ))
  }
  pfm::coeftestToDataFrame(sel$bestModel$coeftest)
}

#' Extract best model diagnostics
#'
#' @param wf A modelSelectionWorkflow result object.
#' @param sector Character. "Bulk" or "Diffuse".
#' @param stage Character. "adoption" or "stringency".
#' @return The bestModel list element, or a list of NAs if missing.
get_best_diag <- function(wf, sector, stage) {
  comboName <- paste(sector, stage, sep = "_")
  sel <- wf$selections[[comboName]]
  if (is.null(sel) || is.null(sel$bestModel)) {
    return(list(pseudoR2 = NA, aic = NA, nSignificant = 0, nPredictors = 0))
  }
  sel$bestModel
}
