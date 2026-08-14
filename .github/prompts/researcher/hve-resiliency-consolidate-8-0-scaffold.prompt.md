---
description: Scaffold the split Consolidate 8 (Other Findings) pipeline - validate the outer consolidation manifest, freeze the Section 8 group-routing table, emit the Section 8 sub-skeleton fragment and a frozen sub-manifest sidecar
agent: "Task Researcher"
argument-hint: "[outerManifestPath=...] [consolidatedDocPath=...]"
---

# HVE Resiliency Consolidate 8 - 0 - Scaffold

Follow the [Consolidate 8 Split Contract](../../instructions/hve-resiliency-consolidate-8-split.instructions.md) and the outer [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md). This prompt runs the prerequisite and scaffolding stage only. It does not read source artifacts, does not render provisional findings, does not run cross-section-precedence checks, and does not set any terminal status other than its own.

## Inputs

* ${input:outerManifestPath}: (Optional) Workspace-relative path to the frozen outer consolidation manifest sidecar emitted by `hve-resiliency-consolidate-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Consolidation Shared Contract.
* ${input:consolidatedDocPath}: (Optional) Path to the consolidated document; used only to derive `consolidatedDocDir`. Defaults to the outer manifest's companion document.

## Direct Invocation and Prerequisite

* Run only the scaffold stage. Do not run any group fill, verify, or finalize behavior.
* Require the outer consolidation manifest at `outerManifestPath`, produced by a prior step, to exist, be readable, and be well-formed per the outer Frozen Manifest Sidecar Contract. If the outer manifest is missing, unreadable, structurally invalid, or lists zero accepted required artifacts, a prior step failed or ran out of order: name the specific defect and stop `Blocked` per Status and Failure Semantics before writing anything.
* Require the outer manifest to record the Section 8 residual scope and the accepted-artifact set with `promptId`, normalized `path`, `completionStatus`, and `contentSha256` for every entry. If any required outer prompt ID (`0`, `1a`, `1b`, `2`, `3`, `4`, `5`, `6`, `7`) is absent from the accepted-artifact set, stop `Blocked` with `outer required prompt missing`.

## Group Routing Derivation

Read the outer manifest once. Compute the Section 8 group routing table by mapping every accepted-artifact record to exactly one group:

* `core-context`: accepted artifacts with `promptId` `0`, `1a`, or `1b`.
* `platform-state`: accepted artifacts with `promptId` `2`, `3`, or `4`.
* `failure-crossrepo`: accepted artifacts with `promptId` `5` or `6`.
* `secrets-adjacent`: the accepted artifact with `promptId` `7`.
* `services`: every accepted artifact whose `promptId` is one of `8` through `19`.

Copy each artifact's `promptId`, normalized `path`, `completionStatus`, and `contentSha256` verbatim from the outer manifest. Do not re-derive them and do not recompute the digest.

## Services Applicability Freeze

Set `servicesApplicability` to `applicable` when the `services` group's routing set is non-empty; otherwise set it to `not-applicable`. Never re-derive `servicesApplicability` in a downstream stage.

## Sub-Manifest Emission

Emit the frozen sub-manifest sidecar per the Frozen Sub-Manifest Sidecar Contract in the shared instructions. Write it to `<consolidatedDocDir>/sections/section-8-fragments/section-8.manifest.md`, where `<consolidatedDocDir>` is the directory of the consolidated document.

Record `outerManifestSha256` as the lowercase SHA-256 hexadecimal digest of the sanitized outer manifest bytes read at this stage. Include the five fixed `groupRouting` records mapping each group key to its fill prompt ID (`hve-resiliency-consolidate-8-1-core-context`, `hve-resiliency-consolidate-8-2-platform-state`, `hve-resiliency-consolidate-8-3-failure-crossrepo`, `hve-resiliency-consolidate-8-4-secrets-adjacent`, `hve-resiliency-consolidate-8-5-services`), its sub-fragment file name (`core-context.md`, `platform-state.md`, `failure-crossrepo.md`, `secrets-adjacent.md`, `services.md`), and the enumerated accepted-artifact records that group owns.

## Sub-Skeleton Emission

Emit the Section 8 sub-skeleton fragment at `<consolidatedDocDir>/sections/section-8-fragments/section-8.sub-skeleton.md`. Do not render any provisional finding. Every placeholder comment is replaced by the nested finalize prompt.

```markdown
<!-- markdownlint-disable-file -->
---
source-prompt: hve-resiliency-consolidate-8-0-scaffold
schema-version: hve-resiliency-consolidate-8-split/v1
pipeline: consolidate-8-split
pipeline-stage: scaffold
status: draft
ms.date: YYYY-MM-DD
---

## 8. Other Findings Not Categorized Above

<!-- group core-context placeholder: assembled by hve-resiliency-consolidate-8-finalize -->

<!-- group platform-state placeholder: assembled by hve-resiliency-consolidate-8-finalize -->

<!-- group failure-crossrepo placeholder: assembled by hve-resiliency-consolidate-8-finalize -->

<!-- group secrets-adjacent placeholder: assembled by hve-resiliency-consolidate-8-finalize -->

<!-- group services placeholder: assembled by hve-resiliency-consolidate-8-finalize -->

<!-- ledger placeholder: assembled by hve-resiliency-consolidate-8-finalize -->
```

Create the sub-fragment directory `<consolidatedDocDir>/sections/section-8-fragments/` if it does not exist. Do not create any group sub-fragment file; the group-fill prompts create their own sub-fragment files. Do not modify `sections/section-8.md`; the nested finalize prompt writes it.

## Completion

Report the outer manifest path, the accepted-artifact count per group, the `servicesApplicability` value, the sub-skeleton path, the sub-manifest path, and the sub-fragment directory. Set the scaffold stage status to `Complete` when the outer manifest validated, the sub-manifest wrote successfully, and the sub-skeleton wrote successfully. Otherwise `Blocked` with the specific reason.

> **Next step:** Run `/hve-resiliency-consolidate-8-1-core-context`
