# PFM Reports Tutorial

Welcome to the `pfm-reports` directory. This folder is dedicated to **R Markdown (.Rmd)** documents that perform deep analytical evaluations, progressive testing, and generate reproducible, shareable HTML/PDF reports of the Political Feasibility Module (PFM) models.

---

## 📚 Available Reports

### 1. `model-selection.Rmd`
**What it is for:** 
This report is a deep-dive into the econometric assumptions behind the PFM Hurdle Models (Logit Adoption & Gamma Stringency). It tests 6 progressive model specifications:
1. **Baseline**: Single `Actor Power Index`
2. **Split Variables**: Evaluates asymmetric lobbying by separating Innovators and Incumbents
3. **Advanced Controls**: Adds macro-structural controls like `Energy Intensity` and `Urban Population Share`
4. **Non-Linear Dynamics**: Tests if wealth has diminishing returns using `GDP per Capita Sq`
5. **Heterogeneous Regions**: Tests if Actor Power operates differently across global blocks (EU vs OECD) by interacting power indices with Region Fixed Effects
6. **Path Dependency**: Tests institutional inertia by adding lagged adoption/stringency to the fully specified heterogeneous regions model.

**Why use it:** 
Run this report whenever you update your core `iamHistoricalData` or want to validate the statistical justification for choosing one model structure over another. The report outputs the Akaike Information Criterion (AIC) for every stage and sector across all 6 configurations.

---

### 2. `panel-data-input.Rmd`
**What it is for:**
This report provides a detailed inspection, validation, and visualization of the trainer and projection panel data inputs. It compares institutional quality drivers, actor power drivers/indexes, and socioeconomic controls before regional aggregation (country-level) and after regional aggregation (region-level mapping to 54 clusters) for both historical (2000–2022) and scenario (2005–2150) datasets.

**Why use it:**
Run this report whenever you update raw inputs or run a new REMIND scenario to verify that the aggregation weights preserve global totals, verify variance preservation across aggregation scales, and perform continuity stitching diagnoses at the historical-to-scenario boundary (2022/2025).

---

## 🚀 How to Run the Reports

R Markdown files combine narrative text with executable R code. To execute the code and generate the final document, you must **"Knit"** or **Render** the file.

### Method A: Using RStudio (Recommended)
1. Open the `.Rmd` file (e.g., `model-selection.Rmd`) in RStudio.
2. At the top of the editor window, look for the **"Knit"** button (it has an icon of a ball of yarn).
3. Click **Knit** (or use the shortcut `Ctrl+Shift+K`).
4. RStudio will run all the code chunks in the background and generate an `.html` file in this same directory. The file will automatically pop up in a viewer window.

### Method B: Using the R Console
If you prefer running commands directly in the R console without using the RStudio interface:
```R
# Make sure the rmarkdown package is installed
if (!require(rmarkdown)) install.packages("rmarkdown")

# Render the report
rmarkdown::render("pfm-reports/reports/model-selection/model-selection.Rmd")
```

### Method C: From the Command Line / Terminal
You can generate the report directly from your operating system's terminal:
```bash
Rscript -e "rmarkdown::render('pfm-reports/reports/model-selection/model-selection.Rmd')"
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
If you wish to create a new report in the future (e.g., `PFM_Projection_Analysis.Rmd`), simply place it in this folder. Be sure to configure `madrat` in the setup chunk of your new report to ensure data loading works seamlessly:

```R
madrat::setConfig(
  forcecache = TRUE,
  cachefolder = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/cache/default",
  mappingfolder = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/mappings"
)
```
