library(ggplot2)
library(dplyr)

#' Render a coefficient forest plot for a fitted model
#'
#' @param coef_df Data frame from coeftestToDataFrame() — columns: term,
#'   estimate, stdError, statistic, pValue.
#' @param title Plot title string.
#' @param subtitle Plot subtitle string.
#' @return A ggplot object, or NULL if coef_df has no rows.
render_forest_plot <- function(coef_df, title, subtitle) {
  if (nrow(coef_df) == 0) return(NULL)

  ap_vars   <- make.names(c("Actor Power Index", "Incumbent Power", ext_actorPowerDrivers))
  iq_vars   <- make.names(ext_instQualityDrivers)
  ctrl_vars <- make.names(c(ext_controlDrivers, "lagged_ecp", "lagged_adoption"))

  p_data <- coef_df %>%
    filter(term != "(Intercept)") %>%
    mutate(
      lo  = estimate - 1.96 * stdError,
      hi  = estimate + 1.96 * stdError,
      sig = case_when(
        pValue < 0.001 ~ "***", pValue < 0.01 ~ "**",
        pValue < 0.05  ~ "*",   pValue < 0.1  ~ ".", TRUE ~ ""
      ),
      Group = case_when(
        grepl("_x_|_X_", term)  ~ "Interaction",
        term %in% ap_vars        ~ "Actor Power",
        term %in% iq_vars        ~ "Institutional Quality",
        term %in% ctrl_vars      ~ "Controls",
        grepl("^regionFE", term) ~ "Region Fixed Effects",
        grepl("timeTrend|Year|year", term) ~ "Time Trend",
        TRUE ~ "Institutional Quality & Controls"
      ),
      clean_term = term %>%
        gsub("\\.", " ", .) %>%
        gsub("_x_|_X_", " x ", .)
    )

  p_data$Group <- factor(p_data$Group, levels = c(
    "Actor Power", "Institutional Quality", "Interaction",
    "Controls", "Region Fixed Effects", "Time Trend"
  ))

  ggplot(p_data, aes(x = reorder(clean_term, estimate), y = estimate, color = Group)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, linewidth = 0.8) +
    geom_text(aes(label = sig), nudge_y = 0.4, size = 4.5, color = "black", show.legend = FALSE) +
    coord_flip() +
    labs(title = title, subtitle = subtitle, x = NULL, y = "Estimate (95% CI)") +
    theme_report() +
    scale_color_manual(values = col_group) +
    guides(color = guide_legend(nrow = 2, title = NULL)) +
    theme(legend.position = "bottom")
}
