---
description: Shared evidence-only contract for the split HVE Resiliency Consolidate 8 (Other Findings) pipeline (scaffold, group-fill, verify, finalize prompts)
applyTo: '.github/prompts/researcher/hve-resiliency-consolidate-8-*.prompt.md'
---

# HVE Resiliency Consolidate 8 Split Contract

Apply this contract to every prompt in the split Consolidate 8 pipeline: the scaffold prompt, the five group-fill prompts, the verify prompt, and the finalize prompt. Each pipeline prompt inherits these stage-invariant rules and adds only its stage-specific behavior. When a pipeline prompt conflicts with this contract, the pipeline prompt's stage-specific scope takes precedence for that stage only; the evidence-only prohibitions and output schema below are never overridden.

This split pipeline is a nested sub-pipeline inside the outer HVE Resiliency Consolidation pipeline. Use the [Consolidation Shared Contract](hve-resiliency-consolidation-shared.instructions.md) for the outer manifest contract, sanitization, line-number integrity, the Required Finding Schema, schema-safe values, the source-record canonical-tuple identity, and evidence-only prohibitions. Use [Application Platform Context](hve-resiliency-platform-context.instructions.md) for inherited platform scenarios, dependency applicability rules, and P0-P3 definitions.

The nested pipeline replaces the retired single-shot `hve-resiliency-consolidate-8-other` prompt. It produces exactly one Section 8 fragment file consumed by the outer verify and outer finalize prompts.

## Pipeline Overview

The split Consolidate 8 workflow is a bounded sub-pipeline that fills Section 8 (Other Findings Not Categorized Above) of the consolidated resiliency research document:

1. Scaffold (`-8-0-scaffold`): validate the outer consolidation manifest once, freeze the Section 8 group-routing table derived from the outer manifest's accepted artifacts, emit an empty Section 8 sub-skeleton fragment file plus a Section 8 sub-manifest sidecar. No provisional findings are rendered.
2. Group fill (`-8-1-core-context`, `-8-2-platform-state`, `-8-3-failure-crossrepo`, `-8-4-secrets-adjacent`, `-8-5-services`): each prompt reads only the Section 8 sub-manifest, the outer manifest, and the accepted source artifacts routed to its group; emits Section 8 provisional findings for exactly one artifact group; and writes them to its own sub-fragment file. The five fills may run in any order and never edit each other's sub-fragments or the sub-skeleton.
3. Verify (`-8-verify`): audit all five group sub-fragments against the Section 8 sub-manifest and against the source artifacts routed to each group. Report-only.
4. Finalize (`-8-finalize`): assemble the five group sub-fragments into the single Section 8 fragment (`sections/section-8.md`) consumed by the outer verify-5-8 and outer finalize prompts. Set nested-pipeline status once. Preserve provisional markers and section-scoped IDs; never renumber into `F-00X`.

Every artifact emitted by this nested pipeline uses schema version `hve-resiliency-consolidate-8-split/v1` and targets the current repository.

## Evidence-Only Prohibitions

Preserve the Task Researcher evidence-only contract end to end. Do not enter Task Researcher Phase 2. Do not produce alternatives, recommendations, selected approaches, examples, implementation details, design changes, remediation, advisory language, or next-step suggestions beyond the single Next step link required by the platform context. Do not introduce artifact groups beyond the five declared in Artifact Groups below. Do not re-run discovery. Do not read Prompt 1a, Prompt 1b, or any accepted source artifact directly during scaffold; scaffold reads only the outer manifest. Emit only sanitized, evidence-backed provisional findings.

## Frozen Sub-Manifest Sidecar Contract

The scaffold prompt emits one frozen sub-manifest sidecar alongside the Section 8 sub-skeleton. Every downstream stage of this nested pipeline reads this sub-manifest and never repeats prerequisite validation, outer-manifest parsing, or group routing. The sub-manifest is deterministic and stable across reads.

The sub-manifest records:

* `schemaVersion`: `hve-resiliency-consolidate-8-split/v1`.
* `repository`: current workspace root basename (must equal the outer manifest's repository).
* `generatedAt`: UTC date `YYYY-MM-DD`.
* `outerManifestPath`: normalized workspace-relative path to the outer consolidation manifest.
* `outerManifestSha256`: lowercase SHA-256 hexadecimal digest of the outer manifest's sanitized bytes at scaffold time.
* `consolidatedDocDir`: normalized workspace-relative directory that holds `sections/section-8.md`.
* `subSkeletonPath`: normalized workspace-relative path to the Section 8 sub-skeleton fragment file emitted by scaffold.
* `subFragmentDir`: normalized workspace-relative directory holding the five group sub-fragments. Fixed to `<consolidatedDocDir>/sections/section-8-fragments/`.
* `groupRouting`: the five fixed routing keys `core-context`, `platform-state`, `failure-crossrepo`, `secrets-adjacent`, `services`, each mapped to its fill prompt ID, its sub-fragment file name, and the enumerated accepted source artifact records that the group owns.
* `sources`: the accepted source artifact records copied verbatim from the outer manifest, each carrying `promptId`, normalized `path`, `completionStatus`, and `contentSha256`.
* `servicesApplicability`: `applicable` when the outer manifest records at least one accepted optional service artifact (Prompt IDs `8`-`19`), otherwise `not-applicable`. This value is frozen; downstream stages do not re-derive it.

## Sub-Manifest Auto-Location

When a prompt's `subManifestPath` input is omitted, auto-locate the frozen Section 8 sub-manifest sidecar instead of asking the user. Enumerate files named `section-8.manifest.md` under `.copilot-tracking/research/` within any `sections/section-8-fragments/` directory. Select the candidate under the lexicographically largest `YYYY-MM-DD` dated ancestor segment; if dated segments tie or are absent, select the one whose normalized path sorts last using ordinal comparison. Never use file modification time. If exactly one resolves, use it. If none resolve, stop `Blocked` with `Section 8 sub-manifest not found; run hve-resiliency-consolidate-8-0-scaffold first`. An explicitly supplied path always overrides auto-location. When `-8-0-scaffold` runs with `outerManifestPath` omitted, resolve it through the outer Manifest Auto-Location rule in the Consolidation Shared Contract.

Downstream stages read the outer manifest through this sub-manifest's `outerManifestPath`; they never re-run outer discovery. If the outer manifest's SHA-256 drifts between stages, the affected stage stops `Blocked` with `outer manifest drift`.

## Artifact Groups (inherited by every group-fill prompt)

The five artifact groups are the only routing axes for this pipeline. Each group-fill prompt owns exactly one group and emits provisional Section 8 findings only for that group.

* `core-context`: Prompts `0`, `1a`, `1b`. Residuals from repository context and dependency inventory scaffolding that map to no other section.
* `platform-state`: Prompts `2`, `3`, `4`. Residuals from region and zone, state and data, and adjacent platform-context artifacts that map to no other section.
* `failure-crossrepo`: Prompts `5`, `6`. Residuals from failure and degraded-mode behavior and shared cross-repository dependency artifacts that map to no other section.
* `secrets-adjacent`: Prompt `7`. Residuals sanitized by the Prompt 7 secret sweep that are not hard-coded secret or value findings and that map to no other section.
* `services`: applicable optional Prompt IDs `8` through `19`. Membership is exactly the accepted service artifact records recorded in the sub-manifest's `groupRouting.services` entry. When `servicesApplicability` is `not-applicable`, the services group emits zero provisional findings and its sub-fragment records the negative-check scope.

Both platform scenarios apply: West US 2 zone failure and West US 2 to West US regional failover. Never combine zone and regional evidence in one provisional finding.

## Residual Discipline

A Section 8 provisional finding is a residual candidate: sanitized evidence retained from an accepted source artifact that maps to no other section (Sections 1-7) under the outer Section-to-Source Mapping.

Each group-fill prompt must, for every candidate finding it considers:

* Confirm the underlying source record maps to no other section by inspecting the outer Section-to-Source Mapping and the Section 2.1 service-finding scope and Section 7 secret sweep scope defined in the outer Consolidation Shared Contract.
* Drop any candidate that Sections 1-7 primary or scoped rules already claim, without emitting the record and without renumbering.
* Retain every candidate whose canonical tuple does not match a primary or scoped rule for Sections 1-7 as a provisional Section 8 finding. Do not attempt cross-section overlap resolution during fill; the outer finalize prompt applies the section-precedence tie-break.

Never expand assessment scope through Section 8. Never introduce a new dependency category, failure mode class, or scenario in Section 8 that is not permitted by the outer Consolidation Shared Contract.

## Provisional Marker

Every finding emitted by a group-fill prompt is a PROVISIONAL residual candidate. Every group-fill prompt and the nested finalize prompt must retain a stable provisional marker on every emitted finding. Use the exact line, as a bullet inside the finding block:

* `Disposition: provisional Section 8 residual candidate (resolved by outer finalize)`

The outer verify-5-8 prompt applies its `provisional-ok` disposition to entries carrying this marker. The outer finalize prompt drops any provisional candidate whose canonical tuple appears in a finding retained by Sections 1-7 and preserves the remainder in the assembled consolidated document.

## Bounded Discovery

Limits are per accepted source artifact within a group and per group-fill prompt. Aliases, environments, wording, questions, repeated research, and delegated actions cannot reset or transfer a counter.

* At most 1 sanitized-read pass per accepted source artifact assigned to the group.
* At most 20 candidate findings surfaced per accepted source artifact.
* At most 5 candidate normalized source records held for cross-section-precedence checks per accepted source artifact.
* At most 1 bounded corrective reread per named defect during finalize.
* Exclude any artifact whose `completionStatus` in the outer manifest is not `Complete`.

Treat every reached numeric limit as source exhaustion. Do not broaden, reword, or repeat that discovery route afterward.

## Finding Identity and Deduplication

Use the outer source-record canonical identity tuple defined in the Consolidation Shared Contract: `dependencyOrCategory`, `failureMode`, `lineRange`, `path`, `scenario`, and `sourceFindingIdentity`. Compute the tuple only after sanitization and normalization. Deduplicate provisional findings only on exact canonical-tuple matches within one group sub-fragment.

Across groups, the five fill prompts operate on disjoint accepted source artifact sets, so the same canonical tuple cannot appear in more than one group sub-fragment. If a fill prompt observes a candidate whose accepted source artifact belongs to another group's set, drop the candidate and do not emit it in the current fragment.

## Section-Scoped Finding IDs

Every group-fill prompt allocates section-scoped finding IDs of the form `F-8-<group-key>-00X`, assigned in emission order starting at `F-8-<group-key>-001` (for example `F-8-core-context-001`, `F-8-services-004`). The nested finalize prompt preserves these IDs verbatim in the assembled `sections/section-8.md`; it does not renumber, merge, or reorder them.

The outer finalize prompt reconciles the assembled Section 8 fragment's `F-8-<group-key>-00X` IDs into the authoritative sequential `F-00X` scheme exactly once, by canonical tuple order across all sections. No stage of this nested pipeline uses `F-00X`.

## Required Finding Schema

Every provisional finding uses the outer Consolidation Shared Contract's Required Finding Schema exactly once, with the section-scoped ID form `F-8-<group-key>-00X` in place of `F-00X`, and with the provisional marker bullet appended verbatim.

* Dependency or Category: <canonical dependency or category>
* Priority: P0 | P1 | P2 | P3
* Ownership: <evidence-backed owner or schema-safe value>
* Scenario: West US 2 zone failure | West US 2 to West US regional failover
* Description: <evidence-based current behavior>
* Failure Mode and Scenario-Specific Risk: <evidence-based risk>
* Impacts: <operational, data, financial, and customer impacts supported by evidence>
* Evidence: `<normalized-path>:L<start>-L<end>`
* Source Record IDs: <one or more retained NR IDs>
* Existing Mitigations: <evidence-backed mitigations or schema-safe value>
* Constraints and Limitations: <evidence-backed constraints or schema-safe value>
* Disposition: provisional Section 8 residual candidate (resolved by outer finalize)

Every closed field must resolve to positive evidence copied verbatim from an accepted source artifact assigned to the group. Never use `Unknown` in closed fields; retain the record without rendering when a closed field cannot be filled.

Permit `Unknown: evidence unavailable`, bounded `Not observed in completed sources`, or `None found` only in the nullable prose fields defined by the outer Consolidation Shared Contract (ownership boundary, impacts, existing mitigations, constraints and limitations).

## Sanitization and Line Number Integrity

Sanitize buffered content immediately after reading and before any write, hash, comparison, or emitted record. Never retain or reproduce secret values. Normalize workspace-relative paths to `/` while preserving repository path case. Encode text as UTF-8 without a byte-order mark. Use lowercase SHA-256 hexadecimal digests.

For potential secrets observed in a source artifact, retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity. Mark an artifact unsafe and stop `Blocked` when sanitization cannot be guaranteed. The `secrets-adjacent` fill in particular must never reproduce a secret value or a reversible derivative.

Never estimate line numbers. Never merge line ranges. Never recalculate line numbers. Copy file paths and line numbers verbatim from the source artifact. If a line number cannot be validated, do not emit the provisional finding.

## Output Locations

* Sub-skeleton fragment: `<consolidatedDocDir>/sections/section-8-fragments/section-8.sub-skeleton.md`.
* Sub-manifest sidecar: `<consolidatedDocDir>/sections/section-8-fragments/section-8.manifest.md`.
* Sub-fragment directory: `<consolidatedDocDir>/sections/section-8-fragments/`.
* Sub-fragment files: `core-context.md`, `platform-state.md`, `failure-crossrepo.md`, `secrets-adjacent.md`, `services.md`.
* Verify audit report: `<consolidatedDocDir>/sections/section-8-fragments/verify-audit.md`.
* Final assembled Section 8 fragment: `<consolidatedDocDir>/sections/section-8.md`.

The nested finalize prompt writes `sections/section-8.md`. It never modifies the sub-skeleton, the sub-manifest, or the sub-fragments; they remain as run evidence.

## Status and Stopping

Every stage sets exactly one terminal status on its own output:

* `Blocked`: outer manifest missing, unreadable, drifted, or malformed; sub-manifest missing or malformed; unsafe evidence encountered; a hard limit was reached before the stage could establish a coherent output; or a required outer prompt ID is absent from the outer manifest's accepted artifact set.
* `Incomplete`: bounded discovery exhausted with at least one accepted source artifact contributing zero considered candidates due to hard-limit truncation, or one or more sub-fragments carry `Incomplete` at finalize time.
* `Complete`: every accepted source artifact in the group was scanned to a terminal ledger outcome and every emitted provisional finding conforms to the Required Finding Schema and the residual discipline.

The nested-pipeline status is set exclusively by the nested finalize prompt on the assembled `sections/section-8.md`, based on the terminal status of each of the five sub-fragments plus the nested verify report. The outer consolidation pipeline's overall status remains the responsibility of the outer finalize prompt (`hve-resiliency-consolidate-9-finalize`).
