---
description: Fill the data-loss-partial-processing fragment of the split Prompt 5 pipeline - emit rows only for the data-loss or partial-processing observed outcome
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - 3 - Data Loss or Partial Processing

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt fills the data-loss-partial-processing fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other outcome fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the data-loss / partial-processing fill stage. Do not run any other outcome fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-5-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other outcome fragments. Do not re-derive the eligible dependency list.

## Outcome Focus

Emit rows only for the observed outcome `data-loss-partial-processing`: a message, record, or write may be lost, partially processed, duplicated in a way that violates business intent, or left in an inconsistent state when a dependency exhibits a timeout, DNS failure, authentication failure, or partial outage. Skip any evidence that maps to startup failure, silent degradation, or blocking transactions; those outcomes belong to their own fragments.

Data-loss / partial-processing discovery hints (evidence-only):

* Message-consumer commit strategy (auto commit vs. manual, before-execute vs. after-execute) on production topic paths.
* Producer publish paths that acknowledge before durable persistence, or that drop on error without retry.
* Multi-step transactions where a partial write can commit while a subsequent write fails silently.
* Idempotency guards, dedupe keys, and unique indexes that are absent, incomplete, or bypassed on production paths.
* Retry paths that produce duplicate side effects when downstream is only partially available.
* Cache-write paths that update the cache but not the system of record, or vice versa, on partial dependency outages.
* Reactive `.onErrorContinue` or `.onErrorResume` sites that drop or acknowledge the affected element without downstream compensation.

Never emit a row solely because durability documentation is unavailable; require positive repository evidence that a code path can lose, duplicate, or partially process a record under the stated dependency failure type.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this outcome only. Counters do not carry over from another outcome fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Row Emission

For every data-loss / partial-processing row, emit the Required Row Schema from the shared contract. Use section-scoped IDs of the form `F-5-data-loss-00X`, assigned in emission order starting at `F-5-data-loss-001`.

Never combine zone-failure and regional-failover evidence in one row. If the same dependency plus failure type plus entrypoint applies to both scenarios with materially different behavior, emit two rows.

## Output

Write the fragment to `<fragmentDir>/data-loss-partial-processing.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with the `## 5.3 Data Loss or Partial Processing` heading followed by frontmatter recording `source-prompt: hve-resiliency-researcher-5-3-data-loss-partial-processing`, `outcome-key: data-loss-partial-processing`, and the fragment's terminal status. Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-5-4-blocking-transactions`
