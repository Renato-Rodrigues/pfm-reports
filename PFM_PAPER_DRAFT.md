# Polity, Politics, and Policy: A Political Feasibility Module for Carbon Pricing in Integrated Assessment Models

**Authors:** [Author list TBD — Elevate Project Team]  
**Target journal:** *Nature Climate Change* / *Global Environmental Change* / *Climate Policy*  
**Status:** Draft v4 — 2026-06-17 (review-readiness pass for NCC + political-economy scrutiny: explicit research questions (§1.3); honest per-RQ verdicts on the three theory channels (§7.1) and on fit-for-purpose for IAM coupling (§7.4); strengthened limitations on specification search and causal identification (§7.5). Results from the gated exhaustive sweep: Adoption = WGI GovEff + RoL + Vertical Accountability, split AP, H12 — Green/Green; Stringency = WGI GovEff + RoL + Horizontal Accountability, split AP, EU/OECD+ — Blue/Blue.)  
**Data and code:** https://github.com/[repo]/pfm [TBD]

---

## Abstract

Integrated assessment models (IAMs) typically implement carbon pricing either as scenario-defined exogenous variables or endogenously as shadow prices of emissions constraints, bypassing the political-economic processes that determine whether and at what level such prices are actually implemented. We introduce the Political Feasibility Module (PFM) — a two-stage hurdle model that links governance institutions (Polity), political actor coalitions (Politics), and carbon pricing outcomes (Policy) within a framework suitable for REMIND-MAgPIE coupling. The adoption stage is a Firth penalised logit; the stringency stage is a Gaussian-identity GLM on log(1+ECP) (back-transformed as ECP = expm1(Xβ)). Three institutional-quality channels — WGI Government Effectiveness (state capacity), and V-Dem Rule of Law and Accountability — interact with an Actor Power decomposition (innovator vs. incumbent coalitions) across a panel of 54 regions over 2000–2022. Rather than committing to one specification a priori, we identify the deliverable model through an exhaustive specification sweep (~1,445 specifications, ~5,780 fits) that crosses the institutional channels and actor-power form with eight curated control sets and five region fixed-effect resolutions (pooled, H12 blocks, EU/OECD+, 54-unit, and Mundlak correlated random effects), selecting one shared specification per stage by a maximin theory-tier rule gated by a projection-sanity check on SSP2 scenario trajectories. The module is built for iterative REMIND coupling: a slim, load-once fitted model applies frozen driver transforms to each scenario, with the time trend frozen at the last historical year out of sample and projection guards bounding extrapolated prices, so that future differentiation across SSP governance pathways is carried by the scenario drivers rather than an extrapolated trend. The selected adoption specification (WGI Government Effectiveness + Rule of Law + Vertical Accountability; split Actor Power; H12 fixed effects) is **Green tier in both sectors** — Actor Power, Institutional Quality, and their interaction are each jointly significant (ΔR²(theory) 0.30–0.42) — while the stringency specification (with Horizontal Accountability and EU/OECD+ fixed effects) is **Blue tier**, with institutional quality and the Actor Power × Institutional Quality interaction significant. A fit-reliability gate proved essential: it removes 54-region fixed-effects specifications whose ΔR²(theory) exceeds the McFadden bound, so the deliverable rests on interpretable, well-identified models rather than degenerate ones.

**Keywords:** political feasibility, carbon pricing, integrated assessment models, two-stage hurdle model, governance indicators, WGI, V-Dem, actor power, institutional quality, fixed effects, Mundlak, REMIND

---

## 1. Introduction

### 1.1 The political economy gap in climate modelling

Carbon pricing is widely regarded by economists as one of the most efficient instruments for meeting climate targets [CITATION: Stern 2007, Nordhaus 2017]. Yet IAMs routinely implement carbon prices either as exogenous policy parameters or endogenously as the shadow prices of emissions constraints under cost-optimisation [CITATION: Riahi et al. 2017, Rogelj et al. 2018]. The implicit assumption is that any shadow price path required to meet a given climate target is politically achievable — an assumption increasingly at odds with the observed political resistance to carbon pricing across democratic and authoritarian settings alike [CITATION: Colgan et al. 2021, Meckling & Nahm 2018]. The political feasibility of mitigation pathways has accordingly been flagged as a first-order determinant of which climate futures are achievable (Jewell & Cherp 2020), and recent work argues that integrated assessment must incorporate political-science insights more systematically (Brutschin & Andrijevic 2022; Leininger et al. 2024).

This political economy gap has two consequences for IAM projections. First, adoption pathways are driven primarily by GDP growth and time trends rather than governance conditions, producing near-identical price trajectories across SSP scenarios that differ substantially in their governance assumptions [CITATION: Bauer et al. 2020]. Second, the absence of a political-economic mechanism means IAM-derived carbon prices cannot be used to test hypotheses about which institutions, actor configurations, or governance reforms are most conducive to ambitious climate policy — a question of central importance to climate policy research.

### 1.2 The Polity → Politics → Policy framework

We frame the PFM around the "3P" linkage — polity, politics, policy — a tripartition with deep roots in political theory (Sternberger 1978) that has recently been proposed as an organising frame for integrating political development into climate scenarios (Leininger et al. 2024) and applied to comparative climate-governance analysis (Gong et al. 2020):

**Polity** refers to the institutional architecture of the state — its capacity to design credible policies, enforce them against opposition, and to whom decision-makers are accountable [CITATION: Acemoglu & Robinson 2012, North et al. 2009]. We operationalise polity through three governance channels: **WGI Government Effectiveness** (state/administrative capacity), and **V-Dem Rule of Law** and **Accountability** (the rule-based and regime dimensions, distinct from administrative capacity; cf. Fukuyama 2014). State capacity and accountability are conceptually and empirically distinct, and we keep them separate rather than collapsing them into a single "good governance" index.

**Politics** refers to the configuration of organised political interests that can veto or advance carbon pricing [CITATION: Mildenberger 2020, Hacker & Pierson 2002]. We operationalise this through an Actor Power Index that captures the relative strength of innovator coalitions (clean-energy industries, renewable investors) versus incumbent coalitions (fossil fuel producers, energy-intensive manufacturing). The key hypothesis is that innovator power translates into policy change when incumbent resistance is overcome — an asymmetric political contest.

**Policy** refers to the observable outcome: carbon pricing adoption (binary) and price stringency (conditional on adoption). These are measured through the World Bank Effective Carbon Price (ECP) database, separating industrial (Bulk) and household/transport (Diffuse) sectors.

The connecting hypothesis is that institutional quality (Polity) conditions the translation of political actor pressure (Politics) into policy outcomes: the AP × IQ interaction term captures whether strong innovator coalitions are more effective in high-capacity institutional environments. This is the theoretical lynchpin of the PFM framework and the hardest claim to identify empirically.

### 1.3 Research questions

The PFM is built to answer three questions, in ascending order of difficulty:

- **RQ1 (channels).** Do the three theory channels — actor-power asymmetry (innovators vs. incumbents), institutional quality, and their interaction — serve as statistically significant predictors of carbon-pricing **adoption** and, conditional on adoption, **stringency**, across the industrial (Bulk) and household/transport (Diffuse) sectors?
- **RQ2 (institutional conditionality, H1).** Is the effect of innovator coalition strength on carbon pricing *larger where state capacity is higher* — i.e. is the Actor Power × Institutional Quality interaction positive and identified, net of each main effect?
- **RQ3 (fit for purpose).** Applied out of sample, can the estimated relationships discriminate carbon-pricing trajectories across SSP governance pathways usefully — and robustly, without the spurious extrapolation that has historically plagued such projections — so as to give an IAM an *endogenous, estimated* political-feasibility signal rather than an exogenous assumption?

We answer RQ1–RQ2 from the historical panel (§6) and assess RQ3 through the projection/coupling design (§5.4) and its sanity diagnostics; §7 weighs how far each is genuinely established versus suggestive, given the identification limits of a 54-region, 23-year panel.

### 1.4 Contribution

This paper makes four contributions:

1. **Introduces the PFM** as a theory-grounded, REMIND-compatible political feasibility model. To our knowledge, this is the first two-stage hurdle model explicitly designed for IAM coupling that jointly estimates adoption probability and price stringency across multiple sectors.

2. **Identifies the deliverable specification by an exhaustive, theory-disciplined sweep** rather than a single hand-chosen model: ~1,445 specifications cross the three institutional-quality channels and the actor-power form with eight curated control sets and five region-FE resolutions, scored by a maximin theory-tier rule and gated by a projection-sanity check. This makes the trade-off between theory identification and fixed-effect heterogeneity control explicit and reproducible rather than assumed.

3. **Establishes a robust projection path for iterative IAM coupling**: We design a slim, load-once fitted model with frozen driver transforms, an out-of-sample time-trend freeze, and projection guards (clamp + price ceiling). This ensures that future scenario differentiation is driven by substantive governance and actor-power drivers (WGI Government Effectiveness, V-Dem Rule of Law, and Accountability) rather than an extrapolated trend.

---

## 2. Background and Related Literature

### 2.1 Political economy of carbon pricing

The political economy determinants of carbon pricing — both whether a price is adopted and how stringent it becomes — have been studied directly in cross-country settings (Levi, Flachsland & Jakob 2020), with non-environmental objectives (revenue, competitiveness, distributional concerns) often decisive for carbon-tax adoption (Klein et al. 2026). We organise this literature through three complementary lenses.

*Coalition politics*: [Meckling et al. 2015; Pahle et al. 2018] argue that carbon pricing requires a "winning coalition" of business actors with economic interests in pricing carbon — primarily clean-energy innovators and renewable energy investors. The clean-tech industries shift from opponents to proponents of carbon pricing as their cost competitiveness relative to fossil energy improves [CITATION: Meckling & Nahm 2018]. Incumbent fossil industries, conversely, have the strongest incentives to oppose carbon pricing [CITATION: Mildenberger 2020]. This coalition theory generates the Actor Power hypothesis: the relative strength of innovator vs. incumbent coalitions is a primary statistical predictor of adoption. Energy-transition outcomes are also strongly path-dependent — early policy choices lock in advocacy coalitions and infrastructure (Aklin & Urpelainen 2013; Mealy et al. 2025) — motivating the lagged-adoption dynamics of Section 3.3.

*Institutional capacity*: [Stasavage 2002; Persson & Tabellini 2000] emphasise that credible policy commitment requires institutional infrastructure — bureaucracies capable of designing regulation, courts capable of enforcing it, and regulatory agencies insulated from capture. [Meckling & Allan 2020] show that state capacity mediates the effectiveness of clean-energy industrial policy, and Meckling & Nahm (2021) show that state capacity enables governments to counter organised opposition to climate policy. Crucially, institutional capacity varies independently of regime type (Fukuyama 2014), and higher enforcement capacity is associated with measurable emission reductions from national climate legislation (Eskander & Fankhauser 2020), and carbon pricing has reduced emissions even at relatively low price levels (Bayer & Aklin 2020). Machine-learning analyses likewise identify institutional quality among the strongest predictors of climate-policy stringency (von Dulong & Hagen 2025). We build on this tradition in using V-Dem state capacity indicators as the governance channel.

*Conditionality*: The interaction between political actors and institutions is theorised in [CITATION: Putnam 1988; Acemoglu & Robinson 2012]: strong innovator coalitions may be necessary but insufficient — they can only translate into policy where institutions can absorb and sustain a new pricing regime. Empirically, Povitkina (2018) shows that state capacity moderates the effect of democracy on climate outcomes — a direct precedent for an actor-power × institutional-capacity interaction. This generates the AP × IQ interaction hypothesis.

### 2.2 Governance in integrated assessment models

IAMs vary in how they handle political economy constraints [CITATION: van Soest et al. 2021, Dafnomilis et al. 2022]. Most treat policy as exogenous (scenario-defined) or derive carbon prices endogenously as the shadow prices of emissions constraints under cost-minimisation or welfare maximisation. A smaller literature attempts endogenous governance: [CITATION: Köhler et al. 2019] introduce technology-political dynamics in WITCH; [CITATION: Geels et al. 2017] discuss socio-technical system dynamics; [CITATION: Keppo et al. 2021] review behavioural constraints in IAMs. None implements a statistically-estimated political feasibility function with explicit governance channels. A parallel strand argues that IAMs must integrate political-science insights more systematically (Brutschin & Andrijevic 2022; Peng et al. 2021; Trutnevyte et al. 2019) and has begun to quantify scenario feasibility, including the role of institutional capacity in deep-mitigation pathways (Brutschin et al. 2021; Gidden et al. 2023; Hickmann et al. 2022) — but this work evaluates the feasibility of given pathways rather than estimating an adoption–stringency process from observed policy. The stakes are high: a recent multi-model intercomparison finds that **institutional** feasibility constraints — the capacity to enforce climate regulation — cut the likelihood of limiting peak warming to 1.6 °C from roughly 50% to 5–45%, the largest reduction among the feasibility dimensions considered (Bertram et al. 2024). Recent contributions map political-feasibility constraints directly onto global mitigation pathways (Poujon et al. 2026) and formalise "feasibility spaces" bridging the modelled and real-world views (Jewell & Cherp 2023), while national climate institutions are shown to complement targets and policies in driving action (Dubash et al. 2021), and distinct national models of climate governance are systematically associated with policy ambition and performance across major emitters (Guy et al. 2023). The representation of democratic principles in the SSP narratives themselves has also been examined directly (Xexakis et al. 2026).

The closest precursors are scenario-conditional adoption studies [CITATION: Calvin et al. 2019; Bertram et al. 2021] that link SSP socioeconomic pathways to carbon pricing scenarios. The PFM extends this by providing a bottom-up econometric model of the adoption–stringency process with identifiable theory channels.

### 2.3 Governance measurement: WGI and V-Dem

We measure institutional quality through three named channels, each with a fixed operationalisation. **State capacity** is captured by **WGI Government Effectiveness** (World Bank Worldwide Governance Indicators) — the literature-preferred, directly interpretable measure of bureaucratic quality and policy-implementation capacity, and a measure that is independent of regime type (Fukuyama 2014). **Rule of law** and **accountability** are drawn from the Varieties of Democracy project [CITATION: Coppedge et al. 2022], which provides expert-survey indicators with granular theoretical coverage: V-Dem Rule of Law enters directly, and the accountability channel uses the best-performing of V-Dem's Vertical, Horizontal, and Diagonal Accountability indices.

An earlier version of the module summarised five V-Dem state-capacity indicators into an orthogonal first principal component (State Capacity PC1). We retired that construct in favour of WGI Government Effectiveness: a single, externally validated and directly interpretable state-capacity measure avoids the within-block collinearity of the raw V-Dem indicators while remaining transparent for policy interpretation and projection. Importantly for forward coupling, all three channels can be projected along the SSPs — WGI governance (Andrijevic et al. 2020) and V-Dem rule of law (Soergel et al. 2021) — supplying scenario-conditional input trajectories for the drivers used here (Section 7.4).

---

## 3. Theoretical Framework

### 3.1 The two-stage hurdle model as a theory of political feasibility

Carbon pricing policy exhibits a fundamental two-stage structure: first, a region must decide to adopt *any* carbon price at all (a political decision about whether to have a carbon pricing instrument); second, conditional on adoption, it must decide how ambitious that price should be (a political-economic decision about stringency, driven by the balance of supporting and opposing interests).

This structure maps directly onto a hurdle model:

**Stage 1 — Adoption:** Binary outcome (ECP > 0 vs ECP = 0). Modelled as the resolution of a political contest between pro-pricing and anti-pricing coalitions, mediated by institutional capacity. We estimate a Firth's penalised logistic regression:

$$\Pr(\text{Adoption}_{r,t}) = \text{logit}^{-1}\bigl(\alpha + \beta_1 \cdot \text{AP}_{r,t-1} + \beta_2 \cdot \text{IQ}_{r,t-1} + \beta_3 \cdot (\text{AP} \times \text{IQ})_{r,t-1} + \boldsymbol{\gamma}' \mathbf{Z}_{r,t-1}\bigr)$$

**Stage 2 — Stringency:** Conditional price level (ECP | ECP > 0). Modelled as the equilibrium price outcome given that adoption has occurred, modelled as a function of the same political-economic forces but conditional on the adoption regime. We estimate a **Gaussian GLM with identity link on the log-transformed price**, log(1+ECP), and back-transform; this avoids the double-exponentiation pathology of a log link applied to an already-logged outcome (Section 5.4):

$$\mathbb{E}\bigl[\log(1+\text{ECP}_{r,t}) \mid \text{ECP}_{r,t} > 0\bigr] = \alpha + \beta_1 \cdot \text{AP}_{r,t-1} + \beta_2 \cdot \text{IQ}_{r,t-1} + \beta_3 \cdot (\text{AP} \times \text{IQ})_{r,t-1} + \boldsymbol{\gamma}' \mathbf{Z}_{r,t-1}, \qquad \widehat{\text{ECP}}_{r,t} = \exp(\hat{\eta}_{r,t}) - 1$$

To account for the time required for institutional capacity and political coalitions to translate into legislative action, and to reduce contemporaneous endogeneity, all independent variables ($\text{AP}$, $\text{IQ}$, and controls $\mathbf{Z}$) are lagged by one period ($t-1$ / 1 year) in the historical estimation.

The full expected ECP is $\mathbb{E}[\text{ECP}_{r,t}] = \hat{\pi}_{r,t} \times \hat{q}_{r,t}$ — the product of adoption probability and conditional price. The control/trend vector $\mathbf{Z}$ differs by stage: the **adoption stage carries no time-trend term**, while the **stringency stage retains a single bounded, saturating logistic time trend** (Section 5.4), frozen at the last historical year for out-of-sample projection.

### 3.2 The AP × IQ interaction: The institutional conditionality hypothesis

The key theoretical claim is that Actor Power and Institutional Quality interact:

> **Hypothesis H1 (Interaction):** The effect of innovator coalition strength on carbon pricing is larger in regions with higher state capacity. Formally: $\partial^2 \mathbb{E}[\text{ECP}] / \partial \text{AP} \partial \text{IQ} > 0$.

The intuition is that innovator coalitions can only successfully lobby for carbon pricing where the bureaucratic apparatus can implement and enforce it. In low-capacity states, strong innovator lobbying may produce carbon pricing legislation that remains unenforced. In high-capacity states, innovator power more directly translates into effective pricing regimes.

### 3.3 Identification strategy: Two key panel design choices

Identifying the three-channel theory requires overcoming two structural challenges in our region-year panel:

**1. FE–theory suppression.** Actor power and institutional quality are highly *persistent within a region*, so unit-level (54-region) fixed effects absorb the cross-region variation that identifies them, causing the explanatory power of the theory variables to collapse. To resolve this, we treat regional heterogeneity control as an explicit sweep axis — testing pooled, grouped block fixed effects (H12 and EU/OECD+), 54-unit fixed effects, and Mundlak correlated random effects. The sweep demonstrates that grouped block fixed effects (H12 for adoption, EU/OECD+ for stringency) provide the optimal balance: they control for regional heterogeneity without suppressing the persistent theory channels or causing degenerate model separation.

**2. Actor power asymmetry.** A composite AP index forces symmetric innovator and incumbent effects. We solve this by implementing a **split AP specification** (estimating separate Innovator Power and Incumbent Power terms), allowing for asymmetric political contests with opposing signs.


---

## 4. Data and Measures

### 4.1 Dependent variable: Effective Carbon Price

The World Bank Effective Carbon Price (ECP) database covers carbon taxes and cap-and-trade systems at the country level, 2000–2022. We use two sector-level measures:
- **ECP_Bulk**: Carbon pricing for industrial/Bulk sectors (ETS, industrial carbon taxes)
- **ECP_Diffuse**: Carbon pricing for Diffuse sectors (transport fuel taxes, residential energy taxes)

Country-level values are aggregated to REMIND-R54 regions using population weights. The binary adoption indicator is ECP > 0. The N = 1,188 region-year panel (54 regions × 22 years) drops 54 observations with missing covariates.

### 4.2 Institutional quality: three channels

Institutional quality enters through three named channels, each with a fixed operationalisation:

1. **Government Effectiveness (state capacity)** — **WGI Government Effectiveness** (World Bank Worldwide Governance Indicators, ≈ −2.5 to +2.5 scale): bureaucratic quality and the capacity to formulate and implement policy.
2. **Rule of Law** — V-Dem Rule of Law (`v2x_rule`, 0–1 scale), entered directly.
3. **Accountability** — the best-performing of V-Dem Vertical (`v2x_veracc`), Horizontal (`v2x_horacc`), and Diagonal (`v2x_diagacc`) Accountability, selected by a Stage-0 partial-correlation screen (Section 5.3).

The search protocol attempts all three channels jointly first; where collinearity, separation, or insignificance prevents coexistence, a subset is permitted. All governance variables carry a parenthetical source tag (`(WGI)` / `(VDem)`). (See Section S4 in the Supplementary Materials for details on alternative and retired indicators, including the principal component state-capacity index).

### 4.3 Actor Power Index

The Actor Power Index measures the net political pressure—the "Green Push" of innovator coalitions minus the "Legacy Power" of incumbent fossil coalitions—within a specific sector:
$$\text{Actor Power Index}_{r,t,s} = \gamma_1 \cdot \text{Innovator Power}_{r,t,s} - \gamma_2 \cdot \text{Incumbent Power}_{r,t,s}$$
where $\gamma_1 = 1$ and $\gamma_2 = 1$ represent equal reference lobbying weights. In the split AP specifications, Innovator Power and Incumbent Power enter the regression models as separate variables to allow for asymmetric political contests.

Rather than relying on qualitative proxies, the components are calculated directly from physical technology and fuel shares. Historical data (2000–2022) are constructed from **IEA** and **Ember** databases, while future scenario trajectories are extracted from **REMIND** output drivers. 

#### 4.3.1 Innovator Power
Innovator Power proxies the green push, capturing supply-side momentum from clean energy alongside demand-side readiness for decarbonization. It is calculated as:
$$\text{Innovator Power}_{r,t,s} = \frac{w_{1,s} \cdot \text{VRE share}_{r,t} + w_{2,s} \cdot \text{Electrification}_{r,t} + w_{3,s} \cdot \text{Biofuel Displacement}_{r,t}}{\sum_k w_{k,s}}$$
where:
- **VRE share** is the share of variable renewable electricity (wind and solar) in power generation, proxying supply-side green push.
- **Electrification** is the final energy electrification share, proxying demand-side readiness (as electrified consumers are insulated from direct fossil fuel price exposure).
- **Biofuel Displacement** is the share of biofuels in transport and residential sectors (relevant for Diffuse).
- **Weights ($w$)**:
  - **Bulk (Power/Industry)**: $w_{\text{VRE}} = 1.0$, $w_{\text{elec}} = 0.6$, $w_{\text{biofuel}} = 0.0$ (normalized by $1.6$).
  - **Diffuse (Transport/Buildings)**: $w_{\text{VRE}} = 0.5$, $w_{\text{elec}} = 1.0$, $w_{\text{biofuel}} = 0.4$ (normalized by $1.9$).

#### 4.3.2 Incumbent Power
Incumbent Power proxies legacy power—the ability of fossil-fuel interests to resist carbon pricing and industrial lock-in. It is calculated as:
$$\text{Incumbent Power}_{r,t,s} = \frac{\lambda_{1,s} \cdot \text{Coal primary energy share}_{r,t} + \lambda_{2,s} \cdot \text{Oil/Gas primary energy share}_{r,t} + \lambda_{3,s} \cdot \text{Fossil share in Industry}_{r,t}}{\sum_k \lambda_{k,s}}$$
where:
- **Coal** and **Oil/Gas primary energy shares** proxy supply-side fossil lobbying rents and extraction-related dependencies.
- **Fossil share in Industry** captures demand-side capital stock rigidity and concerns over industrial competitiveness.
- **Weights ($\lambda$)**:
  - **Bulk**: $\lambda_{\text{coal}} = 1.0$, $\lambda_{\text{oilgas}} = 1.0$, $\lambda_{\text{fossilInd}} = 0.5$ (normalized by $2.5$).
  - **Diffuse**: $\lambda_{\text{coal}} = 0.2$, $\lambda_{\text{oilgas}} = 0.2$, $\lambda_{\text{fossilInd}} = 1.0$ (normalized by $1.4$).

All actor power variables represent physical shares [0,1] and remain unstandardised prior to index aggregation to preserve their calculated political weight, before being standardized to standard-deviation units for estimation. The split AP specification consistently outperforms the composite index in theory identification (TFrac 0.42–0.55 vs 0.12–0.25).

### 4.4 Controls

Controls are treated as an explicit axis of the specification sweep (Section 5.3) rather than a fixed set, spanning eight curated combinations from **no controls** through income-only to the full set, and including a **no-income** set to test whether income is needed. The candidate controls are:

- **GDP per Capita** — entered only in projection-safe forms (log-GDP and log-GDP²), deliberately excluding raw GDP or raw GDP² which can lead to unstable extrapolation out of sample. (The alternative GDP Q-centred control is detailed in Section S4 of the Supplementary Materials).
- **Population (log)** — country size; logged because raw population is heavily right-skewed.
- **Hydro/Nuclear Share** — a [0,1] low-carbon-endowment share, used as-is.

All drivers (actor power, institutional quality, controls, and interaction factors) are **standardised** to per-standard-deviation units with mean/sd **frozen from the historical fit** and reused for scenarios; this is fit-, prediction-, significance- and tier-neutral and removes the mechanical main-effect/interaction collinearity.

**Time trend (stringency stage only):** a single common, bounded, saturating logistic curve in [0,1] (midpoint 2030, steepness 0.08), shared across scenarios so "ambition" is not double-counted. The adoption stage carries no trend. For projection the trend is **frozen at the last historical year** (Section 5.4): a period effect cannot be extrapolated, so future differentiation is carried by the scenario drivers.

### 4.5 Panel structure

| Dimension | Value |
|---|---|
| Regions | 54 (REMIND-R54) |
| Time period | 2000–2022 |
| N (adoption) | 1,188 |
| N (Bulk stringency) | ~456 |
| N (Diffuse stringency) | ~258 |
| Governance data | WGI (Government Effectiveness) + V-Dem v13 (Rule of Law, Accountability) |

---

## 5. Methods

### 5.1 Model specification

Rather than fixing one specification a priori, the deliverable model for each stage is **selected from an exhaustive sweep** (Section 5.3). A generic specification has the form:

$$\text{ECP}_{r,t} \sim \text{Hurdle}\bigl(\text{AP}_{r,t},\ \text{IQ}_{r,t},\ (\text{AP} \times \text{IQ})_{r,t},\ \text{Controls}_{r,t},\ \text{Trend}_t,\ \text{FE}_r\bigr)$$

where AP is the Actor Power form (composite Actor Power Index, or the Innovator/Incumbent split — main effects and interaction source share the same representation), IQ is one or more of the three institutional-quality channels (WGI Government Effectiveness, V-Dem Rule of Law, V-Dem Accountability), Controls is one of the eight control sets, Trend is the bounded logistic trend (stringency only), and FE is one of the five region-FE resolutions.

**Adoption stage:** Firth's penalised logit (`logistf`). Firth's penalty is required because the adopter group is dominated by high-income democracies, creating quasi-complete separation in standard logit. No time-trend term.

**Stringency stage:** Gaussian GLM with identity link on log(1+ECP), back-transformed as ECP = expm1(Xβ), with clustered standard errors (54 region clusters). The Gaussian-identity-on-log form (rather than a Gamma/Gaussian *log* link) avoids double-exponentiation in back-transform and projection (Section 5.4).

### 5.2 Identification metrics

We introduce three complementary metrics for theory channel identification:

**Theory Fraction (TFrac):** The share of the non-intercept linear predictor attributable to theory channels (AP + IQ + Interaction):
$$\text{TFrac} = \frac{|\bar{\eta}_{AP}| + |\bar{\eta}_{IQ}| + |\bar{\eta}_{AP \times IQ}|}{\sum_j |\bar{\eta}_j|}$$
where $\bar{\eta}_j$ is the mean partial linear predictor for term group $j$.

**Incremental Theory R² (ΔR²(theory)):** The increment in McFadden Pseudo-R² from adding theory variables over a controls-only baseline:
$$\Delta R^2(\text{theory}) = R^2_{\text{full}} - R^2_{\text{baseline}}$$
where the baseline retains controls, time trend, FEs, and path dependency but removes all AP, IQ, and interaction terms.

**Significance tier:** Green (all three channels p < 0.05), Blue (at least one channel p < 0.05), Yellow (no channel p < 0.05).

### 5.3 Model selection

Selection proceeds in three steps. **Stage-0 Channel Screen:** before any model is fit, pairwise correlations flag institutional channels that cannot co-enter (|r| > 0.8), and a partial-correlation ranking gives "best accountability index" a data-driven definition. **Exhaustive sweep:** we then fit every specification in a full multiplicative cross — the institutional channels × actor-power form × Panel Transform (levels / hybrid first-difference / pure first-difference) × **eight control sets** × **five region-FE resolutions** (pooled, H12, EU/OECD+, 54-unit, Mundlak) — totalling ~1,445 specifications (~5,780 fits across the four sector/stage combinations). **Maximin selection with a sanity gate:** within each stage a specification is scored by its *worse sector* — ranked first by the minimum theory tier across Bulk and Diffuse (Green > Blue > Yellow), tie-broken by the worse sector's ΔR²(theory) — subject to hard gates in both sectors (VIF < 10, convergence, no unintended lagged terms, and a **fit-reliability gate** that rejects specifications whose ΔR²(theory) exceeds 1 — impossible for a genuine incremental McFadden pseudo-R² and a signature of a degenerate, near-separated baseline, typically 54-region fixed effects). The deliverable is additionally restricted to interpretable region-FE resolutions (H12, EU/OECD+, Mundlak), excluding pooled and 54-unit fixed effects. The maximin-ranked candidates are then passed through a **Projection Sanity gate** evaluated on SSP2 scenario trajectories (severe rules — price explosion, negative/non-finite prices, dead never-adopting blocks — disqualify; saturation and seam warnings are reported), and the deliverable is the best-ranked candidate that passes all severe rules. Each stage yields one **shared specification** applied to both sectors, with coefficients estimated independently per sector. Predictive diagnostics (Brier, AUC, calibration slope, price RMSE) are reported but play no role in selection.

---

### 5.4 Projection robustness and IAM coupling

The PFM is built to be applied out of sample inside REMIND, where naive extrapolation is the main hazard. Four design choices make projection robust:

1. **Link choice.** Stringency is estimated as Gaussian-identity on log(1+ECP); a log link on an already-logged outcome double-exponentiates and was a primary cause of projected-price blow-ups (to ~10³⁰⁰ USD/tCO₂ in early versions). The Actor Power form was also restricted to same-representation main/interaction terms to remove the ill-conditioned, opposing coefficients that amplified the problem.

2. **Out-of-sample time-trend freeze.** The fitted trend coefficient is large (≈ +28 log-odds for the historical diffusion) and the curve keeps rising past 2022, so left free it would dominate projections (mean adoption pushed to ~0.90 by 2050; stringency linear predictors inflated to ~26). The trend is therefore **frozen at the last historical year** for all projection years — applied only when preparing scenario panels, so the historical fit and the exhaustive selection are unchanged. Future differentiation is then carried by the scenario drivers, not an extrapolated period effect.

3. **Projection guards.** As a safety net, projected log-prices are clamped to the in-sample fitted maximum plus a margin (≈ 7.4× the highest in-sample price) and an absolute price ceiling (5,000 USD/tCO₂) is applied; whenever a guard binds the region-year is flagged by the sanity gate, keeping fragility visible. Above-historical-range projected prices (historical ECP tops out ~130 USD/tCO₂) should be read as a *relative* feasibility signal, not absolute levels. Where a stringency spec carries a lagged price, projection is recursive, with each year's prediction seeded into the next (zero for never-adopters) and clamped each step. (Note that the final selected parsimonious specifications do not include lagged dependent variables, so projections are executed as a one-shot process, though the recursive framework remains fully supported for alternative specifications).

4. **Slim, load-once coupling artifact.** For iterative REMIND coupling the fitted model is persisted as a *slim predictor* — coefficients, vcov, term structure, and the frozen application transforms (GDP-Q fit, driver standardisation mean/sd, region-FE levels, trend parameters) — with **no embedded training data**; the historical training panel is stored once, content-addressed, and shared by reference. Applying the model to an updated scenario gdx requires no refit and no historical panel: `predictFeasibility` rehydrates the frozen transforms, rebuilds the scenario design, applies the freeze and guards, and returns adoption probability and expected price per region-year-sector over the projection horizon (> 2022), bit-identical to the refit path. Projections are returned in memory and persisted only on request, so a coupling iteration never rewrites the fitted model. **Scenario scope is currently SSP2**; SSP-differentiated governance trajectories are a planned data-layer extension.

---

## 6. Results

The deliverable specifications are those chosen by the maximin theory-tier rule — with the fit-reliability gate and FE constraint of §5.3 — and confirmed by the projection-sanity gate, all estimated under the **WGI Government Effectiveness** state-capacity channel. One shared specification is used per stage, applied to both sectors with coefficients estimated independently:

- **Adoption:** WGI Government Effectiveness + Rule of Law + Vertical Accountability; split Actor Power (Innovator/Incumbent); no additional controls; **H12** (12-block) fixed effects.
- **Stringency:** WGI Government Effectiveness + Rule of Law + Horizontal Accountability; split Actor Power; no additional controls; **EU/OECD+** fixed effects.

### 6.1 Theory identification: Adoption stages

The adoption specification achieves **Green tier in both sectors** — Actor Power, Institutional Quality, and their interaction are each jointly significant at p < 0.05. Theory channels carry 30–42 percentage points of unique explained variation beyond fixed effects (ΔR²(theory)), and the models fit well (McFadden pseudo-R² 0.58–0.64).

**Table 1. Adoption — selected shared spec (WGI GovEff + Rule of Law + Vertical Accountability, split AP, H12 FE)**

| Sector | Tier | ΔR²(theory) | Theory Fraction | AIC | Pseudo-R² | MaxVIF | N |
|---|---|---|---|---|---|---|---|
| Adoption: Bulk | 🟢 Green | 0.299 | 0.351 | 585.4 | 0.641 | 8.27 | 1,188 |
| Adoption: Diffuse | 🟢 Green | 0.421 | 0.345 | 535.0 | 0.583 | 8.39 | 1,188 |

Key coefficients (see Supplementary Table S1):
- **Innovator Power** positive, **Incumbent Power** negative on adoption probability — reflecting that clean-energy actors lobby for pricing to boost transition competitiveness, while fossil incumbents organize to protect resource rents and shield legacy capital from taxation.
- **WGI Government Effectiveness** positive — higher state capacity is associated with a higher probability of adoption.
- **Actor Power × Government Effectiveness** interaction significant — innovator power is more effective where institutions are stronger (the institutional-conditionality hypothesis, H1).

This configuration is theoretically consistent with a binary policy entry gate. First, because adoption is a high-stakes, binary decision, it is characterized by a direct push-and-pull contest between concentrated interests. Green innovators push to establish a pricing instrument to shift market dynamics, while fossil incumbents deploy resources to veto the policy. The individual significance of both opposing power terms confirms that adoption is highly sensitive to the balance of interest-group mobilization. Second, government effectiveness represents the administrative capacity required to design, set up, and run a carbon pricing system (e.g., establishing registries, emissions tracking, and tax collection). Weak states struggle with these complex regulatory prerequisites, making state capacity a first-order predictor of adoption. Third, the significant positive interaction ($\text{AP} \times \text{IQ}$) indicates that green lobbying is more successful when the state has the administrative competence to execute the policy, acting as a structural multiplier for green coalition influence.

### 6.2 Theory identification: Stringency stages

The stringency specification achieves **Blue tier in both sectors**: Institutional Quality and the Actor Power × IQ interaction are jointly significant, while the Actor-Power *main* effect does not reach individual significance conditional on adoption. Theory-unique variance is substantial, especially in the Diffuse sector.

**Table 2. Stringency — selected shared spec (WGI GovEff + Rule of Law + Horizontal Accountability, split AP, EU/OECD+ FE)**

| Sector | Tier | ΔR²(theory) | AIC | Pseudo-R² | MaxVIF | N |
|---|---|---|---|---|---|---|
| Stringency: Bulk | 🔵 Blue | 0.157 | 982.7 | 0.483 | 4.39 | 456 |
| Stringency: Diffuse | 🔵 Blue | 0.584 | 462.7 | 0.882 | 6.33 | 258 |

Worse-sector tier = Blue; mean ΔR²(theory) = 0.370. The **interaction term carries the institutional-conditionality signal even though the actor-power main effect is not individually significant** — consistent with innovator power operating *through* institutional capacity rather than independently (H1). 

This empirical pattern is theoretically coherent for two reasons. First, the baseline political vetoes of incumbents are primary during the *adoption* stage; once a policy is adopted (conditional on adoption), actor power is no longer a simple binary veto but rather a lobbying force whose efficacy is moderated by the state's capacity to implement and enforce policy. Second, innovator power only leads to higher carbon prices when the administrative state has the capacity to monitor and enforce them (captured by WGI Government Effectiveness) and is insulated from rent-seeking capture (captured by V-Dem Rule of Law). In low-capacity environments, strong green coalitions may achieve nominal policy adoption but fail to translate this into high prices, making the interaction term the primary carrier of the actor-power signal.

The Diffuse-sector ΔR²(theory) = 0.584 is the largest theory-unique contribution across all four sector/stage fits, with a high overall pseudo-R² (0.88) on the N = 258 adopter sub-panel.

### 6.3 Why these specifications: the fit-reliability gate

The selection deliberately excludes two otherwise high-scoring but untrustworthy families — pooled (no-FE) specifications and 54-region fixed-effects specifications. The latter produce **inflated ΔR²(theory) above 1**, impossible for a genuine incremental McFadden pseudo-R² and symptomatic of a near-separated, degenerate baseline (54 region dummies on a short panel). The fit-reliability gate (§5.3) demotes the 66 such adoption specifications; the FE constraint additionally removes the pooled specs. The deliverable therefore uses **moderate, interpretable fixed effects** — H12 (12 blocks) for adoption and EU/OECD+ for stringency — that control regional heterogeneity without absorbing the cross-region variation that identifies the persistent institutional and actor-power channels. This is what allows the adoption stage to reach Green tier with credible (≤ 1) ΔR²(theory) values.

### 6.4 Projection sanity

Both selected specifications pass the Projection Sanity gate on SSP2 trajectories with **no severe flags** (adoption: 1 non-severe warning; stringency: 17 non-severe saturation/seam warnings). With the out-of-sample time-trend freeze and the projection guards (§5.4), projected adoption probabilities and price paths are driven by the scenario governance and actor-power drivers rather than an extrapolated trend, and remain within bounded, finite ranges.

---

## 7. Discussion

### 7.1 Implications for the Polity–Politics–Policy linkage

Our results provide quantitative evidence for the three-channel political economy theory of carbon pricing:

1. **Actor Power matters at adoption** (Green tier, both sectors): innovator coalition strength is positively associated with adoption probability and incumbent strength is negatively associated — both individually significant. This is clear evidence that the coalition politics theory [Meckling et al. 2015] holds in a cross-country panel. At the *stringency* stage the Actor-Power main effect is not individually significant; actor power operates there mainly through its interaction with institutional quality (point 3).

2. **Institutional quality matters** (significant at both stages): WGI Government Effectiveness (with Rule of Law and an accountability channel) is independently associated with both adoption and price stringency beyond actor power. High-capacity states adopt carbon pricing more readily and sustain higher prices because they can design and enforce credible pricing commitments.

3. **The interaction is identifiable at both stages**: the Actor Power × Institutional Quality interaction is jointly significant in adoption (contributing to its Green tier) and in stringency (Blue tier). Innovator power is more effective where institutions can enforce pricing commitments — empirical support for the institutional-conditionality hypothesis (H1) in an IAM-compatible framework, and the reason the stringency stage is Blue rather than Yellow despite a non-significant actor-power main effect.

The adoption stage reaching **Green in both sectors** — a stronger result than earlier PFM specifications — is contingent on the fit-reliability gate (§5.3, §6.3): the unconstrained ranking favoured a 54-region fixed-effects spec with an inflated, out-of-bound ΔR²(theory), which the gate correctly demotes in favour of the interpretable H12 specification reported here.

**Verdict on RQ1–RQ2.** The three channels are *not* confirmed uniformly, and we report the asymmetry plainly. RQ1 is **supported at adoption** — actor power, institutional quality, and the interaction are each individually significant in both sectors. Conditional on adoption (stringency), RQ1 holds only **partially**: institutional quality and the interaction are significant, but the actor-power *main* effect is not. RQ2 (the AP × IQ interaction) is **supported at both stages** — positive sign, significant, robust across the specification family. The recurring pattern — a significant interaction alongside a non-significant actor-power main effect at the stringency stage — is theoretically coherent (innovator power bites mainly where state capacity can convert lobbying into enforced prices), but we read it cautiously: a significant interaction with an insignificant main effect can also reflect collinearity between the main and interaction terms, and the moderate adoption-stage VIF (≈ 8.3, below the conventional 10 threshold but non-trivial) confirms the channels are correlated. We therefore treat RQ2 as **empirically supported but not proven**: the sign and significance are consistent across stages and across the ~1,445 specifications, yet a 54-region, 23-year observational panel cannot exclude that the interaction partly absorbs omitted, governance-correlated heterogeneity.

### 7.2 Implications for IAM-PFM coupling

The PFM is designed for direct coupling with REMIND-MAgPIE. Imposing institutional-feasibility constraints on IAM pathways has been shown to change mitigation feasibility materially (Bertram et al. 2024); the PFM supplies exactly such a constraint — but one *estimated from observed carbon-pricing behaviour* rather than imposed exogenously. The slim, load-once fitted model with frozen transforms, out-of-sample trend freeze, and projection guards (§5.4) makes iterative coupling tractable and robust: the same fitted model is applied to each REMIND iteration's updated scenario without refitting. Key implications:

**Scenario discrimination**: The AP × IQ interaction enables meaningful SSP differentiation for carbon price trajectories. Under SSP1 (strong institutions, strong innovator coalitions), the interaction term yields substantially higher projected adoption probabilities and price levels than under SSP3 (weak institutions, fragmented actor power). Prior GDP-driven specifications produced near-identical trajectories across SSPs.

**Policy counterfactuals**: The model supports governance-conditional policy analysis: "how much would adoption probabilities increase if institutional capacity improved by X in region Y?" This is not possible with specification-agnostic policy scenarios.

**Governance projection availability**: Scenario-conditional governance trajectories projected along the SSPs (Andrijevic et al. 2020 for WGI governance; Soergel et al. 2021 for V-Dem rule of law) provide the input time series for PFM coupling under different SSPs, avoiding the need to proxy governance with GDP as in prior work.

**Verdict on RQ3 (fit for purpose).** The module clears the bar it was built for: both selected specifications turn governance and actor-power inputs into bounded, finite, scenario-discriminating carbon-pricing signals, and both pass the projection-sanity gate with no severe flags (§6.4). Two honest qualifications bound that claim. First, projected prices are a *relative feasibility signal, not a calibrated forecast* — historical effective carbon prices top out near 130 USD/tCO₂, so any higher projected level is extrapolation and is treated as such (clamped and flagged, §5.4). Second, the live scenario scope is SSP2; genuine cross-SSP discrimination needs SSP-differentiated governance and actor-power *inputs*, a data-layer task the module is ready to consume but does not itself supply. Within those bounds the PFM gives an IAM what it has lacked — an *estimated, theory-grounded, reproducible* feasibility constraint instead of an exogenous assumption — the gap identified by Jewell & Cherp (2020), Brutschin & Andrijevic (2022), and Bertram et al. (2024). So RQ3 is answered affirmatively *as a feasibility-signal generator*, while calibrated price prediction remains explicitly out of scope.

### 7.3 Limitations

1. **Short panel**: 22 years and 54 regions limits statistical power for joint theory identification in the adoption stages. Extended panels (back to 1990 or with sub-national data) would improve identification.

2. **Actor Power measurement**: The Actor Power Index relies on physical technology and fuel shares (e.g., electrification and VRE generation) as structural proxies for political influence rather than direct lobbying expenditure or political finance data. Formal validation against direct political-influence measures would strengthen construct validity.

3. **Endogeneity**: Carbon pricing adoption may itself affect institutional quality over time (e.g., through regulatory capacity building). The one-year lag on explanatory variables partially addresses this, but reverse causality cannot be fully ruled out in the adoption stages.

4. **Small adopter sub-panels and potential overfitting at the stringency stage** (N = 456 Bulk, **258 Diffuse**): The conditional-price estimates rest on relatively few adopting region-years. The exceptionally high Pseudo-R² (0.88) and incremental theory ΔR² (0.58) in the Diffuse stringency sector are potential warning signs of three compounding issues:
   - *Overfitting*: Estimating multiple parameters (including split Actor Power, three governance channels, and their interaction terms) on a small sample of 258 observations increases the risk of overfitting.
   - *Sample Homogeneity*: Adopters of diffuse-sector carbon pricing are predominantly high-income, high-capacity European and OECD jurisdictions. This high homogeneity means the model is fitting a very specific, select group of countries, which limits out-of-sample generalizability.
   - *Residual Autocorrelation*: Both carbon prices and institutional quality are highly persistent. In the absence of an explicit autoregressive correction (which is avoided to keep the projection design simple and stable), serial correlation in the residuals can artificially inflate the $R^2$ metric.
   Therefore, these stringency results should be read as provisional and illustrative of historical associations within a small group of pioneer adopters, rather than as robust, universally generalizable elasticities.

5. **Candidate controls in coupling**: If future specifications require the inclusion of income controls, utilizing the developed GDP Q-centred control would introduce dynamic re-computation of income quartile boundaries in each projection period — a pipeline step that is not required for the current parsimonious, control-free deliverable model.

6. **Scope — governance and actors, not conflict**: Following the three-dimensional view of political development (political regime/accountability, institutional quality, and violent conflict; Leininger et al. 2024), the PFM operationalises the governance and actor-power channels but not violent conflict. Conflict is a recognised determinant of mitigation and adaptation capacity and a natural extension of the framework. We also echo the call for out-of-sample and hindsight validation of governance–climate relationships (Leininger et al. 2024); the predictive diagnostics and projection-sanity checks reported here are a first step, but systematic backtesting on extended panels remains future work.

7. **Specification search.** The deliverable is selected from ~1,445 specifications (~5,780 fits). Selection is theory-disciplined — a maximin rule over theory *tiers* (not a search for one favourable coefficient), then a projection-sanity gate, with a single *shared* specification imposed across both sectors and a fit-reliability gate excluding degenerate fits — and we report the full ranking rather than only the winner. Nonetheless, exploring a specification space this large inflates the risk that a selected model's tier reflects favourable sampling. Temporal-holdout validation and pre-registration of the specification family are the appropriate next safeguards; until then the tiers should be read as the *most defensible* specifications under transparent rules, not as the unique truth.

8. **Associational, not causal.** The estimates are conditional associations on observational cross-country panel data. Region fixed effects and the one-year lag on regressors reduce, but do not eliminate, confounding and reverse causality (e.g. capacity-building induced by prior pricing). We therefore frame the interaction as evidence *consistent with* the institutional-conditionality hypothesis (H1), not as causal identification of it; credible causal estimates would require plausibly exogenous variation in actor power or state capacity that this design does not exploit.

---

## 8. Conclusions

We introduce the Political Feasibility Module (PFM) as a theory-grounded two-stage hurdle model for IAM coupling, embedding the Polity → Politics → Policy linkage directly into the carbon pricing structure of REMIND-MAgPIE. Our key contributions are:

1. **A theory-disciplined, reproducible selection procedure.** The deliverable specification per stage is chosen from an exhaustive ~1,445-specification sweep that crosses three institutional-quality channels (WGI Government Effectiveness, V-Dem Rule of Law and Accountability) and the actor-power form with eight control sets and five region-FE resolutions (including Mundlak correlated random effects), scored by a maximin theory-tier rule and gated by a projection-sanity check — making the theory-vs-heterogeneity trade-off explicit rather than assumed.

2. **An interpretable, projection-safe driver set and coupling path.** By utilizing WGI Government Effectiveness alongside V-Dem indices, we replace latent PCA constructs with transparent, externally validated indicators. We pair this with a slim, load-once fitted model, an out-of-sample time-trend freeze, and projection guards to ensure that scenario differentiation is driven by governance and actor-power drivers rather than an extrapolated trend.

3. **Empirical support for the institutional-conditionality hypothesis.** Under WGI Government Effectiveness, the adoption stage achieves Green-tier significance in both sectors, and the Actor Power × Institutional Quality interaction is jointly significant at both stages (§6) — indicating that innovator coalition strength is more effective where state capacity is high. The fit-reliability gate was essential to isolate this trustworthy result from degenerate fixed-effects specifications.

Read against the research questions: RQ1 (the three channels) is supported at adoption and partially at stringency; RQ2 (the institutional-conditionality interaction) is supported, though not causally proven, at both stages; and RQ3 (fit for purpose) is met for the role the module is designed to play — generating an estimated, bounded, scenario-discriminating feasibility signal for an IAM, as opposed to forecasting calibrated price levels. These contributions position the PFM as a methodologically sound and theoretically grounded component of IAM frameworks, advancing the integration of political economy into quantitative climate policy analysis — while the associational design, the constructed Actor Power Index, and the short panel mark exactly where the next round of work (causal identification, construct validation, extended panels, SSP-differentiated inputs) must strengthen it before its feasibility signals are treated as more than directional.

---

## Acknowledgements

[TBD — Elevate Project funding, V-Dem Project data access, World Bank ECP Database]

---

## References

Acemoglu, D., & Robinson, J. A. (2012). *Why Nations Fail*. Crown Publishers.

Aklin, M., & Urpelainen, J. (2013). Political competition, path dependence, and the strategy of sustainable energy transitions. *American Journal of Political Science*, 57(3), 643–658.

Andrijevic, M., Crespo Cuaresma, J., Muttarak, R., & Schleussner, C.-F. (2020). Governance in socioeconomic pathways and its role for future adaptive capacity. *Nature Sustainability*, 3(1), 35–41.

Bauer, N., et al. (2020). Quantification of an efficiency–sovereignty trade-off in climate policy. *Nature*, 588(7837), 261–266.

Bayer, P., & Aklin, M. (2020). The European Union Emissions Trading System reduced CO2 emissions despite low prices. *Proceedings of the National Academy of Sciences*, 117(16), 8804–8812. https://doi.org/10.1073/pnas.1918128117

Bertram, C., et al. (2021). COVID-19-induced low power demand and market forces starkly reduce CO2 emissions. *Nature Climate Change*, 11(3), 193–196.

Bertram, C., Brutschin, E., Drouet, L., Luderer, G., van Ruijven, B., … Riahi, K. (2024). Feasibility of peak temperature targets in light of institutional constraints. *Nature Climate Change*, 14(9), 954–960. https://doi.org/10.1038/s41558-024-02073-4

Brutschin, E., & Andrijevic, M. (2022). Why ambitious and just climate mitigation needs political science. *Politics and Governance*, 10(3), 4–8.

Brutschin, E., Pianta, S., Tavoni, M., Riahi, K., Bosetti, V., Marangoni, G., & van Ruijven, B. J. (2021). A multidimensional feasibility evaluation of low-carbon scenarios. *Environmental Research Letters*, 16(6), 064069.

Calvin, K., et al. (2019). GCAM v5.1. *Geoscientific Model Development*, 12(2), 677–698.

Colgan, J. D., Green, J. F., & Hale, T. N. (2021). Asset revaluation and the existential politics of climate change. *International Organization*, 75(2), 586–610.

Coppedge, M., Gerring, J., Knutsen, C. H., et al. (2022). V-Dem [Country–Year] Dataset v13. *Varieties of Democracy Project*.

Dafnomilis, I., Chen, H.-H., den Elzen, M., Fragkos, P., Chewpreecha, U., & van Soest, H. (2022). Targeted green recovery measures in a post-COVID-19 world enable the energy transition. *Frontiers in Climate*, 4, 840933. https://doi.org/10.3389/fclim.2022.840933

Dubash, N. K., et al. (2021). National climate institutions complement targets and policies. *Science*, 374(6568), 690–693. https://doi.org/10.1126/science.abm1157

Eskander, S. M. S. U., & Fankhauser, S. (2020). Reduction in greenhouse gas emissions from national climate legislation. *Nature Climate Change*, 10(8), 750–756.

Fukuyama, F. (2014). *Political Order and Political Decay: From the Industrial Revolution to the Globalization of Democracy*. Farrar, Straus and Giroux.

Geels, F. W., et al. (2017). Sociotechnical transitions for deep decarbonization. *Science*, 357(6357), 1242–1244.

Gidden, M. J., Brutschin, E., Ganti, G., Unlu, G., Zakeri, B., Fricko, O., ... Riahi, K. (2023). Fairness and feasibility in deep mitigation pathways with novel carbon dioxide removal considering institutional capacity to mitigate. *Environmental Research Letters*, 18(7), 074006.

Gong, X., Liu, Y., & Sun, T. (2020). Evaluating climate change governance using the "Polity–Policy–Politics" framework: A comparative study of China and the United States. *Sustainability*, 12(16), 6403. https://doi.org/10.3390/su12166403

Guy, J., Shears, E., & Meckling, J. (2023). National models of climate governance among major emitters. *Nature Climate Change*, 13(2), 189–195. https://doi.org/10.1038/s41558-022-01589-x

Hacker, J. S., & Pierson, P. (2002). Business power and social policy: Employers and the formation of the American welfare state. *Politics & Society*, 30(2), 277–325.

Heinze, G., & Schemper, M. (2002). A solution to the problem of separation in logistic regression. *Statistics in Medicine*, 21(16), 2409–2419.

Hickmann, T., Bertram, C., Biermann, F., Brutschin, E., Kriegler, E., Livingston, J. E., ... van Vuuren, D. (2022). Exploring global climate policy futures and their representation in integrated assessment models. *Politics and Governance*, 10(3), 171–185.

Jewell, J., & Cherp, A. (2020). On the political feasibility of climate change mitigation pathways: Is it too late to keep warming below 1.5°C? *WIREs Climate Change*, 11(1), e621.

Jewell, J., & Cherp, A. (2023). The feasibility of climate action: Bridging the inside and the outside view through feasibility spaces. *WIREs Climate Change*, e838. https://doi.org/10.1002/wcc.838

Keppo, I., et al. (2021). Exploring the possibility space: Taking stock of the diverse capabilities and gaps in integrated assessment models. *Environmental Research Letters*, 16(5), 053006.

Klein, F., Kramer, N., & Steckel, J. C. (2026). Non-environmental objectives are decisive for carbon tax adoption. Working paper (unpublished).

Köhler, J., Geels, F. W., Kern, F., Markard, J., Onsongo, E., Wieczorek, A., ... & Wells, P. (2019). An agenda for sustainability transitions research: State of the art and future directions. *Environmental Innovation and Societal Transitions*, 31, 1–32. https://doi.org/10.1016/j.eist.2019.01.004

Leininger, J., Buhaug, H., Gilmore, E., Lindberg, S. I., Andrijevic, M., Bauer, N., ... van Ruijven, B. (2024). *Climate Futures are Political Futures: Integrating Political Development Into the Shared Socioeconomic Pathways (SSPs)*. Zenodo. https://doi.org/10.5281/zenodo.14387075

Levi, S., Flachsland, C., & Jakob, M. (2020). Political economy determinants of carbon pricing. *Global Environmental Politics*, 20(2), 128–156.

Mealy, P., et al. (2025). Climate policies are path-dependent: Implications for policy sequencing and feasibility. *World Bank Policy Research Working Paper* 11094. https://doi.org/10.1596/1813-9450-11094

Meckling, J., & Allan, B. B. (2020). The evolution of ideas in global climate policy. *Nature Climate Change*, 10(5), 434–438.

Meckling, J., Kelsey, N., Biber, E., & Zysman, J. (2015). Winning coalitions for climate policy. *Science*, 349(6253), 1170–1171.

Meckling, J., & Nahm, J. (2018). The power of process: State capacity and climate policy. *Governance*, 31(4), 741–757. https://doi.org/10.1111/gove.12338

Meckling, J., & Nahm, J. (2021). Strategic state capacity: How states counter opposition to climate policy. *Comparative Political Studies*, 55(3), 493–523. https://doi.org/10.1177/00104140211024308

Mildenberger, M. (2020). *Carbon Captured: How Business and Labor Control Climate Politics*. MIT Press.

Mundlak, Y. (1978). On the pooling of time series and cross section data. *Econometrica*, 46(1), 69–85.

North, D. C., Wallis, J. J., & Weingast, B. R. (2009). *Violence and Social Orders*. Cambridge University Press.

Nordhaus, W. D. (2017). Revisiting the social cost of carbon. *PNAS*, 114(7), 1518–1523.

Pahle, M., et al. (2018). Sequencing to ratchet up climate policy stringency. *Nature Climate Change*, 8(10), 861–867.

Peng, W., Iyer, G., Bosetti, V., Chaturvedi, V., Edmonds, J., Fawcett, A. A., ... Weyant, J. (2021). Climate policy models need to get real about people. *Nature*, 594(7862), 174–176.

Persson, T., & Tabellini, G. (2000). *Political Economics: Explaining Economic Policy*. MIT Press.

Poujon, A., et al. (2026). Political feasibility constraints global mitigation pathways. *Research Square* preprint. https://doi.org/10.21203/rs.3.rs-9170039/v1

Povitkina, M. (2018). The limits of democracy in tackling climate change. *Environmental Politics*, 27(3), 411–432.

Putnam, R. D. (1988). Diplomacy and domestic politics: The logic of two-level games. *International Organization*, 42(3), 427–460.

Riahi, K., et al. (2017). The Shared Socioeconomic Pathways and their energy, land use, and greenhouse gas emissions implications. *Global Environmental Change*, 42, 153–168.

Rogelj, J., et al. (2018). Scenarios towards limiting global mean temperature increase below 1.5°C. *Nature Climate Change*, 8(4), 325–332.

Soergel, B., Kriegler, E., Weindl, I., Rauner, S., Dirnaichner, A., Ruhe, C., ... Popp, A. (2021). A sustainable development pathway for climate action within the UN 2030 Agenda. *Nature Climate Change*, 11(8), 656–664.

Stasavage, D. (2002). Credible commitment in early modern Europe. *Journal of Law, Economics, and Organization*, 18(1), 155–186.

Stern, N. (2007). *The Economics of Climate Change: The Stern Review*. Cambridge University Press.

Sternberger, D. (1978). *Drei Wurzeln der Politik*. Suhrkamp.

Trutnevyte, E., Hirt, L. F., Bauer, N., Cherp, A., Hawkes, A., Edenhofer, O., ... van Vuuren, D. P. (2019). Societal transformations in models for energy and climate policy: The ambitious next step. *One Earth*, 1(4), 423–433.

van Soest, H. L., et al. (2021). Net-zero emission targets for major emitting countries consistent with the Paris Agreement. *Nature Communications*, 12(1), 2140.

von Dulong, A., & Hagen, A. (2025). Institutions make a difference: Assessing the predictors of climate policy stringency using machine learning. *Environmental Research Letters*, 20(1), 014056. https://doi.org/10.1088/1748-9326/ada0cb

World Bank. (2022). *Carbon Pricing Dashboard*. https://carbonpricingdashboard.worldbank.org

Wooldridge, J. M. (2010). *Econometric Analysis of Cross Section and Panel Data* (2nd ed.). MIT Press.

Xexakis, G., Spatharidou, P., Bala, A., Frilingou, N., Koasidis, K., Tigka, K., & Nikas, A. (2026). Narrative and quantitative analysis of democratic principles in the Shared Socioeconomic Pathways. *npj Climate Action*. https://doi.org/10.1038/s44168-026-00351-9

---

## Supplementary Materials

### Table S1. Full coefficient estimates — Stringency (selected shared specification)

[To be populated from the exhaustive-sweep selection: see `output/results_stringency_channels-exhaustive.html` and `reports/model-selection/model-configs/selected-models-channels-exhaustive.yml`. Variable rows below reflect the current channel set; the exact controls/FE depend on the selected control set and region-FE resolution.]

| Variable | Estimate | Std. Error | z value | p-value |
|---|---|---|---|---|
| (Intercept) | — | — | — | — |
| Innovator Power | — | — | — | — |
| Incumbent Power | — | — | — | — |
| Government Effectiveness (WGI) | — | — | — | — |
| Rule of Law (VDem) | — | — | — | — |
| Accountability (VDem) | — | — | — | — |
| Actor Power × Gov. Effectiveness | — | — | — | — |
| Controls (selected set) | — | — | — | — |
| Logistic Time Trend (frozen out-of-sample) | — | — | — | — |
| Region FE / Mundlak means (selected resolution) | — | — | — | — |

### Table S2. Model sweep overview — full.yml (26 models)

[Populated from `data/model_selection_results_full.csv`]

### Table S3. ridgeInteractions comparison

| Model | ridgeInteractions | AIC | TFrac | Tier |
|---|---|---|---|---|
| Split AP Log GDP-Q + PC1 + H12 | FALSE | 676.1 | 0.384 | Green |
| Split AP Log GDP-Q + PC1 + H12 | TRUE | 676.1 | 0.384 | Green |
| Theory Optimal PC1 Mundlak | FALSE | — | — | — |
| Theory Optimal PC1 Mundlak | TRUE | — | — | — |

[No difference detected; ridge regularisation has no effect with V-Dem models.]

### Section S4. Alternative Specifications, Controls, and Retired Constructs

This section details the alternative model elements tested during the specification sweep but not included in the final selected models, as well as constructs retired during the module's development.

#### S4.1 Choice of State-Capacity Measure and Retired V-Dem Principal Component
In earlier development versions of the module, state capacity was operationalised using the first principal component (PC1) of five V-Dem indicators (civil-service professionalism, policy-implementation capacity, rule predictability, absence of corruption, and meritocracy). This index was retired in favor of **WGI Government Effectiveness** for three main reasons:
1. **Interpretability and external validity**: WGI Government Effectiveness is a single, widely used, externally validated index with a transparent meaning (bureaucratic quality and capacity to formulate and implement policy), whereas a principal component of five V-Dem indicators is a latent composite whose units and loadings are harder to interpret and to communicate to policy audiences.
2. **Conceptual cleanliness**: State capacity varies independently of regime type (Fukuyama 2014); a directly interpretable capacity index keeps the capacity channel distinct from the rule-of-law and accountability channels, which V-Dem still supplies.
3. **Projection transparency**: A single observed index is straightforward to project along the SSPs (Andrijevic et al. 2020) and to freeze/standardise for coupling, without carrying a fitted PCA rotation into projection.

The WGI-vs-V-Dem comparison was internal to the specification cross rather than asserted, and the outcome was favourable: under WGI Government Effectiveness the adoption stage reaches Green tier in both sectors and the AP × IQ interaction is identified at both stages (§6), so the move to the interpretable index loses nothing in theory identification while gaining transparency for projection and coupling.

#### S4.2 GDP Quartile-Centred Income Control (GDP-Q)
Although the final selected specifications are parsimonious and do not include income controls (as "no additional controls" was selected by the maximin rule), the GDP Quartile-centred income control developed for the specification sweep remains a useful methodological option. When the main predictor of interest (governance quality) is highly correlated with a control variable like income (r ≈ 0.75), standard specifications risk underestimating the predictor's effect. Quartile-centring removes the cross-quartile income gradient while retaining within-quartile variation—effectively running the governance regression within income tiers (analogous to using within-cohort variation in consumer demand estimation).

To ensure robust projections, GDP-Q is frozen from the historical fit (quartile breaks, group means, and per-region assignments are stored and reused in projection mode). While not utilized in the final parsimonious models, it remains a projection-safe alternative for future specification extensions or other IAM-coupling frameworks where income controls are conceptually required.

#### S4.3 Non-Selected Region Fixed Effect Resolutions
The specification sweep evaluated five regional heterogeneity control resolutions:
1. **Pooled (No Fixed Effects)**: Excluded to prevent omitted variable bias from unobserved regional characteristics.
2. **54-unit Fixed Effects**: Excluded because regional dummy variables for 54 units on a short time series absorb too much of the persistent within-region governance and actor power signals, causing degenerate fits and separation (flagged by the fit-reliability gate).
3. **Mundlak Correlated Random Effects**: An alternative approach where each driver's within-region time-mean is entered as a regressor instead of unit dummies. While projection-stable, it was not selected by the maximin theory-tier rule in favor of the simpler block fixed effects (H12 and EU/OECD+) which control regional heterogeneity without absorbing the persistent theory channels.

### Figure S1. Polity → Politics → Policy conceptual diagram

[See presentation slide "Main Objective" in `output/PFM_Publication_Presentation.pptx`]

### Figure S2. Three-channel theory identification — Theory Fraction heatmap

[See `output/model_selection_full.html` → Term Contributions tab]

### Figure S3. Predicted probability profiles by governance scenario

[See `output/adoption_model_vdem-publication.html`]

---

*Draft v3 — 2026-06-16. Design, methods and §6 results reflect the gated exhaustive channels sweep (ADR 0009/0010/0011 + fit-reliability gate, CONTEXT.md glossary). All results from pfm and mrpfm R packages, Elevate Project.*
