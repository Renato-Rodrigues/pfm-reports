# PFM Reports — interactive build launcher
#
# Usage: source("run.R")  (from within RStudio or an R session at repo root)
# Or:    Rscript run.R    (from a terminal at repo root)
#
# The script discovers all reports under reports/, asks which one to build,
# prompts for its required parameters, then delegates to that report's run.R.

library(rprojroot)

root         <- find_rstudio_root_file()
reports_dir  <- file.path(root, "reports")

# --- Discover available reports ---
report_dirs <- list.dirs(reports_dir, recursive = FALSE, full.names = FALSE)
report_dirs <- report_dirs[file.exists(file.path(reports_dir, report_dirs, "run.R"))]

if (length(report_dirs) == 0) {
  stop("No reports found under reports/. Each report needs a run.R file.")
}

cat("\n=== PFM Reports Builder ===\n\n")
cat("Available reports:\n")
for (i in seq_along(report_dirs)) {
  cat(sprintf("  [%d] %s\n", i, report_dirs[i]))
}
cat("\n")

# --- Select report ---
selection <- readline(prompt = sprintf("Select report [1-%d]: ", length(report_dirs)))
idx       <- suppressWarnings(as.integer(trimws(selection)))

if (is.na(idx) || idx < 1 || idx > length(report_dirs)) {
  stop("Invalid selection.")
}

chosen <- report_dirs[idx]
cat(sprintf("\nBuilding: %s\n\n", chosen))

# --- Collect parameters ---
# Each report declares its params; we prompt for the common ones here.
# Report-specific run.R scripts can extend or override these.

prompt_path <- function(label, default = "") {
  msg <- if (nchar(default) > 0) sprintf("%s [%s]: ", label, default) else sprintf("%s: ", label)
  val <- trimws(readline(prompt = msg))
  if (nchar(val) == 0) default else val
}

cat("--- Parameters ---\n")
cat("(Press Enter to accept the default shown in brackets)\n\n")

model_data_file <- prompt_path("modelDataFile", "data/modelData.RData")
cache_dir       <- prompt_path("cacheDir (madrat cache, leave blank to skip)", "")
gdx_path        <- prompt_path("gdxPath (fulldata.gdx, leave blank to skip projections)", "")
output_file     <- prompt_path("outputFile", sprintf("output/%s_report.html", gsub("-", "_", chosen)))
asset_dir       <- prompt_path("assetDir",   sprintf("output/%s_report",       gsub("-", "_", chosen)))

cat("\n--- Starting render ---\n\n")

# --- Source the report's run.R with the collected params ---
# The report run.R exposes render_report(); we call it with our params.
report_run <- file.path(reports_dir, chosen, "run.R")

local({
  source(report_run, local = TRUE)
  render_report(
    modelDataFile = model_data_file,
    cacheDir      = cache_dir,
    gdxPath       = gdx_path,
    outputFile    = output_file,
    assetDir      = asset_dir
  )
})
