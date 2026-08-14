---
description: Verify the five category fragments of the split Prompt 7 Logging pipeline against the frozen manifest and workspace source, report-only
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 7 Logging - Verify

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt audits the five category fragments only. It reports findings; it does not renumber rows or findings, add rows or findings, reorder them, edit fragments, or modify the skeleton.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-7-logging-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 7 Logging Split Contract.

## Direct Invocation and Prerequisite

* Run only the verify stage. Do not run any category fill or the finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not write an audit report. If the manifest is well-formed but lists zero eligible dependencies, do not block: write a bounded audit report with no findings and a terminal `Complete` verify status.
* Require all five fragment files (`startup-health.md`, `transactions.md`, `correlation-context.md`, `log-hygiene.md`, `silent-outage-diagnostics.md`) to exist under the manifest's `fragmentDir`. Missing fragments are reported as `fragment-missing`; verification continues on the present fragments.

## Read Scope

Read the frozen manifest, the five fragment files, and only the repository source files referenced by fragment citations. The skeleton is still a placeholder at this stage; verify the fragments, not the skeleton. Do not read Prompt 1a, Prompt 1b, or any other researcher artifact. Do not re-derive the eligible dependency list.

## Verification Protocol

For each fragment, confirm in this exact order and record one terminal disposition per row or finding:

1. **Fragment identity.** The fragment's frontmatter declares the expected `source-prompt`, `category-key`, and a terminal status (`Blocked`, `Incomplete`, or `Complete`). The `transactions` fragment additionally declares `payment-applicability` and it must match the manifest's `paymentApplicability`. Reject any fragment whose `category-key` disagrees with its file name or with the manifest's `categoryRouting`. Record `fragment-header-invalid` and stop verification for that fragment when invalid.
2. **Row-schema completeness.** Every inventory row carries all Required Inventory Row Schema fields in the order defined by the shared contract, and every finding carries all Required Finding Schema fields in the order defined by the shared contract. Section-scoped IDs use the correct pattern for the category key (`I-7-<category-key>-00X` and `F-7-<category-key>-00X`). Findings carry exactly one allowed scenario. Record `schema-incomplete` when any closed field is missing, blank, or uses `Unknown`.
3. **Dependency scope.** Every row's Dependency or workflow and every finding's Dependency or workflow resolves to an entry in the manifest's frozen `eligibleDependencies` list, or to the payment `Not Applicable` summary row permitted by the shared contract. Record `dependency-out-of-scope` otherwise.
4. **Category discipline.** Every row and finding maps to the fragment's category key. Record `category-mismatch` when a row or finding belongs in a different fragment.
5. **Payment discipline.** When the manifest's `paymentApplicability` is `not-applicable`, the transactions fragment must contain exactly one payment summary inventory row marked `Not Applicable` and zero payment findings. Record `payment-discipline-violation` otherwise. When `paymentApplicability` is `applicable`, no payment summary row is permitted.
6. **Scenario discipline.** No finding combines zone-failure and regional-failover evidence. Record `scenario-combined` when both scenarios are cited on one finding.
7. **Citation validity.** Every citation in an Evidence citations field resolves to a workspace source file inside the source scope declared in the platform context. Never estimate or recalculate line numbers. Record `citation-drift` when a cited quoted fragment is present in the source at a different line, `citation-ambiguous` when it appears at more than one location, `quote-mismatch` when it is absent, `path-unresolved` when the path does not resolve, or `line-out-of-range` when the cited lines fall outside the file. When a row or finding cites lines without an adjacent quoted fragment in the fragment file, record `citation-unverified-no-quote`; this is unverifiable by this stage but is not treated as wrong.
8. **Prohibited content.** No row or finding contains recommendations, remediation, alternatives, examples, or implementation guidance. Record `prohibited-content` when detected.
9. **Sanitization.** No row or finding reproduces a raw secret value or a raw PII value. Record `unsafe` when detected and stop verification for that fragment.

## Cross-Fragment Checks

After per-row and per-finding verification, check:

* Row-ID and finding-ID uniqueness within each fragment.
* No duplicate inventory row-key (component + dependency + sink) inside a single fragment. Record `duplicate-inventory-key`.
* No duplicate finding-key (dependency + concern + entrypoint + diagnostic outcome + scenario) inside a single fragment. Record `duplicate-finding-key`.
* Cross-fragment overlap where the same row-key or finding-key appears in more than one fragment. Record `cross-fragment-overlap` on the newer-emission fragment and leave both records in place; the finalize prompt resolves overlaps.

## Bounds

Process at most 400 records (inventory rows plus findings) across all fragments. Read each fragment file's bytes exactly once. Read each referenced source file at most twice: once for verification and once, only when needed, for a bounded corrective reread against a named record. Total source reads must not exceed 400. Reaching either cap stops new admission but permits reconciliation of already-admitted records.

## Audit Report

Write exactly one audit report to `<fragmentDir>/verify-audit.md`. The audit report contains exactly these sections in this order:

* Frontmatter with `producer: hve-resiliency-researcher-7-logging-verify`, `manifestPath`, `status`, and `ms.date`.
* `## Summary` with counts by disposition, fragments audited, source files read, records processed, and hard-limit state.
* `## Rows` table with columns `recordId`, `recordKind` (`inventory` or `finding`), `fragment`, `dependency`, `scenario`, `disposition`, and `notes`. One row per verified record.
* `## Cross-Fragment Findings` list of `duplicate-inventory-key`, `duplicate-finding-key`, and `cross-fragment-overlap` items with the offending key and involved fragments.
* `## Manual Review Required` list of record IDs with disposition `quote-mismatch`, `citation-ambiguous`, `path-unresolved`, `line-out-of-range`, `category-mismatch`, `payment-discipline-violation`, `dependency-out-of-scope`, `scenario-combined`, `prohibited-content`, `schema-incomplete`, `fragment-header-invalid`, or `unsafe`, each with a one-sentence sanitized note.
* `## Sanitization Notes` list of any records redacted due to secret or PII detection.

Do not edit fragments. Do not modify the skeleton. Do not touch the manifest.

## Completion

Report the fragments audited, disposition totals, cross-fragment issue count, manual-review count, and terminal verify status (`Blocked`, `Incomplete`, or `Complete`).

> **Next step:** Run `/hve-resiliency-researcher-7-logging-finalize`
