# PFM Reports

Reporting and visualisation code for the **Political Feasibility Module (PFM)** used in Integrated Assessment Models (IAMs). Reports are generated from model outputs produced by the [`pfm`](../pfm) and [`mrpfm`](../mrpfm) R packages.

---

## Repository structure

```
pfm-reports/
├── data/                              # gitignored — model output files from mrPEM
│   └── modelData.RData                #   cached pipeline result (auto-generated)
├── output/                            # gitignored — rendered reports and assets
│   ├── IAM_PFM_report.html
│   └── IAM_PFM_report/
│       └── plots/
├── reports/
│   └── model-diagnostics/             # IAM-PFM econometric diagnostics report
│       ├── IAM_PFM_report.Rmd         #   report document
│       ├── run.R                      #   report-specific render script
│       └── R/
│           ├── forestPlot.R           #   coefficient forest plot helper
│           └── modelHelpers.R         #   model extraction helpers
├── src/
│   └── r/                             # shared R helpers (used across reports)
│       ├── loadModelData.R            #   loads / computes the modelData list
│       ├── theme.R                    #   ggplot2 theme, colours, driver lists
│       └── kableCorrelationMatrix.R   #   styled correlation table helper
├── run.R                              # interactive CLI — build any report
└── CONTEXT.md                         # domain glossary
```

---

## Quickstart

### Build a report interactively (recommended)

Open an R session at the repo root and run:

```r
source("run.R")
```

The script will:
1. List all available reports.
2. Ask you to pick one.
3. Prompt for any required parameters (paths, etc.).
4. Render the report and save it to `output/`.

### Build a specific report directly

```r
source("reports/model-diagnostics/run.R")
```

This runs `render_report()` with default parameters. Edit the call at the bottom of the file, or call `render_report()` yourself with custom arguments:

```r
source("reports/model-diagnostics/run.R", local = TRUE)
render_report(
  modelDataFile = "data/modelData.RData",
  cacheDir      = "C:/path/to/madrat/cache",
  gdxPath       = "C:/path/to/fulldata.gdx",
  outputFile    = "output/IAM_PFM_report.html",
  assetDir      = "output/IAM_PFM_report"
)
```

---

## Parameters explained

| Parameter | What it is | Required? |
|---|---|---|
| `modelDataFile` | Path to the cached `.RData` file. If it does not exist, the full pipeline runs and saves here. | Yes (default: `data/modelData.RData`) |
| `cacheDir` | madrat cache folder (see mrPEM docs). Only needed the first time, or after clearing the cache. | Only when recomputing |
| `gdxPath` | Path to `fulldata.gdx` from a REMIND run. Enables the Projection Results section. Leave `""` to skip. | No |
| `outputFile` | Where to write the rendered HTML. | Yes (has default) |
| `assetDir` | Folder for plots and other assets saved during rendering. | Yes (has default) |

### Example: first-time run (no cached data)

```r
source("reports/model-diagnostics/run.R", local = TRUE)
render_report(
  modelDataFile = "data/modelData.RData",
  cacheDir      = "C:/Users/yourname/Desktop/Input Data/remind_inputdata/cache/default",
  gdxPath       = "C:/Users/yourname/Desktop/Projects/Elevate/code/fulldata.gdx"
)
```

This will run the full pfm/mrpfm pipeline (~10–30 min depending on machine), save the result to `data/modelData.RData`, then render the report.

### Example: re-render from cached data (fast)

```r
source("reports/model-diagnostics/run.R", local = TRUE)
render_report()  # uses data/modelData.RData if it exists
```

### Example: pass a pre-loaded object (skip file I/O entirely)

```r
# Useful during interactive development
modelData <- loadModelData(list(
  modelDataFile = "data/modelData.RData",
  cacheDir      = "",
  gdxPath       = ""
))

rmarkdown::render(
  "reports/model-diagnostics/IAM_PFM_report.Rmd",
  output_file = "output/IAM_PFM_report.html",
  params = list(modelData = modelData, assetDir = "output/IAM_PFM_report")
)
```

---

## Adding a new report

1. Create `reports/<descriptive-name>/` with at minimum:
   - `<ReportName>.Rmd` — the report document
   - `run.R` — exposing a `render_report(...)` function (copy from an existing report and adapt)
   - `R/` — any report-specific helpers

2. The root `run.R` automatically discovers the new report — no registration needed.

3. Add shared helpers (reused across reports) to `src/r/`.

4. Document the new report in this README under a new section.

---

## Reports

### model-diagnostics — `IAM_PFM_report`

**What it covers:** Full diagnostic and validation report for the two-stage hurdle model (adoption + stringency) across four model variants (`md`, `md2`, `md3`, `md4`) and two sectors (Bulk, Diffuse).

**Sections:** Model architecture · Correlation analysis · Model fit summary · Coefficient forest plots · Group-level variance partitioning · Pseudo-R² comparison · Issues table · IAM integration notes · Projection results (adoption probability, timelines, spatial maps).

**Output:** `output/IAM_PFM_report.html` + plots in `output/IAM_PFM_report/plots/`.
