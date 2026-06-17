# PFM Model Selection — Key Findings

**Last updated:** 2026-06-10  
**Source sweeps:** `full.yml` (26 models) + `exhaustive.yml` (43 models), V-Dem indicators only, `ridgeInteractions = FALSE`  
**Reports:** `output/model_selection_full.html`, `output/model_selection_exhaustive.html`

---

## Best-per-Sector Selection (Updated 2026-06-10)

Independently optimal model per sector/stage — tier-first (Green > Blue > Yellow), then
maximise ΔR²(theory); VIF < 10, no lagged, Converged = TRUE.
Config: `selected-models-best.yml` (also updates `selected-models-theory.yml`).

| Sector/Stage | Tier | Best Model | TFrac | ΔR²(theory) | vs D2 |
|---|---|---|---|---|---|
| Adoption: Diffuse | 🟡 Yellow | **D4** No-Hydro Log GDP-Q + PC1 + H12 | 0.420 | **0.249** | +57% |
| Adoption: Bulk | 🟡 Yellow | **D4** No-Hydro Log GDP-Q + PC1 + H12 | 0.468 | **0.186** | +66% |
| Stringency: Diffuse | 🟢 Green | **D4** No-Hydro Log GDP-Q + PC1 + H12 | 0.379 | **0.339** | +49% — highest in sweep |
| Stringency: Bulk | 🟢 Green | **IQ-01** CSP + Composite AP + Linear + H12 | 0.314 | 0.020 | tier upgrade |

**vs. publication (selected-models-v2.yml):** all four stages change (D2→D4 for first three; D2→IQ-01 for Bulk).  
**vs. theory (selected-models-theory.yml):** adoption stages updated D2→D4; Str.Diffuse updated D2→D4; Str.Bulk unchanged.

To generate best-per-sector reports:
```r
Rscript reports/adoption-model/run.R  --reportName=best
Rscript reports/stringency-model/run.R --reportName=best
Rscript reports/publication/run.R      --reportName=best
```

---

## Status per Sector/Stage

| Sector/Stage | Tier | Model | TFrac | ΔR²(theory) | AIC | MaxVIF | REMIND-ready |
|---|---|---|---|---|---|---|---|
| Adoption: Diffuse | 🟡 Yellow | D4 Split AP Log GDP-Q + PC1 + H12 (no Hydro) | 0.420 | 0.249 | 665.7 | 2.8 | ✅ |
| Adoption: Bulk | 🟡 Yellow | D4 Split AP Log GDP-Q + PC1 + H12 (no Hydro) | 0.468 | 0.186 | 615.5 | 2.4 | ✅ |
| **Stringency: Diffuse** | **🟢 Green** | **D4 Split AP Log GDP-Q + PC1 + H12 (no Hydro)** | **0.379** | **0.339** | **676.4** | **2.4** | **✅** |
| Stringency: Bulk | 🟢 Green | IQ-01 CSP + Composite AP + Linear + H12 | 0.314 | 0.020 | 1393.7 | 3.1 | ✅ |

_Publication-consistent alternative (consistent D2 spec for all):_

| Sector/Stage | Tier | Model | TFrac | ΔR²(theory) | AIC | MaxVIF | REMIND-ready |
|---|---|---|---|---|---|---|---|
| Adoption: Diffuse | 🟡 Yellow | D2 Split AP Log GDP-Q + PC1 + H12 | 0.424 | 0.158 | 666.8 | 3.0 | ✅ |
| Adoption: Bulk | 🟡 Yellow | D2 Split AP Log GDP-Q + PC1 + H12 | 0.546 | 0.112 | 611.9 | 2.5 | ✅ |
| **Stringency: Diffuse** | **🟢 Green** | **D2 Split AP Log GDP-Q + PC1 + H12** | **0.384** | **0.227** | **676.1** | **2.6** | **✅** |
| Stringency: Bulk | 🔵 Blue | D2 Split AP Log GDP-Q + PC1 + H12 | 0.310 | 0.077 | 1358.4 | 4.4 | ✅ conditional |

---

## Key Findings

### 1. Stringency: Diffuse — Green Tier; D4 is Best Spec

**Status:** Confirmed in both full.yml and exhaustive.yml sweeps (deterministic model cache).

**Best specification:** D4 Split AP Logistic GDP-Q No-Hydro + State Capacity PC1 (VDem) + H12  
ΔR²(theory)=0.339 — highest in the entire exhaustive sweep. D2 (Hydro included) achieves ΔR²=0.227.

**Why it works:** Three compounding innovations jointly resolve the identification problems:
- V-Dem PC1 orthogonalises the state-capacity block (VIF 2.4 vs >40 for raw indicators)
- GDP Q-centred removes income–governance collinearity (r ≈ 0.75)
- Split AP + logistic trend isolates innovator/incumbent effects without sign cancellation
- Removing Hydro Nuclear Share (D4) frees the AP×PC1 interaction variance suppressed by Hydro's overlap

**Robustness:** Green tier holds across D2, D4, and B2. D4 is strictly superior by ΔR²; use D4 for best-per-sector work, D2 for publication-consistent spec.

**Caveat:** N = 258 region-years; confidence intervals are wide. Finding should be replicated on extended panels.

### 2. Stringency: Bulk — Green Tier (Exhaustive, Theory Spec)

**Status:** New finding from exhaustive.yml sweep.

**Specification:** IQ-01 VDem Civil Service Professionalism + Composite AP + Linear + H12

- Composite Actor Power Index + Civil Service Professionalism only (simpler than D2)
- All three channels (AP, CSP, AP×CSP interaction) significant at p < 0.05
- TFrac=0.314, ΔR²=0.020, VIF=3.1

**Interpretation:** Civil Service Professionalism is the cleanest institutional channel for industrial carbon pricing — technocratic state capacity directly enables implementation.

**Note:** The publication D2 model (Split AP + PC1) achieves Blue tier for Bulk (TFrac=0.310, ΔR²=0.077). The Green tier requires the simpler Composite AP + CSP spec.

### 3. Adoption Stages — Yellow Tier; D4 is Best Spec

**Status:** Yellow tier consistent across both sweeps. Yellow does NOT mean theory is absent.

**Best specification:** D4 Split AP Logistic GDP-Q No-Hydro + PC1 + H12 (both sectors).  
- Adoption Diffuse: ΔR²=0.249 (D4) vs 0.158 (D2), TFrac 0.420 vs 0.424
- Adoption Bulk: ΔR²=0.186 (D4) vs 0.112 (D2), TFrac 0.468 vs 0.546

D4 removes Hydro Nuclear Share, which was absorbing AP×PC1 variance. TFrac drops slightly but ΔR² gains are substantial (+57%/+66%).

Evidence of theory activity:
- Adoption: Bulk TFrac=0.468 (D4) → 47% of linear predictor is theory-driven
- Adoption: Diffuse TFrac=0.420 (D4) → 42%
- ΔR²(theory) > 0 (0.186/0.249) confirms unique theory contribution

**Why not Green/Blue:** Joint significance of all three channels requires more statistical power than available in the 22-year, 54-region binary adoption panel. Each channel reaches significance individually; joint identification is the constraint.

### 4. ridgeInteractions = FALSE Confirmed

Ridge regularization (L2 on interaction terms) has **zero effect** with V-Dem models. Identical TFrac, AIC, tier across all ridge=true vs ridge=false comparisons. V-Dem PC1 is well-conditioned (VIF 2–4); the ridge was only needed for WGI pathological interactions.

Library default changed to FALSE. Verified in 4 head-to-head model comparisons.

### 5. WGI Removed — V-Dem Enables Superior Identification

| Specification | Stringency: Diffuse tier | Stringency: Bulk tier |
|---|---|---|
| WGI Gov Eff + H12 (prior) | Yellow | Blue |
| V-Dem PC1 + H12 (V-Dem sweep) | **Green** | Blue |
| V-Dem CSP + H12 (exhaustive) | Green | **Green** |

V-Dem indicators provide:
- Better theoretical grounding (expert survey vs. statistical composite)
- Orthogonalisation via PCA (VIF < 3 vs WGI joint VIF > 10)
- Higher ΔR²(theory) for both stringency stages

---

## Prediction-Optimal Models

FE-05 (Composite AP + Linear + PC1 + 54-region FE) wins prediction across all four sector/stages:

| Sector/Stage | AIC | TFrac |
|---|---|---|
| Adoption: Diffuse | 335.0 | 0.105 |
| Adoption: Bulk | 345.7 | 0.133 |
| Stringency: Diffuse | 125.5 | 0.001 |
| Stringency: Bulk | 854.7 | 0.125 |

**Note:** 54-region FE absorbs almost all cross-regional variance (TFrac near zero for stringency). Use theory model for causal/scenario analysis; prediction model for calibration only.

---

## Selected Model Configurations

| Purpose | Config file | Spec | Notes |
|---|---|---|---|
| **Best-per-sector** | `selected-models-best.yml` | D4 (adoption+Str.Diffuse) + IQ-01 (Str.Bulk) | Independently optimal per stage |
| Theory | `selected-models-theory.yml` | Same as best (updated D2→D4) | = best, with rationale comments |
| Publication | `selected-models-publication.yml` | D2 consistently all 4 stages | Sacrifices quality for consistency |
| Prediction | `selected-models-prediction.yml` | FE-05 54 Regions all 4 stages | Calibration only; TFrac≈0 |
| v2 (alias) | `selected-models-v2.yml` | = publication | |
| Two-stage | `selected-models-twostage.yml` | D2 adoption + D4 stringency | Superseded by best |

---

## Deployment Readiness

| Component | Ready | Notes |
|---|---|---|
| Adoption: Bulk | ✅ | D4 spec (best); logistic trend bounded; GDP Q-centred pipeline required |
| Adoption: Diffuse | ✅ | Same spec |
| Stringency: Diffuse | ✅ | Green tier confirmed; N=258 caveat noted |
| Stringency: Bulk | ✅ | Green tier (IQ-01); REMIND scenarios use Composite AP |
| GDP Q-centred coupling | ⚠️ pending | Dynamic quartile recomputation per SSP scenario period |

---

## Reports

| Report | Output | Contents |
|---|---|---|
| Model selection (full) | `output/model_selection_full.html` | 26 V-Dem models × 4 stages |
| Model selection (exhaustive) | `output/model_selection_exhaustive.html` | 43 V-Dem models × 4 stages |
| Model selection analysis | `output/model_selection_analysis_vdem.html` | Justification + exhaustive live tables |
| Adoption (publication) | `output/adoption_model_vdem-publication.html` | D2 spec, both sectors |
| **Adoption (best)** | `output/adoption_model_best.html` | D4 No-Hydro, both sectors |
| Stringency (publication) | `output/stringency_model_D2-vdem-exhaustive.html` | D2 spec, both sectors |
| Stringency (theory) | `output/stringency_model_vdem-theory.html` | Theory-optimal (Green Bulk) |
| **Stringency (best)** | `output/stringency_model_best.html` | D4 Diffuse + IQ-01 Bulk |
| Publication report | `output/publication_report_vdem-publication.html` | Full two-stage results (D2) |
| **Publication (best)** | `output/publication_report_best.html` | Full two-stage (D4+IQ-01) |
| IAM diagnostic | `output/IAM_PFM_report.html` | Coupling diagnostics |
| Panel data | `output/panel_data_input.html` | V-Dem PC1/PC2 + GDP Q-centred added |

---

*Generated 2026-06-10 — Elevate PFM Team*

<!-- BEGIN channels-workflow:guided (auto-generated) -->
## Channels Workflow - guided (auto-generated 2026-06-15)

### Adoption - Maximin ranking (top 5 of 17)

| rank | model | minTier | meanDeltaR2 | minDeltaR2 | tierBySector | gatePass |
|---|---|---|---|---|---|---|
| 1 | J-06 WGI GovEff + RoL + VerAcc (composite AP) | Blue | 0.300 | 0.258 | Bulk: Blue; Diffuse: Blue | TRUE |
| 2 | B-D4 Split AP Logistic GDP-Q No-Hydro (incumbent) | Blue | 0.238 | 0.210 | Bulk: Blue; Diffuse: Green | TRUE |
| 3 | S1-AC3 Diagonal Accountability (VDem) | Blue | 0.233 | 0.200 | Bulk: Green; Diffuse: Blue | TRUE |
| 4 | S1-RL1 Rule of Law (VDem) | Blue | 0.228 | 0.227 | Bulk: Blue; Diffuse: Blue | TRUE |
| 5 | S1-AC1 Vertical Accountability (VDem) | Blue | 0.219 | 0.203 | Bulk: Blue; Diffuse: Green | TRUE |

**Selected shared spec:** J-06 WGI GovEff + RoL + VerAcc (composite AP)

### Stringency - Maximin ranking (top 5 of 17)

| rank | model | minTier | meanDeltaR2 | minDeltaR2 | tierBySector | gatePass |
|---|---|---|---|---|---|---|
| 1 | S1-AC2 Horizontal Accountability (VDem) | Blue | 0.228 | 0.043 | Bulk: Blue; Diffuse: Blue | TRUE |
| 2 | S1-GE2 GovEff: State Capacity PC1+PC2 | Yellow | 0.260 | 0.090 | Bulk: Yellow; Diffuse: Yellow | TRUE |
| 3 | S1-AC3 Diagonal Accountability (VDem) | Yellow | 0.250 | 0.077 | Bulk: Yellow; Diffuse: Blue | TRUE |
| 4 | B-D4 Split AP Logistic GDP-Q No-Hydro (incumbent) | Yellow | 0.244 | 0.063 | Bulk: Yellow; Diffuse: Blue | TRUE |
| 5 | S1-RL1 Rule of Law (VDem) | Yellow | 0.244 | 0.076 | Bulk: Yellow; Diffuse: Blue | TRUE |

**Selected shared spec:** S1-AC2 Horizontal Accountability (VDem)

### Best per sector/stage (secondary view)

| stage | sector | model | tier | deltaR2Theory | maxVIF | panelTransform |
|---|---|---|---|---|---|---|
| Adoption | Bulk | S1-AC3 Diagonal Accountability (VDem) | Green | 0.200 | 1.554 | levels |
| Adoption | Diffuse | B-D4 Split AP Logistic GDP-Q No-Hydro (incumbent) | Green | 0.265 | 2.790 | levels |
| Stringency | Bulk | FD-03 D4 hybridFD | Blue | 0.056 | 1.379 | hybridFD |
| Stringency | Diffuse | B-D4 Split AP Logistic GDP-Q No-Hydro (incumbent) | Blue | 0.426 | 2.355 | levels |

_68 fits; see output/model_selection_channels-guided.html for the full sweep._
<!-- END channels-workflow:guided -->

<!-- BEGIN channels-workflow:exhaustive (auto-generated) -->
## Channels Workflow - exhaustive (auto-generated 2026-06-16)

### Adoption - Maximin ranking (top 5 of 720)

| rank | model | minTier | meanDeltaR2 | minDeltaR2 | tierBySector | gatePass |
|---|---|---|---|---|---|---|
| 1 | X-0050 WGIge|RoL|VerAcc splitAP lev ctl:ctlNone fe:H12 | Green | 0.360 | 0.299 | Bulk: Green; Diffuse: Green | TRUE |
| 2 | X-0056 WGIge|RoL|VerAcc splitAP lev ctl:GDPq fe:H12 | Green | 0.347 | 0.276 | Bulk: Green; Diffuse: Green | TRUE |
| 3 | X-0062 WGIge|RoL|VerAcc splitAP lev ctl:GDPq.sq fe:H12 | Green | 0.340 | 0.265 | Bulk: Green; Diffuse: Green | TRUE |
| 4 | X-0051 WGIge|RoL|VerAcc splitAP lev ctl:ctlNone fe:OECDp | Green | 0.322 | 0.259 | Bulk: Green; Diffuse: Green | TRUE |
| 5 | X-0063 WGIge|RoL|VerAcc splitAP lev ctl:GDPq.sq fe:OECDp | Green | 0.310 | 0.218 | Bulk: Green; Diffuse: Green | TRUE |

**Selected shared spec:** X-0050 WGIge|RoL|VerAcc splitAP lev ctl:ctlNone fe:H12

### Stringency - Maximin ranking (top 5 of 720)

| rank | model | minTier | meanDeltaR2 | minDeltaR2 | tierBySector | gatePass |
|---|---|---|---|---|---|---|
| 1 | X-0147 WGIge|RoL|HorAcc splitAP lev ctl:ctlNone fe:OECDp | Blue | 0.370 | 0.157 | Bulk: Blue; Diffuse: Blue | TRUE |
| 2 | X-0435 WGIge|noRoL|VerAcc splitAP lev ctl:ctlNone fe:OECDp | Blue | 0.350 | 0.134 | Bulk: Blue; Diffuse: Blue | TRUE |
| 3 | X-0242 WGIge|RoL|DiagAcc splitAP lev ctl:ctlNone fe:H12 | Blue | 0.346 | 0.185 | Bulk: Blue; Diffuse: Green | TRUE |
| 4 | X-0291 WGIge|RoL|noAcc compAP lev ctl:ctlNone fe:OECDp | Blue | 0.336 | 0.117 | Bulk: Blue; Diffuse: Blue | TRUE |
| 5 | X-0146 WGIge|RoL|HorAcc splitAP lev ctl:ctlNone fe:H12 | Blue | 0.335 | 0.161 | Bulk: Blue; Diffuse: Green | TRUE |

**Selected shared spec:** X-0147 WGIge|RoL|HorAcc splitAP lev ctl:ctlNone fe:OECDp

### Best per sector/stage (secondary view)

| stage | sector | model | tier | deltaR2Theory | maxVIF | panelTransform |
|---|---|---|---|---|---|---|
| Adoption | Bulk | X-1192 noGE|noRoL|VerAcc compAP lev ctl:lnGDP.sq fe:FE54 | Green | 3.211 | 9.516 | levels |
| Adoption | Diffuse | X-1384 noGE|noRoL|DiagAcc compAP lev ctl:lnGDP.sq fe:FE54 | Green | 3.705 | 9.726 | levels |
| Stringency | Bulk | X-0529 WGIge|noRoL|HorAcc splitAP lev ctl:ctlNone fe:noFE | Green | 0.217 | 3.614 | levels |
| Stringency | Diffuse | X-0145 WGIge|RoL|HorAcc splitAP lev ctl:ctlNone fe:noFE | Green | 0.861 | 6.328 | levels |

_5780 fits; see output/model_selection_channels-exhaustive.html for the full sweep._
<!-- END channels-workflow:exhaustive -->
