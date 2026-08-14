---
description: Run consolidation discovery once, emit the consolidated skeleton and a frozen manifest sidecar for the split resiliency consolidation pipeline
agent: "Task Researcher"
argument-hint: "[researchRoot=.copilot-tracking/research/]"
---

# HVE Resiliency Consolidate 0 - Scaffold and Discovery

Follow the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md) for the manifest contract, sanitization, line-number integrity, and evidence-only prohibitions. This prompt runs the discovery stage only: it emits an empty consolidated document and one frozen manifest sidecar. It does not normalize findings, render sections, or run a conflict matrix.

## Inputs

* ${input:researchRoot:.copilot-tracking/research/}: (Optional) Workspace-relative research root. Defaults to `.copilot-tracking/research/`. Must resolve to an existing directory inside the workspace.

## Scope

Discover and freeze the accepted researcher artifacts for the current repository, then emit two outputs:

1. The consolidated document skeleton at `.copilot-tracking/research/YYYY-MM-DD-<repo-name>-research.md`.
2. The frozen manifest sidecar at `.copilot-tracking/research/YYYY-MM-DD-<repo-name>-research.manifest.md`.

Enter discovery directly. Do not fill any section, allocate finding IDs, or set a terminal `Complete` status.

## Discovery Contract

Treat the resolved research root as the only input root. Enumerate `.md` files under it recursively and sort by normalized workspace-relative path using ordinal comparison. Do not use file modification time to select among candidates. Do not read files outside the research root, follow symbolic links out of it, accept absolute paths, or accept paths containing traversal segments or alternate separators. Normalize paths to `/` while preserving repository path case.

Extract each candidate's prompt ID from its filename. Match the first case-insensitive occurrence of one of these anchored tokens: `researcher-<id>`, `prompt-<id>`, or `research-<id>`, where `<id>` is exactly one of `0`, `1a`, `1b`, or `2` through `19`. Reject filenames whose extracted ID is missing, resolves to more than one distinct ID, or falls outside the allowed set.

Confirm the extracted prompt ID against the artifact body. Read the file's first non-empty heading plus its front matter or first 40 lines and require an explicit reference to the same prompt ID (for example `Prompt <id>`, `Researcher <id>`, or a producer schema identifier of the form `hve-resiliency-researcher-<id>`). Reject any candidate whose filename ID and body ID disagree, and any candidate that carries no body reference to a prompt ID.

Exclude the following even when their filenames match a prompt ID token:

* Any file whose normalized path is under `<researchRoot>/subagents/`, `<researchRoot>/validator/`, or `<researchRoot>/sandbox/`.
* Any prior consolidation output, identified by a title that starts with `# HVE Task Research -` or a body that declares schema version `hve-resiliency-consolidation/v1`.
* Planner outputs, optimization or update studies, subagent studies, sandboxes, unrelated repositories, and incomplete, blocked, malformed, unreadable, or unsafe artifacts. Do not admit an artifact by filename alone.

When more than one candidate resolves to the same prompt ID after body confirmation, select the candidate whose normalized path has the lexicographically largest dated ancestor segment matching `YYYY-MM-DD`. If no candidate carries a dated segment, or if dated segments tie, select the candidate whose normalized path sorts last using ordinal comparison. Record every non-selected duplicate in the manifest with disposition `exact duplicate` and preserve its provenance.

## Discovery Bounds

Sort discovered candidates by normalized path using ordinal comparison, then process no more than 100 candidates. Reaching the cap stops new admission. Read each accepted artifact's bytes exactly once for baseline processing, then compute its sanitized `contentSha256`. Do not repeat discovery and do not reread an artifact for confidence or broader exploration.

## Validation

Read each accepted artifact's bytes once and validate:

* Presence of the expected producer heading and the artifact's completion status.
* Conformance to the producer body schema for its prompt ID.
* Repository relevance: identifiers, paths, and workspace references cited by the artifact belong to the current workspace.

Stop `Blocked` with no fallback when the research root is missing, unreadable, or empty of admissible artifacts; when an admitted candidate is malformed, unreadable, or unsafe; or when accepted candidates disagree on repository identity. A required prompt ID (`0`, `1a`, `1b`, `2`, `3`, `4`, `5`, `6`, `7`) with zero admitted candidates does not block: record it as absent in the coverage snapshot and proceed, leaving its section to render bounded no evidence; finalize sets the terminal status to reflect the missing required coverage.

Freeze the discovery result after selection. Duplicate prompt IDs are resolved by the tie-break above rather than by stopping.

## Manifest Emission

Emit the frozen manifest sidecar per the shared Frozen Manifest Sidecar Contract. Record per accepted artifact: `promptId`, normalized `path`, `completionStatus`, and `contentSha256`. Record the section-routing map: each accepted artifact's primary section (1-8) from the shared Section-to-Source Mapping, plus the enumerated Section 2.1 service-finding scope, Section 7 secret sweep scope, and Section 8 residual scope. Record the coverage snapshot: required prompt IDs present or absent, and applicable optional service IDs determined solely by accepted Prompt 1a and 1b Section 1 evidence.

## Skeleton Emission

Emit the consolidated document skeleton with the following structure and a reserved placeholder in each section body that finalize will replace with the assembled section fragment. Do not render any finding.

```markdown
# HVE Task Research - <repo-name>

Assessment Scope:

* Repository: <repo-name>
* Focus: West US 2 zone failure and West US 2 to West US regional failover
* Regions Evaluated: West US 2 to West US
* Assessment Date: YYYY-MM-DD
* Generated By: HVE Task Researcher
* Schema Version: hve-resiliency-consolidation/v1
* Consolidation Status: Incomplete
* Status Reasons: scaffold emitted; sections not yet filled
* Coverage: <accepted>/<required>, <accepted>/<applicable optional>
* Processing Metrics: <candidates>, <accepted>, pending fill

Notes:

* This document is the evidence-only authoritative research input for HVE Task Planner.
* No remediation or design guidance is included.

## 1. Repository Context

<!-- section-1 placeholder: filled by hve-resiliency-consolidate-1-repository-context -->

## 2. Dependency Inventory

<!-- section-2 placeholder: filled by hve-resiliency-consolidate-2-dependency-inventory -->

## 3. Region and Zone Assumptions

<!-- section-3 placeholder: filled by hve-resiliency-consolidate-3-region-zone -->

## 4. State and Data Characteristics

<!-- section-4 placeholder: filled by hve-resiliency-consolidate-4-state-data -->

## 5. Failure and Degraded-Mode Behavior

<!-- section-5 placeholder: filled by hve-resiliency-consolidate-5-failure-degraded -->

## 6. Shared and Cross-Repository Dependencies

<!-- section-6 placeholder: filled by hve-resiliency-consolidate-6-shared-cross-repo -->

## 7. Hard-Coded Values or Secrets in Code or Files

<!-- section-7 placeholder: filled by hve-resiliency-consolidate-7-secrets -->

## 8. Other Findings Not Categorized Above

<!-- section-8 placeholder: filled by hve-resiliency-consolidate-8-other -->

## 9. Research Findings Index (Authoritative)

<!-- section-9 placeholder: built by hve-resiliency-consolidate-9-finalize -->
```

## Completion

Report the accepted-artifact count, the required-coverage snapshot, the emitted skeleton path, and the emitted manifest path. End with a next-step suggestion to run the Section 1 and Section 2 fill prompts.
