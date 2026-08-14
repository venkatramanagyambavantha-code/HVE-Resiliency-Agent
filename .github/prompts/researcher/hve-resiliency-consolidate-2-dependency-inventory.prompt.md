---
description: Fill Section 2 (Dependency Inventory) of the consolidated resiliency research document from Prompt 1a and 1b evidence
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 2 - Dependency Inventory

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, the Required Finding Schema, schema-safe values, and evidence-only prohibitions. This prompt fills Section 2 only and writes a section fragment file. It never writes the shared consolidated document and never re-runs discovery.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment output directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, then read only the artifacts whose primary section is Section 2: the accepted Prompt 1a and Prompt 1b artifacts (Sections 1-3). Also apply the Section 2.1 service-finding read scope: service artifacts (8-19) contribute confirmed dependency findings to Section 2.1. Do not read artifacts outside these scopes and do not re-run discovery.

## Fill Protocol

1. Load the manifest and confirm the Section 2 primary scope and the Section 2.1 service-finding scope.
2. Read each routed artifact's bytes once; sanitize immediately.
3. Normalize findings into source records and deduplicate within the section on the shared canonical-tuple identity, preserving every contributing record ID.
4. Render three subsections:
   * `### 2.1 Used Dependencies (Evidence Found)`: render each confirmed dependency using the Required Finding Schema with section-scoped IDs `F-2-00X`.
   * `### 2.2 Checked but Not Present`: a table with columns `Dependency | Reason Checked | Evidence Result`; include retained record IDs in `Evidence Result`.
   * `### 2.3 Not Applicable Dependency Categories`: a table with columns `Category | Reason Not Applicable`; include retained record IDs in `Reason Not Applicable`.
5. Use only dependencies confirmed in Prompt 1a or 1b Section 1 for 2.1. Never combine regional and non-regional evidence in one finding.

## Output

Write the Section 2 fragment to `<consolidatedDocDir>/sections/section-2.md` beginning with the `## 2. Dependency Inventory` heading. Do not modify the consolidated document; finalize assembles fragments.

## Completion

Report the routed artifacts read, the finding count in 2.1, the row counts in 2.2 and 2.3, retained record totals, and the fragment path. End with a next-step suggestion to run the Section 3 fill prompt.
