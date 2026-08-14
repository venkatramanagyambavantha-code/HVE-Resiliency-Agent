---
description: Fill Section 1 (Repository Context) of the consolidated resiliency research document from Prompt 0, 1a, and 1b evidence
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 1 - Repository Context

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, schema-safe values, and evidence-only prohibitions. This prompt fills Section 1 only and writes a section fragment file. It never writes the shared consolidated document and never re-runs discovery.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment output directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, then read only the artifacts whose primary section is Section 1: the accepted Prompt 0 artifact and Section 1 of the accepted Prompt 1a and Prompt 1b artifacts. Do not read artifacts outside this scope and do not re-run discovery.

Document service purpose, application overview, execution model, runtime environment, explicit repository boundaries, and key business processes. Section 1 is evidence-backed prose context, not findings; do not use the Required Finding Schema here.

## Fill Protocol

1. Load the manifest and confirm the Section 1 read scope.
2. Read each routed artifact's bytes once; sanitize immediately.
3. Normalize findings into source records and deduplicate within the section on the shared canonical-tuple identity, preserving every contributing record ID.
4. Render Section 1 as evidence-backed bullets. Append the retained normalized-record IDs to every substantive bullet.
5. Use schema-safe nullable prose values (`Unknown: evidence unavailable`, `Not observed in completed sources`, `None found`) rather than inventing evidence.

## Output

Write the Section 1 fragment to `<consolidatedDocDir>/sections/section-1.md` beginning with the `## 1. Repository Context` heading. Do not modify the consolidated document; finalize assembles fragments.

## Completion

Report the routed artifacts read, the count of rendered bullets, retained record totals, and the fragment path. End with a next-step suggestion to run the Section 2 fill prompt.
