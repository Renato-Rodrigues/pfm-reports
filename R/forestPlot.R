#' Render a coefficient forest plot for a fitted model
#'
#' @param coef_df Data frame from \code{pfm::coeftestToDataFrame()} — columns \code{term},
#'   \code{estimate}, \code{stdError}, \code{statistic}, \code{pValue}.
#' @param title Plot title.
#' @param subtitle Optional subtitle.
#' @return A ggplot object, or \code{NULL} if \code{coef_df} has no rows.
#' @importFrom dplyr filter mutate case_when
#' @importFrom ggplot2 ggplot aes geom_hline geom_point geom_errorbar geom_text coord_flip labs scale_color_manual guides guide_legend theme
#' @importFrom rlang .data
#' @importFrom stats reorder
#' @export
render_forest_plot <- function(coef_df, title, subtitle = NULL) {
  if (nrow(coef_df) == 0) return(NULL)
  if (!is.null(subtitle) && subtitle == "") subtitle <- NULL

  apVars   <- make.names(c("Actor Power Index", "Innovator Power", "Incumbent Power",
                           ext_actorPowerDrivers))
  iqVars   <- make.names(ext_instQualityDrivers)
  ctrlVars <- make.names(c("GDP per Capita Sq", ext_controlDrivers, "lagged_ecp",
                           "lagged_adoption"))

  pData <- dplyr::mutate(
    dplyr::filter(coef_df, .data$term != "(Intercept)"),
    lo  = .data$estimate - 1.96 * .data$stdError,
    hi  = .data$estimate + 1.96 * .data$stdError,
    sig = dplyr::case_when(
      .data$pValue < 0.001 ~ "***", .data$pValue < 0.01 ~ "**",
      .data$pValue < 0.05  ~ "*",   .data$pValue < 0.1  ~ ".", TRUE ~ ""
    ),
    Group = dplyr::case_when(
      grepl("_x_|_X_", .data$term)  ~ "Interaction",
      .data$term %in% apVars        ~ "Actor Power",
      .data$term %in% iqVars        ~ "Institutional Quality",
      .data$term %in% ctrlVars      ~ "Controls",
      grepl("^regionFE", .data$term) ~ "Region Fixed Effects",
      grepl("timeTrend|Year|year", .data$term) ~ "Time Trend",
      TRUE ~ "Institutional Quality & Controls"
    ),
    term_label = vapply(.data$term, clean_term_plain, character(1))
  )
  pData$Group <- factor(pData$Group, levels = c(
    "Actor Power", "Institutional Quality", "Interaction",
    "Controls", "Region Fixed Effects", "Time Trend"
  ))

  ggplot2::ggplot(pData, ggplot2::aes(x = stats::reorder(.data$term_label, .data$estimate),
                                      y = .data$estimate, color = .data$Group)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$lo, ymax = .data$hi),
                           width = 0.2, linewidth = 0.8) +
    ggplot2::geom_text(ggplot2::aes(label = .data$sig), nudge_y = 0.4, size = 4.5,
                       color = "black", show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title, subtitle = subtitle, x = NULL, y = "Estimate (95% CI)") +
    theme_report() +
    ggplot2::scale_color_manual(values = col_group) +
    ggplot2::guides(color = ggplot2::guide_legend(nrow = 2, title = NULL)) +
    ggplot2::theme(legend.position = "bottom")
}
