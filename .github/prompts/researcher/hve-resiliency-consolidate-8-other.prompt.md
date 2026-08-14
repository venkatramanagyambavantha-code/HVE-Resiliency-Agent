---
description: Fill Section 8 (Other Findings) of the consolidated resiliency research document as provisional residual candidates resolved at finalize
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 8 - Other Findings

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, the Required Finding Schema, schema-safe values, and evidence-only prohibitions. This prompt fills Section 8 only and writes a section fragment file. It never writes the shared consolidated document and never re-runs discovery.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment output directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, then apply the Section 8 residual read scope: retained evidence from any accepted artifact that maps to no other section (Sections 1-7). Render only meaningful evidence that cannot map elsewhere. Do not use this section to expand assessment scope and do not re-run discovery.

Because fill prompts run in parallel and the scaffold does not normalize findings, Section 8 entries are PROVISIONAL residual candidates. The finalize section-precedence pass drops any candidate that Sections 1-7 already claimed.

## Fill Protocol

1. Load the manifest and confirm the Section 8 residual scope.
2. Read each candidate artifact's bytes once; sanitize immediately.
3. Normalize residual findings into source records and deduplicate within the section on the shared canonical-tuple identity, preserving every contributing record ID.
4. Render each provisional finding using the Required Finding Schema with section-scoped IDs `F-8-00X`. Never combine zone and regional evidence in one finding.

## Output

Write the Section 8 fragment to `<consolidatedDocDir>/sections/section-8.md` beginning with the `## 8. Other Findings Not Categorized Above` heading. Mark the fragment's findings as provisional. Do not modify the consolidated document; finalize assembles fragments and resolves overlaps.

## Completion

Report the candidate artifacts read, the provisional finding count, retained record totals, and the fragment path. End with a next-step suggestion to run the Section 1-4 and Section 5-8 verify prompts.
