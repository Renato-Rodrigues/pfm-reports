# PFM Reports Tutorial

Welcome to the `pfm-reports` directory. This folder is dedicated to **R Markdown (.Rmd)** documents that perform deep analytical evaluations, progressive testing, and generate reproducible, shareable HTML/PDF reports of the Political Feasibility Module (PFM) models.

---

## 📚 Available Reports

The directory contains five core analytical R Markdown reports:

### 1. Adoption Model (`reports/adoption-model/adoption-model.Rmd`)
* **What it is for:** A detailed assessment of policy adoption, specifically calibrating alternative probability thresholds (e.g., 5%, 10%, 25%, 35%, 50%) for the hurdle stage, mapping spatial adoption, and graphing regional timelines.
* **Why use it:** Run this to evaluate geographical adoption patterns, calibrate triggers, and analyze policy transition speeds.

### 2. Downscale (`reports/downscale/downscale.Rmd`)
* **What it is for:** Diagnostic report for the IPF (Iterative Proportional Fitting) country-level downscaling of REMIND regional energy variables. Shows reaggregation consistency, country composition over time, historical alignment, fuel mix evolution, and country-level driver snapshots.
* **Why use it:** Run this to verify that downscaled country values reaggregate exactly to REMIND regional targets, and to inspect how the historical country energy mix is preserved in projected years.

### 3. Model Diagnostics (`reports/model-diagnostics/IAM_PFM_report.Rmd`)
* **What it is for:** The core feasibility diagnostics report. It fits the baseline political feasibility model formulations across diffuse/bulk sectors and hurdle/stringency stages. It computes in-sample statistics, country-level regressions, and out-of-sample projections using REMIND scenarios.
* **Why use it:** Run this first to generate the consolidated shared data cache (`data/modelData.RData`) consumed by other reports.

### 4. Model Selection (`reports/model-selection/model-selection.Rmd`)
* **What it is for:** An econometric progressive specification testing report. It fits 12 base formulations and dynamically generated combination models to compare metrics (AIC, BIC, Pseudo-R²) across base assumptions, institutional variables, and regional effects.
* **Why use it:** Run this to justify model changes, evaluate asymmetric lobbying (splitting actors), macroeconomic controls, Rule of Law indices, and fixed effects.

### 5. Panel Data Input (`reports/panel-data-input/panel-data-input.Rmd`)
* **What it is for:** Detailed inspection and validation of historical and scenario panel data.
* **Why use it:** Run this to verify that country-to-region aggregations preserve variance and that historical and projection data stitch together smoothly at the boundary year.

### 6. CAPMF Regional Coverage (`reports/capmf-coverage/capmf-coverage.Rmd`)
* **What it is for:** Spatial coverage evaluation of the OECD CAPMF policy stringency database mapped to the REMIND R54 regional classification.
* **Why use it:** Run this to check represented GDP and Population shares for covered countries and regions, and identify data gaps in non-covered regions.


---

## 🚀 How to Run the Reports

Each report is a self-contained `.Rmd` with its own `run.R` launcher in
`reports/<name>/`. Launchers read default paths dynamically from `config.yml`
(copy from `config.yml.example` to customize) via `src/r/configHelper.R`.

### Method A: Compute in pfm, then render (Recommended)

Compute now lives in the **pfm** package (ADR 0018/0019/0020): it runs the sweep,
selection, and post-processing in parallel and writes a **Run-Group** under
`results/<group>/` (`sweep.rds`, `selected-models.yml`, `robustness.rds`,
`temporal-split.rds`, `subnational.rds`, `manifest.json`). pfm-reports is a pure
consumer that reads a Run-Group and renders. Run from the `pfm-reports` root:

```bash
# 1. Compute a model group (locally or auto-submitted as a PIK SLURM job).
#    start.R auto-detects SLURM vs local and sizes parallelism to the cores.
Rscript start.R --group=exhaustive                 # full sweep + post-processing
Rscript start.R --group=guided --steps=sweep       # fast curated suite, sweep only
Rscript start.R --group=exhaustive --nCores=128 --render   # also render reports after
Rscript status.R --group=exhaustive                # check run status (+ live SLURM)

# 2. Render the consumer reports against a Run-Group (if not already via --render):
Rscript reports/selection/run.R          --group=exhaustive
Rscript reports/results-adoption/run.R   --group=exhaustive
Rscript reports/results-stringency/run.R --group=exhaustive
Rscript reports/publication/run.R        --group=exhaustive
Rscript reports/robustness/run.R         --group=exhaustive
Rscript reports/subnational/run.R        --group=exhaustive
```

Compute runs from this directory via `start.R` (which calls `pfm::runModelGroup`); the
individual steps are also reachable as `--steps=sweep,robustness,temporal,subnational` (and
`difference-first`). There are no longer separate `build-*.R` / `run-*.R` launcher scripts —
they were thin shims and have been removed in favour of `start.R` and the `pfm` functions.

Fitted models and panels are cached under `cache/` (content-addressed, ADR 0009),
so reruns reuse completed fits (and resume after an interrupted run).

### Method B: Single Report

Render any individual report via its `run.R` launcher. From the `pfm-reports` root:

```bash
Rscript reports/adoption-model/run.R --modelConfig=results/exhaustive/selected-models.yml
Rscript reports/stringency-model/run.R --modelConfig=results/exhaustive/selected-models.yml
Rscript reports/country-adoption/run.R --country=IND
Rscript reports/downscale/run.R
Rscript reports/model-diagnostics/run.R
Rscript reports/capmf-coverage/run.R
```


Most launchers accept `--reportName=<label>` (output suffix) and `--modelConfig=`
(or `--theoryConfig=` / `--adoptionConfig=` / `--stringencyConfig=`) to point at a
selected-models YAML in `reports/model-selection/model-configs/`.

> **Note:** the model-diagnostics report generates the shared `data/modelData.RData`
> cache consumed by other reports. Delete that file to force a recompute
> against a new selection.

### Method C: Manual Render (R Console)
To render a single report manually without its launcher:
```R
library(rmarkdown)
rmarkdown::render("reports/model-selection/model-selection.Rmd", output_dir = "output")
```

---

## 📝 Creating New Reports
If you wish to create a new report in the future (e.g., `reports/my-new-report/my-new-report.Rmd`), simply place it in a subdirectory under `reports/`. 

To ensure it doesn't contain hardcoded paths, use the dynamic configuration helper `getPfmConfig` in your setup chunk:

```R
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

# Configure madrat with the user-defined data-cache folder (config key: cachefolder;
# legacy alias cacheDir still accepted)
cache_dir <- getPfmConfig("cachefolder", getPfmConfig("cacheDir", "../data/cache"))
mapping_dir <- gsub("cache/default", "mappings", cache_dir)

madrat::setConfig(
  forcecache = TRUE,
  cachefolder = cache_dir,
  mappingfolder = mapping_dir
)
```
