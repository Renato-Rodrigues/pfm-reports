# Canonical measure glossary (shared across all PFM reports) — single source of truth so the
# definitions of every statistic shown in any report cannot drift. Reports render this via
# measureDefinitions() instead of carrying their own inline definition tables (ADR 0028 follow-up).

#' Canonical measure / statistic definitions used across the PFM reports
#'
#' One row per measure shown anywhere in the report suite (selection, model-selection,
#' results-adoption, results-stringency, publication, robustness, subnational). The \code{Group}
#' and \code{`Shown in`} columns let a report render the whole glossary or a filtered slice.
#'
#' @param groups Optional character vector of \code{Group} values to keep (e.g.
#'   \code{c("Selection","Model form")}); \code{NULL} (default) returns every measure.
#' @return A data.frame with columns \code{Group}, \code{Measure}, \code{Definition},
#'   \code{`Shown in`}.
#' @export
#' @author Renato Rodrigues
measureDefinitions <- function(groups = NULL) {
  d <- function(group, measure, shownIn, definition) {
    data.frame(Group = group, Measure = measure, Definition = definition,
               `Shown in` = shownIn, check.names = FALSE, stringsAsFactors = FALSE)
  }
  defs <- rbind(

    # ── Significance & theory tier ───────────────────────────────────────────────
    d("Tier", "Tier (Green / Blue / Yellow)", "selection, model-selection, publication",
      paste0("Theory-significance tier: Green = ≥1 significant term in all three theory ",
             "groups (Actor Power, Institutional Quality, Interaction); Blue = at least one group; ",
             "Yellow = none. The primary maximin sort key (worse sector across Bulk/Diffuse).")),
    d("Tier", "sigActorPower / sigInstQual / sigInteractions", "selection, model-selection",
      paste0("Per-group significance flags (any term in the group significant at 5%) that define ",
             "the Tier. Reported per sector and combined to the worse-sector tier.")),

    # ── Theory content ───────────────────────────────────────────────────────────
    d("Theory content", "ΔR²(theory)", "selection, model-selection, robustness",
      paste0("Pseudo-R² of the full model minus a baseline refit with all theory terms removed ",
             "(FE + controls + trend kept) — the unique incremental explanatory contribution of ",
             "the institutional theory terms. The lead theory metric and the maximin tie-break.")),
    d("Theory content", "Theory Fraction (theoryFrac)", "selection, model-selection",
      paste0("|theory contribution| / Σ|non-intercept contributions| of the linear predictor, ",
             "Region FE included in the denominator — the share of the model's signal that is ",
             "theory vs controls/FE/trend. Mechanically LOW under strong Region FE; read alongside ",
             "ΔR²(theory), not instead of it (it is not a weakness).")),

    # ── Selection mechanics ──────────────────────────────────────────────────────
    d("Selection", "Maximin rank", "selection, model-selection",
      paste0("Position under the Maximin Selection Rule: worse-sector tier first ",
             "(Green>Blue>Yellow), then mean ΔR²(theory), then within-band tie-breaks ",
             "(drop-idle-control → VIF/temporal fragility → trend → FE-discounted BIC).")),
    d("Selection", "gatePass", "selection, model-selection",
      paste0("TRUE only if the spec clears every HARD gate in BOTH sectors: maxVIF < 10, model ",
             "converged, no unintended lagged term, ΔR² ≤ 1. gatePass = FALSE specs rank last.")),
    d("Selection", "minTier / meanDeltaR2 / minDeltaR2", "selection",
      paste0("Worse-sector tier, and the mean / worse-sector ΔR²(theory) across Bulk and ",
             "Diffuse — the maximin keys in priority order.")),
    d("Selection", "FE-discounted BIC", "selection, robustness",
      paste0("BIC with the Region-FE dummies not penalised for parameter count ",
             "(feParsimonyWeight = 0): adjBIC = BIC − nFE·log(nObs). The parsimony tie-break, so ",
             "FE granularity does not decide on raw parameter count. Lower = simpler-adequate.")),
    d("Selection", "Shared Specification", "selection, results-adoption, results-stringency",
      paste0("One formula per stage applied to BOTH sectors (the deliverable constraint). The ",
             "per-sector optimum ignoring this constraint is shown as 'Best per sector/stage'.")),
    d("Selection", "trendShare", "selection",
      paste0("Share of the linear predictor's magnitude carried by the time trend — a fragility ",
             "signal (a spec leaning on the trend rather than drivers); a within-band tie-break, ",
             "lower preferred.")),
    d("Selection", "nFE", "selection",
      "Number of Region fixed-effect dummies in the spec (0 for Mundlak / pooled)."),

    # ── Fit & complexity ─────────────────────────────────────────────────────────
    d("Fit", "AIC", "selection, model-selection",
      paste0("Akaike information criterion (−2logL + 2k); lower = better fit–complexity ",
             "trade-off. Comparable only within the same stage, sector and panelTransform.")),
    d("Fit", "BIC", "selection, model-selection, robustness",
      "Bayesian information criterion (−2logL + k·log n); a stronger complexity penalty than AIC."),
    d("Fit", "pseudo-R²", "selection, model-selection",
      "McFadden (adoption) / deviance (stringency) R². In-sample explanatory power."),
    d("Fit", "maxVIF (VIF)", "selection, model-selection, robustness",
      "Largest variance-inflation factor among predictors; ≥ 10 fails the hard collinearity gate."),
    d("Fit", "nObs (N)", "selection, results-adoption, results-stringency",
      "Number of region-year observations used in the fit (complete cases)."),

    # ── Model form ───────────────────────────────────────────────────────────────
    d("Model form", "Coefficients (standardized)", "selection, results-adoption, results-stringency",
      paste0("Drivers are STANDARDIZED, so each coefficient is the effect of a ONE-standard-deviation ",
             "change in the driver on the log-odds (adoption) or the estimation-scale price ",
             "(stringency). Magnitudes are directly comparable across drivers; de-scale to natural ",
             "units by dividing by the driver's SD.")),
    d("Model form", "Stringency model (priceLink)", "selection, results-stringency, publication",
      paste0("The conditional-price response form. ‘log1p’ (default): gaussian identity link on ",
             "log(1+ECP), so E[log(1+ECP)] = Xβ and ECP = expm1(Xβ) (unbounded). ",
             "‘saturating’ (ADR 0026/0028, swept twin ‘ | satP’): ",
             "E[ECP] = Pmax·logit⁻¹(Xβ), bounded by Pmax so projections cannot explode. ",
             "It is NOT a Gamma/log-link double-log.")),
    d("Model form", "Pmax (priceCeilingMax)", "selection, results-stringency, publication",
      paste0("Saturating-form ceiling on the conditional price (default 1000 USD/tCO2) — a citable ",
             "economic backstop (marginal-abatement / high-end social-cost upper bound).")),
    d("Model form", "panelTransform", "selection, model-selection",
      paste0("Estimation scale: ‘levels’ (price/adoption on levels, Region FE allowed), ",
             "‘hybridFD’ (Δ drivers, FE differenced out), ‘pureFD’ (everything ",
             "differenced). Saturating price is defined only on ‘levels’ (ADR 0028).")),
    d("Model form", "ECP", "results-stringency, publication",
      "Effective Carbon Price (USD/tCO2) — the stringency outcome (sector-mean effective price)."),

    # ── Predictive diagnostics (report-only) ─────────────────────────────────────
    d("Predictive (report-only)", "AUC", "selection, model-selection, results-adoption, robustness",
      paste0("Probability a random adopting region-year is ranked above a non-adopting one ",
             "(0.5 = chance, 1 = perfect discrimination). Report-only — plays no role in selection.")),
    d("Predictive (report-only)", "Brier", "selection, results-adoption",
      "Mean squared error of predicted adoption probabilities; compare against the base-rate. Report-only."),
    d("Predictive (report-only)", "Calibration slope", "selection, results-adoption",
      paste0("Slope of refitting the outcome on the model's own logit: 1 = calibrated, ",
             "< 1 = overconfident. Report-only.")),
    d("Predictive (report-only)", "RMSE", "selection, model-selection, results-stringency, robustness",
      paste0("Root-mean-square error of fitted vs observed on the estimation scale. Comparable only ",
             "within the same panelTransform (levels RMSE is log-price; FD RMSE is Δlog-price). ",
             "Report-only.")),
    d("Predictive (report-only)", "AME", "results-adoption",
      paste0("Average Marginal Effect: the mean change in adoption probability per natural unit (or ",
             "per SD) of a driver, averaged over the sample — the interpretable effect size.")),

    # ── Out-of-sample robustness ─────────────────────────────────────────────────
    d("Robustness", "LORO (leave-one-region-out)", "robustness",
      paste0("Out-of-sample check: refit dropping each region in turn and predict it. Reports ",
             "out-of-sample AUC (adoption) / RMSE (stringency) vs in-sample and the naive base-rate.")),
    d("Robustness", "Temporal sign-stability", "robustness",
      paste0("Fraction of THEORY-term signs that hold between the full fit and an early-window refit ",
             "(worse sector). Reported as the Temporal-Stability Frontier; does NOT drive selection ",
             "(ADR 0027).")),
    d("Robustness", "Parsimony Frontier (ε-sensitivity)", "robustness",
      paste0("How the deliverable changes as the near-tie band ε widens — which simpler specs ",
             "would win at each tolerance.")),

    # ── Projection sanity ────────────────────────────────────────────────────────
    d("Projection", "Projection Sanity gate", "selection, results-stringency, publication",
      paste0("Scenario screen run after maximin. SEVERE (disqualifying): price > 2000 USD/tCO2, ",
             "invalid prices, a never-adopting region block, > 25% clamp-pinned region-years. ",
             "WARNINGS (reported only): all-region adoption saturation (expected under ambitious ",
             "policy), seam jumps, price spikes. Evaluated in expanding batches; first PASS wins.")),
    d("Projection", "Sanity flag severity", "selection",
      paste0("Each rule violation found while evaluating candidates is ‘severe’ (disqualifies ",
             "the spec) or ‘warning’ (recorded, non-disqualifying). ‘value’ is the ",
             "offending quantity (USD/tCO2 for price rules, probability for adoption rules).")),
    d("Projection", "Clamp-reliance (clampPinned / priceUnclamped)", "selection, results-stringency",
      paste0("Share of projected region-years pinned at the observed-anchored price clamp, and the ",
             "raw unclamped price. High clamp-reliance means the clamp is load-bearing — the ",
             "saturating form is the structural fix (ADR 0023/0026/0028).")),

    # ── Selection uncertainty (model-selection report) ───────────────────────────
    d("Selection uncertainty", "Near-tie confidence set", "model-selection",
      paste0("All specs within ε of the winner on the maximin keys — the set of models the ",
             "data cannot distinguish from the deliverable.")),
    d("Selection uncertainty", "Knob-sensitivity", "model-selection",
      paste0("How the selected spec changes as one selection knob (VIF gate, ε, FE set, parsimony ",
             "weight) is varied — reveals which choices the deliverable is sensitive to.")),
    d("Selection uncertainty", "Region-block bootstrap / channel stability", "model-selection",
      paste0("Region cluster-resampled refits of the candidate pool; reports how often each ",
             "channel set (and exact spec, with detail=full) wins — a stability check on the ",
             "selected channels.")),

    stringsAsFactors = FALSE
  )
  if (!is.null(groups)) defs <- defs[defs$Group %in% groups, , drop = FALSE]
  rownames(defs) <- NULL
  defs
}
