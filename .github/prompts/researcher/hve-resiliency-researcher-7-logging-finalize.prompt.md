---
description: Finalize the split Prompt 7 Logging pipeline - assemble the five category fragments into the single Prompt 7 research artifact and build the Section 3 planning handoff
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 7 Logging - Finalize

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt assembles the five category fragments into the final Prompt 7 research artifact. It does not run repository traversal, does not read Prompt 1a or Prompt 1b, does not re-derive the eligible dependency list, and does not render new inventory rows or findings.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-7-logging-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 7 Logging Split Contract.

## Direct Invocation and Prerequisite

* Run only the finalize stage. Do not run any category fill or verify behavior.
* Require the manifest to exist, be readable, be sanitizable, and be well-formed per the Frozen Manifest Sidecar Contract.
* Require the skeleton artifact at the manifest's `skeletonPath` to exist and still carry the four placeholder comments (`inventory placeholder`, `findings placeholder`, `handoff placeholder`, `ledger placeholder`) emitted by the scaffold prompt.
* Require the verify audit report at `<fragmentDir>/verify-audit.md` to exist and to have a terminal verify status. If the verify audit is missing, stop `Blocked` with `verify audit missing`.

## Read Scope

Load the manifest, the five category fragment files, the skeleton artifact, and the verify audit report. Do not read Prompt 1a, Prompt 1b, or any other researcher artifact. Do not read repository source files; every citation was validated in verify.

## Assembly Protocol

1. Read each fragment's frontmatter and terminal status. Compute the pipeline-level status per the Status Aggregation rules below.
2. Preserve every inventory row and every finding exactly as emitted. Copy each record's fields, IDs, and citations verbatim. Never renumber IDs, merge records, split records, add fields, or reword any field.
3. Assemble Section 1 by concatenating each fragment's `## Category <category-key> Inventory Rows` subsection body under the skeleton's `## Section 1 Current Logging Inventory` heading, in this fixed order: `startup-health`, `transactions`, `correlation-context`, `log-hygiene`, `silent-outage-diagnostics`. Precede each fragment's contribution with a `### <category-key>` sub-subheading. Replace the `<!-- inventory placeholder ... -->` comment with the assembled content. End Section 1 with a `Limitations:` line summarizing per-fragment bounded-discovery counters recorded in each fragment.
4. Assemble Section 2 by concatenating each fragment's `## Category <category-key> Findings` subsection body under the skeleton's `## Section 2 Prioritized Gaps and Risks` heading, in the same fixed category order. Precede each fragment's contribution with a `### <category-key>` sub-subheading. Replace the `<!-- findings placeholder ... -->` comment with the assembled content.
5. End Section 2 with exactly one closing question: `Can we diagnose a silent payment outage?` when the manifest's `paymentApplicability` is `applicable`, otherwise `Can we diagnose a silent transaction outage?`. Synthesize only finding IDs and confirmed inventory evidence in the surrounding paragraph; do not repeat impacts.
6. Build Section 3 by iterating every Section 2 finding in emission order and rendering one row per finding with: Finding ID, Observed missing capability (verbatim `Diagnostic outcome` field), Evidence (verbatim `Evidence citations` field), Constraints (verbatim `Constraints` field or blank when Unknown), Planner owner or scope (verbatim from the finding when repository-evidenced, blank otherwise). Add no new finding, no prescriptive language, and no content beyond the fields defined here. Replace the `<!-- handoff placeholder ... -->` comment with the assembled content.
7. If the verify audit's `## Cross-Fragment Findings` list reports a `cross-fragment-overlap` key, keep both records in place and add a single line under the record on the newer-emission fragment: `Cross-fragment overlap: also emitted as <other-id> in <other-fragment>.` Do not delete or renumber either record.
8. Assemble the ledger section: replace the skeleton's `<!-- ledger placeholder ... -->` comment with a `## Ledger and Terminal Outcomes` table listing, per category fragment, the inventory row count, the finding count, the count of findings carrying any `Unknown: not found after bounded search <scope>` descriptor, and the fragment's terminal status. Include one final row for the pipeline-level status computed in step 1.
9. Update the skeleton frontmatter: set `pipeline-stage: finalized`, set `status` to the pipeline-level status, and set `ms.date` to the current UTC date.

## Status Aggregation

The pipeline-level status is:

* `Blocked` if any fragment status is `Blocked`, or the verify audit contains `unsafe`, `fragment-header-invalid`, `payment-discipline-violation`, `dependency-out-of-scope`, `category-mismatch`, `scenario-combined`, or `prohibited-content` items that were not resolved by an operator before finalize was invoked.
* `Incomplete` otherwise if any fragment status is `Incomplete`, or the verify audit lists any `## Manual Review Required` item, or any emitted finding carries `Unknown: not found after bounded search <scope>` in a nullable field.
* `Complete` only when every fragment status is `Complete`, the verify audit's `## Manual Review Required` list is empty, and no finding carries any `Unknown` descriptor.

## Output

Write the assembled result back to the skeleton path recorded in the manifest, overwriting the placeholder skeleton. Do not create a separate final file. Do not modify the manifest. Do not modify or delete the fragment files or the verify audit; they remain as run evidence.

## Completion

Report the total inventory row count per category, the total finding count per category, the count of overlap annotations added, the pipeline-level status, and the final artifact path.

The final artifact is now consumable by the downstream consolidation and planner prompts.

> **Next step:** Run the first applicable service-specific prompt from Phase 2, or `/hve-resiliency-consolidate-0-scaffold` if none apply
