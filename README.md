# HVE Resiliency

## Table of Contents

* [Overview](#overview)
* [Quick start](#quick-start)
* [Documentation](#documentation)
* [Problem statement](#problem-statement)
* [Scope](#scope)
* [Customization and extensibility](#customization-and-extensibility)
* [Workflow phases](#workflow-phases)
* [Repository layout](#repository-layout)
* [Token consumption estimates](#token-consumption-estimates)
* [Alignment with Microsoft frameworks](#alignment-with-microsoft-frameworks)
* [HVE at Microsoft](#hve-at-microsoft)
* [Contributing](#contributing)

---

## Overview

HVE Resiliency is an **AI-assisted analysis framework** that evaluates application source code and infrastructure (IaC) to identify resiliency gaps and generate a **prioritized remediation plan (P0–P3)**.

Unlike traditional architecture reviews, this framework:

- Works directly on **source code and infrastructure definitions**
- Produces **evidence-based findings with file and line references**
- Translates findings into **actionable, backlog-ready remediation plans**
- Focuses on **real failure scenarios** (zone failure and regional failover)

It is designed for engineering teams building or operating systems in Azure, especially those targeting **high availability and multi-region resiliency**.

The framework ships as a set of Copilot skills:

- `hve-resiliency-research`: runs the five-phase research-to-assessment workflow.
- `hve-resiliency-telemetry-report`: turns a completed run into an executive ROI report.
- `hve-resiliency-workitem-export`: converts assessment findings into an ADO or Jira import CSV.
- `hve-resiliency-workitem-import`: bulk-creates Azure DevOps work items from that CSV.
- `hve-resiliency-workitem-jira-import`: bulk-creates Jira Cloud issues from that CSV.

---

## Quick start

1. Install the [HVE Core VS Code extension](https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core) so the shared `Researcher Subagent` worker (used by the orchestrator agents) and the HVE agents are available in Copilot Chat.
2. Install this framework into the **root** of the codebase you want to assess. From your target repo's root:

   ```powershell
   # PowerShell (Windows / macOS / Linux)
   irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1 | iex
   ```

   The installer copies `.github/skills/`, `.github/prompts/`, and `.github/instructions/` into your `.github/` folder. Reload VS Code (**Developer: Reload Window**) so Copilot Chat re-indexes the new files, then commit the `.github/` additions so the rest of your team gets the same workflow.
3. Reload VS Code so the new agents appear in the picker: **Developer: Reload Window**.

### Run it (recommended: two clicks)

The fastest path is the two **orchestrator agents**. Each runs its entire phase in one shot - no per-prompt commands, no manual `/clear`. You start by **selecting the agent in the picker**, then sending a plain message (not a slash command).

**Research (Phases 1-3):**

1. In Copilot Chat, open the **agent picker** at the top of the chat panel and select **Resiliency Research Orchestrator**.
2. Send exactly:

   ```text
   Run the resiliency research pipeline for this repository.
   ```

   It runs discovery, then the analysis prompts in parallel, then consolidation, and points you to the consolidated research document under `.copilot-tracking/research/`. It only pauses for the Kafka topology question, a large-repo warning, or a verification failure.

**Planning (Phases 4-5):**

1. Switch the **agent picker** to **Resiliency Planning Orchestrator** (start a new chat when switching agents).
2. Send exactly:

   ```text
   Run the resiliency planning pipeline from the consolidated research.
   ```

   It produces the executive Master report, the Developer Guide, and the final **Code-Level Resiliency Assessment** report under `Microsoft-Assessment/`.

> Tip: add `autonomy=checkpointed` to either kickoff message to pause for review at phase boundaries. Add `audit=on` to the planning message to also run the optional Phase 6 evidence audit (`/fix-assessment-finding`) per tier after the assessment is built.

### Manual alternative (one prompt at a time)

Prefer to drive each step yourself? Run `/hve-resiliency-research` in Chat and follow the numbered steps in the skill: select a research agent for Phases 1-3 (Core Research, Service Research, Consolidation) and a planning agent for Phases 4-5 (Planning, Assessment). A context reset between prompts is optional - see below.

After a completed run, produce an executive ROI report with `/hve-resiliency-telemetry-report`. See the [Telemetry Report Workflow](docs/telemetry-report-workflow.md) cheatsheet for the fast path.

### About `/clear` between prompts

A context reset (`/clear` or a new chat) is **optional, not required**. State is carried by the artifacts on disk under `.copilot-tracking/` (research docs, plans, the assessment), not by chat history - each prompt re-reads what it needs before it works. A reset just drops accumulated prior turns to lower cost and avoid context bloat, so it is recommended for cost in the manual path but never needed for correctness. The **orchestrator agents manage context automatically** by dispatching each step to a fresh subagent, so you do not run `/clear` at all when using them.

See [.github/skills/hve-resiliency-research/SKILL.md](.github/skills/hve-resiliency-research/SKILL.md) for the authoritative workflow definition.

---

## Documentation

Start here before running the framework end-to-end. These two guides are the primary references for everything in this repo:

| Guide                                                                             | Read this when you want to                                                                                                                                                 |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[Resiliency Researcher Workflow](docs/resiliency-researcher-workflow.md)** | Understand the five-phase research-to-assessment workflow, per-phase prompt sequence, mode selection (interactive vs autonomous), and the workflow evolution diagrams.     |
| **[Work Item Skills Guide](docs/workitem-skills-guide.md)**                  | Turn a finished assessment into a real backlog in Azure DevOps or Jira Cloud via the export and import skills, including hierarchy options, dry runs, and troubleshooting. |
| **[Telemetry Report Workflow](docs/telemetry-report-workflow.md)**           | See the end-to-end diagrams: the resiliency workflow that produces the assessment, and the telemetry report that measures a completed run and turns it into an executive ROI report. |

The authoritative skill definitions live alongside the skills themselves at [.github/skills/hve-resiliency-research/SKILL.md](.github/skills/hve-resiliency-research/SKILL.md), [.github/skills/hve-resiliency-telemetry-report/SKILL.md](.github/skills/hve-resiliency-telemetry-report/SKILL.md), [.github/skills/hve-resiliency-workitem-export/SKILL.md](.github/skills/hve-resiliency-workitem-export/SKILL.md), [.github/skills/hve-resiliency-workitem-import/SKILL.md](.github/skills/hve-resiliency-workitem-import/SKILL.md), and [.github/skills/hve-resiliency-workitem-jira-import/SKILL.md](.github/skills/hve-resiliency-workitem-jira-import/SKILL.md).

---

## Problem statement

### Background

Manual resiliency assessments tend to be inconsistent across teams and engagements, slow to repeat as code evolves, infrastructure-first rather than code-aware, and disconnected from engineering backlogs. This framework addresses those gaps with standardized, AI-assisted workflows that produce a traceable evidence chain from research to a prioritized P0-P3 remediation plan, reviewed by a qualified engineer before delivery.

### What this skill solves

Manual resiliency assessments are often:

- Inconsistent across teams and engagements
- Time-consuming to repeat as code evolves
- Focused on infrastructure, ignoring code-level risks
- Difficult to translate into actionable backlog work

This skill standardizes and automates resiliency analysis across repositories.

#### Expected impact

Using this framework, teams can:

- Reduce assessment time (hours instead of days)
- Increase consistency across projects
- Identify **code-level failure paths** not visible in architecture diagrams
- Maintain full traceability from finding → code → remediation
- Generate **prioritized, backlog-ready actions**

### Finding prioritization (P0–P3)

Findings are classified based on their potential impact:

| Priority                | Description                                       |
| ----------------------- | ------------------------------------------------- |
| **P0 (Critical)** | Risk of full system failure or data loss          |
| **P1 (High)**     | Significant service degradation or partial outage |
| **P2 (Medium)**   | Resiliency gaps affecting recovery or stability   |
| **P3 (Low)**      | Improvements or optimizations                     |

This prioritization enables teams to focus on **failover-blocking risks first**.

### What you get as output

After running the workflow, you will obtain:

- Evidence-based research artifacts (file + line references)
- Consolidated resiliency findings
- Prioritized remediation plan (P0–P3)
- Developer guidance for issue resolution
- Backlog-ready resiliency assessment aligned with Microsoft frameworks

Example:
[View sample assessment](Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment_v2.md)

---

## Scope

### Applicability

Use this skill when:

- Preparing a system for **production readiness**
- Validating resiliency before a **major release**
- Migrating to **multi-region or active/active architectures**
- Converting resiliency risks into **engineering backlog items**
- Performing **code-level resiliency analysis**

#### Typical use cases

- Pre go-live validation
- Architecture and resiliency reviews
- Cloud migration readiness
- Continuous resiliency checks
- Engineering quality improvements

### What this framework does NOT do

This skill is intended for **design-time and code-level analysis**.

It does **not**:

- Execute or simulate failover scenarios
- Perform chaos engineering or load testing
- Automatically fix issues in the codebase
- Analyze runtime telemetry or production behavior
- Replace engineering review or decision-making

A qualified engineer must validate all findings before implementation.

---

## Customization and extensibility

The framework is context-driven, not static. Its default behavior comes from two instruction files:

- [.github/instructions/hve-resiliency-platform-context.instructions.md](.github/instructions/hve-resiliency-platform-context.instructions.md)
- [.github/instructions/hve-resiliency-planner-context.instructions.md](.github/instructions/hve-resiliency-planner-context.instructions.md)

Edit these to match your engagement: target and failover architecture (active/passive vs active/active), what qualifies as a resiliency finding and which failure scenarios matter, the P0-P3 priority model, architectural assumptions, and output format. Re-run `/hve-resiliency-research` and the agents pick up the updated context automatically.

Treat the instruction files as part of the product and evolve them as the system changes. The quality of findings depends on how well the context reflects your architecture, the failure scenarios that matter, and your business goals.

---

## Workflow phases

The framework follows an application-centric, evidence-first flow built on HVE Core's `Task Researcher` and `Task Planner` agents:

1. **Source code and IaC** in the target repository serve as primary evidence.
2. **Task Researcher** runs Phase 1-2 prompts to produce per-area research artifacts (architecture, dependencies, failure paths, per-service findings), citing file and line for every claim.
3. **Phase 3 consolidation** merges those artifacts into a single evidence document, deduplicating findings and normalizing terminology.
4. **Task Planner** reads the consolidated document under evidence-lock-in rules and produces a prioritized P0-P3 plan plus a code-level resiliency assessment. Verbatim code first enters the pipeline here: the Developer Guide quotes each snippet exactly from the cited file, and the assessment builders copy from it.
5. **Outputs** include forensic research artifacts, a Master plan and Developer Guide, and a backlog-ready assessment report with Microsoft Standards Alignment.
6. **Optional evidence audit** (`fix-assessment-finding`) re-resolves every citation, verbatim code block, and fix block in the finished assessment against the repository, run per priority tier as a backstop.

| Phase               | Prompts                                                          | Notes                                       |
| ------------------- | ---------------------------------------------------------------- | ------------------------------------------- |
| 1. Core Research    | `researcher-0` … `researcher-7-logging`                     | Sequential. Mode-aware.                     |
| 2. Service Research | `researcher/service/*` (8-19, filtered to applicable services) | Mode B allows up to 3 concurrent subagents. |
| 3. Consolidation    | `consolidate-0-scaffold` … `consolidate-9-finalize` (split pipeline with verify passes) | User-gated,`/clear` between steps.        |
| 4. Planning         | `planner-0`, `planner-1`, `planner-0`, `planner-2`       | User-gated,`/clear` between steps.        |
| 5. Assessment       | `planner-3a` … `planner-3d`                                 | User-gated,`/clear` between steps.        |
| 6. Evidence Audit (optional) | `fix-assessment-finding` (per tier: P0, P1, P2, P3)      | Backstop; verifies citations and code against the repo. |

A worked example output lives at [Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment_v2.md](Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment_v2.md). Per-phase descriptions, workflow evolution diagrams, and the post-Phase-5 backlog import flow are covered in the guides linked from [Documentation](#documentation).

## Repository layout

| Path                                                                                                      | Purpose                                                                                                                                                                              |
| --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [.github/skills/hve-resiliency-research/](.github/skills/hve-resiliency-research/)                         | Skill that orchestrates the full research workflow.                                                                                                                                  |
| [.github/skills/hve-resiliency-telemetry-report/](.github/skills/hve-resiliency-telemetry-report/)         | Skill that turns a completed workflow run into an executive ROI and telemetry report, comparing the research, planning, and assessment phases against a manual baseline.             |
| [.github/prompts/researcher/](.github/prompts/researcher/)                                                 | Phase 1 (core) and Phase 2 (per-service) research prompts, plus the consolidation prompt.                                                                                            |
| [.github/prompts/planner/](.github/prompts/planner/)                                                       | Phase 4 planning and Phase 5 assessment prompts (`planner-0` … `planner-3d`).                                                                                                        |
| [.github/prompts/fix-assessment-finding.prompt.md](.github/prompts/fix-assessment-finding.prompt.md)       | Phase 6 optional evidence-audit prompt: verifies assessment citations and code against the repository, per priority tier.                                                            |
| [.github/prompts/telemetry-report/](.github/prompts/telemetry-report/)                                     | Slash command that generates the executive ROI and telemetry report from a completed run.                                                                                           |
| [.github/prompts/workitem-export/](.github/prompts/workitem-export/)                                       | Backlog export prompt for converting assessment findings into ADO or Jira import CSV files.                                                                                          |
| [.github/prompts/workitem-import/](.github/prompts/workitem-import/)                                       | Bulk-import prompts for posting an export CSV directly into Azure DevOps or Jira Cloud.                                                                                              |
| [.github/skills/hve-resiliency-workitem-export/](.github/skills/hve-resiliency-workitem-export/)           | Skill that converts assessment findings into ADO or Jira import CSV files.                                                                                                           |
| [.github/skills/hve-resiliency-workitem-import/](.github/skills/hve-resiliency-workitem-import/)           | Skill that bulk-creates ADO work items from an export CSV via REST API, with optional parent Epic, priority-grouped User Stories, rich HTML descriptions, and assessment attachment. |
| [.github/skills/hve-resiliency-workitem-jira-import/](.github/skills/hve-resiliency-workitem-jira-import/) | Skill that bulk-creates Jira Cloud issues from an export CSV via REST API v3, with optional parent Epic, priority-grouped Stories, ADF descriptions, and assessment attachment.      |
| [.github/instructions/](.github/instructions/)                                                             | Platform context and evidence-only rules applied to researcher and planner prompts.                                                                                                  |
| [docs/](docs/)                                                                                             | Workflow overview and reference documentation — see the[Documentation](#documentation) section above.                                                                                |
| [Microsoft-Assessment/](Microsoft-Assessment/)                                                             | Worked example assessment output.                                                                                                                                                    |
| [install.ps1](install.ps1) / [install.sh](install.sh)                                                       | One-line bootstrap installers that copy the skills, prompts, and instructions into another repository (no`git` required).                                                          |

## Token consumption estimates

Approximate token usage for a full end-to-end workflow run, sized by the *target* codebase being assessed (after exclusions like `node_modules`, `bin`, `obj`, and generated code). Phase 2 cost scales with the number of in-scope Azure services, not raw lines of code.

| Sizing dimension                                  | Small                | Medium               | Large                  | Very Large           |
| ------------------------------------------------- | -------------------- | -------------------- | ---------------------- | -------------------- |
| Example                                           | Single microservice  | 5-service platform   | 15-20 service platform | Enterprise monorepo  |
| In-scope files                                    | <100                 | 100-500              | 500-2,000              | 2,000+               |
| In-scope lines of code                            | <5K                  | 5K-30K               | 30K-150K               | 150K+                |
| In-scope Azure services                           | 1-3                  | 4-7                  | 7-10                   | 10-12                |
| Total prompts run                                 | ~21                  | ~24                  | ~27                    | ~30                  |
| Phase 1 input/prompt                              | 8K-15K               | 20K-35K              | 60K-120K               | 150K-300K            |
| Phase 2 input/prompt (per service)                | 8K-15K               | 12K-25K              | 20K-40K                | 30K-60K              |
| Phase 3 consolidation input                       | 40K-70K              | 70K-120K             | 120K-200K              | 180K-300K            |
| Phase 4-5 input/prompt                            | 25K-50K              | 35K-70K              | 50K-90K                | 70K-120K             |
| Output tokens/prompt (typical)                    | 4K-15K               | 5K-25K               | 6K-30K                 | 8K-35K               |
| **Total tokens, Mode A (`/clear`-gated)** | **~550K-950K** | **~1.0M-1.7M** | **~1.9M-3.2M**   | **~3.1M-5.4M** |
| **Total tokens, Mode B (autonomous)**       | **~700K-1.3M** | **~1.4M-2.4M** | **~2.7M-4.5M**   | **~4.4M-7.5M** |

Mode B totals are 30-50% higher because the orchestrating agent retains conversation context across phases, even though each prompt runs as an isolated subagent. Estimates are per-prompt averages; individual prompts can spike 2-3x on unusually large source files or repos with deep tool-call iteration.

## Alignment with Microsoft frameworks

| Microsoft framework                                                                                        | How this framework aligns                                                                                                                                                                                                                             |
| ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)                     | Reliability pillar: availability, resiliency, and recovery. Phase 5 assessment maps every P0-P3 finding to WAF reliability patterns (see [`planner-3d`](.github/prompts/planner/hve-resiliency-planner-3d.prompt.md)). |
| [Azure Proactive Resiliency Library (APRL)](https://azure.github.io/Azure-Proactive-Resiliency-Library-v2/) | Design-time and detection-time resiliency guidance for Azure services, used as a reference for per-service findings in Phase 2.                                                                                                                       |
| [Cloud Adoption Framework (CAF)](https://learn.microsoft.com/azure/cloud-adoption-framework/)               | Application readiness for cloud scale and reliability, supporting the transition to active/active multi-region operation.                                                                                                                             |

## HVE at Microsoft

HVE (Hypervelocity Engineering) is a Microsoft engineering practice and toolset. Related Microsoft resources:

- [microsoft/hve-core](https://github.com/microsoft/hve-core): Shared instructions, skills, agents, and conventions used across HVE repositories.
- [HVE Essentials VS Code extension](https://marketplace.visualstudio.com/items?itemName=ise-hve.hve-essentials): Bundles `hve-core` prompts, instructions, and skills into VS Code.
- [Microsoft Industry Solutions Engineering (ISE)](https://www.microsoft.com/en-us/industry/microsoft-industry-solutions-engineering): The Microsoft engineering org behind HVE.
- [Azure Well-Architected Framework Reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/): Foundational reliability guidance referenced by the resiliency prompts.
- [Azure reliability documentation](https://learn.microsoft.com/azure/reliability/): Per-service availability zone and regional failover reference content.

## Contributing

Prompts, instructions, agents, and skills in this repository follow the conventions in [microsoft/hve-core](https://github.com/microsoft/hve-core). When editing files under `.github/prompts/`, `.github/instructions/`, or `.github/skills/`, follow the prompt-builder and markdown instructions inherited from `hve-core`.
