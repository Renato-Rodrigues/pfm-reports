# PFM Reports Tutorial

Welcome to the `pfm-reports` directory. This folder is dedicated to **R Markdown (.Rmd)** documents that perform deep analytical evaluations, progressive testing, and generate reproducible, shareable HTML/PDF reports of the Political Feasibility Module (PFM) models.

---

## 📚 Available Reports

### 1. `model-selection.Rmd`
**What it is for:** 
This report is a deep-dive into the econometric assumptions behind the PFM Hurdle Models (Logit Adoption & Gamma Stringency). It tests 6 progressive model specifications:
1. **Baseline**: Single `Actor Power Index`
2. **Split Variables**: Evaluates asymmetric lobbying by separating Innovators and Incumbents
3. **Path Dependency**: Tests institutional inertia by adding lagged adoption/stringency
4. **Advanced Controls**: Adds macro-structural controls like `Energy Intensity` and `Urban Population Share`
5. **Non-Linear Dynamics**: Tests if wealth has diminishing returns using `GDP per Capita Sq`
6. **Heterogeneous Regions**: Tests if Actor Power operates differently across global blocks (EU vs OECD) by interacting power indices with Region Fixed Effects.

**Why use it:** 
Run this report whenever you update your core `iamHistoricalData` or want to validate the statistical justification for choosing one model structure over another. The report outputs the Akaike Information Criterion (AIC) for every stage and sector across all 6 configurations.

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

## 📝 Creating New Reports
If you wish to create a new report in the future (e.g., `PFM_Projection_Analysis.Rmd`), simply place it in this folder. Be sure to configure `madrat` in the setup chunk of your new report to ensure data loading works seamlessly:

```R
madrat::setConfig(
  forcecache = TRUE,
  cachefolder = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/cache/default",
  mappingfolder = "C:/Users/renatoro/Desktop/Input Data/remind_inputdata/mappings"
)
```
