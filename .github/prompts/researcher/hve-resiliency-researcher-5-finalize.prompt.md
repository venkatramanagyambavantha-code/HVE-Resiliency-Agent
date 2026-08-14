---
description: Finalize the split Prompt 5 pipeline - assemble the four outcome fragments into the single Prompt 5 research artifact consumed by Consolidate 5
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - Finalize

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt assembles the four outcome fragments into the final Prompt 5 research artifact. It does not run repository traversal, does not read Prompt 1a or Prompt 1b, does not re-derive the eligible dependency list, and does not render new rows.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the finalize stage. Do not run any outcome fill or verify behavior.
* Require the manifest to exist, be readable, be sanitizable, and be well-formed per the Frozen Manifest Sidecar Contract.
* Require the skeleton artifact at the manifest's `skeletonPath` to exist and still carry the four fragment placeholder comments emitted by the scaffold prompt.
* Require the verify audit report at `<fragmentDir>/verify-audit.md` to exist and to have a terminal verify status. If the verify audit is missing, stop `Blocked` with `verify audit missing`.

## Read Scope

Load the manifest, the four outcome fragment files, the skeleton artifact, and the verify audit report. Do not read Prompt 1a, Prompt 1b, or any other researcher artifact. Do not read repository source files; every citation was validated in verify.

## Assembly Protocol

1. Read each fragment's frontmatter and terminal status. Compute the pipeline-level status per the Status Aggregation rules below.
2. Preserve every row exactly as emitted. Copy each row's fields, IDs, and citations verbatim. Never renumber row IDs, merge rows, split rows, add fields, or reword any field.
3. Assemble the four fragments into the skeleton in this fixed order: 5.1 Startup Failure, 5.2 Silent Functional Degradation, 5.3 Data Loss or Partial Processing, 5.4 Blocking Transactions. Replace each `<!-- fragment placeholder ... -->` comment in the skeleton with the corresponding fragment body starting immediately after that fragment's own `## 5.<n>` heading. Preserve the skeleton's frontmatter, Scope and Assumptions section, and Task Implementation Requests section.
4. If the verify audit's `## Cross-Fragment Findings` list reports a `cross-fragment-overlap` row-key, keep both rows in place, add a single line under the row on the newer-emission fragment: `Cross-fragment overlap: also emitted as <other-row-id> in <other-fragment>.` Do not delete either row. Do not renumber either row.
5. Assemble the ledger section: replace the skeleton's `<!-- ledger placeholder ... -->` comment with a `## Ledger and Terminal Outcomes` table listing, per outcome fragment, the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, and the fragment's terminal status. Include one final row for the pipeline-level status computed in step 1.
6. Update the skeleton frontmatter: set `pipeline-stage: finalized`, set `status` to the pipeline-level status, and set `ms.date` to the current UTC date.

## Status Aggregation

The pipeline-level status is:

* `Blocked` if any fragment status is `Blocked`, or the verify audit contains `unsafe`, `fragment-header-invalid`, `dependency-out-of-scope`, `outcome-mismatch`, `scenario-combined`, or `prohibited-content` items that were not resolved by an operator before finalize was invoked.
* `Incomplete` otherwise if any fragment status is `Incomplete`, or the verify audit lists any `## Manual Review Required` item, or any emitted row carries `Unknown: not found after bounded search <scope>` in a nullable field.
* `Complete` only when every fragment status is `Complete`, the verify audit's `## Manual Review Required` list is empty, and no row carries any `Unknown` descriptor.

## Output

Write the assembled result back to the skeleton path recorded in the manifest, overwriting the placeholder skeleton. Do not create a separate final file. Do not modify the manifest. Do not modify or delete the fragment files or the verify audit; they remain as run evidence.

## Completion

Report the total row count per outcome, the count of overlap annotations added, the pipeline-level status, and the final artifact path.

The final artifact is now consumable by `hve-resiliency-consolidate-5-failure-degraded`.

> **Next step:** Run `/hve-resiliency-researcher-6`
