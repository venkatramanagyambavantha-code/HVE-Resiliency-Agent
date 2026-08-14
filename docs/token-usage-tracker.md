# Resiliency Research Session Token Tracker

Record the **Session Cost (credits)** shown in VS Code's Copilot Chat **Session Info** panel at
the end of each stage of the `/hve-resiliency-research` workflow. This is the only telemetry the
telemetry report needs.

> **The only value the telemetry report needs is Session Cost (credits).** Record it once at the
> end of each stage (research, planning, assessment).
>
> **Reset warning:** Session Cost keeps counting up across `/clear`, so clearing between prompts
> does not lose it. It resets to zero only when you start a brand-new chat session, and once it
> resets the number is gone. Write down the Session Cost before you end or restart the chat.

- **Repository / Customer:** _fill in_
- **Execution Mode:** _Mode A (interactive) or Mode B (autonomous)_
- **Model:** _e.g. Claude Opus 4.8_
- **Date started:** _fill in_

## Session Cost per stage (all the report needs)

Record the cumulative **Session Cost (credits)** from the Session Info panel once at the end of
each stage. These three readings are the only values the telemetry report requires. Fill this
table in for your run:

| Stage | End-of-stage prompt | Cumulative Session Cost (credits) |
|-------|---------------------|-----------------------------------|
| Research (Phases 1-3) | `/hve-resiliency-researcher-consolidate-2` | |
| Planning (Phase 4) | `/hve-resiliency-planner-2` | |
| Assessment (Phase 5) | `/hve-resiliency-assessment-builder-3` | |

Session Cost is cumulative, so each stage's own cost is the difference from the previous stage's
reading: research cost is its reading, planning cost is the planning reading minus the research
reading, and assessment cost is the assessment reading minus the planning reading.

## Cost Estimation

Cost basis (GitHub usage-based billing, effective June 1, 2026):

- **1 GitHub AI Credit = $0.01 USD** (fixed conversion). Source: GitHub Docs, Usage-based billing for individuals.
- Credits are computed from actual token usage (input + output + cached tokens times the model's per-token price), so the panel's Session Cost is already the real cost; multiply by $0.01 for USD.
- The legacy request multiplier (Claude Opus 4.8 = 27x) applies only to old annual request-based plans and does not apply to credit-metered sessions.
- The 10% auto-model-selection discount does not apply when a model is explicitly selected (e.g. Opus 4.8 High).

USD cost of a stage or the whole run = `credits x $0.01`. For example, a final Session Cost of
484.7 credits is 484.7 x $0.01 = $4.85 for the run.



