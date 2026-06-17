# Drives the full Institutional Quality Channels workflow (ADR 0004) via
# pfm::runChannelsWorkflow(): config generation, Stage-0 screen, all fits,
# maximin selection, selected-models config, report rendering, findings.md.
#
# Usage (from the pfm-reports root):
#   Rscript run-channels-workflow.R --mode=guided
#   Rscript run-channels-workflow.R --mode=exhaustive

args <- commandArgs(trailingOnly = TRUE)
mode <- "guided"
selectFE <- NULL
for (a in args) {
  if (startsWith(a, "--mode=")) mode <- sub("^--mode=", "", a)
  if (startsWith(a, "--selectFE=")) selectFE <- strsplit(sub("^--selectFE=", "", a), ",")[[1]]
}
stopifnot(mode %in% c("guided", "exhaustive"))

library(rprojroot)
root <- find_rstudio_root_file()
source(file.path(root, "src/r/configHelper.R"))

madrat::setConfig(forcecache = TRUE)

# Cache root (ADR 0009): {root}/cache/{models,panels,projections} + index.json
model_dir <- getPfmConfig("modelDir", "cache")
if (!is_absolute_path(model_dir)) model_dir <- file.path(root, model_dir)
dir.create(model_dir, showWarnings = FALSE, recursive = TRUE)
options(pfm.modelDir = model_dir)

message("[driver] Loading historical panel data ...")
panel <- getPanelDataHistoricalCached(
  aggregate = TRUE, y = 2000:2022,
  outputRegionMappingFile = "regionmapping_54.csv"
)
panel <- magclass::mbind(
  panel,
  magclass::setNames(panel[, , "GDP per Capita"]^2, "GDP per Capita Sq")
)
message("[driver] Panel: ", paste(dim(panel), collapse = " x "))

# ADR 0009: store the shared Training Panel once (content-addressed) and set
# options(pfm.trainingPanelHash) so every Fitted Model saved this run references
# it by hash instead of embedding its own copy of the data.
panel_hash <- pfm::saveTrainingPanel(panel, dir = model_dir)
message("[driver] Training Panel stored (hash ", panel_hash, ")")

# Scenario panel (enables the Projection Sanity selection gate) — requires the
# REMIND gdx; skipped with a message when absent.
gdx_path <- getPfmConfig("gdxPath", "data/fulldata.gdx")
if (!is_absolute_path(gdx_path)) gdx_path <- file.path(root, gdx_path)
scenario <- NULL
if (file.exists(gdx_path)) {
  message("[driver] Loading scenario panel data (", gdx_path, ") ...")
  scenario <- tryCatch(
    getPanelDataScenarioCached(
      gdxFile = gdx_path, aggregate = TRUE,
      outputRegionMappingFile = "regionmapping_54.csv"
    ),
    error = function(e) {
      message("[driver] Scenario panel failed (", conditionMessage(e),
              ") - Projection Sanity gate will be skipped.")
      NULL
    }
  )
} else {
  message("[driver] No gdx at ", gdx_path, " - Projection Sanity gate will be skipped.")
}

res <- pfm::runChannelsWorkflow(
  mode = mode,
  panelData = panel,
  scenarioData = scenario,
  reportsDir = root,
  modelDir = model_dir,
  selectFE = selectFE
)

dir.create(file.path(root, "output"), showWarnings = FALSE, recursive = TRUE)
out_rds <- file.path(root, "output", paste0("channels_workflow_", mode, ".rds"))
saveRDS(res, out_rds)
message("[driver] Workflow results saved: ", out_rds)
message("[driver] DONE (", mode, ")")
