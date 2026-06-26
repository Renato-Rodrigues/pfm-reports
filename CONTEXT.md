---
name: pfm-reports-context
description: Domain glossary for the pfm-reports repository
metadata:
  type: project
---

# pfm-reports — Domain Glossary

## Report
A self-contained analysis document (`.Rmd`) together with its report-specific R helpers and render script. Lives in `reports/<descriptive-name>/`. Each report is independently reproducible by running its `run.R`.

## Shared Helper
An R function reusable across more than one Report. Lives in `src/r/`. Currently: `loadModelData()`, `theme_report()` + colour palette, `kableCorrelationMatrix()`.

## Report-Specific Helper
An R function tightly coupled to a single Report's content. Lives in `reports/<name>/R/`. Not imported by other reports.

## modelData
The structured list produced by `loadModelData()` — wraps panel data, correlation matrices, four `modelSelectionWorkflow` results (`md`, `md2`, `md3`, `md4`), and scenario projection data. Persisted as `data/modelData.RData` (gitignored). Passed into a Report via `params$modelData` to avoid recomputation on every render.

## Render Script (run.R)
An R script inside each report folder that sets render params (paths, data object) and calls `rmarkdown::render()`. The root `run.R` is a CLI entry point that lists available reports, prompts for params, and delegates to the chosen report's `run.R`.

## Asset Folder
The output subfolder named after the report (e.g. `output/IAM_PFM_report/`) that holds plots and other files saved during rendering. Gitignored.

## Pure-Consumer Report
A report that only visualizes precomputed artifacts (workflow RDS, model store, selected-models config) and never estimates models or recomputes selection results itself (ADR 0006). The redesigned reports (`panel-data`, `selection`, `results-adoption`, `results-stringency`) are pure consumers; scenario projection prediction is the one in-report computation allowed (presentation-specific). The deprecated self-computing reports are `panel-data-input`, `model-selection`, `adoption-model`, `stringency-model`.

## Projection Convergence
The behaviour of a panel input at and beyond the historical→scenario seam: its convergence target (e.g. V-Dem logistic convergence to the 75th global percentile by 2150, midpoint 2080), the stitched trajectory, and continuity at the seam. A mandatory subsection per data type in the panel-data report.

## Seam-Continuity Table
Per variable × region, the normalized jump between the last historical year and the first scenario year, sorted descending with flagged offenders. The panel-data report's primary instrument for catching historical/scenario misalignment (e.g. the 2026-06-12 GDP Q-centred reference-shift bug). Computed by a tested pfm helper, not report-local code.

## Price Outlier
A region-year whose observed, fitted, or projected ECP exceeds the 99th percentile of positive historical ECP (data-driven, recomputed per panel). Distinct from the Projection Sanity explosion threshold (2000 USD/tCO₂): outliers are *extreme*, sanity violations are *insane*. Handling rule: charts are display-capped at p99 with an "+N above cap" annotation, never dropped from estimation; every outlier is listed in a sortable table. The adoption-stage analogue is |Pearson residual| > 3 (badly mispredicted region-years), flagged in tables and highlighted in calibration plots.

## How-to-Read Caption
A mandatory explanatory block rendered below **every** chart and table in the redesigned reports, starting "How to read this chart/table:" and stating the units, what each visual element encodes, and what a problematic pattern would look like. Emitted by a shared helper so styling is uniform; a chart without one is a defect.

## Section Explanation
A mandatory introductory paragraph at the beginning of each major section across all redesigned reports (Selection, Adoption, and Price Stringency), starting with `*What this section is for.*` in italics, explaining the purpose, scope, and interpretation of the section.

## Dispersion Chart
A per-data-type chart of cross-region dispersion over time (σ-convergence view) showing whether the regional variation that identifies the model is shrinking.
