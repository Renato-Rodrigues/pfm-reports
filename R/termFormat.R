# Model-term and equation display formatting for the reports.

#' Convert a model-matrix term name to a plain-text label
#'
#' Handles interactions, (WGI)/(VDem) suffixes, regionFE prefix, timeTrend, and
#' Actor.Power.Index -> API; replaces dots with spaces.
#'
#' @param t Character scalar — raw R term name.
#' @return Cleaned plain-text string.
#' @export
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
  t <- gsub("Actor\\.Power\\.Index", "API", t)
  t <- gsub("timeTrend", "Time Trend", t)
  t <- gsub("\\(Intercept\\)", "Intercept", t)
  t <- gsub("\\.\\.(WGI)\\.", " (WGI)", t)
  t <- gsub("\\.\\.(VDem)\\.", " (VDem)", t)
  t <- gsub("\\.", " ", t)
  gsub(" {2,}", " ", trimws(t))
}

#' Format model coefficients into a LaTeX aligned equation for RMarkdown
#'
#' @param coefficients Data frame with columns \code{term}, \code{estimate}, \code{pValue}.
#' @param actorPowerIndex Character or NULL.
#' @param actorPowerDrivers,instQualityDrivers,controlDrivers Character vectors or NULL.
#' @param depVar Character. Left-hand-side variable label.
#' @return A MathJax LaTeX block string.
#' @importFrom dplyr mutate case_when group_by summarise
#' @importFrom rlang .data
#' @export
formatModelEquationLatex <- function(coefficients, actorPowerIndex = NULL,
                                     actorPowerDrivers = NULL, instQualityDrivers = NULL,
                                     controlDrivers = NULL, depVar = "y") {
  if (nrow(coefficients) == 0) return("")

  getStarsLatex <- function(p) {
    if (is.na(p)) return("")
    if (p < 0.01) return("^{***}")
    if (p < 0.05) return("^{**}")
    if (p < 0.1) return("^{*}")
    ""
  }
  formatTermLatex <- function(estimate, term, pValue, isIntercept = FALSE) {
    stars <- getStarsLatex(pValue)
    val <- abs(round(estimate, 3))
    if (isIntercept) {
      paste0(if (estimate >= 0) "" else "- ", val, stars)
    } else {
      cleanLbl <- gsub(" × ", " \\times ", clean_term_plain(term))
      paste0(if (estimate >= 0) "+ " else "- ", val, stars, " \\cdot \\text{", cleanLbl, "}")
    }
  }

  safeAPI <- if (!is.null(actorPowerIndex)) make.names(actorPowerIndex) else NULL
  safeAPD <- if (!is.null(actorPowerDrivers)) make.names(actorPowerDrivers) else NULL
  safeIQD <- if (!is.null(instQualityDrivers)) make.names(instQualityDrivers) else NULL
  safeCD  <- if (!is.null(controlDrivers)) make.names(controlDrivers) else NULL

  df <- dplyr::summarise(
    dplyr::group_by(
      dplyr::mutate(
        coefficients,
        group = dplyr::case_when(
          .data$term == "(Intercept)" ~ "1_intercept",
          .data$term == safeAPI | .data$term %in% safeAPD ~ "2_actor",
          .data$term %in% safeIQD ~ "3_inst",
          grepl("_x_|_interaction_", .data$term) ~ "4_interaction",
          .data$term %in% safeCD ~ "5_controls",
          .data$term == "timeTrend" ~ "6_time",
          grepl("regionFE", .data$term) ~ "7_fixed_effects",
          TRUE ~ "5_controls"
        ),
        term_txt = mapply(formatTermLatex, .data$estimate, .data$term, .data$pValue,
                          .data$term == "(Intercept)")
      ),
      .data$group
    ),
    group_txt = paste(.data$term_txt, collapse = " "), .groups = "drop"
  )

  eqParts <- stats::setNames(df$group_txt, df$group)
  out <- paste0("$$\n\\begin{aligned}\n", depVar, " = & ")
  if ("1_intercept" %in% names(eqParts)) out <- paste0(out, eqParts["1_intercept"])
  for (g in c("2_actor", "3_inst", "4_interaction", "5_controls", "6_time", "7_fixed_effects")) {
    if (g %in% names(eqParts)) out <- paste0(out, " \\\\\n& ", eqParts[g])
  }
  paste0(out, "\n\\end{aligned}\n$$")
}
