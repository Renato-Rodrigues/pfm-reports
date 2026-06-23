# Shared ggplot theme + palette/driver constants for the reports. The constants keep their
# legacy names (and dotted/underscore styling) because the report templates reference them
# directly via library(pfmreports); renaming would break every report.

#' Shared ggplot theme for PFM reports
#'
#' @return A ggplot2 theme object.
#' @importFrom ggplot2 theme_minimal theme element_text element_blank
#' @export
theme_report <- function() {
  ggplot2::theme_minimal(base_size = 16, base_family = "serif") +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle    = ggplot2::element_text(size = 14, colour = "grey40"),
      axis.title       = ggplot2::element_text(size = 18),
      axis.text        = ggplot2::element_text(size = 14),
      legend.text      = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "bottom",
      strip.text       = ggplot2::element_text(face = "bold", size = 18)
    )
}

#' @rdname pfmreports-palette
#' @title PFM report palette and driver-name constants
#' @description Exported colour and driver-name vectors used across the report templates.
#' @format Character scalars / vectors.
#' @export
col_md  <- "#1A9641"
#' @rdname pfmreports-palette
#' @export
col_md2 <- "#FDAE61"
#' @rdname pfmreports-palette
#' @export
col_md3 <- "#8e44ad"
#' @rdname pfmreports-palette
#' @export
col_md4 <- "#f39c12"
#' @rdname pfmreports-palette
#' @export
col_bulk <- "#2C7BB6"
#' @rdname pfmreports-palette
#' @export
col_diffuse <- "#D7191C"
#' @rdname pfmreports-palette
#' @export
col_good <- "#2ecc71"
#' @rdname pfmreports-palette
#' @export
col_warn <- "#f39c12"
#' @rdname pfmreports-palette
#' @export
col_bad <- "#e74c3c"

#' @rdname pfmreports-palette
#' @export
col_group <- c(
  "Actor Power"   = "#e74c3c", "Inst. Quality" = "#2ecc71", "Interaction" = "#f1c40f",
  "Controls"      = "#3498db", "Path Dep."     = "#e67e22", "Region FE"   = "#9b59b6",
  "Time Trend"    = "#34495e", "Intercept"     = "#95a5a6", "Other"       = "#bdc3c7",
  "Institutional Quality"        = "#2ecc71",
  "Institutional Quality (VDem)" = "#27ae60",
  "Region Fixed Effects"         = "#9b59b6"
)

#' @rdname pfmreports-palette
#' @export
ext_actorPowerDrivers <- c(
  "VRE share", "Electrification", "Coal primary energy share",
  "Oil/Gas primary energy share", "Fossil share in Industry"
)
#' @rdname pfmreports-palette
#' @export
ext_instQualityDrivers <- c(
  "Government Effectiveness (WGI)", "Control of Corruption (WGI)",
  "Voice and Accountability (WGI)", "Political Stability (WGI)",
  "Regulatory Quality (WGI)", "Rule of Law (WGI)"
)
#' @rdname pfmreports-palette
#' @export
ext_vdemDrivers <- c(
  "Rule of Law (VDem)", "Vertical Accountability (VDem)",
  "Horizontal Accountability (VDem)", "Diagonal Accountability (VDem)"
)
#' @rdname pfmreports-palette
#' @export
ext_instQualityDrivers_all <- c(ext_instQualityDrivers, ext_vdemDrivers)
#' @rdname pfmreports-palette
#' @export
ext_controlDrivers <- c(
  "Population", "GDP per Capita", "Land Area", "Urban Population Share",
  "Gini Income Inequality Coefficient", "Gender Inequality Index",
  "Energy Intensity", "Hydro Nuclear Share"
)
