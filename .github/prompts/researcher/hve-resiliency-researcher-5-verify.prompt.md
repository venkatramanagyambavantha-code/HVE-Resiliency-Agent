---
description: Verify the four outcome fragments of the split Prompt 5 pipeline against the frozen manifest and workspace source, report-only
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - Verify

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt audits the four outcome fragments only. It reports findings; it does not renumber rows, add rows, reorder rows, edit fragments, or modify the skeleton.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the verify stage. Do not run any outcome fill or the finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not write an audit report. If the manifest is well-formed but lists zero eligible dependencies, do not block: write a bounded audit report with no findings and a terminal `Complete` verify status.
* Require all four fragment files (`startup-failure.md`, `silent-degradation.md`, `data-loss-partial-processing.md`, `blocking-transactions.md`) to exist under the manifest's `fragmentDir`. Missing fragments are reported as `fragment-missing`; verification continues on the present fragments.

## Read Scope

Read the frozen manifest, the four fragment files, and only the repository source files referenced by fragment citations. The skeleton is still a placeholder at this stage; verify the fragments, not the skeleton. Do not read Prompt 1a, Prompt 1b, or any other researcher artifact. Do not re-derive the eligible dependency list.

## Verification Protocol

For each fragment, confirm in this exact order and record one terminal disposition per row:

1. **Fragment identity.** The fragment's frontmatter declares the expected `source-prompt`, `outcome-key`, and a terminal status (`Blocked`, `Incomplete`, or `Complete`). Reject any fragment whose `outcome-key` disagrees with its file name or with the manifest's `outcomeRouting`. Record `fragment-header-invalid` and stop verification for that fragment when invalid.
2. **Row-schema completeness.** Every row carries all Required Row Schema fields in the order defined by the shared contract, a section-scoped ID in the correct pattern for the outcome key (`F-5-startup-00X`, `F-5-degradation-00X`, `F-5-data-loss-00X`, or `F-5-blocking-00X`), exactly one allowed scenario, and a canonical failure-type value. Record `schema-incomplete` when any closed field is missing, blank, or uses `Unknown`.
3. **Dependency scope.** Every row's Triggering dependency resolves to an entry in the manifest's frozen `eligibleDependencies` list. Record `dependency-out-of-scope` otherwise.
4. **Outcome discipline.** Every row's Observed behavior maps to the fragment's outcome key. Record `outcome-mismatch` when a row belongs in a different fragment.
5. **Scenario discipline.** No row combines zone-failure and regional-failover evidence. Record `scenario-combined` when both scenarios are cited in one row.
6. **Citation validity.** Every citation in the Evidence citations field resolves to a workspace source file inside the source scope declared in the platform context. Never estimate or recalculate line numbers. Record `citation-drift` when a cited quoted fragment is present in the source at a different line, `citation-ambiguous` when it appears at more than one location, `quote-mismatch` when it is absent, `path-unresolved` when the path does not resolve, or `line-out-of-range` when the cited lines fall outside the file. When a row cites lines without an adjacent quoted fragment in the fragment file, record `citation-unverified-no-quote`; this is unverifiable by this stage but is not treated as wrong.
7. **Prohibited content.** No row contains recommendations, remediation, alternatives, examples, or implementation guidance. Record `prohibited-content` when detected.
8. **Sanitization.** No row reproduces a raw secret value. Record `unsafe` when detected and stop verification for that fragment.

## Cross-Fragment Checks

After per-row verification, check:

* Row-ID uniqueness within each fragment.
* No duplicate row-key (dependency + failure type + entrypoint + scenario) inside a single fragment. Record `duplicate-row-key`.
* Cross-fragment row overlap where the same row-key appears in more than one fragment. Record `cross-fragment-overlap` on the newer-emission fragment and leave both rows in place; the finalize prompt resolves overlaps.

## Bounds

Process at most 400 rows across all fragments. Read each fragment file's bytes exactly once. Read each referenced source file at most twice: once for verification and once, only when needed, for a bounded corrective reread against a named row. Total source reads must not exceed 400. Reaching either cap stops new admission but permits reconciliation of already-admitted rows.

## Audit Report

Write exactly one audit report to `<fragmentDir>/verify-audit.md`. The audit report contains exactly these sections in this order:

* Frontmatter with `producer: hve-resiliency-researcher-5-verify`, `manifestPath`, `status`, and `ms.date`.
* `## Summary` with counts by disposition, fragments audited, source files read, rows processed, and hard-limit state.
* `## Rows` table with columns `rowId`, `fragment`, `dependency`, `scenario`, `disposition`, and `notes`. One row per verified fragment row.
* `## Cross-Fragment Findings` list of `duplicate-row-key` and `cross-fragment-overlap` items with row-key and involved fragments.
* `## Manual Review Required` list of row IDs with disposition `quote-mismatch`, `citation-ambiguous`, `path-unresolved`, `line-out-of-range`, `outcome-mismatch`, `dependency-out-of-scope`, `scenario-combined`, `prohibited-content`, `schema-incomplete`, `fragment-header-invalid`, or `unsafe`, each with a one-sentence sanitized note.
* `## Sanitization Notes` list of any rows redacted due to secret detection.

Do not edit fragments. Do not modify the skeleton. Do not touch the manifest.

## Completion

Report the fragments audited, disposition totals, cross-fragment issue count, manual-review count, and terminal verify status (`Blocked`, `Incomplete`, or `Complete`).

> **Next step:** Run `/hve-resiliency-researcher-5-finalize`
