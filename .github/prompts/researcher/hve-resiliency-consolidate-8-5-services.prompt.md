---
description: Fill the services sub-fragment of the split Consolidate 8 pipeline - emit provisional Section 8 residual candidates only for artifact group services (applicable optional Prompts 8-19)
agent: "Task Researcher"
argument-hint: "[subManifestPath=...]"
---

# HVE Resiliency Consolidate 8 - 5 - Services

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt fills the `services` sub-fragment only. It does not modify the sub-skeleton, does not read or edit other group sub-fragments, does not write `sections/section-8.md`, and does not set the nested-pipeline status.

## Inputs

* ${input:subManifestPath}: (Optional) Workspace-relative path to the frozen Section 8 sub-manifest sidecar emitted by `hve-resiliency-consolidate-8-0-scaffold`. When omitted, auto-locate it per the Sub-Manifest Auto-Location rule in the Consolidate 8 Split Contract.

## Direct Invocation and Prerequisite

* Run only the `services` fill stage. Do not run any other group fill, verify, or finalize behavior.
* Require the sub-manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Sub-Manifest Sidecar Contract. If it is missing, unreadable, structurally invalid, or does not list `services` in `groupRouting`, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a sub-fragment file.
* Require the outer manifest at the sub-manifest's `outerManifestPath` to still be readable and its sanitized SHA-256 digest to match `outerManifestSha256`. On mismatch, stop `Blocked` with `outer manifest drift`.

## Read Scope

Load the sub-manifest, confirm `schemaVersion: hve-resiliency-consolidate-8-split/v1`, and enumerate the `groupRouting.services` accepted-artifact records. Confirm each accepted artifact's `contentSha256` still matches; if any source digest disagrees, stop `Blocked` with `source drift`.

Read only:

* The Section 8 sub-manifest.
* The outer consolidation manifest.
* The accepted service source artifacts routed to `services` (applicable optional Prompt IDs `8` through `19`).

Do not read source artifacts routed to other groups. Do not re-run outer discovery and do not re-derive the group routing table.

## Group Focus and Services Applicability

Read the sub-manifest's frozen `servicesApplicability` value.

* When `servicesApplicability` is `applicable`, emit provisional Section 8 residual candidates only for accepted service artifacts routed to `services`: sanitized evidence that maps to no other section under the outer Section-to-Source Mapping (in particular, that is not claimed by the Section 2.1 service-finding scope, and that is not a primary Sections 3-7 finding).
* When `servicesApplicability` is `not-applicable`, run one negative-check pass inside the bounded discovery limits, record its scope in the completion report, emit zero provisional findings, and write the sub-fragment with the negative-check acknowledgement described in Output below.

Services residual discovery hints (evidence-only):

* Service artifact observations that Section 2.1 (service-finding scope over Section 2 Used Dependencies) does not claim.
* Service artifact observations that map to no primary Sections 3-7 rule.
* Cross-service context that describes an observable production behavior with a validated file-line citation to the service artifact and a canonical dependency or category.

Never emit a candidate solely because a service artifact mentions a topic; require positive evidence with a validated file-line citation and confirm that no other section's primary or scoped rule already claims the canonical tuple.

## Residual Discipline

Apply the Residual Discipline in the shared contract. For every candidate:

* Compute the canonical-tuple identity from the outer Consolidation Shared Contract.
* Confirm the canonical tuple maps to no other section by inspecting Sections 1-7 primary rules and the Section 2.1 and Section 7 scoped rules.
* Drop the candidate when Sections 1-7 already claim the tuple, including via the Section 2.1 service-finding scope.
* Retain the candidate as a provisional Section 8 residual otherwise.

Do not attempt cross-section overlap resolution during fill; the outer finalize prompt applies the section-precedence tie-break.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per accepted service source artifact assigned to `services`. Counters do not carry over from another group fill and cannot be reset by aliases, environments, or wording.

Exclude any artifact whose `completionStatus` in the outer manifest is not `Complete`. Stop when repository-free ledger review adds nothing.

## Emission

For every provisional finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-8-services-00X`, assigned in emission order starting at `F-8-services-001`. Every finding block ends with the exact provisional marker line:

* `Disposition: provisional Section 8 residual candidate (resolved by outer finalize)`

Never combine zone-failure and regional-failover evidence in one finding. If the same canonical dependency or category and observation applies to both scenarios with materially different evidence, emit two findings.

## Output

Write the sub-fragment to `<subFragmentDir>/services.md`, where `<subFragmentDir>` is the `subFragmentDir` recorded in the sub-manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-consolidate-8-5-services`, `group-key: services`, `services-applicability: <value from sub-manifest>`, `schema-version: hve-resiliency-consolidate-8-split/v1`, and the sub-fragment's terminal status.

* When `servicesApplicability` is `applicable`, follow the frontmatter with the subsection `## Group services Provisional Findings` containing every emitted provisional finding.
* When `servicesApplicability` is `not-applicable`, follow the frontmatter with the subsection `## Group services Provisional Findings` containing a single acknowledgement line: `Services group not applicable per sub-manifest; negative-check scope recorded in the completion report.` Emit no provisional finding.

Do not modify the sub-skeleton artifact. Do not touch any other sub-fragment. Do not write `sections/section-8.md`.

## Completion

Report the accepted service artifact `promptId` values read (or the `not-applicable` state and negative-check scope), the provisional finding count, the retained source-record totals, the sub-fragment path, and the terminal sub-fragment status.

> **Next step:** Run `/hve-resiliency-consolidate-8-verify`
