# MACAESA Resiliency Assessment: Agent-Assisted ROI and Telemetry Report

> Example report. Cost is measured from an actual run (Session Cost 5544.6 credits). Timing,
> quality, and manual-baseline figures are illustrative placeholders. Replace them with measured
> values before sharing, and have a qualified engineer or finance reviewer validate every headline
> metric.

- **Repository:** MACAESA
- **Execution mode:** Mode A (interactive)
- **Model:** Claude Opus 4.8 High
- **Date:** 2026-07-15
- **Session Cost:** 5544.6 credits ($55.45 at $0.01 per credit)

## 1. Executive Summary

> The agent-assisted resiliency assessment reduced analyst time by **76.1 percent** and cut cost
> per assessment by **93.2 percent**, saving roughly **$4,697** on this run while holding quality
> slightly above the manual baseline.

- **Time saved:** 7.17 agent human hours versus 30 manual hours (Confidence Medium).
- **Cost reduction:** $342.95 versus $5,040 per assessment (Confidence Medium).
- **Quality differential:** weighted **91.7 of 100** versus **88 of 100**, a **+3.7 point** improvement (Confidence Medium).
- **Recommendation:** Continue and expand. Cost is dominated by human oversight ($287.50), not model spend ($55.45).

> Financial impact: at the expected 12 assessments over 12 months, projected annual savings are
> approximately **$56,365**, or roughly **$169,094** over three years.

## 2. Methodology and Baseline Definition

- **Baseline:** Single senior engineer, analysis-only assessment, estimated at 30 hours with 12 percent rework at $150 per hour. Estimated, Confidence Medium.
- **Comparison scope:** Repository MACAESA, Mode A (interactive), Claude Opus 4.8 High, covering the in-scope Azure services identified in Phase 1.
- **Agent effort** is active work time plus human oversight, so review effort is not hidden.
- **Cost assumption:** 1 GitHub AI Credit = $0.01 USD. Measured Session Cost = 5544.6 credits = $55.45.

> Caveat: Baseline estimated; recommend collecting measured baseline data on the next engagement for calibration.

## 3. Results Dashboard

| Metric | Agent-Assisted | Manual Baseline | Improvement |
|---|---|---|---|
| Total human hours | **7.17** | **30** | **76.1 percent faster** |
| Weighted quality score | **91.7 of 100** | **88 of 100** | **+3.7 points** |
| Errors and rework | **2 corrections** | **12 percent rework** | Materially lower |
| Cost per assessment | **$342.95** | **$5,040** | **93.2 percent reduction** |

Elapsed wall-clock time was 8.5 calendar hours (including 3.25 hours of pauses across 10 pause
events), reported separately from the 7.17 active-plus-oversight hours.

## 4. Detailed Cost-Benefit Analysis

Agent-side cost:

| Component | Amount |
|---|---|
| Model cost (5544.6 credits x $0.01) | **$55.45** |
| Human oversight (1.92 hrs x $150) | **$287.50** |
| **Total agent cost** | **$342.95** |

> The per-stage credit split was not separately captured (single final Session Cost reading).
> Oversight by phase: Research 0.75 hr, Planning 0.50 hr, Assessment 0.67 hr.

- **Manual baseline cost:** 30 hrs x $150 x 1.12 rework = $5,040.
- **Per-assessment savings:** $4,697.05.

Scaling scenarios (annual):

| Scenario | Assessments | Annual savings |
|---|---|---|
| Conservative (-30 percent) | 8.4 | ~$39,455 |
| Base case (horizon) | 12 | ~$56,365 |
| Optimistic (+50 percent) | 18 | ~$84,547 |
| Sensitivity: +50 percent model cost | 12 | ~$56,032 |

> Even at +50 percent model cost, annual savings move by roughly $333. The ROI is robust to
> credit-price changes because model spend is small next to human time.

## 5. Quality and Reliability Evidence

| Phase | Score | Evidence fidelity (35) | Completeness (25) | Correctness (25) | Consistency (15) |
|---|---|---|---|---|---|
| Research | 92 | 33 | 24 | 21 | 14 |
| Planning | 90 | 32 | 23 | 21 | 14 |
| Assessment | 93 | 34 | 24 | 22 | 13 |

- **Weighted quality:** 92(0.25) + 90(0.35) + 93(0.40) = **91.7 of 100**.
- **Evidence fidelity:** findings cite file and line references; no fabricated citations were found on review.
- **Errors:** 2 corrections versus a 12 percent baseline rework rate.

> Quality was maintained and slightly improved while time and cost fell sharply.

## 6. Risk Assessment and Mitigation

- **Caveat - Model and credit-pricing dependency:** cost scales with GitHub credit pricing and model choice. Mitigation: model cost is a small share of total, so exposure is low.
- **Caveat - Quality degradation at scale:** single-run quality may not hold across a portfolio. Mitigation: continuous scoring against the rubric on every run.
- **Caveat - Evidence fabrication risk:** AI output can invent citations. Mitigation: evidence-lock-in rules plus the mandatory qualified-engineer review gate.
- **Decision Point - Review gate:** a qualified engineer must validate all findings before implementation.

## 7. Scaling and Sustainability

- **Growth Opportunity:** at 12 assessments per year, the workflow returns roughly $56,365 per year in analyst time against modest model spend.
- **Team impact:** shifts senior engineers from first-pass analysis to review and judgment, raising throughput without added headcount.
- **Expansion:** apply to more repositories and services; Phase 2 cost scales with in-scope service count, not lines of code.
- **Continuous improvement:** feed rubric scores back into prompt and instruction tuning each engagement.

## 8. Recommendations and Next Steps

- **Primary recommendation:** Continue and expand to the next 2-3 repositories.
- **Success criteria for next engagement:** collect a measured baseline, keep weighted quality at or above 90, keep corrections at or below 2 per run.
- **Resourcing and budget:** model budget under $60 per run at current pricing; reserve senior-engineer time (~2 hours per run) for the review gate.
- **Timeline and owner:** re-review after the next 3 runs; assign a workflow owner to maintain the tracker and telemetry inputs.

> Confidence Medium overall: cost is measured (5544.6 credits), but the manual baseline is
> estimated. Calibrate with a measured baseline on the next run to reach Confidence High.
