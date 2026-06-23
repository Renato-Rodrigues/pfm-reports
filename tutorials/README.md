# pfm-reports — Report tutorials

pfm-reports is a **pure consumer**: it reads the curated artifacts a compute run wrote to a
**Run-Group** (`results/<group>/`) and renders HTML reports and paper figures. It never fits or
selects models — that's the **pfm** package (to *produce* the artifacts, see
`pfm/inst/tutorials/`).

These guides are about the reports themselves: **what each one is, the results it shows, why we
show them, and what you can conclude.**

## How to render a report

Every report has a `run.R` launcher and reads a Run-Group selected with `--group`:

```bash
# from the pfm-reports working directory, after a run produced results/<group>/
Rscript reports/selection/run.R          --group=exhaustive
Rscript reports/results-adoption/run.R   --group=exhaustive
Rscript reports/robustness/run.R         --group=exhaustive
```

HTML lands in `output/`. `--reportName=<label>` sets the output filename suffix. If you omit
`--group`, the default comes from `config.yml` (`group:` key). The compute launcher can also
render automatically with `start.R --render` (local only). Paper figures:
`Rscript make-paper-figures.R --group=<g>`.

## The reports at a glance

| Report | Reads | One-line purpose |
|---|---|---|
| **selection** | `sweep.rds` | Which model was chosen per stage, and why. |
| **model-selection** | `sweep.rds` | What the whole specification space looks like. |
| **results-adoption / results-stringency** | `selected-models.yml` | The deployed model's coefficients & effects, per stage. |
| **publication** | `selected-models.yml` | The peer-review-ready writeup. |
| **adoption-model / stringency-model** | a model config | Single-model forest plots & diagnostics. |
| **country-adoption** | drivers (params) | One country's adoption decomposition over time. |
| **robustness** | `robustness.rds`, `sweep.rds`, `temporal-split.rds`, `difference-first.rds` | Do the conclusions survive perturbation? |
| **subnational** | `subnational.rds` | Does within-country coverage change the picture? |
| **model-diagnostics / panel-data / panel-data-input / downscale / capmf-coverage** | inputs/cache | Data assembly & QA. |

## Tutorials

1. **[01-selection-reports.md](01-selection-reports.md)** — `selection` and `model-selection`: choosing the deliverable and reading the sweep.
2. **[02-deployed-model-reports.md](02-deployed-model-reports.md)** — `results-adoption`, `results-stringency`, `publication`, `adoption-model`, `stringency-model`, `country-adoption`: reading the chosen models.
3. **[03-robustness-reports.md](03-robustness-reports.md)** — `robustness` and `subnational`: stress-testing the conclusions.
4. **[04-data-and-diagnostic-reports.md](04-data-and-diagnostic-reports.md)** — `panel-data`, `panel-data-input`, `model-diagnostics`, `downscale`, `capmf-coverage`: inputs and QA.

## Reading these well

Every chart/table in the redesigned reports carries a **How-to-Read caption** (ADR 0006) — read
it first. The measure glossary is in the **selection** report's *Measure Definitions* section and
in `CONTEXT.md`. For the modelling concepts behind the numbers (two-stage hurdle, theory tiers,
Maximin, gates), see `pfm/inst/tutorials/05-understanding-the-model.md`.
