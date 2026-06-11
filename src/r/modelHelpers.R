library(pfm)

# Null-coalescing operator — returns x if non-NULL, otherwise y.
# Defined here so all reports that source modelHelpers.R have it available
# without relying on rlang being on the search path.
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (!is.null(x)) x else y
}

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

#' Format model coefficients into a LaTeX aligned equation for RMarkdown
#'
#' @param coefficients A data frame with columns \code{term}, \code{estimate}, and \code{pValue}.
#' @param actorPowerIndex Character or NULL.
#' @param actorPowerDrivers Character vector.
#' @param instQualityDrivers Character vector.
#' @param controlDrivers Character vector.
#' @param depVar Character. Left-hand side variable (e.g. "Pr(Adoption)").
#' @return A MathJax LaTeX block string.
formatModelEquationLatex <- function(coefficients, actorPowerIndex = NULL, actorPowerDrivers = NULL,
                                     instQualityDrivers = NULL, controlDrivers = NULL,
                                     depVar = "y") {
  if (nrow(coefficients) == 0) return("")

  # Helper for significance stars
  getStarsLatex <- function(p) {
    if (is.na(p)) return("")
    if (p < 0.01) return("^{***}")
    if (p < 0.05) return("^{**}")
    if (p < 0.1) return("^{*}")
    return("")
  }

  # Helper for formatting individual terms
  formatTermLatex <- function(estimate, term, pValue, isIntercept = FALSE) {
    stars <- getStarsLatex(pValue)
    val   <- abs(round(estimate, 3))
    
    if (isIntercept) {
      sign <- if (estimate >= 0) "" else "- "
      return(paste0(sign, val, stars))
    } else {
      sign  <- if (estimate >= 0) "+ " else "- "
      
      clean_lbl <- clean_term_plain(term)
      clean_lbl <- gsub(" × ", " \\times ", clean_lbl)
      
      return(paste0(sign, val, stars, " \\cdot \\text{", clean_lbl, "}"))
    }
  }

  safeAPI <- if (!is.null(actorPowerIndex)) make.names(actorPowerIndex) else NULL
  safeAPD <- if (!is.null(actorPowerDrivers)) make.names(actorPowerDrivers) else NULL
  safeIQD <- if (!is.null(instQualityDrivers)) make.names(instQualityDrivers) else NULL
  safeCD  <- if (!is.null(controlDrivers)) make.names(controlDrivers) else NULL

  df <- coefficients |>
    dplyr::mutate(
      group = dplyr::case_when(
        term == "(Intercept)" ~ "1_intercept",
        term == safeAPI | term %in% safeAPD ~ "2_actor",
        term %in% safeIQD ~ "3_inst",
        grepl("_x_|_interaction_", term) ~ "4_interaction",
        term %in% safeCD ~ "5_controls",
        term == "timeTrend" ~ "6_time",
        grepl("regionFE", term) ~ "7_fixed_effects",
        TRUE ~ "5_controls"
      ),
      term_txt = mapply(
        formatTermLatex, estimate, term, pValue, term == "(Intercept)"
      )
    ) |>
    dplyr::group_by(group) |>
    dplyr::summarise(group_txt = paste(term_txt, collapse = " "), .groups = "drop")

  eqParts <- stats::setNames(df$group_txt, df$group)

  out <- paste0("$$\n\\begin{aligned}\n", depVar, " = & ")
  if ("1_intercept" %in% names(eqParts)) {
    out <- paste0(out, eqParts["1_intercept"])
  }
  
  orderedGroups <- c("2_actor", "3_inst", "4_interaction", "5_controls", "6_time", "7_fixed_effects")
  for (g in orderedGroups) {
    if (g %in% names(eqParts)) {
      out <- paste0(out, " \\\\\n& ", eqParts[g])
    }
  }
  out <- paste0(out, "\n\\end{aligned}\n$$")
  return(out)
}

