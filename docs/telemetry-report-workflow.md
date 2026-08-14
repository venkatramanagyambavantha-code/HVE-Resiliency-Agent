---
title: Telemetry Report Workflow
description: End-to-end diagrams for the HVE Resiliency workflow and the telemetry report that measures a completed run
author: HVE Resiliency
ms.date: 2026-07-15
ms.topic: reference
keywords:
  - resiliency
  - telemetry
  - roi
  - workflow
estimated_reading_time: 4
---

## Quick reference (cheatsheet)

Fast path for producing the report after a completed `hve-resiliency-research` run.

| Step | Action |
|------|--------|
| 1 | Confirm the run is complete: research in `.copilot-tracking/research/`, plans in `.copilot-tracking/plans/`, final report in `Microsoft-Assessment/`. |
| 2 | Confirm [token-usage-tracker.md](token-usage-tracker.md) has the Session Cost (credits) you recorded at the end of each stage. |
| 3 | Run `/hve-resiliency-telemetry-report`. |
| 4 | If prompted, follow [collection-guide.md](../.github/skills/hve-resiliency-telemetry-report/collection-guide.md) to fill the JSON (aggregate the tracker rows per bucket). |
| 5 | Review the 8-section report, verify confidence markers, then share the one-page summary. |

Command:

```text
/hve-resiliency-telemetry-report [telemetryJson=...]
```

Three telemetry buckets (aggregate the tracker rows into these):

| Bucket | Phases | Source |
|--------|--------|--------|
| `task_researcher` | 1-3 | `.copilot-tracking/research/` |
| `task_planner` | 4 | `.copilot-tracking/plans/` |
| `assessment_builder` | 5 | `Microsoft-Assessment/` |

Gotchas to remember:

* Cost comes from the token tracker's Session Cost credits (the one value you record), not a word-count estimate (word counts miss system, tool, and re-read tokens and understate cost).
* Session Cost is cumulative, so each stage cost is the difference from the previous stage's reading.
* Session Cost survives `/clear` but resets to zero on a brand-new chat session; record it before ending or restarting the chat.
* Include human oversight time in agent cost so ROI is not overstated.

## Overview

These two diagrams show the whole process at a glance. The first is the resiliency workflow that produces the assessment and backlog. The second is the telemetry report that measures a completed run and turns it into an executive ROI report.

The handoff between them is direct: the artifacts and token tracker produced in Diagram 1 are exactly the inputs Diagram 2 consumes.

## Diagram 1: Resiliency workflow (research to backlog)

```mermaid
flowchart TD
    START([Install framework<br/>Run /hve-resiliency-research]) --> MODE{Execution mode}
    MODE -- "Mode A: interactive, /clear-gated" --> P1
    MODE -- "Mode B: autonomous subagents" --> P1

    subgraph RESEARCH [Task Researcher agent]
        direction TB
        P1["Phase 1: Core Research<br/>researcher-0 to 7-logging"]
        P2["Phase 2: Service Research<br/>researcher 8-19 (applicable services)"]
        P3["Phase 3: Consolidation<br/>researcher-consolidate-0 to -2"]
        P1 --> P2 --> P3
    end

    subgraph PLAN [Task Planner agent]
        direction TB
        P4["Phase 4: Planning<br/>planner-0, planner-1, planner-2"]
        P5["Phase 5: Assessment Build<br/>assessment-builder-0 to 3"]
        P4 --> P5
    end

    P3 --> P4
    P5 --> REPORT["Final report<br/>Microsoft-Assessment/<br/>serviceName-Code-Level-Resiliency-Assessment.md"]

    REPORT --> EXPORT["/hve-resiliency-workitem-export<br/>findings to ADO or Jira CSV"]
    EXPORT --> IMPORT["/hve-resiliency-workitem-import<br/>or -jira-import<br/>bulk-create work items"]
    IMPORT --> REMEDIATE([Engineers implement fixes<br/>downstream, out of workflow scope])

    TRACK[["docs/token-usage-tracker.md<br/>Session Cost + Context tokens<br/>recorded live per prompt step"]]
    RESEARCH -.recorded in.-> TRACK
    PLAN -.recorded in.-> TRACK

    classDef phase fill:#e1f5ff,stroke:#0078d4,stroke-width:2px,color:#000
    classDef out fill:#dff6dd,stroke:#107c10,stroke-width:2px,color:#000
    classDef track fill:#fff4ce,stroke:#bf8803,stroke-width:2px,color:#000
    class P1,P2,P3,P4,P5 phase
    class REPORT,EXPORT,IMPORT out
    class TRACK track
```

## Diagram 2: Telemetry report (measures a completed run)

```mermaid
flowchart TD
    START([Run /hve-resiliency-telemetry-report]) --> CHECK{Completed run<br/>plus filled token tracker?}
    CHECK -- No --> BACK[Complete the run<br/>and token tracker first]
    BACK --> CHECK
    CHECK -- Yes --> JSON{Telemetry JSON<br/>provided?}

    JSON -- No --> COLLECT[collection-guide.md]

    subgraph BUCKETS [Aggregate telemetry into 3 buckets]
        direction TB
        R["task_researcher<br/>Phases 1-3<br/>.copilot-tracking/research/"]
        P["task_planner<br/>Phase 4<br/>.copilot-tracking/plans/"]
        A["assessment_builder<br/>Phase 5<br/>Microsoft-Assessment/"]
        C["Cost<br/>Session Cost credits<br/>(the one value recorded)"]
        B["Manual baseline<br/>measured or estimated"]
    end

    COLLECT --> BUCKETS
    BUCKETS --> FILL["Fill JSON template<br/>mark estimated fields"]
    FILL --> GEN
    JSON -- Yes --> GEN

    GEN["Apply report-prompt.md"] --> CALC["Calculations<br/>- time = active plus oversight hrs vs baseline<br/>- cost = tracker credits plus oversight<br/>- ROI plus annual plus 3-year projection<br/>- weighted quality 0.25 / 0.35 / 0.40"]
    CALC --> OUT["8-section executive report<br/>plus confidence markers<br/>plus one-page summary"]
    OUT --> REVIEW([Engineer or finance<br/>validates headline metrics])

    classDef phase fill:#e1f5ff,stroke:#0078d4,stroke-width:2px,color:#000
    classDef source fill:#fff4ce,stroke:#bf8803,stroke-width:2px,color:#000
    classDef gate fill:#fde7e9,stroke:#a4262c,stroke-width:2px,color:#000
    class GEN,CALC,OUT phase
    class R,P,A,C,B source
    class CHECK,JSON gate
```

## Notes

* The telemetry buckets stop at `assessment_builder` (Phase 5). The "engineers implement fixes" node in Diagram 1 is downstream and intentionally out of scope for the report.
* Cost comes from the token tracker's measured Session Cost credits (recorded live per step), not a word-count estimate. Word counts miss the system prompt, tool definitions, tool results, and context re-reads, so they understate real cost.
* Human oversight time is included in agent-side cost so ROI is not overstated.
* Every headline metric must be validated by a qualified engineer or finance reviewer before the report is shared.
