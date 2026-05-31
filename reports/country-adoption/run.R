# Render the PFM Country Adoption Analysis report.
#
# Usage (from repo root or this folder):
#   source("reports/country-adoption/run.R")
#
# Or with custom params:
#   source("reports/country-adoption/run.R")
#   render_report(country = "IND", countryName = "India")
#
# CLI usage (via createReports.R or directly with Rscript):
#   Rscript run.R --country=IND
#   Rscript run.R --country=ZAF --countryName="South Africa"
#
# Parameters
# ----------
# country           : ISO3 country code. Default: "BRA" (Brazil).
# countryName       : Display name for the country.
# cacheDir          : madrat cache folder.
# gdxPath           : path to fulldata.gdx for scenario projections. Leave "" to skip.
# outputFile        : path for the rendered HTML.
# assetDir          : folder for saved plots.
# modelName         : display name for the model specification.
# instQualityDrivers: character vector of IQ driver names.
# controlDrivers    : character vector of control variable names.
# regionMappingFE   : filename of the region mapping CSV for fixed effects (or "").
# includeLagged     : logical; include lagged adoption as a predictor.
# adoptionThreshold : numeric [0, 1]; probability threshold for adoption classification.
# waterfallYears    : integer vector of years for which waterfall charts are rendered.

library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

COUNTRY_NAMES <- getRegionNames()

render_report <- function(
    country            = "BRA",
    countryName        = "Brazil",
    cacheDir           = getPfmConfig("cacheDir", ""),
    gdxPath            = getPfmConfig("gdxPath", "data/fulldata.gdx"),
    outputFile         = NULL,
    assetDir           = "output/country_adoption",
    modelName          = getPfmConfig("modelName", "Baseline + Rule of Law"),
    instQualityDrivers = c("Government Effectiveness (WGI)", "Rule of Law (VDem)"),
    controlDrivers     = c("GDP per Capita", "Hydro Nuclear Share"),
    regionMappingFE    = getPfmConfig("regionMappingFE", "regionmappingH12.csv"),
    includeLagged      = getPfmConfig("includeLagged", FALSE),
    adoptionThreshold  = getPfmConfig("adoptionThreshold", 0.5),
    waterfallYears     = c(2000L, 2005L, 2010L, 2015L, 2019L, 2022L)) {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/country-adoption/country-adoption.Rmd")

  if (nchar(gdxPath) > 0 && !is_absolute_path(gdxPath)) {
    gdxPath <- file.path(root, gdxPath)
  }
  if (nchar(cacheDir) > 0 && !is_absolute_path(cacheDir)) {
    cacheDir <- file.path(root, cacheDir)
  }

  if (is.null(outputFile)) {
    outputFile <- file.path("output", paste0("country_adoption_", country, ".html"))
  }

  params <- list(
    country            = country,
    countryName        = countryName,
    cacheDir           = cacheDir,
    gdxPath            = gdxPath,
    assetDir           = file.path(root, assetDir),
    modelName          = modelName,
    instQualityDrivers = instQualityDrivers,
    controlDrivers     = controlDrivers,
    regionMappingFE    = regionMappingFE,
    includeLagged      = includeLagged,
    adoptionThreshold  = adoptionThreshold,
    waterfallYears     = waterfallYears
  )

  output_path <- file.path(root, outputFile)
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input       = rmd_path,
    output_file = output_path,
    params      = params,
    envir       = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

# Run immediately when sourced — honour CLI args when called via Rscript
.cli_args         <- commandArgs(trailingOnly = TRUE)
.cli_country      <- NULL
.cli_country_name <- NULL
for (.a in .cli_args) {
  if (startsWith(.a, "--country="))     .cli_country      <- sub("^--country=",     "", .a)
  if (startsWith(.a, "--countryName=")) .cli_country_name <- sub("^--countryName=", "", .a)
}

if (!is.null(.cli_country)) {
  .cli_country <- toupper(trimws(.cli_country))
  if (is.null(.cli_country_name)) {
    .cli_country_name <- if (.cli_country %in% names(COUNTRY_NAMES)) {
      COUNTRY_NAMES[[.cli_country]]
    } else {
      .cli_country
    }
  }
  render_report(country = .cli_country, countryName = .cli_country_name)
} else {
  render_report()
}
