#' @title kableCorrelationMatrix
#' @description Formats a correlation matrix data frame for display using \code{kableExtra},
#' with background color scaling based on correlation strength.
#'
#' @param corDf A data frame returned by \code{computeCorrelationMatrix}.
#' @param digits Integer. Number of digits to round the correlations to. Defaults to 2.
#' @param font_size Numeric. Font size for the table. Defaults to 12.
#' @param show Character. Which part of the matrix to show: "all", "lower", or "upper". Defaults to "lower".
#' @param color_threshold Numeric or NULL. Only correlations with absolute values above this threshold will have a background color. If \code{NULL} (default), a threshold is automatically selected based on the specified percentile of correlations.
#' @param percentile Numeric. The percentile used for automatic threshold selection when \code{color_threshold} is \code{NULL}. Defaults to 0.6.
#' @param verbose Logical. If \code{TRUE}, prints the automatically selected \code{color_threshold}. Defaults to \code{FALSE}.
#' @param ... Additional arguments passed to \code{knitr::kable}.
#'
#' @return A \code{kable} object.
#'
#' @author Renato Rodrigues
#' @export
#'
#' @importFrom knitr kable
#' @importFrom kableExtra kable_styling column_spec cell_spec spec_color
#' @importFrom stats quantile
kableCorrelationMatrix <- function(corDf, digits = 2, font_size = 12, show = "lower", color_threshold = NULL, percentile = 0.6, verbose = FALSE, ...) {
  if (!requireNamespace("kableExtra", quietly = TRUE)) {
    stop("Package 'kableExtra' is required for this function. Please install it.")
  }

  # Extract numeric columns (all except the first 'Driver' column)
  numericCols <- colnames(corDf)[-1]
  n <- length(numericCols)

  # Automatic threshold selection if NULL
  if (is.null(color_threshold)) {
    all_vals <- as.matrix(corDf[, numericCols])
    # Extract only off-diagonal values
    off_diag_vals <- all_vals[row(all_vals) != col(all_vals)]
    abs_vals <- abs(off_diag_vals)
    abs_vals <- abs_vals[!is.na(abs_vals)]

    if (length(abs_vals) > 0) {
      color_threshold <- unname(stats::quantile(abs_vals, percentile))
      if (isTRUE(verbose)) {
        message("Automatic color_threshold selected: ", round(color_threshold, 4), " (based on ", percentile * 100, "th percentile)")
      }
    } else {
      color_threshold <- 0.8 # fallback
    }
  }

  # Create a copy for formatting
  formattedDf <- corDf

  # Define a color ramp for red (0 to 1)
  red_palette <- grDevices::colorRampPalette(c("#FFFFFF", "#FF0000"))(100)

  for (j in seq_along(numericCols)) {
    col <- numericCols[j]
    vals <- corDf[[col]]

    for (i in seq_len(nrow(corDf))) {
      val <- vals[i]

      # Determine if we should show this cell
      is_upper <- j > i
      is_lower <- i > j
      is_diag <- i == j

      should_hide <- (show == "lower" && is_upper) || (show == "upper" && is_lower)

      if (should_hide) {
        formattedDf[i, col] <- ""
      } else if (is_diag) {
        # De-emphasize the diagonal (r = 1.00)
        formattedVal <- format(round(val, digits), nsmall = digits)
        formattedDf[i, col] <- kableExtra::cell_spec(
          formattedVal,
          color = "#A9A9A9", # DarkGray
          bold = FALSE
        )
      } else {
        # Format values with rounding
        formattedVal <- format(round(val, digits), nsmall = digits)

        # Apply coloring only if above threshold
        if (abs(val) >= color_threshold) {
          # Gradual scaling: map [color_threshold, 1] to [0.1, 1] for visible range
          scaled_val <- (abs(val) - color_threshold) / (1 - color_threshold)
          scaled_val <- max(0, min(1, scaled_val))

          # Map to color palette index (1 to 100)
          col_idx <- max(1, min(100, round(scaled_val * 99) + 1))
          bg_color <- red_palette[col_idx]

          formattedDf[i, col] <- kableExtra::cell_spec(
            formattedVal,
            background = bg_color,
            color = ifelse(scaled_val > 0.6, "white", "black"),
            bold = TRUE
          )
        } else {
          # Default formatting for low correlations
          formattedDf[i, col] <- kableExtra::cell_spec(
            formattedVal,
            color = "black",
            bold = FALSE
          )
        }
      }
    }
  }

  # Generate kable
  ktable <- kableExtra::kbl(formattedDf, format = "html", escape = FALSE, ...)
  ktable <- kableExtra::kable_styling(
    ktable,
    bootstrap_options = c("striped", "hover", "condensed", "responsive"),
    full_width = FALSE,
    font_size = font_size
  )
  ktable <- kableExtra::column_spec(ktable, 1, bold = TRUE, border_right = TRUE)

  return(ktable)
}
