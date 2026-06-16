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
* **Why use it:** Run this first to generate the consolidated shared data cache (`data/modelData.RData`) consumed by other reports and the Python dashboard.

### 4. Model Selection (`reports/model-selection/model-selection.Rmd`)
* **What it is for:** An econometric progressive specification testing report. It fits 12 base formulations and dynamically generated combination models to compare metrics (AIC, BIC, Pseudo-R²) across base assumptions, institutional variables, and regional effects.
* **Why use it:** Run this to justify model changes, evaluate asymmetric lobbying (splitting actors), macroeconomic controls, Rule of Law indices, and fixed effects.

### 5. Panel Data Input (`reports/panel-data-input/panel-data-input.Rmd`)
* **What it is for:** Detailed inspection and validation of historical and scenario panel data.
* **Why use it:** Run this to verify that country-to-region aggregations preserve variance and that historical and projection data stitch together smoothly at the boundary year.

---

## 🚀 How to Run the Reports

Each report is a self-contained `.Rmd` with its own `run.R` launcher in
`reports/<name>/`. Launchers read default paths dynamically from `config.yml`
(copy from `config.yml.example` to customize) via `src/r/configHelper.R`.

### Method A: Full Channels Workflow (Recommended)

The end-to-end driver `run-channels-workflow.R` generates the sweep config, runs
model selection (maximin + Projection Sanity), writes the selected-models config,
and renders the consumer reports (`selection`, `results-adoption`,
`results-stringency`, `publication`) automatically. Run from the `pfm-reports` root:

```bash
Rscript run-channels-workflow.R --mode=guided      # fast curated suite
Rscript run-channels-workflow.R --mode=exhaustive  # full combination sweep
```

Fitted models and panels are cached under `cache/` (content-addressed, ADR 0009),
so reruns reuse completed fits.

### Method B: Single Report

Render any individual report via its `run.R` launcher. From the `pfm-reports` root:

```bash
Rscript reports/adoption-model/run.R
Rscript reports/stringency-model/run.R
Rscript reports/model-selection/run.R --modelConfig=model-configs/selected-models-channels-exhaustive.yml
Rscript reports/country-adoption/run.R --country=IND
Rscript reports/downscale/run.R
Rscript reports/model-diagnostics/run.R
```

Most launchers accept `--reportName=<label>` (output suffix) and `--modelConfig=`
(or `--theoryConfig=` / `--adoptionConfig=` / `--stringencyConfig=`) to point at a
selected-models YAML in `reports/model-selection/model-configs/`.

> **Note:** the model-diagnostics report generates the shared `data/modelData.RData`
> cache consumed by the Python dashboard. Delete that file to force a recompute
> against a new selection.

### Method C: Manual Render (R Console)
To render a single report manually without its launcher:
```R
library(rmarkdown)
rmarkdown::render("reports/model-selection/model-selection.Rmd", output_dir = "output")
```

---

---

## 🐍 Python Dashboard

The `dashboard/` folder contains a multi-page interactive web app built with [Plotly Dash](https://dash.plotly.com/) for exploring PFM model outputs: coefficients, diagnostics, training data, and scenario projections.

### Prerequisites

- Python 3.10+
- R on `PATH` (the dashboard calls `Rscript` to export model data on first load)

### Installation

From the `pfm-reports/dashboard/` directory, install the Python dependencies:

```bash
pip install -r requirements.txt
```

The required packages are:

| Package    | Version  | Purpose                        |
|------------|----------|--------------------------------|
| `dash`     | ≥ 2.16   | Web framework & UI components  |
| `pandas`   | ≥ 2.0    | Data manipulation              |
| `pyarrow`  | ≥ 14.0   | Parquet file reading           |
| `plotly`   | ≥ 5.18   | Interactive charts             |

### Running the Dashboard

```bash
cd pfm-reports/dashboard
python app.py
```

Then open [http://localhost:8050](http://localhost:8050) in your browser.

### First-Time Setup: Pointing to a Models Folder

The dashboard reads model exports from a folder produced by `src/r/exportForDashboard.R`. On first launch:

1. Navigate to the **Model List** page (the default `/` route).
2. In the **Models folder** field, type the path to your models directory, or click **…** to browse to it. The folder must contain an `index.json` file.
3. If any models have not yet been exported, the **Load models** button will be enabled. Click it — a loading overlay will appear while `Rscript` exports the data (this may take a few minutes on the first run).
4. Once complete, the model table populates and the sidebar dropdown becomes active.

The chosen folder path is saved to `dashboard_config.json` and remembered across sessions.

### Navigating the Dashboard

The top navigation bar contains five pages:

| Page            | Route          | What it shows                                                         |
|-----------------|----------------|-----------------------------------------------------------------------|
| **Model List**  | `/`            | All exported models with AIC, pseudo-R², N obs, and export status     |
| **Data**        | `/data`        | Training data explorer and correlation matrices (Pearson / Spearman)  |
| **Model**       | `/model`       | Coefficient table, standard errors, p-values, and VIF scores          |
| **Results**     | `/results`     | In-sample fit diagnostics and residual plots                          |
| **Projections** | `/projections` | Out-of-sample scenario projections                                    |

The **Active model** dropdown in the left sidebar controls which model is shown across all pages. You can also click a row in the Model List table to switch the active model.

---

## 📝 Creating New Reports
If you wish to create a new report in the future (e.g., `reports/my-new-report/my-new-report.Rmd`), simply place it in a subdirectory under `reports/`. 

To ensure it doesn't contain hardcoded paths, use the dynamic configuration helper `getPfmConfig` in your setup chunk:

```R
library(rprojroot)
source(file.path(rprojroot::find_rstudio_root_file(), "src/r/configHelper.R"))

# Configure madrat with user-defined cache directory
cache_dir <- getPfmConfig("cacheDir", "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/cache/default")
mapping_dir <- gsub("cache/default", "mappings", cache_dir)

madrat::setConfig(
  forcecache = TRUE,
  cachefolder = cache_dir,
  mappingfolder = mapping_dir
)
```
