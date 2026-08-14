---
description: Validate researcher artifacts against workspace source and correct unambiguous citation and code-fragment drift before consolidation
agent: "Task Researcher"
argument-hint: "researchRoot=.copilot-tracking/research/ [assessmentManifestPath=...] [mode={audit|autofix}]"
---

# Application HVE Researcher Validator

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) for inherited platform scenarios and evidence rules. If inherited instructions conflict with this validator-only contract, this prompt takes precedence.

## Inputs

* `${input:researchRoot:.copilot-tracking/research/}`: (Optional) Workspace-relative root directory containing researcher artifacts to validate. Defaults to `.copilot-tracking/research/`.
* `${input:assessmentManifestPath}`: (Optional) Workspace-relative path to an assessment sidecar manifest. When supplied, restrict validation to artifacts named in the sidecar and reject artifacts outside it. When omitted, validate every non-subagent `.md` file directly under `researchRoot` and every `.md` under `researchRoot/YYYY-MM-DD/`. Do not descend into `subagents/` unless the sidecar names an artifact there.
* `${input:mode:audit}`: (Optional) One of `audit` or `autofix`. `audit` reports findings only. `autofix` applies the strict correction rules in the Auto-Correction Protocol section and reports what changed. Default is `audit`.

## Scope And Override

Validate that every citation and quoted code fragment inside admitted researcher artifacts is faithful to the current workspace source. Emit one audit report per run and, when `mode=autofix`, apply only the strict corrections defined here. Do not consolidate, do not render new findings, do not add or reorder findings, do not introduce recommendations, and do not modify sidecar manifests or SHA-256 digests.

Enter validation directly. Skip Task Researcher Phase 2, generic completion criteria, and deeper-research handoffs. Do not run subagents.

The validator's authority is limited to two artifact classes:

* Researcher artifacts under `researchRoot` — read always, edit only under the Auto-Correction Protocol.
* Workspace source files — read only, never edit. Source scope is limited to `src/**`, `pom.xml`, `Dockerfile`, `Actionsfile/**`, `settings.xml`, `checkstyle/**`, `cert/**` (path only, not contents), `.github/workflows/**`, and `src/main/resources/**`.

The validator must not read any other prompt file, subagent artifact, sidecar-not-supplied by the user, planner artifact, or file outside the two artifact classes above.

## Canonical Input Contract

When `assessmentManifestPath` is supplied, apply the same sidecar validation rules as the consolidate prompt: exact top-level fields (`schemaVersion`, `repository`, `assessmentId`, `revision`, `status`, `generatedAt`, `artifacts`), exact per-artifact fields (`promptId`, `path`, `required`, `completionStatus`, `schemaId`, `contentSha256`), and reject additional properties. Reject absolute paths, traversal, alternate separators, and case mismatches. A malformed sidecar stops `Blocked`.

When `assessmentManifestPath` is omitted, freeze one sanitized in-memory manifest by enumerating `.md` files directly under `researchRoot` and directly under any `researchRoot/YYYY-MM-DD/` subdirectory. Sort by normalized path using ordinal comparison. Do not descend into `subagents/` in this mode.

Admit only artifacts whose frontmatter (when present) identifies a researcher producer or whose H1 matches the `HVE Resiliency Researcher` heading family. Exclude planner outputs, consolidations, sandboxes, and unrelated documents by filename or heading. Reject artifacts unrelated to the current repository by workspace-root basename.

## Discovery And Read Bounds

Sort admitted artifact candidates by normalized path using ordinal comparison, then process at most 60 artifacts per run. Retain at most 4,000 extracted citation records total. Reaching either cap stops new admission but permits bounded reconciliation of already retained records.

Read each admitted researcher artifact's bytes exactly once. From that same in-memory buffer, extract every citation and every quoted code fragment adjacent to a citation. Do not reread an artifact for confidence or broader exploration.

Read each referenced workspace source file at most twice per run: once for verification and once, only when needed, for a bounded corrective reread tied to a named auto-correction target. Total source reads must not exceed 600. Do not repeat discovery.

Do not read a workspace source file that is outside the source scope declared in Scope And Override.

## Sanitization

Sanitize buffered content immediately after reading and before any write, hash, comparison, manifest entry, extracted record, or audit-report entry. Never retain or reproduce secret values in the audit report. Normalize workspace-relative paths to `/` while preserving repository path case. Encode text as UTF-8 without a byte-order mark.

For potential secrets observed in a researcher artifact or a source file, retain only the secret type, normalized file path, line, and a stable redacted identity. Mark an artifact unsafe and stop `Blocked` for that artifact when sanitization cannot be guaranteed; do not attempt an auto-correction on an unsafe artifact.

## Citation Extraction

For every admitted researcher artifact, extract every citation and every adjacent quoted code fragment. A citation is any occurrence of:

* `<normalized-path>:<line>` where `<line>` is a positive integer.
* `<normalized-path>:L<start>-L<end>` where `<start>` and `<end>` are positive integers and `<start> <= <end>`.
* `<normalized-path>#L<line>` and `<normalized-path>#L<start>-L<end>` link forms.

An adjacent quoted fragment is the nearest single backticked span or the nearest fenced code block on the same line, in the same list item, or in the same table cell as the citation, where the backticked span or fence contains text that could plausibly appear in the cited source file.

Build one extracted citation record per citation. Populate exactly these properties:

* `artifactPath`: normalized path to the researcher artifact.
* `artifactLine`: 1-based line number inside the researcher artifact where the citation was extracted.
* `sourcePath`: normalized workspace-relative path from the citation.
* `sourceLineStart`: integer.
* `sourceLineEnd`: integer, equal to `sourceLineStart` when the citation names a single line.
* `quotedFragment`: the adjacent verbatim fragment as a single logical string, or `null` when no adjacent fragment exists.
* `citationKind`: one of `single-line`, `line-range`, or `link-form`.
* `recordId`: `VR-` plus the first 12 lowercase hexadecimal characters of the SHA-256 digest of the canonical JSON serialization of the other properties.

Deduplicate records only on exact `recordId` matches. Preserve every distinct citation, even when two citations point to the same source line.

Never treat prose sentences or unbacked identifier names as quoted fragments. The extractor only records fragments that are backticked or fenced in the researcher artifact.

## Verification Protocol

Verify every extracted record in this exact order and record one terminal disposition per record:

1. **Path resolution.** If `sourcePath` does not resolve to a readable workspace file inside the source scope, record disposition `path-unresolved` and stop verification for this record. If the path resolves but case does not match the workspace, record `path-case-mismatch` and stop.
2. **Line range validity.** If `sourceLineStart` or `sourceLineEnd` is outside the target file's line count, record `line-out-of-range` and stop.
3. **Fragment presence.** When `quotedFragment` is not `null`, search the target file for an exact substring match of the fragment, ignoring only leading and trailing ASCII whitespace on each line and preserving internal whitespace and punctuation exactly. Record one of:
   * `citation-ok` when the fragment appears at or fully within `sourceLineStart..sourceLineEnd`.
   * `citation-line-drift` when the fragment appears at exactly one other location in the file and does not appear at the cited lines.
   * `citation-ambiguous` when the fragment appears at more than one location in the file.
   * `quote-mismatch` when the fragment does not appear anywhere in the file.
4. **Fragment absent.** When `quotedFragment` is `null`, record `citation-unverified-no-quote` and do not attempt further checks. The citation is not treated as wrong; it is treated as unverifiable by this validator.

Never estimate line numbers. Never merge line ranges. Never approximate a fragment by trimming its interior. Never mark `citation-ok` when the match is at a different line than the citation names.

## Auto-Correction Protocol

Auto-correction runs only when `mode=autofix`. In `audit` mode, produce the audit report and stop without editing any researcher artifact.

In `autofix` mode, apply corrections only for records whose disposition is `citation-line-drift` or `path-case-mismatch`. All other dispositions are report-only.

For every `citation-line-drift` record:

* Compute the corrected single-line number or corrected `Lstart-Lend` range that spans exactly the lines where the fragment appears in the source file.
* Locate the exact citation string in the researcher artifact at `artifactLine`. Replace only the numeric portion of that citation. Do not modify surrounding prose, backticks, punctuation, or the `sourcePath`.
* When the citation was `path:N` and the fragment spans multiple lines in source, replace it with `path:Lstart-Lend`. When the citation was `path:Lstart-Lend` and the fragment is on one line, replace with `path:N`. When the citation was a link form, preserve the link form and update the anchor.
* Record the before-and-after strings in the audit report.

For every `path-case-mismatch` record:

* Replace only the path casing to match the workspace-preserved case. Do not modify any other characters.
* Record the before-and-after strings in the audit report.

Never edit for `quote-mismatch`, `citation-ambiguous`, `path-unresolved`, `line-out-of-range`, or `citation-unverified-no-quote`. Report these and stop; the operator must resolve them manually.

Never introduce new citations, new quoted fragments, new sentences, or new sections. Never delete existing findings. Never change SHA-256 digests. Never touch sidecar files.

Apply corrections in a single deterministic pass per researcher artifact, sorted by `artifactLine` descending so earlier edits do not shift later line numbers. After all corrections for one artifact are applied, run the Verification Protocol once more against that artifact only. If any correction fails to re-verify as `citation-ok`, revert the failing edit and record `autofix-rollback` in the audit report.

Total corrective actions per run are capped at 400. Total corrective rereads of source files are counted against the 600-read cap in Discovery And Read Bounds.

## Audit Report

Write exactly one audit report per run at `.copilot-tracking/research/validator/YYYY-MM-DD-validator-audit.md`, where `YYYY-MM-DD` is the current UTC date. Create the `validator/` directory if it does not exist. Overwrite an existing report with the same path only when the run completes without `Blocked`; otherwise write to `-partial.md` sibling.

The audit report contains exactly these sections in this order:

* Frontmatter with `producer: hve-resiliency-researcher-validator`, `mode`, `researchRoot`, `assessmentManifestPath` (or the string `not-supplied`), `status`, and `ms.date`.
* `## Summary` with counts by disposition, artifacts admitted, artifacts skipped, source files read, corrections applied, corrections rolled back, and hard-limit state.
* `## Records` table with columns `recordId`, `artifactPath`, `artifactLine`, `sourcePath`, `sourceLineStart`, `sourceLineEnd`, `disposition`, and `notes`. Include one row per extracted record.
* `## Corrections Applied` table with columns `recordId`, `artifactPath`, `artifactLine`, `before`, and `after`. Include one row per applied correction. Present only when `mode=autofix`.
* `## Manual Review Required` list of `recordId` values with disposition `quote-mismatch`, `citation-ambiguous`, `path-unresolved`, `line-out-of-range`, or `autofix-rollback`, each with a one-sentence sanitized note.
* `## Sanitization Notes` list of any records whose adjacent fragment was redacted due to secret detection.

The audit report is the only artifact this validator creates. It is not an assessment output, is not consumed by the consolidate prompt, and does not enter any sidecar manifest.

## Status And Stopping

Set exactly one status.

Stop `Blocked` for any sidecar failure, missing or ambiguous required input, unsafe evidence in a researcher artifact, unreadable admitted artifact, source-scope violation, or a workspace source path outside the source scope declared above.

Stop `Incomplete` when the hard-limit caps in Discovery And Read Bounds are reached before every admitted artifact is fully verified, or when any `autofix-rollback` occurred.

Stop `Complete` when every admitted artifact was extracted once, every extracted record has a terminal disposition, every eligible `autofix` correction re-verifies as `citation-ok`, and the audit report was written.

Do not continue exploring after a terminal status is established. A `Blocked` or `Incomplete` run must not fill gaps by inference.

## Verification

Before terminating, confirm:

* Every admitted researcher artifact was read exactly once for baseline extraction; corrective rereads did not exceed one per artifact.
* Sanitization preceded all retention and all writes.
* No workspace source file was written to.
* No researcher artifact was written to in `audit` mode.
* Every applied correction was re-verified and either re-verified as `citation-ok` or reverted with `autofix-rollback` recorded.
* The audit report frontmatter, sections, and tables match the schema above.
* No sidecar file was modified.
* No SHA-256 digest was recomputed on a source file.

If verification identifies a specific defect in the audit report itself, correct that defect once and repeat verification. Otherwise apply the stopping rules.

## Response Contract

On termination, return to the caller:

* Audit report path.
* Terminal status.
* Counts by disposition.
* Corrections applied and rolled back counts.
* Manual-review record count.
* Recommendation: rerun `mode=autofix` after operator resolves manual-review items, or proceed to consolidation when zero manual-review items remain.
