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
