# Report tutorial 2 — Deployed-model reports

Once a deliverable is selected, these reports interrogate the **chosen models** themselves — their
coefficients, effect sizes, and behaviour. They load the deployed fit from the Fit Cache by id
(so they show exactly the model that was selected — same fit, same penalty).

```bash
Rscript reports/results-adoption/run.R   --group=exhaustive
Rscript reports/results-stringency/run.R --group=exhaustive
Rscript reports/publication/run.R        --group=exhaustive
```

---

## `results-adoption` — the deployed adoption model

**What it is.** A deep read of the selected **adoption** (Stage-1 logit) model, per sector.

**What it shows.** Coefficient forest plots; **Average Marginal Effects (AMEs)** — each driver's
average effect on the *probability* of adoption (percentage points), not just the log-odds;
**predicted-probability profiles** (Pr(adopt) as one driver sweeps its observed range, others at
means, with CIs); fit/diagnostic summaries.

**Why we show it.** A coefficient's significance doesn't tell you if its effect is *practically*
meaningful. AMEs put every driver on the interpretable probability scale; the profiles show the
shape (linear? saturating? a dip?) and where the model is confident vs. extrapolating.

**What you can conclude.**
- Which drivers move adoption probability the most in practice (largest |AME|), and in which
  direction — the substantive story behind the tier.
- Whether Actor Power and Institutional Quality have *meaningful* effect sizes, or are
  significant-but-tiny (a Green model can still be theoretically thin if AMEs are near zero).
- From the profiles: non-linearities and the ranges where predictions are reliable.

---

## `results-stringency` — the deployed stringency model

**What it is.** The selected **stringency** (Stage-2 GLM) model, per sector.

**What it shows.** Coefficients on the `log(1+ECP)` scale with robust CIs, fit diagnostics, and
the implied price relationships.

**Why we show it.** Adoption and stringency are different processes; a driver can gate *whether*
a price exists without setting *how high* it is. This isolates the level story.

**What you can conclude.** Which drivers raise/lower the *level* of an existing price, and how the
stringency drivers compare to the adoption drivers — often they differ, which is the whole point
of the two-stage hurdle. (Coefficients are per SD on the log(1+price) scale; `ECP = expm1(Xβ)`.)

---

## `publication` — the peer-review writeup

**What it is.** A self-contained, presentation-grade HTML report of the deliverable (theory and
prediction views both read the group's `selected-models.yml`).

**What it shows.** The narrative: model specification, headline coefficients/AMEs, fit, and the
projected feasibility story, formatted for an external audience.

**Why we show it.** One artifact you can hand to a reviewer or co-author without them running R.

**What you can conclude.** The end-to-end argument: what the model says about carbon-pricing
feasibility and how well-supported it is.

---

## `adoption-model` / `stringency-model` — single-model display

**What they are.** Generic single-model reports (forest plots + diagnostics) for *any* config,
defaulting to the group's `selected-models.yml`.

**What they show / why.** A focused look at one specification — useful to inspect a non-deliverable
candidate (`--modelConfig=...`) or a specific sector without the full results report.

**What you can conclude.** The same coefficient/diagnostic read as results-*, but for an arbitrary
chosen spec — handy for comparisons.

```bash
Rscript reports/adoption-model/run.R --group=exhaustive            # the deliverable
Rscript reports/adoption-model/run.R --modelConfig=results/expt/selected-models.yml
```

---

## `country-adoption` — one country's decomposition over time

**What it is.** A per-country view: how the adoption model's drivers contributed to that country's
adoption probability across the years. Takes drivers as parameters (`--country=BRA`), not a
Run-Group config.

**What it shows.** A time-path of the linear-predictor contributions by **Term Group** (Actor
Power, Inst. Quality, Interaction, Controls, FE, trend) for the chosen country.

**Why we show it.** The aggregate model is abstract; stakeholders ask "why does *my* country look
(in)feasible?". This decomposes one country's trajectory into its drivers.

**What you can conclude.** Which forces pushed a specific country toward or away from adoption, and
when — e.g. rising electrification vs. weak governance — turning the model into a country story.

```bash
Rscript reports/country-adoption/run.R --country=IND
```
