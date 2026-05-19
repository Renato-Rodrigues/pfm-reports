library(ggplot2)

theme_report <- function() {
  theme_minimal(base_size = 16, base_family = "serif") +
    theme(
      plot.title      = element_text(face = "bold", size = 14),
      plot.subtitle   = element_text(size = 14, colour = "grey40"),
      axis.title      = element_text(size = 18),
      axis.text       = element_text(size = 14),
      legend.text     = element_text(size = 14),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      strip.text      = element_text(face = "bold", size = 18)
    )
}

# Model variant colours
col_md  <- "#1A9641"
col_md2 <- "#FDAE61"
col_md3 <- "#8e44ad"
col_md4 <- "#f39c12"

# Sector colours
col_bulk    <- "#2C7BB6"
col_diffuse <- "#D7191C"

# Diagnostic traffic-light colours
col_good <- "#2ecc71"
col_warn <- "#f39c12"
col_bad  <- "#e74c3c"

# Coefficient group colours (used in forest plots)
col_group <- c(
  "Actor Power"                  = "#e74c3c",
  "Institutional Quality"        = "#2ecc71",
  "Institutional Quality (VDem)" = "#27ae60",
  "Interaction"                  = "#f1c40f",
  "Controls"                     = "#3498db",
  "Region Fixed Effects"         = "#9b59b6",
  "Time Trend"                   = "#34495e"
)

# Static driver lists (used in correlation analysis and group classification)
ext_actorPowerDrivers <- c(
  "VRE share", "Electrification",
  "Coal primary energy share", "Oil/Gas primary energy share",
  "Fossil share in Industry"
)

# WGI governance indicators
ext_instQualityDrivers <- c(
  "Government Effectiveness", "Control of Corruption",
  "Voice and Accountability", "Political Stability",
  "Regulatory Quality", "Rule of Law"
)

# V-Dem governance indicators (alternative IQ source)
ext_vdemDrivers <- c(
  "Rule of Law (VDem)", "Vertical Accountability (VDem)",
  "Horizontal Accountability (VDem)", "Diagonal Accountability (VDem)"
)

# Combined WGI + V-Dem (used in cross-source correlation and combined model variants)
ext_instQualityDrivers_all <- c(ext_instQualityDrivers, ext_vdemDrivers)

ext_controlDrivers <- c(
  "Population", "GDP per Capita", "Land Area",
  "Urban Population Share", "Gini Income Inequality Coefficient",
  "Gender Inequality Index", "Energy Intensity"
)
