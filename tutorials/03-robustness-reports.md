# Report tutorial 3 — Robustness & sensitivity reports

These reports answer the reviewer's question: **do the conclusions survive?** They consume the
post-processing artifacts (`robustness.rds`, `temporal-split.rds`, `difference-first.rds`,
`subnational.rds`).

```bash
Rscript reports/robustness/run.R  --group=exhaustive
Rscript reports/subnational/run.R --group=exhaustive
```

---

## `robustness` — does the deliverable hold up?

**What it is.** The consolidated stress-test of the selected deliverable, combining several
checks the compute layer produced.

**What it shows.**
- **Robustness Ladder** — the deliverable re-fit under one-knob perturbations (composite Actor
  Power index, single-IQ-channel variants, first-difference, lagged DV, ridge interactions), with
  each rung's tier and ΔR²(theory).
- **Parsimony Frontier** — how the maximin winner shifts as the BIC tie-break tolerance grows
  (does a simpler model take over quickly?).
- **Control specification-curve** — the deliverable re-fit across a grid of control sets (is the
  result an artefact of one control choice?).
- **LORO** (Leave-One-Region-Out) — 54-fold spatial refit: coefficient stability and
  out-of-sample prediction (is the result driven by one region?).
- **Temporal split** — train on early years, predict later years (out-of-time discrimination).
- **Difference-First comparison** — the Falsification-Gate verdict on the levels deliverable vs.
  the dynamic-identification (difference-first) winner.

**Why we show it.** A single chosen model proves little; credibility comes from showing the
qualitative conclusion (tier, sign, significance of theory) is *stable* across reasonable
alternative choices and out-of-sample. Each panel targets a specific threat — specification
search, collinearity, influential regions, overfitting, dynamic confounding.

**What you can conclude.**
- If the **Robustness Ladder** keeps the tier/ΔR² across most rungs → the result isn't a knife-edge of one spec.
- A **first-difference** rung that collapses ΔR² to ~0 → the levels signal may be a level
  artefact (this is exactly what the difference-first method probes).
- **LORO** with stable signs and no single dominant region → not driven by an outlier.
- **Temporal split** with out-of-time AUC well above chance → the model carries forward, not just
  in-sample fit.
- The **difference-first** verdict tells you whether Actor Power is *dynamically identified*
  (persists under pureFD while Inst. Quality vanishes) — the strongest causal-leaning evidence.

---

## `subnational` — does within-country coverage change the picture?

**What it is.** A sensitivity analysis comparing the deployed **national-only** effective carbon
price against a **full-coverage** version that folds in subnational instruments (California,
Quebec, RGGI, the Chinese pilots, provinces).

**What it shows.** Country-level adoption **flips** (regions that become "adopters" once
subnational prices are counted) and price **rises**, per sector; and the deliverable **re-estimated**
on the national vs. full-coverage panel (tier/ΔR²/adoption-rate side by side).

**Why we show it.** The deliverable uses national instruments by design (a conservative,
consistent definition). Reviewers reasonably ask whether that understates real-world carbon
pricing. This quantifies the answer instead of asserting it.

**What you can conclude.**
- How many regions/region-years change adoption status under the broader definition (the size of
  the conservatism).
- Whether the **conclusions are robust to coverage**: if tiers and ΔR² barely move between the
  national and full-coverage refits, the national-only choice doesn't drive the findings; if they
  move a lot, the coverage definition is a material modelling assumption to flag.
