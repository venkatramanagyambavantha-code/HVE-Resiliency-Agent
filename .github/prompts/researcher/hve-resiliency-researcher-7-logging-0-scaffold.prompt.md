---
description: Scaffold the split Prompt 7 Logging pipeline - validate Prompt 1a and 1b prerequisites, freeze eligible dependencies, emit the Prompt 7 skeleton and a frozen manifest sidecar
agent: Task Researcher
argument-hint: "[researchRoot=.copilot-tracking/research/]"
---

# HVE Resiliency Researcher 7 Logging - 0 - Scaffold

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt runs the prerequisite and scaffolding stage only. It does not render inventory rows, does not render findings, does not run per-dependency repository traversal, and does not set any terminal status other than its own.

## Inputs

* `${input:researchRoot:.copilot-tracking/research/}`: (Optional) Workspace-relative research root. Defaults to `.copilot-tracking/research/`. Must resolve to an existing directory inside the workspace.

## Direct Invocation and Prerequisite

* Run only the scaffold stage. Do not run any category fill, verify, or finalize behavior.
* Require exactly one eligible Prompt 1a artifact and exactly one eligible Prompt 1b artifact. Eligibility qualifiers: inherited research location, matching prompt identity (filename ID and body ID agree), and a present Section 1 inventory, which may be empty. An explicitly superseded artifact is stale; age alone is not.
* If either prerequisite artifact from a prior step is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: name the prerequisite and stop `Blocked` per Status and Failure Semantics before writing anything. Auto-location resolves multiple candidates deterministically, so multiple candidates never block.
* If both prerequisites resolve and are readable but their combined Section 1 inventory lists zero confirmed dependencies, do not block: emit the skeleton and a frozen manifest with an empty `eligibleDependencies` list, and record that no confirmed dependency was in scope.

## Discovery and Selection

Enumerate `.md` files under the resolved research root and directly under any `researchRoot/YYYY-MM-DD/` subdirectory. Sort by normalized workspace-relative path using ordinal comparison. Do not descend into `subagents/`, `validator/`, or `sandbox/`. Do not follow symbolic links out of the research root. Reject absolute paths, traversal segments, and alternate separators. Normalize to `/` while preserving repository path case.

Extract each candidate's prompt ID from its filename using the first case-insensitive anchored occurrence of `researcher-<id>`, `prompt-<id>`, or `research-<id>` where `<id>` is one of `1a` or `1b` for this stage. Confirm the extracted ID against the artifact body by reading the front matter or first 40 lines and requiring an explicit reference to the same prompt ID.

Exclude any file whose normalized path is under `subagents/`, `validator/`, or `sandbox/`, any prior consolidation or split-pipeline output, any planner or optimization study, and any incomplete, blocked, malformed, unreadable, or unsafe artifact. Do not admit an artifact by filename alone.

When more than one candidate resolves to `1a` or to `1b`, select the candidate whose normalized path has the lexicographically largest dated ancestor segment matching `YYYY-MM-DD`. If no candidate carries a dated segment, or if dated segments tie, select the candidate whose normalized path sorts last using ordinal comparison. Record every non-selected duplicate in the manifest with disposition `exact duplicate` and preserve its provenance.

Process at most 100 candidates. Read each accepted artifact's bytes exactly once. Compute its sanitized `contentSha256`.

## Eligible Dependency Extraction

For each of the two accepted artifacts, read Section 1 only. Extract every dependency listed as confirmed and used, along with the file-line evidence recorded in the source artifact. Copy the file path and line numbers verbatim; never recalculate.

Apply the platform Service Exclusion Rule: exclude every dependency classified in Section 2 (Checked But Not Present) or Section 3 (Not Applicable) of either accepted artifact. If the same dependency appears in Section 1 of one artifact and Section 2 or 3 of the other, treat the Section 1 evidence as authoritative for eligibility and record the disagreement in the manifest under `sourceDisagreements`.

The resulting `eligibleDependencies` list is the frozen Prompt 7 dependency scope. Every downstream fill prompt uses exactly this list and never re-derives it.

## Payment Applicability Freeze

Derive `paymentApplicability` from Section 1 of the two accepted artifacts. Set it to `applicable` when either artifact's Section 1 confirms a payment workflow, payment dependency, or payment lifecycle citation. Otherwise set it to `not-applicable` and record the negative-check scope in the manifest. Never re-derive `paymentApplicability` in a downstream stage.

## Manifest Emission

Emit the frozen manifest sidecar per the Frozen Manifest Sidecar Contract in the shared instructions. Write it to `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-7-logging-research.manifest.md`, where `YYYY-MM-DD` is the current UTC date and `<repo-name>` is the workspace root basename.

Include the five fixed `categoryRouting` records mapping each category key to its fill prompt ID (`hve-resiliency-researcher-7-logging-1-startup-health`, `hve-resiliency-researcher-7-logging-2-transactions`, `hve-resiliency-researcher-7-logging-3-correlation-context`, `hve-resiliency-researcher-7-logging-4-log-hygiene`, `hve-resiliency-researcher-7-logging-5-silent-outage-diagnostics`) and its fragment file name.

## Skeleton Emission

Emit the Prompt 7 skeleton artifact at `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-7-logging-research.md` with the following structure. Do not render any inventory row or finding. Every placeholder comment is replaced by finalize.

```markdown
<!-- markdownlint-disable-file -->
---
title: <repo-name> Production Logging and Silent-Outage Diagnostics (Researcher 7 Logging)
description: Evidence-only inventory of current logging plus prioritized gaps and risks in production observability, evaluated against West US 2 zone loss and West US 2 to West US regional failover
ms.date: YYYY-MM-DD
ms.topic: research
source-prompt: hve-resiliency-researcher-7-logging
schema-version: 1
status: draft
pipeline: split
pipeline-stage: scaffold
---

## Scope and Assumptions

- Scope: Production logging inventory and silent-outage diagnostic gaps for `<repo-name>`, for the dependencies confirmed in Prompt 1a Section 1 and Prompt 1b Section 1, evaluated against West US 2 zone loss and West US 2 to West US regional failover.
- Eligible dependencies frozen by the scaffold manifest: see `<manifest-path>`.
- Payment applicability frozen by the scaffold manifest.
- Excluded per platform Service Exclusion Rule: every dependency classified in Prompt 1a Section 2 or 3 and Prompt 1b Section 2 or 3.

## Task Implementation Requests

Prompt 7 Logging is evidence-only. There are no implementation tasks.

## Section 1 Current Logging Inventory

<!-- inventory placeholder: assembled by hve-resiliency-researcher-7-logging-finalize -->

## Section 2 Prioritized Gaps and Risks

<!-- findings placeholder: assembled by hve-resiliency-researcher-7-logging-finalize -->

## Section 3 Evidence-Backed Planning Handoff

<!-- handoff placeholder: assembled by hve-resiliency-researcher-7-logging-finalize -->

## Ledger and Terminal Outcomes

<!-- ledger placeholder: assembled by hve-resiliency-researcher-7-logging-finalize -->
```

Create the fragment directory `<researchRoot>/YYYY-MM-DD/prompt-7-logging-fragments/` but do not create any fragment file. The fill prompts create their own fragment files.

## Completion

Report the accepted 1a and 1b artifact paths, the eligible dependency count, the payment applicability value, the skeleton path, the manifest path, and the fragment directory. Set the scaffold stage status to `Complete` when both artifacts admitted, the manifest wrote successfully, and the skeleton wrote successfully. Otherwise `Blocked` with the specific reason.

End with the single next-step suggestion required by the platform context.

> **Next step:** Run `/hve-resiliency-researcher-7-logging-1-startup-health`
