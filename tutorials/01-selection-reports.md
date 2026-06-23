# Report tutorial 1 — Selection reports

Two complementary reports answer two different questions about a sweep. Both are pure consumers
of `results/<group>/sweep.rds`.

- **selection** — *which model was chosen, and why.*
- **model-selection** — *what does the whole specification space look like.*

```bash
Rscript reports/selection/run.R       --group=exhaustive
Rscript reports/model-selection/run.R --group=exhaustive --reportName=exhaustive
```

---

## `selection` — the selection narrative

**What it is.** The decision record for the deliverable: the one shared specification picked per
stage and the full chain of reasoning that led there.

**What it shows.**
- *Executive summary* — sweep size, the selection rule, and the chosen model per stage (with whether it passed the Projection-Sanity gate or was a least-flagged fallback).
- *Chosen Models* — for each stage: the fitted equation per sector, key fit stats (AIC, pseudo-R², maxVIF, N), and a coefficient **forest plot**.
- *Selection Algorithm* — Stage-0 channel screen (forbidden pairs, slot rankings), the **Maximin ranking** of all specs, and the **Projection-Sanity trace** (the expanding-batch walk down the ranking).
- *Alternative Selections* — best-per-sector (ignoring the shared-spec constraint), best-by-predictability (AUC/Brier/RMSE), and the per-stage top-10.
- *Top-model forest plots*, *all Projection-Sanity flags*, the *all-models* table, and a *measure glossary*.

**Why we show it.** Selection is a defensible, rule-based choice, not a hand-pick. The report
makes every step auditable: the screen (what could co-enter a spec), the Maximin order (worse-
sector tier → mean ΔR²(theory) → BIC), and the scenario gate (which candidates projected sanely).
The forest plots show the chosen model's actual coefficients with robust CIs.

**What you can conclude.**
- The **worse-sector tier** of the chosen model is the headline: Green = theory significant in
  all three channels in *both* sectors; Blue/Yellow are weaker.
- The gap between *Chosen Models* and *best-per-sector* is the **price of cross-sector
  consistency** — how much you give up by forcing one formula across Bulk and Diffuse.
- If selection was a **least-flagged fallback**, no candidate passed the scenario sanity gate —
  treat the deliverable as provisional and read the sanity flags.
- Drivers are **standardized**: forest-plot magnitudes are directly comparable (largest bar =
  most influential per SD of the driver).

---

## `model-selection` — the full-sweep analysis

**What it is.** A bird's-eye view of *every* fitted specification — the landscape selection was
chosen from. (Rewritten as a pure consumer; it does no model fitting.)

**What it shows.**
- *Tier distribution* — a stacked bar of Green/Blue/Yellow counts per sector and stage.
- *ΔR²(theory) distribution* — violin/box of theory's unique contribution across all converged specs.
- *Model Rankings* — per sector/stage, a **heat-mapped multi-criterion table**: each cell is
  *rank (value)* with a green gradient, across tier, ΔR²(theory), AIC, BIC, pseudo-R², theory
  fraction, maxVIF, k/N — flagged fits (non-convergence / VIF ≥ 10 / lagged DV) in red, sorted last.
- *Best models* — top-30 by theory fraction and top-10-per-sector by AIC (tier-coloured), plus the maximin shortlist.
- *All fits* — the full filterable table.

**Why we show it.** Selection reports the winner; this reports the **distribution**. Whether
theory survives is often a property of the whole space, not one model — e.g. a sweep that is
overwhelmingly Yellow in Diffuse stringency tells you something structural that no single fit
reveals. The heat-map lets you see at a glance whether the top model dominates on *all* criteria
or only wins on the tie-break.

**What you can conclude.**
- A tier distribution dominated by **Yellow** in a sector/stage = theory rarely registers there;
  a healthy **Green/Blue** mass = the result is not a fluke of one spec.
- A ΔR²(theory) distribution massed near **zero** = theory adds little on average, even where
  individual specs look good.
- In the ranking heat-map, a row that's green **across the board** is a robust winner; a winner
  that's green only in the tier column but pale elsewhere won on tier alone — worth scrutinising.
- Divergence between the **theory** ranking (by theory fraction) and the **prediction** ranking
  (by AIC) marks the tension between theoretical richness and predictive parsimony.

> The cross-model **AME comparison** that used to live here required re-fitting and was removed
> when compute moved into pfm; per-model average marginal effects now live in the
> **results-adoption** report (tutorial 2).
