---
description: Fill the core-context sub-fragment of the split Consolidate 8 pipeline - emit provisional Section 8 residual candidates only for artifact group core-context (Prompts 0, 1a, 1b)
agent: "Task Researcher"
argument-hint: "[subManifestPath=...]"
---

# HVE Resiliency Consolidate 8 - 1 - Core Context

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt fills the `core-context` sub-fragment only. It does not modify the sub-skeleton, does not read or edit other group sub-fragments, does not write `sections/section-8.md`, and does not set the nested-pipeline status.

## Inputs

* ${input:subManifestPath}: (Optional) Workspace-relative path to the frozen Section 8 sub-manifest sidecar emitted by `hve-resiliency-consolidate-8-0-scaffold`. When omitted, auto-locate it per the Sub-Manifest Auto-Location rule in the Consolidate 8 Split Contract.

## Direct Invocation and Prerequisite

* Run only the `core-context` fill stage. Do not run any other group fill, verify, or finalize behavior.
* Require the sub-manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Sub-Manifest Sidecar Contract. If it is missing, unreadable, structurally invalid, or does not list `core-context` in `groupRouting`, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a sub-fragment file.
* Require the outer manifest at the sub-manifest's `outerManifestPath` to still be readable and its sanitized SHA-256 digest to match `outerManifestSha256`. On mismatch, stop `Blocked` with `outer manifest drift`.

## Read Scope

Load the sub-manifest, confirm `schemaVersion: hve-resiliency-consolidate-8-split/v1`, and enumerate the `groupRouting.core-context` accepted-artifact records. Confirm each accepted artifact's `contentSha256` still matches; if any source digest disagrees, stop `Blocked` with `source drift`.

Read only:

* The Section 8 sub-manifest.
* The outer consolidation manifest.
* The accepted source artifacts routed to `core-context` (Prompt `0`, Prompt `1a`, Prompt `1b`).

Do not read source artifacts routed to other groups. Do not read Prompt 1a or Prompt 1b sections outside their evidence body. Do not re-run outer discovery and do not re-derive the group routing table.

## Group Focus

Emit provisional Section 8 residual candidates only for the `core-context` group: sanitized evidence from Prompts `0`, `1a`, and `1b` that maps to no other section under the outer Section-to-Source Mapping and the Section 2.1 and Section 7 scoped rules.

Core-context residual discovery hints (evidence-only):

* Repository context observations from Prompt 0 that do not fit Section 1's evidence-backed prose bullets and do not fit Sections 2-7 primary or scoped rules.
* Dependency inventory observations from Prompt 1a or 1b that neither Section 2 (Dependency Inventory) nor a Section 2.1 service-finding scope claims, and that are not classified in Prompt 1a or 1b Section 2 (Checked but Not Present) or Section 3 (Not Applicable).
* Cross-artifact context notes retained by 1a or 1b that describe an observable production behavior with a validated file-line citation and that map to no other section.

Never emit a candidate solely because an artifact mentions a topic; require positive evidence with a validated file-line citation and confirm that no other section's primary or scoped rule already claims the canonical tuple.

## Residual Discipline

Apply the Residual Discipline in the shared contract. For every candidate:

* Compute the canonical-tuple identity from the outer Consolidation Shared Contract.
* Confirm the canonical tuple maps to no other section by inspecting Sections 1-7 primary rules and the Section 2.1 and Section 7 scoped rules.
* Drop the candidate when Sections 1-7 already claim the tuple.
* Retain the candidate as a provisional Section 8 residual otherwise.

Do not attempt cross-section overlap resolution during fill; the outer finalize prompt applies the section-precedence tie-break.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per accepted source artifact assigned to `core-context`. Counters do not carry over from another group fill and cannot be reset by aliases, environments, or wording.

Exclude any artifact whose `completionStatus` in the outer manifest is not `Complete`. Stop when repository-free ledger review adds nothing.

## Emission

For every provisional finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-8-core-context-00X`, assigned in emission order starting at `F-8-core-context-001`. Every finding block ends with the exact provisional marker line:

* `Disposition: provisional Section 8 residual candidate (resolved by outer finalize)`

Never combine zone-failure and regional-failover evidence in one finding. If the same canonical dependency or category and observation applies to both scenarios with materially different evidence, emit two findings.

## Output

Write the sub-fragment to `<subFragmentDir>/core-context.md`, where `<subFragmentDir>` is the `subFragmentDir` recorded in the sub-manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-consolidate-8-1-core-context`, `group-key: core-context`, `schema-version: hve-resiliency-consolidate-8-split/v1`, and the sub-fragment's terminal status (`Blocked`, `Incomplete`, or `Complete`). Follow the frontmatter with a single subsection in this fixed order:

* `## Group core-context Provisional Findings` containing every emitted provisional finding.

Do not modify the sub-skeleton artifact. Do not touch any other sub-fragment. Do not write `sections/section-8.md`.

## Completion

Report the accepted-artifact `promptId` values read, the provisional finding count, the retained source-record totals, the sub-fragment path, and the terminal sub-fragment status.

> **Next step:** Run `/hve-resiliency-consolidate-8-2-platform-state`
