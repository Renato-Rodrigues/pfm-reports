# PFM Reports — build launcher
#
# CLI usage:
#   Rscript createReports.R                           # interactive menu (defaults: c1, all except model-diagnostics)
#   Rscript createReports.R 1,3                       # reports 1 and 3, default cache (no prompts)
#   Rscript createReports.R all                       # all reports including model-diagnostics, default cache
#   Rscript createReports.R a                         # all except model-diagnostics, default cache
#   Rscript createReports.R 2,4 --madrat              # reports 2+4, also clear madrat caches
#   Rscript createReports.R --no-clear                # keep caches, run default selection (no prompts)
#   Rscript createReports.R 2 --country=IND           # country-adoption for India (name auto-resolved)
#   Rscript createReports.R 2 --country=IND,BRA,DEU   # multiple countries in parallel
#   Rscript createReports.R 2 --country=ZAF --countryName="South Africa"
#   Rscript createReports.R 5 --modelConfig=default                    # model-selection with named config
#   Rscript createReports.R 5 --modelConfig=default,vdem-focus         # two parallel model-selection runs
#   Rscript createReports.R 5 --modelConfig=model-configs/my-cfg.yml   # explicit relative path
#   Rscript createReports.R 1 --reportName=rule-of-law  # adoption-model with a custom name suffix
#   Rscript createReports.R --verbose                    # show all subprocess output (library loads, etc.)
#   Rscript createReports.R -v 1,3                       # verbose shorthand
#
# Interactive (RStudio):
#   source("createReports.R")                         # shows interactive menu with all prompts

library(rprojroot)   # only load needed to find root and discover report dirs

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

# ── Discover model-selection configs (sorted for stable numbering) ───────────
model_configs_dir       <- file.path(reports_dir, "model-selection", "model-configs")
available_model_configs <- if (dir.exists(model_configs_dir)) {
  sort(list.files(model_configs_dir, pattern = "\\.ya?ml$", full.names = FALSE))
} else {
  character(0)
}

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
cli_model_configs  <- NULL    # comma-separated config names/paths for model-selection
cli_adoption_name  <- NULL    # --reportName= suffix for adoption-model output file
cli_verbose        <- FALSE   # --verbose / -v: show all subprocess output

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
  } else if (startsWith(a, "--modelConfig=")) {
    cli_model_configs  <- trimws(strsplit(sub("^--modelConfig=", "", a), ",")[[1]])
  } else if (startsWith(a, "--reportName=")) {
    cli_adoption_name  <- trimws(sub("^--reportName=", "", a))
  } else if (a %in% c("--verbose", "-v")) {
    cli_verbose <- TRUE
  } else if (!startsWith(a, "--")) {
    cli_selection <- a
  }
}

# True only when the user typed Rscript createReports.R with no arguments at all
is_interactive_mode <- length(args) == 0L

# Reads one line from stdin; works in both Rscript (non-interactive) and RStudio
read_stdin <- function(prompt) {
  cat(prompt)
  if (interactive()) readline("") else trimws(readLines("stdin", n = 1L, warn = FALSE))
}

# ── Step 1: cache option ─────────────────────────────────────────────────────
cat("\n=== PFM Reports Builder ===\n\n")
cat("Cache options:\n")
cat("  [c0]  Keep existing data (no clearing)\n")
cat("  [c1]  Clear report data — panelData, downscale cache, modelData  (default)\n")
cat("  [c2]  Clear report data + mrpfm madrat caches  (re-downloads source data on next run)\n")

resolve_cache_mode <- function() {
  if (cli_cache_explicit) return(cli_clear)
  if (!is_interactive_mode) return("reports")
  ans <- read_stdin("Cache option [c0/c1/c2, default c1]: ")
  switch(ans, c0 = "none", c1 = "reports", c2 = "madrat", "reports")
}

cache_mode <- resolve_cache_mode()

# ── Step 2: report selection ──────────────────────────────────────────────────
cat("\nAvailable reports:\n")
cat(sprintf("  [a]   All except %-20s  (default)\n", DEFAULT_EXCLUDE))
cat("  [0]   All reports\n")
for (i in seq_along(report_dirs)) {
  tag <- if (report_dirs[i] == DEFAULT_EXCLUDE) "  <- excluded by default" else ""
  cat(sprintf("  [%d]   %s%s\n", i, report_dirs[i], tag))
}
cat("\nComma-separated indices select a subset, e.g. '1,3' runs reports 1 and 3.\n\n")

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

# Load yaml + pfm and their config/caching helpers only after the user has answered.
# Everything above uses only base R and rprojroot.
if (cli_verbose) {
  source(file.path(root, "src/r/configHelper.R"))
} else {
  suppressPackageStartupMessages(suppressMessages(
    source(file.path(root, "src/r/configHelper.R"))
  ))
}

# ── Helpers for report-specific parameter resolution ─────────────────────────

# Resolve a config name/stem/path to the relative path expected by run.R
normalize_model_config_path <- function(cfg) {
  if (grepl("[/\\\\]", cfg)) return(cfg)                              # already has path separator
  if (!grepl("\\.ya?ml$", cfg, ignore.case = TRUE)) cfg <- paste0(cfg, ".yml")
  paste0("model-configs/", cfg)
}

# Interactive/CLI resolution of which model config files to use
resolve_model_configs <- function() {
  if (!is.null(cli_model_configs)) return(cli_model_configs)

  if (length(available_model_configs) == 0L) {
    message("[model-selection] No .yml files in model-configs/ — using default.yml")
    return("model-configs/default.yml")
  }

  if (!is_interactive_mode) return(available_model_configs[1L])

  cat("\nModel Selection configs:\n")
  for (i in seq_along(available_model_configs)) {
    cat(sprintf("  [%d]  %s\n", i, available_model_configs[i]))
  }
  raw <- read_stdin(sprintf(
    "  Config(s) [1-%d or filename(s), comma-separated, default 1]: ",
    length(available_model_configs)
  ))
  if (!nzchar(trimws(raw))) return(available_model_configs[1L])

  parts <- trimws(unlist(strsplit(raw, "[,\\s]+")))
  idxs  <- suppressWarnings(as.integer(parts))
  if (all(!is.na(idxs))) {
    bad <- idxs < 1L | idxs > length(available_model_configs)
    if (any(bad)) stop(sprintf(
      "Invalid model config index(es): %s", paste(parts[bad], collapse = ", ")
    ))
    return(unique(available_model_configs[idxs]))
  }
  parts   # treat as filenames / stems
}

# ── Resolve countries for country-adoption report ────────────────────────────
report_extra_args <- list()

if ("country-adoption" %in% chosen) {
  COUNTRY_NAMES <- getRegionNames()
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

# ── Resolve model configs for model-selection report ─────────────────────────
if ("model-selection" %in% chosen) {
  sel_configs <- resolve_model_configs()
  sel_paths   <- vapply(sel_configs, normalize_model_config_path, character(1L))
  sel_stems   <- tools::file_path_sans_ext(basename(sel_paths))

  if (is_interactive_mode) {
    cat(sprintf("  Resolved  : %s\n", paste(sel_stems, collapse = ", ")))
  }

  report_extra_args[["model-selection"]] <- lapply(sel_paths, function(p) {
    paste0("--modelConfig=", p)
  })
}

# ── Resolve report name for adoption-model report ────────────────────────────
if ("adoption-model" %in% chosen) {
  if (!is.null(cli_adoption_name)) {
    adoption_name <- cli_adoption_name
  } else if (is_interactive_mode) {
    cat("\nAdoption Model report name:\n")
    raw <- read_stdin("  Name suffix for output file [default]: ")
    adoption_name <- if (nzchar(trimws(raw))) trimws(raw) else "default"
    cat(sprintf("  Resolved  : %s\n", adoption_name))
  } else {
    adoption_name <- "default"
  }
  report_extra_args[["adoption-model"]] <- list(paste0("--reportName=", adoption_name))
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
if ("model-selection" %in% chosen) {
  mc_stems <- tools::file_path_sans_ext(basename(
    sub("^--modelConfig=", "", unlist(report_extra_args[["model-selection"]]))
  ))
  cat(sprintf("Model configs: %s\n", paste(mc_stems, collapse = ", ")))
}
if ("adoption-model" %in% chosen) {
  an <- sub("^--reportName=", "", report_extra_args[["adoption-model"]][[1]])
  cat(sprintf("Adoption name: %s\n", an))
}
cat("\n")

# ── Expand to flat task list (one entry per report/variant combination) ───────
tasks <- list()
for (rep_name in chosen) {
  extra_list <- report_extra_args[[rep_name]]
  if (is.null(extra_list)) {
    tasks <- c(tasks, list(list(report = rep_name, label = rep_name, extra = NULL)))
  } else {
    for (extra in extra_list) {
      # Derive a short tag by stripping --key= from the first arg, then taking
      # the basename without extension (works for both --country=IND and
      # --modelConfig=model-configs/default.yml).
      raw_val <- sub("^--[^=]+=", "", extra[1])
      tag     <- tools::file_path_sans_ext(basename(raw_val))
      tasks   <- c(tasks, list(list(
        report = rep_name,
        label  = sprintf("%s[%s]", rep_name, tag),
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
  task     <- tasks[[1]]
  run_args <- c(file.path(reports_dir, task$report, "run.R"), task$extra)
  cat(sprintf("Building: %s\n\n", task$label))

  if (cli_verbose) {
    status <- system2(rscript_path, run_args, wait = TRUE)
  } else {
    # Stream stdout (render progress) to the terminal; capture stderr silently
    # and only surface it when the build fails.
    stderr_file <- tempfile(fileext = ".txt")
    status      <- system2(rscript_path, run_args, wait = TRUE, stderr = stderr_file)
    if (status != 0L) {
      err_lines <- tryCatch(readLines(stderr_file), error = function(e) character(0))
      if (length(err_lines) > 0L) {
        cat("\n--- Captured error output ---\n")
        cat(paste(err_lines, collapse = "\n"), "\n")
      }
    }
    unlink(stderr_file)
  }

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
    if (cli_verbose) {
      seed_status <- system2(rscript_path, seed_file, wait = TRUE)
    } else {
      seed_status <- system2(rscript_path, seed_file, wait = TRUE,
                             stdout = FALSE, stderr = FALSE)
    }
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
  clusterExport(cl, c("reports_dir", "rscript_path", "cli_verbose"), envir = environment())

  results <- parLapply(cl, tasks, function(task) {
    t0  <- Sys.time()
    out <- tryCatch(
      system2(rscript_path, c(file.path(reports_dir, task$report, "run.R"), task$extra),
              stdout = TRUE, stderr = TRUE),
      error = function(e) {
        msg <- e$message
        attr(msg, "status") <- -1L
        msg
      }
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
  if (cli_verbose) {
    cat("Task output:\n\n")
    for (r in results) {
      cat(sprintf("--- %s [%s] ---\n", r$report, if (r$ok) "OK" else "FAILED"))
      cat(paste(r$output, collapse = "\n"), "\n\n")
    }
  } else if (length(failures) > 0L) {
    cat("Failure details:\n\n")
    for (f in failures) {
      cat(sprintf("--- %s ---\n", f$report))
      cat(paste(tail(f$output, 25L), collapse = "\n"), "\n\n")
    }
  } else {
    cat("All tasks compiled successfully.\n")
  }
}
