# Report tutorial 4 — Data & diagnostic reports

These reports are about the **inputs** and **QA**, not the deliverable. Render them when you want
to verify the data the models were built on, or inspect a scenario/downscaling step. They read
the panels and the madrat cache rather than a Run-Group selection.

```bash
Rscript reports/panel-data/run.R
Rscript reports/panel-data-input/run.R
Rscript reports/model-diagnostics/run.R
Rscript reports/downscale/run.R
Rscript reports/capmf-coverage/run.R
```

---

## `panel-data` — the assembled training (and scenario) panel

**What it is.** A view of the magpie panel that `pfm::panelDataHistorical()` (and, if a gdx is
present, `panelDataScenario()`) produce — the actual matrix the models are fit on.

**What it shows.** Each variable (effective carbon price, Actor Power drivers, Institutional
Quality indices, controls) across the 54 regions and years: coverage, ranges, trends, missingness.

**Why we show it.** Garbage-in checks. Every modelling result is downstream of this panel; before
trusting a tier you want to see the inputs are sane (e.g. the price series, the driver
normalizations, the year range that actually built).

**What you can conclude.** Whether the panel is complete and plausible, what year range is
available (the binding driver is the IEA energy balances), and where data is thin.

---

## `panel-data-input` — the raw inputs behind the panel

**What it is.** A closer look at the upstream raw series (pre-assembly), as read from mrpfm.

**What it shows.** The source-level variables before they're combined/normalized into the panel —
useful for tracing a panel value back to its origin.

**Why we show it.** When a panel variable looks off, this separates a *data* problem (the source)
from an *assembly* problem (the pfm transformation).

**What you can conclude.** Which raw source drives a given panel feature, and whether an anomaly
originates upstream.

---

## `model-diagnostics` — the IAM/PFM diagnostic report

**What it is.** The standalone HTML diagnostic (`IAM_PFM_report`) — the broad model-health view.

**What it shows.** Diagnostic plots and tables for the model pipeline: fit behaviour, separation,
VIF/collinearity, residual/calibration checks.

**Why we show it.** A one-stop health check separate from the selection narrative — the kind of
diagnostics you scan before believing any headline.

**What you can conclude.** Whether the estimation is numerically well-behaved (convergence, no
pathological separation or collinearity) — the preconditions for the selection results to mean
anything.

---

## `downscale` — REMIND scenario downscaling

**What it is.** A view of `downscaleREMINDResults()` — REMIND variables read from a `fulldata.gdx`,
downscaled to country level and (optionally) re-aggregated to a region mapping.

**What it shows.** The scenario trajectories that feed `panelDataScenario()` and, through it, the
Projection-Sanity gate and the feasibility projection.

**Why we show it.** The future story depends entirely on these downscaled trajectories; this lets
you inspect them directly.

**What you can conclude.** Whether the scenario inputs are reasonable, and how the global REMIND
paths translate to the regions used downstream.

---

## `capmf-coverage` — CAPMF regional coverage

**What it is.** A coverage report for the OECD CAPMF policy data across regions.

**What it shows.** Where CAPMF data exists and where it's missing, by region.

**Why we show it.** Coverage gaps shape what the policy data can support; this documents them.

**What you can conclude.** Which regions are well/poorly covered by CAPMF — context for any
CAPMF-based analysis.

---

> These reports don't depend on a Run-Group selection, so most take no `--group`. They read the
> madrat/panel caches directly; see `pfm/inst/tutorials/06-caching-and-resume.md` for what must be
> cached, and `MRPFM_EXTERNAL_CACHE_DEPS.md` for the source list.
