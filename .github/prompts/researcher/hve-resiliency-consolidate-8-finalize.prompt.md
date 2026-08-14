---
description: Finalize the split Consolidate 8 pipeline - assemble the five group sub-fragments into the single Section 8 fragment (sections/section-8.md) consumed by the outer verify-5-8 and outer finalize prompts
agent: "Task Researcher"
argument-hint: "[subManifestPath=...]"
---

# HVE Resiliency Consolidate 8 - Finalize

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt assembles the five group sub-fragments into the single Section 8 fragment consumed downstream. It does not read source artifacts, does not re-derive the group routing table, does not run cross-section-precedence checks (owned by outer finalize), and does not renumber section-scoped IDs into the authoritative `F-00X` scheme (also owned by outer finalize).

## Inputs

* ${input:subManifestPath}: (Optional) Workspace-relative path to the frozen Section 8 sub-manifest sidecar emitted by `hve-resiliency-consolidate-8-0-scaffold`. When omitted, auto-locate it per the Sub-Manifest Auto-Location rule in the Consolidate 8 Split Contract.

## Direct Invocation and Prerequisite

* Run only the finalize stage. Do not run any group fill or verify behavior.
* Require the sub-manifest to exist, be readable, be sanitizable, and be well-formed per the Frozen Sub-Manifest Sidecar Contract.
* Require the outer manifest at the sub-manifest's `outerManifestPath` to still be readable and its sanitized SHA-256 digest to match `outerManifestSha256`. On mismatch, stop `Blocked` with `outer manifest drift`.
* Require the sub-skeleton at the sub-manifest's `subSkeletonPath` to exist and still carry the six placeholder comments (`group core-context placeholder`, `group platform-state placeholder`, `group failure-crossrepo placeholder`, `group secrets-adjacent placeholder`, `group services placeholder`, `ledger placeholder`) emitted by the scaffold prompt.
* Require the verify audit report at `<subFragmentDir>/verify-audit.md` to exist and to have a terminal verify status. If the verify audit is missing, stop `Blocked` with `verify audit missing`.

## Read Scope

Load the sub-manifest, the five group sub-fragment files, the sub-skeleton, and the verify audit report. Do not read the outer manifest beyond confirming its SHA-256 digest. Do not read source artifacts; every citation was validated in verify.

## Assembly Protocol

1. Read each sub-fragment's frontmatter and terminal status. Compute the nested-pipeline status per the Status Aggregation rules below.
2. Preserve every provisional finding exactly as emitted. Copy each finding's fields, section-scoped IDs (`F-8-<group-key>-00X`), citations, and provisional marker bullet verbatim. Never renumber IDs, merge findings, split findings, add fields, or reword any field. Never convert section-scoped IDs to `F-00X`; that reconciliation belongs to the outer finalize prompt.
3. Assemble the assembled Section 8 fragment by inserting each sub-fragment's `## Group <group-key> Provisional Findings` subsection body under a `### <group-key>` sub-subheading, in this fixed order: `core-context`, `platform-state`, `failure-crossrepo`, `secrets-adjacent`, `services`. Each `### <group-key>` sub-subheading is placed at the sub-skeleton's corresponding `<!-- group <group-key> placeholder ... -->` comment.
4. When the `services` sub-fragment carries `services-applicability: not-applicable`, place its acknowledgement line in place of provisional findings under `### services` verbatim.
5. If the verify audit's `## Cross-Fragment Findings` list reports a `cross-fragment-overlap` canonical tuple, leave every listed provisional finding in place and add a single line under the finding on the sub-fragment whose finding ID sorts higher: `Cross-fragment overlap: also emitted as <other-id> in <other-sub-fragment>.` Do not delete or renumber either finding; the outer finalize applies the section-precedence tie-break across sections and both records inform its decision.
6. Assemble the ledger section: replace the sub-skeleton's `<!-- ledger placeholder ... -->` comment with a `### Ledger and Terminal Outcomes` table listing, per group sub-fragment, the provisional finding count, the count of provisional findings carrying `Unknown: evidence unavailable` or `Not observed in completed sources` in nullable prose fields, and the sub-fragment's terminal status. Include one final row for the nested-pipeline status computed in step 1.
7. Write the assembled body under the `## 8. Other Findings Not Categorized Above` heading to `<consolidatedDocDir>/sections/section-8.md`. The outer verify-5-8 and outer finalize prompts consume this file.
8. Update the sub-skeleton frontmatter: set `pipeline-stage: finalized`, set `status` to the nested-pipeline status, and set `ms.date` to the current UTC date. Do not modify the sub-manifest.

## Status Aggregation

The nested-pipeline status is:

* `Blocked` if any sub-fragment status is `Blocked`, or the verify audit contains any `## Manual Review Required` item with disposition `unsafe`, `fragment-header-invalid`, `provisional-marker-missing`, `group-out-of-scope`, `scenario-combined`, `prohibited-content`, `services-applicability-violation`, `citation-drift`, `path-unresolved`, or `line-out-of-range` that was not resolved by an operator before finalize was invoked.
* `Incomplete` otherwise if any sub-fragment status is `Incomplete`, or the verify audit lists any remaining `## Manual Review Required` item.
* `Complete` only when every sub-fragment status is `Complete`, the verify audit's `## Manual Review Required` list is empty, and no cross-fragment `duplicate-finding-key` is reported.

`section-precedence-conflict` items in the verify audit do not alone force `Blocked` or `Incomplete`; they are surfaced to outer finalize by preserving the affected provisional findings.

## Output

Write the assembled Section 8 fragment to `<consolidatedDocDir>/sections/section-8.md`, beginning with the `## 8. Other Findings Not Categorized Above` heading. Mark every rendered finding as PROVISIONAL by preserving its provisional marker bullet verbatim. Do not modify the sub-manifest. Do not modify or delete the sub-fragment files or the verify audit; they remain as run evidence. Do not modify the outer consolidation document; the outer finalize prompt does.

## Completion

Report the provisional finding count per group, the count of overlap annotations added, the nested-pipeline status, the assembled Section 8 fragment path, and the sub-skeleton path.

The assembled `sections/section-8.md` is now consumable by `hve-resiliency-consolidate-verify-5-8` and by `hve-resiliency-consolidate-9-finalize`.

> **Next step:** Run `/hve-resiliency-consolidate-verify-5-8`
