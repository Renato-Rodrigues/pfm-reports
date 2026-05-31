# PFM Reports — build launcher
#
# CLI usage:
#   Rscript createReports.R                        # interactive menu (defaults: c1, all except model-diagnostics)
#   Rscript createReports.R 1,3                    # reports 1 and 3, default cache (no prompts)
#   Rscript createReports.R all                    # all reports including model-diagnostics, default cache
#   Rscript createReports.R a                      # all except model-diagnostics, default cache
#   Rscript createReports.R 2,4 --madrat           # reports 2+4, also clear madrat caches
#   Rscript createReports.R --no-clear             # keep caches, run default selection (no prompts)
#   Rscript createReports.R 2 --country=IND        # country-adoption for India (name auto-resolved)
#   Rscript createReports.R 2 --country=IND,BRA,DEU  # multiple countries in parallel
#   Rscript createReports.R 2 --country=ZAF --countryName="South Africa"
#
# Interactive (RStudio):
#   source("createReports.R")                      # shows interactive menu with country prompt

library(rprojroot)
source(file.path(find_rstudio_root_file(), "src/r/configHelper.R"))

root        <- find_rstudio_root_file()
reports_dir <- file.path(root, "reports")
utils_dir   <- normalizePath(file.path(root, "..", "utils"))

dir.create(file.path(root, "output"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(root, "data"),   showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(root, "models"), showWarnings = FALSE, recursive = TRUE)

rscript_path <- file.path(R.home("bin"),
                           if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")

# ── Discover reports (sorted for stable numbering) ──────────────────────────
report_dirs <- sort(list.dirs(reports_dir, recursive = FALSE, full.names = FALSE))
report_dirs <- report_dirs[file.exists(file.path(reports_dir, report_dirs, "run.R"))]
if (length(report_dirs) == 0L) {
  stop("No reports found under reports/. Each report needs a run.R file.")
}

DEFAULT_EXCLUDE <- "model-diagnostics"

# Reports that write to the shared panelDataHistorical.rds cache
CACHE_USERS <- setdiff(report_dirs, "downscale")

REPORTS_CACHES <- c(
  "data/panelDataHistorical.rds",
  "data/panelDataScenario.rds",
  "data/downscale_country.rds",
  "data/modelData.RData"
)

# ── Parse CLI arguments ──────────────────────────────────────────────────────
args               <- commandArgs(trailingOnly = TRUE)
cli_selection      <- NULL
cli_clear          <- NULL    # NULL = not explicitly set; resolved later
cli_cache_explicit <- FALSE
cli_country        <- NULL
cli_country_name   <- NULL

for (a in args) {
  if (a %in% c("--madrat", "--all-caches")) {
    cli_clear          <- "madrat"
    cli_cache_explicit <- TRUE
  } else if (a %in% c("--no-clear", "--keep")) {
    cli_clear          <- "none"
    cli_cache_explicit <- TRUE
  } else if (startsWith(a, "--country=")) {
    cli_country        <- toupper(trimws(sub("^--country=", "", a)))
  } else if (startsWith(a, "--countryName=")) {
    cli_country_name   <- trimws(sub("^--countryName=", "", a))
  } else if (!startsWith(a, "--")) {
    cli_selection <- a
  }
}

COUNTRY_NAMES <- getRegionNames()

# True only when the user typed Rscript createReports.R with no arguments at all
is_interactive_mode <- length(args) == 0L

# Reads one line from stdin; works in both Rscript (non-interactive) and RStudio
read_stdin <- function(prompt) {
  cat(prompt)
  if (interactive()) readline("") else trimws(readLines("stdin", n = 1L, warn = FALSE))
}

# ── Print menu ───────────────────────────────────────────────────────────────
cat("\n=== PFM Reports Builder ===\n\n")

cat("Cache options:\n")
cat("  [c0]  Keep existing data (no clearing)\n")
cat("  [c1]  Clear report data — panelData, downscale cache, modelData  (default)\n")
cat("  [c2]  Clear report data + mrpfm madrat caches  (re-downloads source data on next run)\n\n")

cat("Available reports:\n")
cat(sprintf("  [a]   All except %-20s  (default)\n", DEFAULT_EXCLUDE))
cat("  [0]   All reports\n")
for (i in seq_along(report_dirs)) {
  tag <- if (report_dirs[i] == DEFAULT_EXCLUDE) "  <- excluded by default" else ""
  cat(sprintf("  [%d]   %s%s\n", i, report_dirs[i], tag))
}
cat("\nComma-separated indices select a subset, e.g. '1,3' runs reports 1 and 3.\n\n")

# ── Resolve cache mode ───────────────────────────────────────────────────────
resolve_cache_mode <- function() {
  if (cli_cache_explicit) return(cli_clear)
  if (!is_interactive_mode) return("reports")   # default when args provided
  ans <- read_stdin("Cache option [c0/c1/c2, default c1]: ")
  switch(ans, c0 = "none", c1 = "reports", c2 = "madrat", "reports")
}

cache_mode <- resolve_cache_mode()

# ── Resolve report selection ─────────────────────────────────────────────────
resolve_reports <- function() {
  raw <- cli_selection
  if (is.null(raw)) {
    if (!is_interactive_mode) {
      raw <- "a"
    } else {
      raw <- read_stdin(sprintf(
        "Reports [comma-separated 1-%d, 'a'=all-except-diagnostics, '0'=all, default a]: ",
        length(report_dirs)
      ))
      if (!nzchar(raw)) raw <- "a"
    }
  }
  raw <- trimws(tolower(raw))

  if (raw %in% c("a", "")) return(setdiff(report_dirs, DEFAULT_EXCLUDE))
  if (raw == "0" || raw == "all") return(report_dirs)

  parts <- trimws(unlist(strsplit(raw, "[,\\s]+")))
  idxs  <- suppressWarnings(as.integer(parts))
  bad   <- is.na(idxs) | idxs < 1L | idxs > length(report_dirs)
  if (any(bad)) {
    stop(sprintf(
      "Invalid selection '%s'. Use comma-separated numbers 1-%d, 'a', or '0'.",
      raw, length(report_dirs)
    ))
  }
  unique(report_dirs[idxs])
}

chosen <- resolve_reports()

# ── Resolve countries for country-adoption report ────────────────────────────
report_extra_args <- list()

if ("country-adoption" %in% chosen) {
  # Collect raw ISO codes from CLI or interactive prompt
  if (!is.null(cli_country)) {
    raw_isos <- toupper(trimws(strsplit(cli_country, ",")[[1]]))
  } else if (is_interactive_mode) {
    cat("\nCountry Adoption report:\n")
    raw_input <- read_stdin("  ISO3 code(s), comma-separated [default BRA]: ")
    raw_isos  <- if (nzchar(trimws(raw_input))) {
      toupper(trimws(strsplit(raw_input, ",")[[1]]))
    } else {
      "BRA"
    }
  } else {
    raw_isos <- "BRA"
  }

  # Resolve display name for each code
  country_pairs <- lapply(raw_isos, function(iso) {
    looked_up <- if (iso %in% names(COUNTRY_NAMES)) COUNTRY_NAMES[[iso]] else NULL
    name <- if (!is.null(looked_up)) {
      looked_up
    } else if (!is.null(cli_country_name) && length(raw_isos) == 1L) {
      cli_country_name   # --countryName only used for single-country CLI
    } else if (is_interactive_mode) {
      raw_name <- read_stdin(sprintf("  Display name for '%s' [default %s]: ", iso, iso))
      if (nzchar(trimws(raw_name))) trimws(raw_name) else iso
    } else {
      iso
    }
    list(country = iso, countryName = name)
  })

  if (is_interactive_mode) {
    cat(sprintf("  Resolved  : %s\n",
      paste(sapply(country_pairs, function(p) sprintf("%s (%s)", p$countryName, p$country)),
            collapse = ", ")))
  }

  # Store as a list of arg vectors — one per country
  report_extra_args[["country-adoption"]] <- lapply(country_pairs, function(p) {
    c(paste0("--country=", p$country), paste0("--countryName=", p$countryName))
  })
}

cat(sprintf("Cache mode  : %s\n", switch(cache_mode,
  none    = "keep existing data",
  reports = "clear report data only",
  madrat  = "clear report data + madrat caches"
)))
cat(sprintf("Reports     : %s\n", paste(chosen, collapse = ", ")))
if ("country-adoption" %in% chosen) {
  cat(sprintf("Countries   : %s\n",
    paste(sapply(country_pairs, function(p) sprintf("%s (%s)", p$countryName, p$country)),
          collapse = ", ")))
}
cat("\n")

# ── Expand to flat task list (one entry per report/country combination) ───────
tasks <- list()
for (rep_name in chosen) {
  extra_list <- report_extra_args[[rep_name]]
  if (is.null(extra_list)) {
    tasks <- c(tasks, list(list(report = rep_name, label = rep_name, extra = NULL)))
  } else {
    for (extra in extra_list) {
      iso   <- sub("^--country=", "", extra[1])
      tasks <- c(tasks, list(list(
        report = rep_name,
        label  = sprintf("%s[%s]", rep_name, iso),
        extra  = extra
      )))
    }
  }
}

# ── Clear caches ─────────────────────────────────────────────────────────────
if (cache_mode != "none") {
  cat("--- Clearing report data caches ---\n")
  for (rel in REPORTS_CACHES) {
    p <- file.path(root, rel)
    if (file.exists(p)) {
      file.remove(p)
      cat(sprintf("  Deleted: %s\n", basename(p)))
    }
  }

  if (cache_mode == "madrat") {
    cat("\n--- Clearing mrpfm madrat caches ---\n")
    clear_script <- file.path(utils_dir, "clearCache.R")
    if (file.exists(clear_script)) {
      system2(rscript_path, c(clear_script, "--madrat", "--force"), wait = TRUE)
    } else {
      cat(sprintf("[WARNING] clearCache.R not found at: %s\n", clear_script))
    }
  }
  cat("\n")
}

# ── Install packages from source (ensures latest algorithm changes are live) ──
#if (cache_mode != "none") {
#  cat("--- Installing mrpfm and pfm from source ---\n")
#  pkg_root <- normalizePath(file.path(root, ".."))
#  install_lines <- character(0)
#  for (pkg in c("mrpfm", "pfm")) {
#    pkg_dir <- file.path(pkg_root, pkg)
#    if (dir.exists(pkg_dir)) {
#      install_lines <- c(install_lines,
#        sprintf("cat('  Installing %s...\\n')", pkg),
#        sprintf("devtools::install('%s', quiet=TRUE, upgrade='never')",
#                gsub("\\\\", "/", pkg_dir)),
#        sprintf("cat('  %s OK\\n')", pkg)
#      )
#    } else {
#      cat(sprintf("  [WARNING] %s source not found: %s\n", pkg, pkg_dir))
#    }
#  }
#  if (length(install_lines) > 0L) {
#    inst_file <- tempfile(fileext = ".R")
#    writeLines(install_lines, inst_file)
#    system2(rscript_path, inst_file, wait = TRUE)
#    unlink(inst_file)
#  }
#  cat("\n")
#}

# ── Build ─────────────────────────────────────────────────────────────────────
if (length(tasks) == 1L) {

  # ── Single task ────────────────────────────────────────────────────────────
  task <- tasks[[1]]
  cat(sprintf("Building: %s\n\n", task$label))
  status <- system2(rscript_path, c(file.path(reports_dir, task$report, "run.R"), task$extra), wait = TRUE)
  if (status == 0L) cat("\nDone.\n") else stop(sprintf("'%s' failed.", task$label))

} else {

  # ── Multiple tasks: seed shared caches first, then run in parallel ─────────
  cat("=== Parallel build ===\n\n")

  # Seed panelDataHistorical and panelDataScenario before launching workers to
  # prevent multiple processes from trying to write the same .rds simultaneously.
  need_seed <- cache_mode != "none" && any(chosen %in% CACHE_USERS)

  if (need_seed) {
    cat("[Seed] Building shared panel data caches...\n")

    gdx_path   <- getPfmConfig("gdxPath", "")
    cache_dir  <- getPfmConfig("cacheDir", "")
    mapping_dir <- if (nzchar(cache_dir)) gsub("cache/default$", "mappings", cache_dir) else ""

    seed_lines <- c(
      sprintf("setwd('%s')", gsub("\\\\", "/", root)),
      if (nzchar(cache_dir) && dir.exists(cache_dir)) {
        sprintf(
          "madrat::setConfig(forcecache=TRUE, cachefolder='%s', mappingfolder='%s')",
          gsub("\\\\", "/", cache_dir),
          gsub("\\\\", "/", mapping_dir)
        )
      } else {
        "madrat::setConfig(forcecache=TRUE)"
      },
      "source('src/r/configHelper.R')",
      "getPanelDataHistoricalCached(aggregate=TRUE, y=2000:2022, outputRegionMappingFile='regionmapping_54.csv')",
      if (nzchar(gdx_path) && file.exists(gdx_path)) {
        sprintf("getPanelDataScenarioCached(gdxFile='%s')",
                gsub("\\\\", "/", gdx_path))
      },
      "cat('[Seed] Panel data caches ready.\\n')"
    )
    seed_lines <- seed_lines[!sapply(seed_lines, is.null)]

    seed_file <- tempfile(fileext = ".R")
    writeLines(seed_lines, seed_file)
    seed_status <- system2(rscript_path, seed_file, wait = TRUE)
    unlink(seed_file)

    if (seed_status != 0L) {
      warning("[Seed] Data seeding failed — parallel reports may hit cache race conditions.")
    }
    cat("\n")
  }

  cat(sprintf("Launching %d tasks in parallel...\n\n", length(tasks)))
  library(parallel)
  n_cores <- min(length(tasks), max(1L, detectCores() - 1L))
  cl      <- makeCluster(n_cores)
  clusterExport(cl, c("reports_dir", "rscript_path"), envir = environment())

  results <- parLapply(cl, tasks, function(task) {
    t0  <- Sys.time()
    out <- tryCatch(
      system2(rscript_path, c(file.path(reports_dir, task$report, "run.R"), task$extra),
              stdout = TRUE, stderr = TRUE),
      error = function(e) structure(e$message, status = -1L)
    )
    status <- attr(out, "status")
    if (is.null(status)) status <- 0L
    list(
      report   = task$label,
      ok       = status == 0L,
      duration = round(difftime(Sys.time(), t0, units = "secs"), 1),
      output   = out
    )
  })
  stopCluster(cl)

  cat("\n=================== BUILD SUMMARY ===================\n")
  for (r in results) {
    cat(sprintf("  %-30s  %s  (%s s)\n",
                r$report,
                if (r$ok) "OK    " else "FAILED",
                r$duration))
  }
  cat("=====================================================\n\n")

  failures <- Filter(function(r) !r$ok, results)
  if (length(failures) > 0L) {
    cat("Failure details:\n\n")
    for (f in failures) {
      cat(sprintf("--- %s ---\n", f$report))
      cat(paste(tail(f$output, 25L), collapse = "\n"), "\n\n")
    }
  } else {
    cat("All tasks compiled successfully.\n")
  }
}
