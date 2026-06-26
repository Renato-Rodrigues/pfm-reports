# Shared display helpers for the pure-consumer reports (ADR 0006).

#' How-to-read caption
#'
#' Emit the mandatory how-to-read caption below a chart or table (CONTEXT.md "How-to-Read
#' Caption"). Renders a styled HTML block; use inside \code{results='asis'} chunks.
#'
#' @param ... Character pieces pasted into the caption text.
#' @param type Either \code{"chart"} or \code{"table"}.
#' @return Invisibly \code{NULL}; called for its \code{cat()} side effect.
#' @export
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

#' Interactive sortable table
#'
#' Renders a \pkg{DT} datatable with sensible defaults; falls back to \code{knitr::kable} when
#' \pkg{DT} is unavailable.
#'
#' @param df A data.frame.
#' @param caption Optional caption.
#' @param pageLength Rows per page. Default 15.
#' @param digits Rounding for numeric columns. Default 3.
#' @param filter DT column-filter mode. Default \code{"none"}.
#' @return A \code{DT::datatable} (or \code{knitr::kable}) object.
#' @export
interactiveTable <- function(df, caption = NULL, pageLength = 15, digits = 3, filter = "none") {
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], function(x) round(x, digits))
  if (requireNamespace("DT", quietly = TRUE)) {
    DT::datatable(
      df, caption = caption, rownames = FALSE, filter = filter, extensions = "Buttons",
      options = list(pageLength = pageLength, scrollX = TRUE, dom = "Bfrtip",
                     buttons = c("copy", "csv"))
    )
  } else {
    knitr::kable(df, caption = caption)
  }
}

#' Render several interactive tables as one tagList
#'
#' Use instead of \code{print(interactiveTable(...))} inside a \code{results='asis'} loop: a
#' \pkg{DT} widget \code{print()}ed in such a loop loses its JS/CSS dependencies and renders blank.
#' Returning a single \code{htmltools::tagList} (the chunk's value, NOT \code{results='asis'})
#' attaches the dependencies correctly. Each list name becomes an \code{<h4>} sub-heading.
#'
#' @param items Named list of data.frames.
#' @param pageLength,filter Passed to \code{\link{interactiveTable}}.
#' @param captions Optional named character vector of captions (defaults to the list names).
#' @return An \code{htmltools::tagList} (print it as the chunk value).
#' @export
tabledList <- function(items, pageLength = 15, filter = "none", captions = NULL) {
  htmltools::tagList(lapply(names(items), function(nm) {
    cap <- if (!is.null(captions) && nm %in% names(captions)) captions[[nm]] else nm
    htmltools::tagList(
      htmltools::h4(nm),
      interactiveTable(items[[nm]], caption = cap, pageLength = pageLength, filter = filter)
    )
  }))
}

#' Display-cap a numeric vector at its p99 (Price Outlier convention)
#'
#' @param x Numeric vector.
#' @param probs Quantile for the cap. Default 0.99.
#' @return A list with \code{values} (capped), \code{cap}, and \code{nAbove}.
#' @importFrom stats quantile
#' @export
capAtP99 <- function(x, probs = 0.99) {
  pos <- x[is.finite(x)]
  if (length(pos) == 0) return(list(values = x, cap = NA_real_, nAbove = 0L))
  cap <- as.numeric(stats::quantile(pos, probs = probs, na.rm = TRUE))
  nAbove <- sum(is.finite(x) & x > cap)
  x[is.finite(x) & x > cap] <- cap
  list(values = x, cap = cap, nAbove = nAbove)
}

#' Annotation string for capped charts
#'
#' @param capInfo Output of \code{\link{capAtP99}}.
#' @param unit Unit label. Default \code{"USD/tCO2"}.
#' @return A character scalar (empty when nothing was capped).
#' @export
capAnnotation <- function(capInfo, unit = "USD/tCO2") {
  if (capInfo$nAbove > 0) {
    sprintf("Display capped at p99 = %.0f %s (+%d values above cap, see outlier table)",
            capInfo$cap, unit, capInfo$nAbove)
  } else {
    ""
  }
}

#' Long data.frame from a magpie object
#'
#' @param mag A magpie object.
#' @param source Optional source label added as a column.
#' @return A data.frame with columns \code{region, year, variable, value} (and \code{source}).
#' @importFrom magclass getRegions getYears getNames
#' @export
magpieToLong <- function(mag, source = NULL) {
  arr <- as.array(mag)
  g <- expand.grid(region = magclass::getRegions(mag),
                   year = magclass::getYears(mag, as.integer = TRUE),
                   variable = magclass::getNames(mag), stringsAsFactors = FALSE)
  g$value <- as.vector(arr)
  if (!is.null(source)) g$source <- source
  g
}

#' Rows of a prepared panel actually used by a fit
#'
#' Complete cases over the formula variables; fitted values are positionally aligned to these
#' rows, not to the full data.frame (GLMs silently drop NA rows).
#'
#' @param fit A fit object with \code{$data} and \code{$formula}.
#' @return Integer row indices.
#' @importFrom stats complete.cases
#' @export
usedRows <- function(fit) {
  df <- fit$data
  v <- intersect(all.vars(fit$formula), colnames(df))
  which(stats::complete.cases(df[, v, drop = FALSE]))
}

#' Significance stars for p-values
#'
#' @param p Numeric vector of p-values.
#' @return Character vector of stars (\code{***}, \code{**}, \code{*}, \code{.}, or \code{""}).
#' @export
sigStars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.001, "***",
      ifelse(p < 0.01, "**",
        ifelse(p < 0.05, "*",
          ifelse(p < 0.1, ".", "")))))
}
