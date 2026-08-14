---
description: Fill the silent-degradation fragment of the split Prompt 5 pipeline - emit rows only for the silent-degradation observed outcome
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - 2 - Silent Degradation

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt fills the silent-degradation fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other outcome fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the silent-degradation fill stage. Do not run any other outcome fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-5-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other outcome fragments. Do not re-derive the eligible dependency list.

## Outcome Focus

Emit rows only for the observed outcome `silent-degradation`: the application continues to serve requests but functional behavior is silently reduced, with no operator-visible signal. Skip any evidence that maps to startup failure, data loss or partial processing, or blocking transactions; those outcomes belong to their own fragments.

Silent-degradation discovery hints (evidence-only):

* Swallowed exceptions on production paths (empty catch blocks, catch-and-log-only, `.onErrorContinue`, `.onErrorResume` returning empty or a downgraded default).
* Fire-and-forget subscribe or async invocation sites that discard failures.
* Feature-flag or configuration branches that bypass a dependency call when it fails or is disabled, without emitting an operator alarm.
* Cache-only or stale-serve fallbacks that keep responding while the upstream dependency is unreachable.
* Reduced-fidelity responses (partial content, default values, skipped enrichment) triggered by dependency timeouts or DNS or auth failures.
* Reactive pipelines that continue on element error and drop the affected event.

Never emit a row solely because a metric or alarm is absent; require positive repository evidence of an actual degraded behavior on a production path.

## Topology Deltas

Read the resolved deployment topology from the frozen manifest, exactly as this stage reads `eligibleDependencies`. Do not re-resolve it, do not infer it from repository contents, and do not override it. If the manifest records no topology, stop `Blocked` with `topology not established - run /hve-resiliency-topology-0-lock`. The [Deployment Topology Contract](../../instructions/hve-resiliency-topology.instructions.md) governs. The resolved topology scopes the silent-degradation discovery hints above. It adds no assessment topic, output field, or section, and it never changes the Required Row Schema.

When the resolved topology is `active-active`, treat these as in scope within the existing hints:

* Degraded behavior that manifests in one region only, since a caller may land in either region and see different behavior request to request with no signal.
* Cache-only and stale-serve fallbacks whose coherence assumption holds only while a caller stays in one region.
* Session state and affinity assumptions that silently downgrade a response when a request resolves in the region that did not create the state.
* Read-your-own-writes exposure that surfaces as a stale or downgraded response rather than an error.
* Feature-flag and configuration branches evaluated per region, where one region silently bypasses a dependency while the partner does not.
* Bidirectional replication lag absorbed silently by a fallback instead of being surfaced to an operator.

When the resolved topology is `active-standby`, treat these as in scope within the existing hints instead:

* Degraded paths on the secondary that stay invisible because no live traffic exercises them while it is idle.
* Configuration and feature-flag drift on the secondary that silently changes functional behavior at promotion.
* Health reporting that cannot distinguish a ready standby from a silently degraded one without live traffic.
* Fallbacks that quietly serve from state rebuilt at promotion, including caches that start cold and downgrade responses with no operator signal.
* Bypass branches that remain permanently active on the standby because their dependency is reachable only from `{primaryRegion}`.
* One-way replication lag absorbed silently by a stale-serve fallback during the cutover window.

Do not emit a row and do not record an evidence gap for a dimension the resolved topology places out of scope. Under `active-active`, standby parity while idle, promotion-time state rebuild, and cutover-window staleness are out of scope and must not be recorded as evidence gaps. Under `active-standby`, silent divergence between two concurrently serving regions, cross-region session affinity, and read-your-own-writes across regions are out of scope and must not be recorded as evidence gaps.

Where observed evidence does not fit the declared topology, continue under the declared topology and record the conflict per the contract's Mismatch Handling rules. Never switch topology and never decline to run.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this outcome only. Counters do not carry over from another outcome fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Row Emission

For every silent-degradation row, emit the Required Row Schema from the shared contract. Use section-scoped IDs of the form `F-5-degradation-00X`, assigned in emission order starting at `F-5-degradation-001`.

Never combine regional-failover and partial-outage evidence in one row. If the same dependency plus failure type plus entrypoint applies to both scenarios with materially different behavior, emit two rows.

## Output

Write the fragment to `<fragmentDir>/silent-degradation.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with the `## 5.2 Silent Functional Degradation` heading followed by frontmatter recording `source-prompt: hve-resiliency-researcher-5-2-silent-degradation`, `outcome-key: silent-degradation`, and the fragment's terminal status. Stamp the resolved deployment topology in the same frontmatter as `topology: <active-active|active-standby>`, carried verbatim from the manifest, and state it with the resolved regions as an evaluation condition. Stamping is required and adds no field to the Required Row Schema. Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-5-3-data-loss-partial-processing`
