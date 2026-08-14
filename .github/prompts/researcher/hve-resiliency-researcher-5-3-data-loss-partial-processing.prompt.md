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

## Topology Deltas

Read the resolved deployment topology from the frozen manifest, exactly as this stage reads `eligibleDependencies`. Do not re-resolve it, do not infer it from repository contents, and do not override it. If the manifest records no topology, stop `Blocked` with `topology not established - run /hve-resiliency-topology-0-lock`. The [Deployment Topology Contract](../../instructions/hve-resiliency-topology.instructions.md) governs. The resolved topology scopes the data-loss and partial-processing discovery hints above. It adds no assessment topic, output field, or section, and it never changes the Required Row Schema.

The resolved deployment topology is not a data write model. Record an observed write model as evidence on the row it belongs to; never treat it as a correction to the declared topology.

When the resolved topology is `active-active`, treat these as in scope within the existing hints:

* Concurrent writes to the same record from both regions, and the conflict-resolution or last-write-wins behavior that governs them, including write skew.
* Identifier, sequence, and key generation that must stay unique across both regions, and the collision that overwrites or corrupts a record.
* Idempotency and duplicate processing under steady state, since both regions process concurrently and continuously.
* Schedulers, cron jobs, singletons, and leader-elected consumers that execute in both regions at once and process the same message twice.
* Bidirectional replication lag in both directions, and the writes, messages, or records at risk while a record converges.
* Read-your-own-writes exposure that causes a multi-step write to read stale state and commit an inconsistent result.

When the resolved topology is `active-standby`, treat these as in scope within the existing hints instead:

* One-way replication lag from primary to secondary, and the recovery point exposure at cutover: writes, messages, or records acknowledged on the primary but not replicated.
* In-flight and uncommitted work on the primary at cutover, including consumer offsets committed on the primary but not replicated.
* Idempotency and duplicate processing bounded to the cutover window, where work is replayed on the secondary after promotion.
* Consumers, producers, and scheduled writers that must not process on the standby and must activate on promotion, and the records lost or double-processed when either fails.
* State rebuilt rather than carried at promotion, and the records whose correctness depends on the discarded state.
* Failback and reverse replication after the primary returns, and writes taken on the secondary that must not be lost or overwritten.

Do not emit a row and do not record an evidence gap for a dimension the resolved topology places out of scope. Under `active-active`, replication lag at cutover, recovery point exposure at promotion, promotion-time state rebuild, and failback and reverse replication are out of scope and must not be recorded as evidence gaps. Under `active-standby`, concurrent multi-region write conflict, cross-region identifier and sequence collision, and read-your-own-writes across regions are out of scope and must not be recorded as evidence gaps; duplicate processing is in scope only within the bounded cutover window, not under steady state.

Where observed evidence does not fit the declared topology, continue under the declared topology and record the conflict per the contract's Mismatch Handling rules. Never switch topology and never decline to run.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this outcome only. Counters do not carry over from another outcome fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Row Emission

For every data-loss / partial-processing row, emit the Required Row Schema from the shared contract. Use section-scoped IDs of the form `F-5-data-loss-00X`, assigned in emission order starting at `F-5-data-loss-001`.

Never combine regional-failover and partial-outage evidence in one row. If the same dependency plus failure type plus entrypoint applies to both scenarios with materially different behavior, emit two rows.

## Output

Write the fragment to `<fragmentDir>/data-loss-partial-processing.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with the `## 5.3 Data Loss or Partial Processing` heading followed by frontmatter recording `source-prompt: hve-resiliency-researcher-5-3-data-loss-partial-processing`, `outcome-key: data-loss-partial-processing`, and the fragment's terminal status. Stamp the resolved deployment topology in the same frontmatter as `topology: <active-active|active-standby>`, carried verbatim from the manifest, and state it with the resolved regions as an evaluation condition. Stamp the deployment topology only; never stamp a write model in that field. Stamping is required and adds no field to the Required Row Schema. Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-5-4-blocking-transactions`
