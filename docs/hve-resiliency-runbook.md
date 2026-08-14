---
title: HVE Resiliency Operator Runbook
description: Step-by-step operator runbook for executing the HVE Resiliency research-to-assessment workflow end-to-end on a target repository
author: HVE Resiliency
ms.date: 2026-06-09
ms.topic: how-to
keywords:
  - resiliency
  - runbook
  - hve
  - operator
  - azure
estimated_reading_time: 12
---

## Purpose

This runbook is the operator playbook for executing the `hve-resiliency-research` skill end-to-end against a target codebase. It assumes you are the engineer driving the workflow in VS Code Copilot Chat and need exact commands, checkpoints, and recovery steps for each phase.

For conceptual background (what each phase produces and why), read [Resiliency Researcher Workflow](resiliency-researcher-workflow.md) first. For backlog handoff after the assessment is complete, see [Work Item Skills Guide](workitem-skills-guide.md).

## Table of Contents

* [Audience and scope](#audience-and-scope)
* [HVE context](#hve-context)
* [Prerequisites](#prerequisites)
* [Pre-flight checklist](#pre-flight-checklist)
* [Phase 0: Install and verify](#phase-0-install-and-verify)
* [Phase 1: Core research (Prompts 0-7)](#phase-1-core-research-prompts-0-7)
* [Phase 2: Service-specific research (Prompts 8-19)](#phase-2-service-specific-research-prompts-8-19)
* [Phase 3: Consolidation](#phase-3-consolidation)
* [Phase 4: Planning](#phase-4-planning)
* [Phase 5: Code-level assessment report](#phase-5-code-level-assessment-report)
* [Post-workflow: Backlog handoff](#post-workflow-backlog-handoff)
* [Operator decision matrix: Mode A vs Mode B](#operator-decision-matrix-mode-a-vs-mode-b)
* [Recovery and re-runs](#recovery-and-re-runs)
* [Troubleshooting](#troubleshooting)
* [Sign-off checklist](#sign-off-checklist)
* [References](#references)

## Audience and scope

This runbook is for the operator who runs the workflow. Specifically:

* Microsoft ISE or HVE field engineers delivering a resiliency engagement.
* Customer engineers performing a self-service resiliency assessment.
* Platform leads validating production readiness or multi-region migration.

It is not a tutorial on Azure resiliency concepts, nor a substitute for the qualified-engineer review required before any artifact is shared or acted on.

## HVE context

HVE (Hypervelocity Engineering) is a Microsoft engineering practice that packages reusable AI-assisted workflows as Copilot skills, prompts, instructions, and agents. This framework builds on three HVE assets:

* The shared conventions and base agents in [microsoft/hve-core](https://github.com/microsoft/hve-core), distributed by the [HVE Core VS Code extension](https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core).
* The `Task Researcher` and `Task Planner` agents from `hve-core`, which back the research and planning phases respectively.
* The resiliency-specific skill, prompts, and instructions in this repository, layered on top of those agents.

Every prompt in this workflow has a declared agent in its frontmatter. Switching to the wrong agent (for example, running a Phase 4 planning prompt with `Task Researcher` still selected) produces off-spec output, so the agent-switch step is called out explicitly in each phase below.

## Prerequisites

Verify each item before you start. Missing prerequisites are the most common cause of failed runs.

| Requirement | Verification command or check |
|-------------|-------------------------------|
| VS Code with GitHub Copilot Chat enabled | `code --version` and confirm Copilot Chat icon in the activity bar |
| PowerShell 7 or later | `pwsh --version` |
| HVE Core VS Code extension installed | Extensions view, search `ise-hve-essentials.hve-core`, confirm Installed |
| Target repository cloned locally | `git status` from the repo root |
| Write access to the repo working tree | Confirm you can create `.copilot-tracking/` |
| Network access to `raw.githubusercontent.com` | `Invoke-WebRequest https://raw.githubusercontent.com -UseBasicParsing` |
| Approximately 5-10 GB free disk for tracking artifacts | `Get-PSDrive C` |

Optional for the post-workflow backlog handoff:

* Azure CLI 2.60+ and `az login` for ADO import.
* Atlassian API token in `$env:JIRA_API_TOKEN` for Jira import.

## Pre-flight checklist

Complete these in order. Do not start Phase 0 until every item is checked.

1. Confirm the engagement scope is written down: target repo, in-scope services, primary and secondary Azure regions, and the failover model (active/active vs active/passive).
2. Review and, if needed, customize `.github/instructions/hve-resiliency-platform-context.instructions.md` and `.github/instructions/hve-resiliency-planner-context.instructions.md` to match the engagement scope.
3. Capture a baseline token budget. Use the [Token consumption estimates](../README.md#token-consumption-estimates) table to forecast Mode A vs Mode B cost for the target repo size.
4. Decide the execution mode you will request when the skill asks (see [Operator decision matrix](#operator-decision-matrix-mode-a-vs-mode-b)).
5. Open the target repository as the active VS Code workspace folder. The skill operates only on the open workspace.

## Phase 0: Install and verify

Install the framework into the target repository and verify that Copilot Chat picks it up.

### 0.1 Install the framework

From the target repository root, run one of the following.

PowerShell (Windows, macOS, Linux):

```powershell
irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1 | iex
```

Bash (macOS, Linux, WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.sh | bash
```

To pin to a specific tag and force overwrite existing files:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1))) -Ref v1.0 -Force
```

### 0.2 Verify the install

Confirm the files were copied:

```powershell
Get-ChildItem .github\skills, .github\prompts, .github\instructions -Recurse -File |
  Measure-Object | Select-Object -ExpandProperty Count
```

You should see a non-zero count, and the following should exist:

* `.github/skills/hve-resiliency-research/SKILL.md`
* `.github/prompts/researcher/` (at minimum prompts 0 through 7-logging)
* `.github/instructions/hve-resiliency-platform-context.instructions.md`

### 0.3 Reload VS Code and confirm slash commands

In VS Code, run **Developer: Reload Window** from the command palette. Then in Copilot Chat, type `/` and confirm these commands appear in the picker:

* `/hve-resiliency-research`
* `/hve-resiliency-workitem-export`
* `/hve-resiliency-workitem-import`
* `/hve-resiliency-workitem-jira-import`

If they are missing, see [Troubleshooting: Slash commands not appearing](#troubleshooting).

### 0.4 Commit the install

Commit the new `.github/` files so the rest of the team works from the same workflow definition:

```powershell
git add .github/skills .github/prompts .github/instructions
git commit -m "chore: install HVE Resiliency framework"
```

## Phase 1: Core research (Prompts 0-7)

Phase 1 establishes the repository context and dependency inventory that all later phases depend on. It runs prompts `0` through `7-logging` strictly in order.

### 1.1 Select the agent

The recommended path is to select **Resiliency Research Orchestrator** from the agent picker: it runs Phases 1-3 in one invocation, parallelizes independent steps, and manages context automatically (no manual `/clear`). For the manual, one-prompt-per-turn path below, select a research agent (`Task Researcher` in HVE Core v3.2.2, or the current research phase agent in your HVE version); every Phase 1 prompt expects a research agent.

### 1.2 Invoke the skill

Send this exactly:

```text
/hve-resiliency-research
```

The skill will ask one and only one question: which execution mode to use.

### 1.3 Choose the mode

Reply with one of:

* `Mode A` for interactive, one-prompt-per-turn execution, with an optional context reset between prompts (recommended for cost, optional for correctness - durable artifacts carry context forward).
* `Mode B` for autonomous execution that dispatches each prompt as an isolated subagent. This is now provided directly by the **Resiliency Research Orchestrator** agent, which is the recommended way to run Mode B.

See [Operator decision matrix](#operator-decision-matrix-mode-a-vs-mode-b) if you have not yet decided.

### 1.4 Mode A operator loop

Repeat this loop for prompts 0, 1a, 1b, 2, 3, 4, 5, 6, 7-logging (in that order):

1. Wait for the prompt artifact to be written under `.copilot-tracking/research/`.
2. Open the artifact and skim it. Confirm it cites file and line references for substantive claims.
3. If the artifact is wrong or empty, retry the same prompt by re-invoking the skill before moving on.
4. When the agent stops with a next-step recommendation, optionally run `/clear` to reset context (recommended for cost).
5. Reply `proceed` (or re-invoke `/hve-resiliency-research`) to continue with the next prompt in the sequence.

After Prompt 1a and 1b complete, **review Section 1 in both artifacts before continuing**. Section 1 is the authoritative dependency list; Sections 2 and 3 are excluded from every later prompt. If Section 1 misses an in-scope service or includes a service that is not actually present, edit the artifact now before Prompt 2 starts.

### 1.5 Mode B operator loop

In Mode B the orchestrator runs all eight prompts back-to-back. Your job is to:

1. Watch for each subagent's completion summary in the chat.
2. Spot-check at least the Prompt 1a and 1b artifacts before they influence later prompts. Stop the run if Section 1 is materially wrong.
3. Stop the run immediately if a prompt fails twice; do not let the orchestrator continue past a hard failure.

### 1.6 Phase 1 exit criteria

Phase 1 is complete when:

* All eight artifacts exist under `.copilot-tracking/research/` with the repo name as the file prefix.
* The agent has presented the Phase 1 completion summary and stopped.
* You have reviewed the Phase 2 readiness summary and know which service prompts will run.

The skill will not auto-start Phase 2. You must confirm in a subsequent turn.

## Phase 2: Service-specific research (Prompts 8-19)

Phase 2 runs one deep-dive prompt per Azure service identified in Phase 1 Section 1. Services not in Section 1 are skipped.

### 2.1 Confirm the applicable prompt set

Before proceeding, list the prompts the orchestrator plans to run. Cross-check each one against Section 1 of the Prompt 1a artifact. The full catalog and service mapping is:

| Slash command | Service |
|---------------|---------|
| `/hve-resiliency-researcher-8-appgw` | Application Gateway |
| `/hve-resiliency-researcher-9-functions` | Azure Functions |
| `/hve-resiliency-researcher-10-keyvault` | Key Vault |
| `/hve-resiliency-researcher-11-aks-istio` | AKS and Istio |
| `/hve-resiliency-researcher-12-cosmosdb` | Cosmos DB |
| `/hve-resiliency-researcher-13-sql` | Azure SQL |
| `/hve-resiliency-researcher-14-redis` | Azure Cache for Redis |
| `/hve-resiliency-researcher-15-storage` | Azure Storage |
| `/hve-resiliency-researcher-16-kafka-active-active` | Kafka (Active-Active, paired with a multi-master database) |
| `/hve-resiliency-researcher-16-kafka-active-standby-confluent` | Kafka (Active-Standby via Confluent Cluster Linking, paired with a single-master database) |
| `/hve-resiliency-researcher-17-networking` | Networking |
| `/hve-resiliency-researcher-18-entraid` | Entra ID |
| `/hve-resiliency-researcher-19-apim` | API Management |

### 2.2 Trigger Phase 2

Reply `proceed` to start Phase 2 in the same mode as Phase 1, or specify a different mode (for example, `Mode A`) to switch.

### 2.3 Mode A loop

For each applicable service prompt, repeat the same loop as Phase 1.4: wait for the artifact, review it, `/clear`, then `proceed`.

### 2.4 Mode B loop

The orchestrator dispatches subagents (up to three concurrent for independent services). Monitor the chat for per-service completion summaries and stop the run on any double failure.

### 2.5 Phase 2 exit criteria

Phase 2 is complete when:

* One artifact exists per applicable service under `.copilot-tracking/research/`.
* The completion summary lists every artifact produced and every service skipped (with reason).
* The agent has stopped and recommended `/clear`, then `/hve-resiliency-researcher-consolidate-0`.

**Do not** let the orchestrator auto-dispatch Phase 3. Consolidation is long-running and times out under autonomous orchestration.

## Phase 3: Consolidation

Phase 3 merges every Phase 1 and Phase 2 artifact into one consolidated evidence document. It runs as three sequential passes so the work never times out: Part A (`consolidate-0`) reads everything, deduplicates, and assigns the authoritative finding IDs into a manifest plus the research file header and Repository Context; Part B (`consolidate-1`) appends Sections 2-5; Part C (`consolidate-2`) appends Sections 6-8 and the authoritative Research Findings Index, then runs the quality bar. Run `/clear` before each pass.

### 3.1 Reset context

```text
/clear
```

### 3.2 Run consolidation (three passes, `/clear` between each)

```text
/hve-resiliency-researcher-consolidate-0
```

```text
/hve-resiliency-researcher-consolidate-1
```

```text
/hve-resiliency-researcher-consolidate-2
```

### 3.3 Verify the output

Confirm a consolidated document exists under `.copilot-tracking/research/` with the repo name as the file prefix (alongside the `-findings-manifest.md` coordination file Part A wrote). Open it and verify:

* Every retained finding still cites the upstream artifact and the original file and line evidence.
* Terminology is consistent (for example, the same service name is used across all sections).
* Duplicates between Phase 1 and Phase 2 are merged, not just appended.
* Finding IDs are contiguous and ascending within each priority tier, and the Section 9 index matches the body.

If a pass is incomplete or inconsistent, re-run that pass (after `/clear`) with an explicit instruction to address the gap. Do not start Phase 4 until consolidation is clean.

## Phase 4: Planning

Phase 4 converts the consolidated evidence into a Master report and a Developer Guide. Switch the active agent to **Task Planner** before starting.

### 4.1 Run the planning context frame

```text
/clear
```

```text
/hve-resiliency-planner-0
```

### 4.2 Produce the Master report

```text
/hve-resiliency-planner-1
```

Confirm the output exists at `.copilot-tracking/plans/<repo-name>-Master.md`. Review it before continuing. If the executive summary or priority distribution looks wrong, fix the underlying research evidence and re-run consolidation rather than editing the Master report by hand.

### 4.3 Re-seed the planning context

```text
/clear
```

```text
/hve-resiliency-planner-0
```

Re-running `planner-0` is intentional. It re-establishes the planning context after the `/clear` so `planner-2` has the same evidence lock-in as `planner-1`.

### 4.4 Produce the Developer Guide

```text
/hve-resiliency-planner-2
```

Confirm the output exists at `.copilot-tracking/plans/<repo-name>-Developer-Guide.md`. Verify each remediation references the corresponding finding ID from the Master report.

### 4.5 Phase 4 exit criteria

Phase 4 is complete when:

* Both `<repo-name>-Master.md` and `<repo-name>-Developer-Guide.md` exist under `.copilot-tracking/plans/`.
* Every finding in the Developer Guide is cross-linked to the Master report.
* A qualified engineer has spot-checked at least every P0 and P1 entry.

## Phase 5: Code-level assessment report

Phase 5 assembles the final deliverable through four append-only passes. Keep the **Task Planner** agent active for all four prompts.

### 5.1 Section 1: header and overview

```text
/clear
```

```text
/hve-resiliency-assessment-builder-0
```

This writes the report header, table of contents, and Assessment Overview to `Microsoft-Assessment/<serviceName>-Code-Level-Resiliency-Assessment.md`.

### 5.2 Section 2: P0 and P1 findings

```text
/clear
```

```text
/hve-resiliency-assessment-builder-1
```

### 5.3 Section 3: P2/P3 and Non-Resilient findings

```text
/clear
```

```text
/hve-resiliency-assessment-builder-2
```

### 5.4 Sections 4-6: IaC gap, finding matrix, alignment

```text
/clear
```

```text
/hve-resiliency-assessment-builder-3
```

### 5.5 Phase 5 exit criteria

Phase 5 is complete when:

* The assessment markdown exists at `Microsoft-Assessment/<serviceName>-Code-Level-Resiliency-Assessment.md`.
* All six sections are present (Overview, Resilient-focused, Non-Resilient-focused, IaC Gap, Full Finding Matrix, Microsoft Standards Alignment).
* A qualified engineer has reviewed and signed off on the full report before it is shared with the customer.

A worked example is at [Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment.md](../Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment.md).

## Post-workflow: Backlog handoff

After the assessment is signed off, convert it into a real backlog using the work item skills. The full sequence is documented in [Work Item Skills Guide](workitem-skills-guide.md); the runbook-level summary is:

1. Run `/hve-resiliency-workitem-export` and answer `ADO` or `Jira` when asked. The CSV lands in `Microsoft-Assessment/exports/`.
2. For Azure DevOps, run `/hve-resiliency-workitem-import` (requires `az login`).
3. For Jira Cloud, run `/hve-resiliency-workitem-jira-import` (requires `$env:JIRA_EMAIL` and `$env:JIRA_API_TOKEN`).

Always do a dry-run import first against a sandbox project before posting to the production backlog.

## Operator decision matrix: Mode A vs Mode B

Use this table to pick the mode before invoking the skill.

| Factor | Choose Mode A when | Choose Mode B when |
|--------|--------------------|--------------------|
| Reviewer availability | A reviewer is at the keyboard for each prompt | The run will execute unattended |
| Risk tolerance for off-spec output | Low (you want to catch errors per-prompt) | Higher (you accept post-hoc cleanup) |
| Token budget pressure | High (Mode A is 30-50% cheaper, see [Token estimates](../README.md#token-consumption-estimates)) | Low (speed matters more than token cost) |
| Repo size | Very large (limits blast radius of a bad run) | Small or medium |
| First-time run on this repo | Yes (use Mode A to learn the artifacts) | No (you have done this before on similar repos) |
| Customization confidence | Low (you have not validated the platform context) | High (context is known-good) |

If unsure, default to Mode A.

## Recovery and re-runs

### Re-run a single research prompt

The framework is file-driven: each prompt writes a discrete artifact under `.copilot-tracking/research/`. To re-run one prompt:

1. Delete (or rename) the stale artifact for that prompt.
2. `/clear`.
3. Re-invoke the specific slash command (for example, `/hve-resiliency-researcher-3`).

### Restart Phase 1 cleanly

If you need to start over with no prior context:

```powershell
Remove-Item .copilot-tracking\research\* -Force
Remove-Item .copilot-tracking\plans\* -Force -ErrorAction SilentlyContinue
```

Then `/clear` and re-invoke `/hve-resiliency-research`.

### Recover from a Phase 4 or Phase 5 error

Planning and assessment phases consume the consolidated research document. If a planning artifact is wrong:

1. Confirm the consolidated research document is correct. Fix it first if not.
2. Delete the wrong planning artifact (`Master.md` or `Developer-Guide.md`).
3. `/clear`, run `/hve-resiliency-planner-0`, then re-run the failing prompt.

### Update the framework mid-engagement

If a new version of the framework is released during an engagement:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1))) -Ref v1.1 -Force
```

Reload VS Code, then continue from the next pending phase. Already-written artifacts under `.copilot-tracking/` are not regenerated automatically; re-run any phase you want to refresh.

## Troubleshooting

### Slash commands not appearing

Symptom: typing `/` in Copilot Chat does not show `/hve-resiliency-research`.

Checks:

1. Confirm the files exist: `Get-ChildItem .github\skills\hve-resiliency-research\SKILL.md`.
2. Confirm the workspace folder open in VS Code is the repo root, not a subfolder.
3. Run **Developer: Reload Window** in VS Code.
4. Confirm GitHub Copilot Chat is signed in and enabled for this workspace.

### Skill activates but ignores mode question

Symptom: the agent runs past the mode question without asking, or starts at a later prompt.

Fix: stop the run, `/clear`, and re-invoke `/hve-resiliency-research`. If it recurs, confirm `.github/skills/hve-resiliency-research/SKILL.md` is unmodified by comparing against the upstream copy.

### Wrong agent is active

Symptom: a planning prompt produces forensic-only output, or a research prompt produces remediation recommendations.

Fix: stop, reset context, and switch to the correct agent - the **Resiliency Research Orchestrator** (or a research phase agent) for Phases 1-3, the **Resiliency Planning Orchestrator** (or a planning phase agent) for Phases 4-5 - then re-run the affected step. Note: HVE Core has consolidated the standalone `Task Researcher` / `Task Planner` agents into the RPI lifecycle; the orchestrator agents do not depend on those specific agents.

### Consolidation times out

Symptom: a consolidation pass runs for an extended period and then errors.

Fix: ensure each consolidation pass (`consolidate-0`, `consolidate-1`, `consolidate-2`) is run interactively (not as part of an autonomous chain), with a fresh `/clear` immediately before it. The three-part split already keeps each pass small; if a single pass still times out, re-run just that pass with explicit instructions to process its findings in smaller batches by section or service.

### Findings missing file and line citations

Symptom: a research artifact contains claims without `path/file:line` references.

Fix: this violates the evidence-only rule. Re-run that single prompt with an explicit instruction to add file and line citations for every substantive claim. If the artifact still lacks citations, treat the run as failed and restart from Prompt 0.

### Em dashes appear in artifacts

Symptom: generated markdown contains `—` or `–` characters.

Fix: the platform context forbids em dashes. Find-and-replace `—` and `–` with ` - ` (space-hyphen-space) in the affected artifact, and add an explicit reminder in the next prompt to avoid em dashes.

### Token budget exceeded mid-run

Symptom: Copilot Chat reports rate-limit or context-window errors during a phase.

Fix: switch to Mode A for the remaining prompts (Mode A is 30-50% cheaper than Mode B). Re-run only the prompts that did not produce an artifact; already-written artifacts survive a `/clear`.

## Sign-off checklist

Before declaring the engagement complete, confirm every item below.

* [ ] All eight Phase 1 artifacts exist and have been spot-checked by a qualified engineer.
* [ ] Every applicable Phase 2 service artifact exists, and skipped services are documented with a reason.
* [ ] The consolidated research document deduplicates findings and preserves file and line evidence.
* [ ] `Master.md` and `Developer-Guide.md` exist under `.copilot-tracking/plans/` and cross-reference correctly.
* [ ] The final assessment at `Microsoft-Assessment/<serviceName>-Code-Level-Resiliency-Assessment.md` contains all six sections.
* [ ] Every P0 and P1 finding has been engineer-reviewed for correctness, severity, and remediation viability.
* [ ] No artifact contains em dashes or unsourced claims.
* [ ] Customizations to `.github/instructions/` reflect the engagement scope and have been committed.
* [ ] The artifacts under `.copilot-tracking/` and `Microsoft-Assessment/` are committed to the repository (or archived per engagement policy).
* [ ] Backlog handoff (if in scope) has been dry-run against a sandbox project before targeting production.

## References

* [Resiliency Researcher Workflow](resiliency-researcher-workflow.md) - phase concepts and workflow evolution diagrams.
* [Work Item Skills Guide](workitem-skills-guide.md) - end-to-end backlog import for ADO and Jira.
* [HVE Resiliency README](../README.md) - overview, customization, and token estimates.
* [`hve-resiliency-research` skill](../.github/skills/hve-resiliency-research/SKILL.md) - authoritative skill definition.
* [Platform context instructions](../.github/instructions/hve-resiliency-platform-context.instructions.md) - evidence-only rules and priority definitions for research prompts.
* [Planner context instructions](../.github/instructions/hve-resiliency-planner-context.instructions.md) - evidence lock-in and classification rules for planning prompts.
* [microsoft/hve-core](https://github.com/microsoft/hve-core) - shared HVE agents, instructions, and conventions.
* [Azure Well-Architected Framework Reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/) - foundational reliability guidance referenced by the prompts.
