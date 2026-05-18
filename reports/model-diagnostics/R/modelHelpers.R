library(pfm)

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
