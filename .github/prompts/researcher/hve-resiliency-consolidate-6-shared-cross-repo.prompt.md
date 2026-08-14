---
description: Fill Section 6 (Shared and Cross-Repository Dependencies) of the consolidated resiliency research document from Prompt 6 evidence
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 6 - Shared and Cross-Repository Dependencies

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, the Required Finding Schema, schema-safe values, and evidence-only prohibitions. This prompt fills Section 6 only and writes a section fragment file. It never writes the shared consolidated document and never re-runs discovery.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment output directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, then read only the artifacts whose primary section is Section 6: the accepted Prompt 6 artifact. Do not read artifacts outside this scope and do not re-run discovery.

Render evidence-backed region coupling, zone dependency, and ownership boundary findings from shared libraries, centralized configuration, or platform utilities.

## Fill Protocol

1. Load the manifest and confirm the Section 6 read scope.
2. Read each routed artifact's bytes once; sanitize immediately.
3. Normalize findings into source records and deduplicate within the section on the shared canonical-tuple identity, preserving every contributing record ID.
4. Render each finding using the Required Finding Schema with section-scoped IDs `F-6-00X`. Never combine zone and regional evidence in one finding.

## Output

Write the Section 6 fragment to `<consolidatedDocDir>/sections/section-6.md` beginning with the `## 6. Shared and Cross-Repository Dependencies` heading. Do not modify the consolidated document; finalize assembles fragments.

## Completion

Report the routed artifacts read, the finding count, retained record totals, and the fragment path. End with a next-step suggestion to run the Section 7 fill prompt.
