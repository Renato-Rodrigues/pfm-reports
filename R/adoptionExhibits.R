# Adoption-report exhibits (ADR 0029): adoption-threshold analysis, Rogers adopter-timeline
# classification, and region world maps. Kept as helpers so results-adoption.Rmd stays readable and
# the logic is testable. Maps degrade gracefully when sf/rnaturalearth are unavailable.

#' Adoption-threshold sweep table
#'
#' For observed 0/1 outcomes \code{y} and fitted probabilities \code{prob}, sweeps candidate
#' thresholds and returns classification quality at each.
#'
#' @param y Numeric/integer 0-1 vector of observed adoption.
#' @param prob Numeric vector of fitted P(adoption), same length as \code{y}.
#' @param grid Numeric thresholds to evaluate. Default \code{seq(0.05, 0.95, 0.05)}.
#' @return data.frame: \code{threshold, sensitivity, specificity, accuracy, youdenJ, predAdoptRate}.
#' @export
adoptionThresholdTable <- function(y, prob, grid = seq(0.05, 0.95, 0.05)) {
  ok <- is.finite(y) & is.finite(prob)
  y <- y[ok]; prob <- prob[ok]
  pos <- sum(y == 1); neg <- sum(y == 0)
  do.call(rbind, lapply(grid, function(t) {
    pred <- prob >= t
    tp <- sum(pred & y == 1); tn <- sum(!pred & y == 0)
    data.frame(
      threshold = t,
      sensitivity = if (pos > 0) tp / pos else NA_real_,
      specificity = if (neg > 0) tn / neg else NA_real_,
      accuracy = mean(pred == (y == 1)),
      youdenJ = (if (pos > 0) tp / pos else 0) + (if (neg > 0) tn / neg else 0) - 1,
      predAdoptRate = mean(pred),
      stringsAsFactors = FALSE)
  }))
}

#' The three reference adoption thresholds (ADR 0029)
#'
#' @param y,prob See \code{\link{adoptionThresholdTable}}.
#' @param sensTarget Sensitivity floor for the Sens threshold. Default 0.90.
#' @param fineGrid Resolution for locating the references. Default \code{seq(0.01, 0.99, 0.01)}.
#' @return Named list with numeric \code{Sens90}, \code{Youden}, \code{BaseRate} thresholds.
#' @export
adoptionReferenceThresholds <- function(y, prob, sensTarget = 0.90, fineGrid = seq(0.01, 0.99, 0.01)) {
  tbl <- adoptionThresholdTable(y, prob, grid = fineGrid)
  sens_ok <- tbl[is.finite(tbl$sensitivity) & tbl$sensitivity >= sensTarget, , drop = FALSE]
  sens90 <- if (nrow(sens_ok)) max(sens_ok$threshold) else min(tbl$threshold)  # largest cutoff still catching >=90%
  youden <- tbl$threshold[which.max(tbl$youdenJ)]
  baseRate <- mean(y[is.finite(y)] == 1)
  list(Sens90 = sens90, Youden = youden, BaseRate = baseRate)
}

#' Rogers adopter-timeline classification (model-driven, ADR 0029)
#'
#' Each region's adoption year = first year its fitted P(adoption) crosses \code{threshold}; adopters
#' are ranked by that year and binned into the Rogers five groups. Regions that never cross are
#' Non-Adopters.
#'
#' @param df data.frame with columns \code{region}, \code{year}, \code{prob} (fitted P(adoption)).
#' @param threshold Numeric adoption-probability cutoff.
#' @return data.frame: \code{region, adoptionYear, rankPct, group} (group an ordered factor).
#' @export
rogersClassify <- function(df, threshold) {
  lv <- c("Innovators", "Early Adopters", "Early Majority", "Late Majority", "Laggards", "Non-Adopters")
  byR <- split(df, df$region)
  ay <- vapply(byR, function(d) {
    cross <- d$year[is.finite(d$prob) & d$prob >= threshold]
    if (length(cross)) min(cross) else NA_real_
  }, numeric(1))
  out <- data.frame(region = names(ay), adoptionYear = as.numeric(ay),
                    rankPct = NA_real_, group = NA_character_, stringsAsFactors = FALSE)
  adopt <- which(is.finite(out$adoptionYear))
  if (length(adopt)) {
    ord <- adopt[order(out$adoptionYear[adopt])]
    out$rankPct[ord] <- (seq_along(ord) - 0.5) / length(ord)   # mid-rank percentile
    out$group[ord] <- cut(out$rankPct[ord], breaks = c(-Inf, 0.025, 0.16, 0.50, 0.84, Inf),
                          labels = lv[1:5])
  }
  out$group[is.na(out$group)] <- "Non-Adopters"
  out$group <- factor(out$group, levels = lv)
  out[order(out$adoptionYear, out$region), ]
}

#' World choropleth of a per-region value (ADR 0029)
#'
#' Joins a per-region value to country geometries via \code{regionmapping_54.csv} and draws a
#' \code{geom_sf} map. Returns \code{NULL} (caller prints a fallback note) when \pkg{sf} /
#' \pkg{rnaturalearth} or the region mapping are unavailable.
#'
#' @param valueByRegion Named vector (names = RegionCode) or data.frame(region, value).
#' @param title,subtitle,legend Labels.
#' @param discrete Logical: treat the value as a categorical fill (default \code{FALSE} = continuous).
#' @param palette Optional named vector (discrete) or viridis option (continuous).
#' @param limits Optional numeric length-2 continuous-scale limits (e.g. \code{c(0,1)}).
#' @return A ggplot, or \code{NULL} if the map cannot be drawn.
#' @export
plotRegionWorldMap <- function(valueByRegion, title = NULL, subtitle = NULL, legend = NULL,
                               discrete = FALSE, palette = NULL, limits = NULL) {
  if (!requireNamespace("sf", quietly = TRUE) || !requireNamespace("rnaturalearth", quietly = TRUE)) {
    return(NULL)
  }
  mapping <- tryCatch(
    madrat::toolGetMapping("regionmapping_54.csv", type = "regional", where = "mappingfolder"),
    error = function(e) NULL)
  if (is.null(mapping)) return(NULL)
  world <- tryCatch(rnaturalearth::ne_countries(scale = "small", returnclass = "sf"),
                    error = function(e) NULL)
  if (is.null(world)) return(NULL)
  world$iso_key <- as.character(world$adm0_a3)

  vdf <- if (is.data.frame(valueByRegion)) {
    stats::setNames(valueByRegion[, 1:2], c("region", "value"))
  } else {
    data.frame(region = names(valueByRegion), value = unname(valueByRegion), stringsAsFactors = FALSE)
  }
  md <- mapping
  names(md)[names(md) == "RegionCode"] <- "region"
  md$region <- as.character(md$region); md$CountryCode <- as.character(md$CountryCode)
  md$CountryCode[md$CountryCode == "SSD"] <- "SDS"
  md <- merge(md, vdf, by = "region", all.x = TRUE)
  wd <- merge(world, md[, c("CountryCode", "value")], by.x = "iso_key", by.y = "CountryCode", all.x = TRUE)

  p <- ggplot2::ggplot(wd) +
    ggplot2::geom_sf(ggplot2::aes(fill = value), colour = "white", linewidth = 0.05) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom", panel.grid = ggplot2::element_blank(),
                   axis.text = ggplot2::element_blank()) +
    ggplot2::labs(title = title, subtitle = subtitle, fill = legend)
  if (discrete) {
    p <- p + if (!is.null(palette)) {
      ggplot2::scale_fill_manual(values = palette, na.value = "grey90", na.translate = FALSE)
    } else ggplot2::scale_fill_viridis_d(na.value = "grey90", na.translate = FALSE)
  } else {
    p <- p + ggplot2::scale_fill_viridis_c(option = if (is.null(palette)) "C" else palette,
                                           na.value = "grey90", limits = limits)
  }
  p
}

# Rogers band palette (shared by the classification table and adopter-category map).
#' @keywords internal
.rogersPalette <- c(
  "Innovators" = "#1a9850", "Early Adopters" = "#66bd63", "Early Majority" = "#fee08b",
  "Late Majority" = "#fdae61", "Laggards" = "#d73027", "Non-Adopters" = "#bdbdbd")
