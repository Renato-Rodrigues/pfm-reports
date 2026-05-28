library(rmarkdown)
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

render_report <- function(
    cacheDir   = getPfmConfig("cacheDir", ""),
    gdxPath    = getPfmConfig("gdxPath", "data/fulldata.gdx"),
    outputFile = "output/downscale.html") {

  root     <- find_rstudio_root_file()
  rmd_path <- file.path(root, "reports/downscale/downscale.Rmd")

  if (nchar(gdxPath) > 0 && !is_absolute_path(gdxPath))
    gdxPath <- file.path(root, gdxPath)
  if (nchar(cacheDir) > 0 && !is_absolute_path(cacheDir))
    cacheDir <- file.path(root, cacheDir)

  output_path <- file.path(root, outputFile)
  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)

  rmarkdown::render(
    input       = rmd_path,
    output_file = output_path,
    params      = list(cacheDir = cacheDir, gdxPath = gdxPath),
    envir       = new.env(parent = globalenv())
  )

  message("Report written to: ", output_path)
  invisible(output_path)
}

render_report()
