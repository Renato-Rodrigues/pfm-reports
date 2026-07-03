# End-to-end render of the PSM Results report against a synthetic Run-Group.
# Skips when pandoc or the pfm PSM pipeline (ADR 0036) is unavailable.

makePSMReportFixture <- function() {
  set.seed(31)
  regions <- paste0("R", 1:12)
  years <- 2000:2019
  nR <- length(regions)
  nY <- length(years)
  vars <- c("Policy Stringency|Bulk", "Policy Stringency|Diffuse",
            "Actor Power Index|Bulk", "Actor Power Index|Diffuse",
            "Rule of Law (VDem)")
  m <- magclass::new.magpie(regions, years, vars, fill = NA)
  iq <- matrix(runif(nR * nY), nR, nY)
  m[, , "Rule of Law (VDem)"] <- as.vector(iq)
  for (sec in c("Bulk", "Diffuse")) {
    ap <- matrix(runif(nR * nY, -0.8, 0.1), nR, nY)
    y <- matrix(NA_real_, nR, nY)
    for (t in 2:nY) {
      y[, t] <- 10 * stats::plogis(-0.5 + 2 * ap[, t - 1] + 1.5 * iq[, t - 1] +
                                     stats::rnorm(nR, sd = 0.25))
    }
    m[, , paste0("Actor Power Index|", sec)] <- as.vector(ap)
    m[, , paste0("Policy Stringency|", sec)] <- as.vector(y)
  }
  scen <- magclass::new.magpie(regions, 2019:2030,
                               c("Actor Power Index|Bulk", "Actor Power Index|Diffuse",
                                 "Rule of Law (VDem)"), fill = NA)
  for (v in magclass::getNames(scen)) {
    scen[, , v] <- if (grepl("Actor Power", v)) runif(nR * 12, -0.8, 0.1) else runif(nR * 12)
  }
  specs <- list(
    list(name = "psmA", actorPowerDrivers = "Actor Power Index",
         actorPowerIndex = "Actor Power Index",
         instQualityDrivers = "Rule of Law (VDem)",
         controlDrivers = NULL, regionMappingFixedEffects = NULL)
  )
  list(panel = m, scen = scen, specs = specs)
}

test_that("renderPSMResults renders a PSM Run-Group end-to-end", {
  skip_if_not(rmarkdown::pandoc_available(), "pandoc unavailable")
  skip_if_not("runPSMSweep" %in% getNamespaceExports("pfm"),
              "installed pfm lacks the PSM pipeline (ADR 0036)")

  fx <- makePSMReportFixture()
  base <- withr::local_tempdir()
  resultsDir <- file.path(base, "results")
  modelDir <- file.path(base, "models")
  outDir <- file.path(base, "reports")

  suppressMessages(suppressWarnings(pfm::runPSMSweep(
    group = "psm-report-test", mode = "guided", resultsDir = resultsDir,
    modelDir = modelDir, panelData = fx$panel, scenarioData = fx$scen,
    specs = fx$specs, selectFE = NULL, verbose = FALSE
  )))
  registry <- list(
    npi = list(id = "npi", name = "National Policies", prebuilt = fx$scen, gating = FALSE),
    amb = list(id = "amb", name = "Climate Ambition", prebuilt = fx$scen, gating = TRUE)
  )
  suppressMessages(suppressWarnings(pfm::runPSMProjection(
    group = "psm-report-test", resultsDir = resultsDir, modelDir = modelDir,
    panelData = fx$panel, scenarios = registry, verbose = FALSE
  )))
  suppressMessages(suppressWarnings(pfm::runPSMEstimatorAgreement(
    group = "psm-report-test", resultsDir = resultsDir, modelDir = modelDir,
    panelData = fx$panel, estimators = c("satP", "fractional", "levels"), verbose = FALSE
  )))

  html <- suppressMessages(renderPSMResults(
    group = "psm-report-test", resultsDir = resultsDir, outputDir = outDir, verbose = FALSE
  ))
  expect_true(file.exists(html))
  expect_gt(file.size(html), 50000)
  txt <- readChar(html, file.size(html), useBytes = TRUE)
  for (needle in c("Policy Stringency Model", "Maximin ranking", "PSM Estimator Suite",
                   "Climate Ambition", "Implementability Factor", "How to read this",
                   "bounded by construction", "out-of-coverage")) {
    expect_true(grepl(needle, txt, fixed = TRUE), label = paste0("HTML contains '", needle, "'"))
  }
})
