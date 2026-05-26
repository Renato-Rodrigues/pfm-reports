# PFM Reports — parallel & interactive build launcher
#
# Usage: source("createReports.R")  (from within RStudio or an R session at repo root)
# Or:    Rscript createReports.R    (from a terminal at repo root)

library(rprojroot)
source(file.path(find_rstudio_root_file(), "src/r/configHelper.R"))

root         <- find_rstudio_root_file()

# Ensure all required folders exist
dir.create(file.path(root, "output"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(root, "data"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(root, "models"), showWarnings = FALSE, recursive = TRUE)

reports_dir  <- file.path(root, "reports")

# Discover available reports
report_dirs <- list.dirs(reports_dir, recursive = FALSE, full.names = FALSE)
report_dirs <- report_dirs[file.exists(file.path(reports_dir, report_dirs, "run.R"))]

if (length(report_dirs) == 0) {
  stop("No reports found under reports/. Each report needs a run.R file.")
}

cat("\n=== PFM Reports Builder ===\n\n")
cat("Available options:\n")
cat("  [0] Run ALL reports in parallel (Recommended)\n")
for (i in seq_along(report_dirs)) {
  cat(sprintf("  [%d] Run %s only\n", i, report_dirs[i]))
}
cat("\n")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  selection <- args[1]
  if (selection == "all" || selection == "--parallel") {
    selection <- "0"
  }
} else {
  selection <- readline(prompt = sprintf("Select option [0-%d]: ", length(report_dirs)))
}
idx       <- suppressWarnings(as.integer(trimws(selection)))

if (is.na(idx) || idx < 0 || idx > length(report_dirs)) {
  stop("Invalid selection.")
}

rscript_path <- file.path(R.home("bin"), "Rscript")
if (.Platform$OS.type == "windows") {
  rscript_path <- file.path(R.home("bin"), "Rscript.exe")
}

if (idx == 0) {
  # --- Parallel Mode ---
  cat("\n=== Starting Parallel Build ===\n\n")
  
  # Ensure the data cache exists first to avoid race conditions
  model_data_path <- file.path(root, "data/modelData.RData")
  if (!file.exists(model_data_path)) {
    cat("[INFO] Shared data cache 'data/modelData.RData' is missing.\n")
    cat("Running 'model-diagnostics' first to populate the cache...\n")
    
    diag_run <- file.path(reports_dir, "model-diagnostics", "run.R")
    
    # We run it synchronously and print to console
    cat("--------------------------------------------------\n")
    status <- system2(rscript_path, diag_run, wait = TRUE)
    cat("--------------------------------------------------\n")
    
    if (status != 0) {
      stop("Failed to build 'model-diagnostics' sequentially. Parallel build aborted.")
    }
    cat("[INFO] Data cache populated successfully.\n\n")
  }
  
  cat("Spawning parallel R workers for reports...\n")
  
  library(parallel)
  
  # Set up socket cluster
  num_cores <- min(length(report_dirs), detectCores() - 1)
  cl <- makeCluster(num_cores)
  
  clusterExport(cl, c("reports_dir", "rscript_path"), envir = environment())
  
  results <- parLapply(cl, report_dirs, function(chosen) {
    report_run <- file.path(reports_dir, chosen, "run.R")
    
    # Run the script using Rscript inside the worker
    t0 <- Sys.time()
    out <- tryCatch({
      res <- system2(rscript_path, report_run, stdout = TRUE, stderr = TRUE)
      status <- attr(res, "status")
      if (is.null(status)) status <- 0
      list(status = status, output = res, error = NULL)
    }, error = function(e) {
      list(status = -1, output = NULL, error = e$message)
    })
    t1 <- Sys.time()
    
    list(
      report   = chosen,
      status   = if (out$status == 0) "Success" else "Failed",
      duration = round(difftime(t1, t0, units = "secs"), 1),
      output   = out$output,
      error    = out$error
    )
  })
  
  stopCluster(cl)
  
  # Print Summary Table
  cat("\n=================== BUILD SUMMARY ===================\n")
  for (res in results) {
    status_str <- sprintf("%-8s", res$status)
    duration_str <- sprintf("%s seconds", res$duration)
    cat(sprintf("  %-20s : %s (Took %s)\n", res$report, status_str, duration_str))
  }
  cat("=====================================================\n\n")
  
  # Print logs for any failures
  failures <- Filter(function(r) r$status == "Failed", results)
  if (length(failures) > 0) {
    cat("Detailed logs for failures:\n\n")
    for (f in failures) {
      cat(sprintf("--- %s Failure Log ---\n", f$report))
      if (!is.null(f$error)) {
        cat("Error:", f$error, "\n")
      }
      if (!is.null(f$output)) {
        cat(paste(f$output, collapse = "\n"), "\n")
      }
      cat("----------------------------------\n\n")
    }
  } else {
    cat("All reports successfully compiled!\n")
  }
  
} else {
  # --- Single Report Mode (Interactive) ---
  chosen <- report_dirs[idx]
  cat(sprintf("\nBuilding: %s\n\n", chosen))
  
  prompt_path <- function(label, default = "") {
    msg <- if (nchar(default) > 0) sprintf("%s [%s]: ", label, default) else sprintf("%s: ", label)
    val <- trimws(readline(prompt = msg))
    if (nchar(val) == 0) default else val
  }
  
  cat("--- Parameters ---\n")
  cat("(Press Enter to accept the default shown in brackets)\n\n")
  
  model_data_file <- prompt_path("modelDataFile", "data/modelData.RData")
  model_dir       <- prompt_path("modelDir (PFM model store)", getPfmConfig("modelDir", "../../models"))
  cache_dir       <- prompt_path("cacheDir (madrat cache)", getPfmConfig("cacheDir", ""))
  gdx_path        <- prompt_path("gdxPath (fulldata.gdx)", getPfmConfig("gdxPath", "../../fulldata.gdx"))
  
  # Dynamically determine the outputFile based on whether the report run.R uses "../../output" or "output"
  default_out <- if (chosen == "adoption-model") {
    "../../output/adoption_model.html"
  } else if (chosen == "model-selection") {
    "../../output/model_selection.html"
  } else if (chosen == "model-diagnostics") {
    "../../output/IAM_PFM_report.html"
  } else {
    "../../output/panel_data_input.html"
  }
  
  output_file     <- prompt_path("outputFile", default_out)
  asset_dir       <- prompt_path("assetDir", gsub(".html$", "", output_file))
  
  cat("\n--- Starting render ---\n\n")
  
  report_run <- file.path(reports_dir, chosen, "run.R")
  
  local({
    source(report_run, local = TRUE)
    
    # Dynamically filter arguments to match the render_report signature
    all_params <- list(
      modelDataFile = model_data_file,
      modelDir      = model_dir,
      cacheDir      = cache_dir,
      gdxPath       = gdx_path,
      outputFile    = output_file,
      assetDir      = asset_dir
    )
    
    valid_names <- formalArgs(render_report)
    params_to_pass <- all_params[names(all_params) %in% valid_names]
    
    do.call(render_report, params_to_pass)
  })
}
