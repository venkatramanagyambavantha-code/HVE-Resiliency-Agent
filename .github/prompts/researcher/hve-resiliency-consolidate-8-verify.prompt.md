---
description: Verify the five group sub-fragments of the split Consolidate 8 pipeline against the Section 8 sub-manifest and routed source artifacts, report-only
agent: "Task Researcher"
argument-hint: "[subManifestPath=...]"
---

# HVE Resiliency Consolidate 8 - Verify

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt audits the five group sub-fragments only. It reports findings; it does not renumber, add, reorder, or render new provisional findings, does not edit sub-fragments, does not modify the sub-skeleton, and does not write `sections/section-8.md`.

## Inputs

* ${input:subManifestPath}: (Optional) Workspace-relative path to the frozen Section 8 sub-manifest sidecar emitted by `hve-resiliency-consolidate-8-0-scaffold`. When omitted, auto-locate it per the Sub-Manifest Auto-Location rule in the Consolidate 8 Split Contract.

## Direct Invocation and Prerequisite

* Run only the verify stage. Do not run any group fill or the finalize behavior.
* Require the sub-manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Sub-Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not write an audit report.
* Require the outer manifest at the sub-manifest's `outerManifestPath` to still be readable and its sanitized SHA-256 digest to match `outerManifestSha256`. On mismatch, stop `Blocked` with `outer manifest drift`.
* Require all five sub-fragment files (`core-context.md`, `platform-state.md`, `failure-crossrepo.md`, `secrets-adjacent.md`, `services.md`) to exist under the sub-manifest's `subFragmentDir`. Missing sub-fragments are reported as `fragment-missing`; verification continues on the present sub-fragments.

## Read Scope

Read the frozen sub-manifest, the outer consolidation manifest, the five sub-fragment files, and only the accepted source artifacts routed to each group per the sub-manifest's `groupRouting`. Do not re-run outer discovery, do not re-derive the group routing table, and do not read source artifacts outside the audited groups.

## Verification Protocol

For each sub-fragment, confirm in this exact order and record one terminal disposition per provisional finding:

1. **Sub-fragment identity.** The sub-fragment's frontmatter declares the expected `source-prompt`, `group-key`, `schema-version: hve-resiliency-consolidate-8-split/v1`, and a terminal status (`Blocked`, `Incomplete`, or `Complete`). The `services` sub-fragment additionally declares `services-applicability` and it must match the sub-manifest's `servicesApplicability`. Reject any sub-fragment whose `group-key` disagrees with its file name or with the sub-manifest's `groupRouting`. Record `fragment-header-invalid` and stop verification for that sub-fragment when invalid.
2. **Finding-schema completeness.** Every provisional finding carries all Required Finding Schema fields in the order defined by the outer Consolidation Shared Contract, plus the provisional marker bullet defined by the shared split contract. Section-scoped IDs use the correct pattern for the group key (`F-8-<group-key>-00X`). Findings carry exactly one allowed scenario. Record `schema-incomplete` when any closed field is missing, blank, or uses `Unknown`, and `provisional-marker-missing` when the exact provisional marker bullet is absent.
3. **Group scope.** Every provisional finding cites an Evidence path that belongs to an accepted source artifact recorded in the sub-manifest's `groupRouting.<group-key>` list, or is derived from such an artifact through a normalized source record whose provenance the outer manifest records. Record `group-out-of-scope` otherwise.
4. **Residual discipline.** No provisional finding's canonical tuple is claimed by any of Sections 1-7 under the outer Section-to-Source Mapping, the Section 2.1 service-finding scope, or the Section 7 secret sweep scope. Record `section-precedence-conflict` when a canonical tuple must be dropped by outer finalize; leave the record in place for outer finalize to resolve.
5. **Scenario discipline.** No provisional finding combines zone-failure and regional-failover evidence. Record `scenario-combined` when both scenarios are cited on one finding.
6. **Citation validity.** Every citation in an Evidence field resolves verbatim to the routed accepted source artifact and its recorded evidence lines. Never estimate or recalculate line numbers. Record `citation-drift` when a cited path or line range differs from the routed source artifact, `path-unresolved` when the path does not resolve, or `line-out-of-range` when the cited lines fall outside the source artifact.
7. **Prohibited content.** No provisional finding contains recommendations, remediation, alternatives, examples, or implementation guidance. Record `prohibited-content` when detected.
8. **Sanitization.** No provisional finding reproduces a raw secret value or a raw PII value. This check is strict for the `secrets-adjacent` sub-fragment. Record `unsafe` when detected and stop verification for that sub-fragment.
9. **Services applicability discipline.** When the sub-manifest's `servicesApplicability` is `not-applicable`, the `services` sub-fragment must carry the single acknowledgement line described in the services fill contract and zero provisional findings. Record `services-applicability-violation` otherwise. When `servicesApplicability` is `applicable`, no acknowledgement line is permitted in place of provisional findings.

## Cross-Fragment Checks

After per-finding verification, check:

* Finding-ID uniqueness within each sub-fragment.
* No duplicate finding key (canonical tuple defined by the outer Consolidation Shared Contract) inside a single sub-fragment. Record `duplicate-finding-key`.
* Cross-fragment overlap where the same canonical tuple appears in more than one sub-fragment. This should not occur because group routing is disjoint; record `cross-fragment-overlap` on the sub-fragment whose emission-order-derived finding ID sorts higher and leave both records in place. The nested finalize prompt preserves both; the outer finalize resolves overlaps by section precedence.

## Bounds

Process at most 400 provisional findings across all sub-fragments. Read each sub-fragment file's bytes exactly once. Read each routed accepted source artifact at most twice: once for verification and once, only when needed, for a bounded corrective reread against a named record. Total source reads must not exceed 400. Reaching either cap stops new admission but permits reconciliation of already-admitted records.

## Audit Report

Write exactly one audit report to `<subFragmentDir>/verify-audit.md`. The audit report contains exactly these sections in this order:

* Frontmatter with `producer: hve-resiliency-consolidate-8-verify`, `sub-manifest-path`, `status`, `schema-version: hve-resiliency-consolidate-8-split/v1`, and `ms.date`.
* `## Summary` with counts by disposition, sub-fragments audited, source files read, provisional findings processed, and hard-limit state.
* `## Findings` table with columns `findingId`, `subFragment`, `groupKey`, `dependencyOrCategory`, `scenario`, `disposition`, and `notes`. One row per verified provisional finding.
* `## Cross-Fragment Findings` list of `duplicate-finding-key` and `cross-fragment-overlap` items with the offending canonical tuple and involved sub-fragments.
* `## Manual Review Required` list of finding IDs with disposition `fragment-header-invalid`, `schema-incomplete`, `provisional-marker-missing`, `group-out-of-scope`, `section-precedence-conflict`, `scenario-combined`, `citation-drift`, `path-unresolved`, `line-out-of-range`, `prohibited-content`, `services-applicability-violation`, or `unsafe`, each with a one-sentence sanitized note.
* `## Sanitization Notes` list of any provisional findings redacted due to secret or PII detection.

Do not edit sub-fragments. Do not modify the sub-skeleton or the sub-manifest. Do not write `sections/section-8.md`.

## Completion

Report the sub-fragments audited, disposition totals, cross-fragment issue count, manual-review count, and terminal verify status (`Blocked`, `Incomplete`, or `Complete`).

> **Next step:** Run `/hve-resiliency-consolidate-8-finalize`
