---
description: Fill the secrets-adjacent sub-fragment of the split Consolidate 8 pipeline - emit provisional Section 8 residual candidates only for artifact group secrets-adjacent (Prompt 7 residuals that are not secret findings)
agent: "Task Researcher"
argument-hint: "[subManifestPath=...]"
---

# HVE Resiliency Consolidate 8 - 4 - Secrets Adjacent

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt fills the `secrets-adjacent` sub-fragment only. It does not modify the sub-skeleton, does not read or edit other group sub-fragments, does not write `sections/section-8.md`, and does not set the nested-pipeline status.

## Inputs

* ${input:subManifestPath}: (Optional) Workspace-relative path to the frozen Section 8 sub-manifest sidecar emitted by `hve-resiliency-consolidate-8-0-scaffold`. When omitted, auto-locate it per the Sub-Manifest Auto-Location rule in the Consolidate 8 Split Contract.

## Direct Invocation and Prerequisite

* Run only the `secrets-adjacent` fill stage. Do not run any other group fill, verify, or finalize behavior.
* Require the sub-manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Sub-Manifest Sidecar Contract. If it is missing, unreadable, structurally invalid, or does not list `secrets-adjacent` in `groupRouting`, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a sub-fragment file.
* Require the outer manifest at the sub-manifest's `outerManifestPath` to still be readable and its sanitized SHA-256 digest to match `outerManifestSha256`. On mismatch, stop `Blocked` with `outer manifest drift`.

## Read Scope

Load the sub-manifest, confirm `schemaVersion: hve-resiliency-consolidate-8-split/v1`, and enumerate the `groupRouting.secrets-adjacent` accepted-artifact records. Confirm each accepted artifact's `contentSha256` still matches; if any source digest disagrees, stop `Blocked` with `source drift`.

Read only:

* The Section 8 sub-manifest.
* The outer consolidation manifest.
* The accepted source artifact routed to `secrets-adjacent` (Prompt `7`).

Do not read source artifacts routed to other groups. Do not re-run outer discovery, do not re-derive the group routing table, and do not perform an independent secret sweep over any other accepted artifact; the Section 7 secret sweep scope belongs to `hve-resiliency-consolidate-7-secrets`.

## Group Focus

Emit provisional Section 8 residual candidates only for the `secrets-adjacent` group: sanitized evidence from Prompt `7` that maps to no other section under the outer Section-to-Source Mapping and specifically does not qualify as a Section 7 hard-coded value or secret finding.

Secrets-adjacent residual discovery hints (evidence-only):

* Prompt 7 sanitized observations that describe a hard-coded value which is not a secret and which Section 7 does not primary-claim, restricted to observable production behavior with a validated file-line citation and a canonical dependency or category.
* Prompt 7 configuration-lifecycle observations that carry no secret metadata and that map to no other section.

Never emit a candidate solely because Prompt 7 mentions a topic; require positive evidence with a validated file-line citation and confirm that no other section's primary or scoped rule already claims the canonical tuple.

## Sanitization

Never reproduce a secret value or a reversible derivative. For any candidate touching a secret-adjacent surface, retain only the secret type, normalized file path and line, key or symbol name, and stable redacted identity carried by the Prompt 7 record. If an individual value cannot be safely sanitized, drop that value and keep the finding using only its safe location metadata; never render the raw value and never block for this reason, per Status and Failure Semantics.

## Residual Discipline

Apply the Residual Discipline in the shared contract. For every candidate:

* Compute the canonical-tuple identity from the outer Consolidation Shared Contract.
* Confirm the canonical tuple maps to no other section by inspecting Sections 1-7 primary rules and the Section 2.1 and Section 7 scoped rules.
* Drop the candidate when Section 7 primary or scoped rules already claim the tuple (Section 7 retains any secret finding under the outer section-precedence tie-break).
* Drop the candidate when any of Sections 1-6 already claim the tuple.
* Retain the candidate as a provisional Section 8 residual otherwise.

Do not attempt cross-section overlap resolution during fill; the outer finalize prompt applies the section-precedence tie-break.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract for the single accepted source artifact assigned to `secrets-adjacent`. Counters do not carry over from another group fill and cannot be reset by aliases, environments, or wording.

Exclude the artifact when its `completionStatus` in the outer manifest is not `Complete`. Stop when repository-free ledger review adds nothing.

## Emission

For every provisional finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-8-secrets-adjacent-00X`, assigned in emission order starting at `F-8-secrets-adjacent-001`. Every finding block ends with the exact provisional marker line:

* `Disposition: provisional Section 8 residual candidate (resolved by outer finalize)`

Never combine zone-failure and regional-failover evidence in one finding.

## Output

Write the sub-fragment to `<subFragmentDir>/secrets-adjacent.md`, where `<subFragmentDir>` is the `subFragmentDir` recorded in the sub-manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-consolidate-8-4-secrets-adjacent`, `group-key: secrets-adjacent`, `schema-version: hve-resiliency-consolidate-8-split/v1`, and the sub-fragment's terminal status. Follow the frontmatter with a single subsection in this fixed order:

* `## Group secrets-adjacent Provisional Findings` containing every emitted provisional finding.

Do not modify the sub-skeleton artifact. Do not touch any other sub-fragment. Do not write `sections/section-8.md`.

## Completion

Report the accepted-artifact `promptId` values read, the provisional finding count, the retained source-record totals, confirmation that no secret value was reproduced, the sub-fragment path, and the terminal sub-fragment status.

> **Next step:** Run `/hve-resiliency-consolidate-8-5-services`
