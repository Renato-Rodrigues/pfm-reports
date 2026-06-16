#!/usr/bin/env Rscript
# exportForDashboard.R — Export PFMModel objects to flat files for the Python dashboard.
#
# Usage (terminal):
#   Rscript src/r/exportForDashboard.R <models_dir> <exports_dir>
#   Rscript src/r/exportForDashboard.R                   # defaults: "models/" -> "dashboard/data/"
#   Rscript src/r/exportForDashboard.R models/ dashboard/data/ --overwrite
#
# Usage (R session):
#   source("src/r/exportForDashboard.R")
#   exportForDashboard("models/", "dashboard/data/")
#   exportForDashboard("models/", "dashboard/data/", overwrite = TRUE)
#
# Output per model:  <exports_dir>/<id>/
#   manifest.json                  scalar metadata + diagnostics
#   vif.json                       VIF values per predictor
#   coefficients.parquet           coeftest rows: term, estimate, std_error, z_value, p_value
#   training_data.parquet          the data.frame passed to glm/logistf
#   fitted_values.parquet          region, year, fitted_value, actual
#   correlation_pearson.parquet    wide-format Pearson matrix (variable column + one column per predictor)
#   correlation_spearman.parquet   wide-format Spearman matrix
#   projections/<name>.parquet     one file per projection data.frame (when projections are attached)
#   projections/metadata.json      non-data-frame projection fields (gdx_path, hash, etc.)
#
# <exports_dir>/index.json   registry of all models with export status

library(pfm)

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop(
    "Package 'arrow' is required for Parquet export.\n",
    "Install it with:  install.packages('arrow')",
    call. = FALSE
  )
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Install with: install.packages('jsonlite')", call. = FALSE)
}

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

#' Export all PFMModels from a models directory to flat files
#'
#' Reads \code{models_dir/index.json}, loads each \code{.rds}, and writes a
#' self-contained export folder per model under \code{exports_dir/<id>/}.
#' Models whose manifest already exists are silently skipped unless
#' \code{overwrite = TRUE}.
#'
#' @param modelsDir  Character. Path to the pfm model store (contains
#'   \code{index.json} + \code{<id>.rds} files).
#'   Defaults to \code{getOption("pfm.modelDir", "models")}.
#' @param exportsDir Character. Destination root for flat-file exports.
#'   Default: \code{"dashboard/data"}.
#' @param overwrite  Logical. Re-export even if output already exists.
#'   Default: \code{FALSE}.
#'
#' @return Invisibly, a data.frame with columns \code{id} and \code{status}
#'   (\code{"ok"}, \code{"skipped"}, or \code{"error"}).
#' @export
exportForDashboard <- function(
    modelsDir  = getOption("pfm.modelDir", "models"),
    exportsDir = file.path(modelsDir, "exports"),
    overwrite  = FALSE) {

  modelsDir  <- normalizePath(modelsDir,  mustWork = FALSE)
  exportsDir <- normalizePath(exportsDir, mustWork = FALSE)

  if (!dir.exists(modelsDir)) {
    stop("models_dir does not exist: ", modelsDir, call. = FALSE)
  }
  idxPath <- file.path(modelsDir, "index.json")
  if (!file.exists(idxPath)) {
    stop("No index.json found in '", modelsDir, "'. Run modelEstimationWorkflow() first.",
         call. = FALSE)
  }

  idx <- jsonlite::fromJSON(idxPath, simplifyDataFrame = TRUE)
  if (length(idx) == 0 || nrow(idx) == 0) {
    message("No models found in index. Nothing to export.")
    return(invisible(data.frame()))
  }

  dir.create(exportsDir, showWarnings = FALSE, recursive = TRUE)
  message("Exporting ", nrow(idx), " model(s)")
  message("  from: ", modelsDir)
  message("  to:   ", exportsDir)

  exportedAt <- rep(NA_character_, nrow(idx))
  statuses   <- rep("pending",     nrow(idx))

  for (i in seq_len(nrow(idx))) {
    id     <- idx$id[i]
    outDir <- file.path(exportsDir, id)
    stamp  <- file.path(outDir, "manifest.json")

    if (!overwrite && file.exists(stamp)) {
      message("  [skip]  ", id, " (", idx$sector[i], "/", idx$stage[i], ")")
      # Read existing exported_at from the manifest if present
      existing <- tryCatch(
        jsonlite::fromJSON(stamp, simplifyVector = TRUE),
        error = function(e) list()
      )
      exportedAt[i] <- existing$exported_at %||% NA_character_
      statuses[i]   <- "skipped"
      next
    }

    message("  [export] ", id, " (", idx$sector[i], "/", idx$stage[i], ")")
    model <- tryCatch(
      loadPFMModel(id, modelsDir),
      error = function(e) {
        message("    ERROR loading .rds: ", e$message)
        NULL
      }
    )
    if (is.null(model)) {
      statuses[i] <- "error"
      next
    }

    result <- tryCatch({
      dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
      .exportOneModel(model, outDir)
      "ok"
    }, error = function(e) {
      message("    ERROR writing exports: ", e$message)
      "error"
    })

    statuses[i]   <- result
    exportedAt[i] <- if (result == "ok") {
      format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else NA_character_
  }

  # Write the exports registry (models index enriched with export metadata)
  registry <- idx
  registry$exported_at   <- exportedAt
  registry$export_path   <- file.path(exportsDir, idx$id)
  registry$export_status <- statuses

  # Enrich with key diagnostics from each model's manifest.json
  registry$aic          <- NA_real_
  registry$pseudoR2     <- NA_real_
  registry$nObs         <- NA_integer_
  registry$nCountries   <- NA_integer_
  registry$nSignificant <- NA_integer_
  registry$converged    <- NA
  registry$separation   <- NA
  registry$overfitting  <- NA

  for (i in seq_len(nrow(registry))) {
    if (identical(registry$export_status[i], "ok") || identical(registry$export_status[i], "skipped")) {
      mfPath <- file.path(exportsDir, registry$id[i], "manifest.json")
      mf <- tryCatch(jsonlite::fromJSON(mfPath, simplifyVector = TRUE), error = function(e) list())
      d  <- mf$diagnostics
      .pick <- function(x) if (!is.null(x) && length(x) > 0 && !is.na(x[[1]])) x[[1]] else NA
      if (!is.null(d)) {
        registry$aic[i]          <- .pick(d$aic)
        registry$pseudoR2[i]     <- .pick(d$pseudoR2)
        registry$nObs[i]         <- .pick(d$nObs)
        registry$nCountries[i]   <- .pick(d$nCountries)
        registry$nSignificant[i] <- .pick(d$nSignificant)
        registry$converged[i]    <- .pick(d$converged)
        registry$separation[i]   <- .pick(d$separation)
        registry$overfitting[i]  <- .pick(d$overfitting)
      }
    }
  }

  jsonlite::write_json(
    registry,
    file.path(exportsDir, "index.json"),
    pretty = TRUE, auto_unbox = TRUE, na = "null"
  )

  nOk      <- sum(statuses == "ok")
  nSkipped <- sum(statuses == "skipped")
  nError   <- sum(statuses == "error")
  message(
    "\nDone: ", nOk, " exported",
    if (nSkipped > 0) paste0(", ", nSkipped, " skipped") else "",
    if (nError   > 0) paste0(", ", nError,   " errors")  else ""
  )

  log <- data.frame(id = idx$id, status = statuses, stringsAsFactors = FALSE)
  invisible(log)
}

# ---------------------------------------------------------------------------
# Internal: export one PFMModel to outDir
# ---------------------------------------------------------------------------

.exportOneModel <- function(model, outDir) {

  exportedAt <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  # ---- 1. manifest.json ---------------------------------------------------
  diag <- model$diagnostics
  manifest <- list(
    id              = model$id,
    id_full         = model$id_full,
    created_at      = model$created_at,
    exported_at     = exportedAt,
    label           = model$label,
    pfm_version     = model$pfm_version,
    sector          = model$sector,
    stage           = model$stage,
    formula         = paste(deparse(model$formula, width.cutoff = 500), collapse = " "),
    family          = model$family,
    training_year_min = if (length(model$training_years) == 2) model$training_years[[1]] else NULL,
    training_year_max = if (length(model$training_years) == 2) model$training_years[[2]] else NULL,
    useFirth        = model$useFirth,
    data_hash       = model$data_hash,
    has_projections = !is.null(model$projections),
    diagnostics = list(
      aic             = .scalarOrNull(diag$aic),
      bic             = .scalarOrNull(diag$bic),
      aicc            = .scalarOrNull(diag$aicc),
      hqic            = .scalarOrNull(diag$hqic),
      loglik          = .scalarOrNull(diag$loglik),
      pseudoR2        = .scalarOrNull(diag$pseudoR2),
      nPredictors     = .scalarOrNull(diag$nPredictors),
      nObs            = .scalarOrNull(diag$nObs),
      nCountries      = .scalarOrNull(diag$nCountries),
      nSignificant    = .scalarOrNull(diag$nSignificant),
      kOverN          = .scalarOrNull(diag$kOverN),
      overfitting     = .scalarOrNull(diag$overfitting),
      separation      = .scalarOrNull(diag$separation),
      highZ           = .scalarOrNull(diag$highZ),
      maxAbsZ         = .scalarOrNull(diag$maxAbsZ),
      converged       = .scalarOrNull(diag$converged),
      maxitWarning    = .scalarOrNull(diag$maxitWarning),
      rejectionReason = .scalarOrNull(diag$rejectionReason)
    )
  )
  jsonlite::write_json(manifest, file.path(outDir, "manifest.json"),
                       pretty = TRUE, auto_unbox = TRUE, na = "null")

  # ---- 2. vif.json --------------------------------------------------------
  vif <- diag$vif
  vifOut <- list(
    maxVIF  = .scalarOrNull(vif$maxVIF),
    highVIF = .scalarOrNull(vif$highVIF),
    flagged = if (length(vif$flagged) > 0) as.list(vif$flagged) else list(),
    values  = if (length(vif$values) > 0) as.list(vif$values)  else list()
  )
  jsonlite::write_json(vifOut, file.path(outDir, "vif.json"),
                       pretty = TRUE, auto_unbox = TRUE, na = "null")

  # ---- 3. coefficients.parquet --------------------------------------------
  ct <- model$coeftest
  if (!is.null(ct) && is.matrix(ct) && nrow(ct) > 0) {
    coefDf <- data.frame(
      term      = rownames(ct),
      estimate  = as.numeric(ct[, 1]),
      std_error = as.numeric(ct[, 2]),
      z_value   = as.numeric(ct[, 3]),
      p_value   = as.numeric(ct[, 4]),
      stringsAsFactors = FALSE
    )
    arrow::write_parquet(coefDf, file.path(outDir, "coefficients.parquet"))
  }

  # ---- 4. training_data.parquet -------------------------------------------
  # ADR 0009: slim Fitted Models no longer embed the training panel (it lives
  # once in the content-addressed Training Panel store, referenced by
  # model$training_panel_hash). The dashboard's per-model training_data /
  # fitted_values parquets are therefore not exported for slim models. Rewiring
  # the dashboard to reconstruct them from the Training Panel + prepSpec is a
  # follow-up; leaving them absent degrades gracefully (the dashboard guards on
  # file presence).
  td <- model$training_data
  if (!is.null(td) && is.data.frame(td) && nrow(td) > 0) {
    td <- .toParquetSafe(td)
    arrow::write_parquet(td, file.path(outDir, "training_data.parquet"))
  } else if (!is.null(model$training_panel_hash) && !is.na(model$training_panel_hash)) {
    message("    (slim model ", model$id, ": training_data/fitted_values not embedded; ",
            "panel hash ", model$training_panel_hash, " - dashboard reconstruction is a follow-up)")
  }

  # ---- 5. fitted_values.parquet -------------------------------------------
  fv <- model$fitted_values
  if (!is.null(fv) && length(fv) > 0 && !is.null(td) && nrow(td) == length(fv)) {
    depVar <- if (model$stage == "adoption") "adoption" else "ecp"
    actual <- if (depVar %in% names(td)) as.numeric(td[[depVar]]) else rep(NA_real_, length(fv))
    fvDf <- data.frame(
      region       = if ("region" %in% names(td)) td$region else rep(NA_character_, length(fv)),
      year         = if ("year"   %in% names(td)) as.integer(td$year) else rep(NA_integer_, length(fv)),
      fitted_value = as.numeric(fv),
      actual       = actual,
      stringsAsFactors = FALSE
    )
    arrow::write_parquet(fvDf, file.path(outDir, "fitted_values.parquet"))
  }

  # ---- 6. correlation matrices (wide format) ------------------------------
  .writeCorMatrix <- function(mat, path) {
    if (is.null(mat) || !is.matrix(mat) || nrow(mat) == 0) return(invisible(NULL))
    df <- as.data.frame(mat, stringsAsFactors = FALSE)
    df <- cbind(data.frame(variable = rownames(mat), stringsAsFactors = FALSE), df)
    rownames(df) <- NULL
    arrow::write_parquet(df, path)
  }
  .writeCorMatrix(model$correlations$pearson,
                  file.path(outDir, "correlation_pearson.parquet"))
  .writeCorMatrix(model$correlations$spearman,
                  file.path(outDir, "correlation_spearman.parquet"))

  # ---- 7. projections/ ----------------------------------------------------
  proj <- model$projections
  if (!is.null(proj) && length(proj) > 0) {
    projDir <- file.path(outDir, "projections")
    dir.create(projDir, showWarnings = FALSE)

    dfNames   <- names(Filter(is.data.frame, proj))
    metaNames <- setdiff(names(proj), dfNames)

    for (nm in dfNames) {
      val <- proj[[nm]]
      if (nrow(val) > 0) {
        val <- .toParquetSafe(val)
        arrow::write_parquet(val, file.path(projDir, paste0(nm, ".parquet")))
      }
    }

    if (length(metaNames) > 0) {
      meta <- proj[metaNames]
      jsonlite::write_json(meta, file.path(projDir, "metadata.json"),
                           pretty = TRUE, auto_unbox = TRUE, na = "null")
    }
  }

  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Convert factor columns to character; ensure all columns are Parquet-safe types.
.toParquetSafe <- function(df) {
  as.data.frame(
    lapply(df, function(col) {
      if (is.factor(col))    return(as.character(col))
      if (is.integer(col))   return(as.integer(col))
      if (is.numeric(col))   return(as.numeric(col))
      if (is.logical(col))   return(as.logical(col))
      as.character(col)  # fallback for anything unexpected
    }),
    stringsAsFactors = FALSE
  )
}

# Return the value if it is a length-1 atomic, or NA (so jsonlite writes null via na="null").
# Returning NULL from a named list element causes jsonlite to emit {} rather than null.
.scalarOrNull <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  if (is.na(x[[1]])) return(NA)
  x[[1]]
}

# Null-coalescing
`%||%` <- function(x, y) if (!is.null(x)) x else y

# ---------------------------------------------------------------------------
# CLI entry point (Rscript only — not executed when sourced interactively)
# ---------------------------------------------------------------------------

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)

  modelsDir  <- if (length(args) >= 1) args[[1]] else getOption("pfm.modelDir", "models")
  exportsDir <- if (length(args) >= 2) args[[2]] else file.path(modelsDir, "exports")
  overwrite  <- "--overwrite" %in% args

  exportForDashboard(modelsDir, exportsDir, overwrite = overwrite)
}
