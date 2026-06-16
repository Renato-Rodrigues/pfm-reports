# Shared helpers for the redesigned pure-consumer reports (ADR 0006).
# Sourced by panel-data, selection, results-adoption and results-stringency.

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Emit the mandatory How-to-Read Caption below a chart or table.
#' Every chart/table in the redesigned reports must be followed by one
#' (CONTEXT.md "How-to-Read Caption"). Renders as a styled HTML block;
#' use inside results='asis' chunks.
howToRead <- function(..., type = c("chart", "table")) {
  type <- match.arg(type)
  txt <- paste0(...)
  cat(sprintf(
    paste0(
      "<div style=\"background:#f5f7fa;border-left:4px solid #607d8b;",
      "padding:8px 12px;margin:6px 0 18px 0;font-size:0.9em;color:#37474f;\">",
      "<strong>How to read this %s:</strong> %s</div>\n\n"
    ),
    type, txt
  ))
}

#' Interactive sortable table (DT) with sensible defaults; falls back to kable
#' when DT is unavailable. Use for any table where ordering columns is useful.
interactiveTable <- function(df, caption = NULL, pageLength = 15, digits = 3,
                             filter = "none") {
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], function(x) round(x, digits))
  if (requireNamespace("DT", quietly = TRUE)) {
    DT::datatable(
      df,
      caption = caption,
      rownames = FALSE,
      filter = filter,
      extensions = "Buttons",
      options = list(
        pageLength = pageLength,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c("copy", "csv")
      )
    )
  } else {
    knitr::kable(df, caption = caption)
  }
}

#' Display-cap a numeric vector at its p99 (Price Outlier convention).
#' Returns list(values = capped vector, cap = cap value, nAbove = count capped).
capAtP99 <- function(x, probs = 0.99) {
  pos <- x[is.finite(x)]
  if (length(pos) == 0) return(list(values = x, cap = NA_real_, nAbove = 0L))
  cap <- as.numeric(stats::quantile(pos, probs = probs, na.rm = TRUE))
  nAbove <- sum(is.finite(x) & x > cap)
  x[is.finite(x) & x > cap] <- cap
  list(values = x, cap = cap, nAbove = nAbove)
}

#' Annotation string for capped charts.
capAnnotation <- function(capInfo, unit = "USD/tCO2") {
  if (capInfo$nAbove > 0) {
    sprintf("Display capped at p99 = %.0f %s (+%d values above cap, see outlier table)",
            capInfo$cap, unit, capInfo$nAbove)
  } else {
    ""
  }
}

#' Long data.frame from a magpie object: region, year, variable, value.
magpieToLong <- function(mag, source = NULL) {
  arr <- as.array(mag)
  regions <- magclass::getRegions(mag)
  years <- magclass::getYears(mag, as.integer = TRUE)
  vars <- magclass::getNames(mag)
  g <- expand.grid(region = regions, year = years, variable = vars,
                   stringsAsFactors = FALSE)
  g$value <- as.vector(arr)
  if (!is.null(source)) g$source <- source
  g
}

#' Rows of a prepared panel actually used by a fit (complete cases over the
#' formula variables) — fitted values are positionally aligned to these rows,
#' NOT to the full data.frame (GLMs silently drop NA rows).
usedRows <- function(fit) {
  df <- fit$data
  v <- intersect(all.vars(fit$formula), colnames(df))
  which(stats::complete.cases(df[, v, drop = FALSE]))
}

#' Standard significance stars for p-values.
sigStars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.001, "***",
      ifelse(p < 0.01, "**",
        ifelse(p < 0.05, "*",
          ifelse(p < 0.1, ".", "")))))
}
