---
description: Fill Section 7 (Hard-Coded Values or Secrets) of the consolidated resiliency research document using the secret sweep over all accepted artifacts
agent: "Task Researcher"
argument-hint: "[manifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 7 - Hard-Coded Values or Secrets

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, the Required Finding Schema, schema-safe values, and evidence-only prohibitions. This prompt fills Section 7 only and writes a section fragment file. It never writes the shared consolidated document and never re-runs discovery.

## Inputs

* ${input:manifestPath}: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by the scaffold prompt. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive the fragment output directory. Defaults to the manifest's companion document.

## Scope

Read the frozen manifest, then apply the Section 7 secret sweep read scope: read the accepted Prompt 7 artifact and scan every other accepted artifact for sanitized hard-coded secret or value findings. This all-artifact read scope is intentional and is the residual scale risk flagged for runtime measurement.

Render sanitized evidence of hard-coded secrets or values. Never render a secret value or reversible derivative; retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity. If a value cannot be safely sanitized, drop that value and keep the finding using only its safe location metadata (path, line, secret type, key or symbol name, redacted identity); never render the raw value and never block for this reason. Reserve `Blocked` for an artifact that cannot be safely read or processed at all.

## Fill Protocol

1. Load the manifest and confirm the Section 7 secret sweep scope.
2. Read each artifact's bytes once; sanitize immediately, before any comparison or write.
3. Normalize secret and hard-coded-value findings into source records and deduplicate within the section on the shared canonical-tuple identity, preserving every contributing record ID.
4. Render each finding using the Required Finding Schema with section-scoped IDs `F-7-00X`. Never combine zone and regional evidence in one finding.

## Output

Write the Section 7 fragment to `<consolidatedDocDir>/sections/section-7.md` beginning with the `## 7. Hard-Coded Values or Secrets in Code or Files` heading. Do not modify the consolidated document; finalize assembles fragments.

## Completion

Report the artifacts swept, the finding count, retained record totals, and the fragment path. Confirm no secret value was reproduced. End with a next-step suggestion to run the Section 8 fill prompt.
