---
description: Verify Section 5-8 fragments of the consolidated resiliency research against routed source artifacts, report-only
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate Verify 5-8

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, the Required Finding Schema, and evidence-only prohibitions. This prompt audits the Section 5-8 fragments only. It reports findings; it does not renumber, add, reorder, or render new findings, and it does not modify the consolidated document.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, the section fragment files for Sections 5-8 (`<consolidatedDocDir>/sections/section-5.md` through `section-8.md`), and only the source artifacts routed to those sections (including the Section 7 secret sweep scope and Section 8 residual scope). The consolidated document is still an empty scaffold at this stage; verify the fragments, not the document. Do not re-run discovery.

## Verification Protocol

For each of Sections 5-8, confirm:

* Citation validity: every `<path>:L<start>-L<end>` citation resolves to the routed source artifact and its recorded evidence; never estimate or recalculate line numbers.
* Finding-schema completeness: every finding carries all Required Finding Schema field labels, a canonical dependency or category, P0-P3 priority, exactly one allowed scenario, a material failure mode, at least one validated file-line citation, and section-scoped `F-<section>-00X` IDs mapped to retained record IDs.
* Section 7 renders no secret value or reversible derivative; only sanitized secret type, path, line, key or symbol name, and redacted identity appear.
* Section 8 findings are marked provisional (overlap resolution deferred to finalize).
* Correct within-fragment finding ordering and heading correctness.
* Absence of recommendation, remediation, example, or implementation content.

## Output

Emit one bounded audit report listing each checked fragment, per-finding disposition (`ok`, `citation-drift`, `schema-incomplete`, `unmapped-id`, `prohibited-content`, `unsafe`, `provisional-ok`), and any operator-action items. Do not edit fragments or the consolidated document.

## Completion

Report the fragments audited, disposition totals, and any blocking issues. End with a next-step suggestion to run the finalize prompt.
