---
description: Fill the silent-outage-diagnostics fragment of the split Prompt 7 Logging pipeline - emit inventory rows and findings only for the silent-outage-diagnostics assessment category
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 7 Logging - 5 - Silent Outage Diagnostics

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt fills the silent-outage-diagnostics fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other category fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-7-logging-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 7 Logging Split Contract.

## Direct Invocation and Prerequisite

* Run only the silent-outage-diagnostics fill stage. Do not run any other category fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-7-logging-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other category fragments. Do not re-derive the eligible dependency list.

## Category Focus

Emit inventory rows and findings only for the assessment category `silent-outage-diagnostics`: health and dependency diagnostics, healthy-process silent failure, and safe metrics, traces, spans, tags, and dependency signals. Skip any evidence that maps to startup and health, transactions, correlation and context propagation, or log hygiene; those categories belong to their own fragments.

Silent-outage-diagnostics discovery hints (evidence-only):

* Health-check and dependency-health endpoints and the diagnostic fields they emit under partial dependency outage.
* Code paths that continue to return success while an upstream dependency is unreachable (empty catch blocks, `.onErrorResume` returning defaults, fire-and-forget subscribe sites), and whether any operator-visible diagnostic is emitted.
* Metric registrations, counters, gauges, timers, and dependency-tagged metrics that would surface silent degradation (or their documented absence on a production surface).
* Distributed-tracing span creation on outbound dependency calls, span tag content, and links to correlation IDs.
* Dependency-specific signals (broker lag, DB latency histograms, cache hit ratios) exposed on production paths.

Never emit a row or finding solely because an alarm is absent; require positive repository evidence of a diagnostic surface, or of a production path whose silent failure would remain undiagnosable given the observed diagnostic wiring.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this category only. Counters do not carry over from another category fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Emission

For every silent-outage-diagnostics inventory row, emit the Required Inventory Row Schema from the shared contract using section-scoped IDs of the form `I-7-silent-outage-diagnostics-00X`, assigned in emission order starting at `I-7-silent-outage-diagnostics-001`.

For every silent-outage-diagnostics finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-7-silent-outage-diagnostics-00X`, assigned in emission order starting at `F-7-silent-outage-diagnostics-001`.

Never combine zone-failure and regional-failover evidence in one row or finding. If the same dependency plus entrypoint applies to both scenarios with materially different behavior, emit two findings.

## Output

Write the fragment to `<fragmentDir>/silent-outage-diagnostics.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-researcher-7-logging-5-silent-outage-diagnostics`, `category-key: silent-outage-diagnostics`, and the fragment's terminal status. Follow the frontmatter with two subsections in this fixed order:

* `## Category silent-outage-diagnostics Inventory Rows` containing every emitted inventory row.
* `## Category silent-outage-diagnostics Findings` containing every emitted finding.

Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the inventory row count, the finding count, the count of findings carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-7-logging-verify`
