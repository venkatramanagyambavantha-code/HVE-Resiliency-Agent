---
description: Shared evidence-only contract for the split HVE resiliency consolidation pipeline (scaffold, section-fill, verify, finalize prompts)
applyTo: '.github/prompts/researcher/hve-resiliency-consolidate-*.prompt.md'
---

# HVE Resiliency Consolidation Shared Contract

Apply this contract to every prompt in the split consolidation pipeline: the scaffold/discovery prompt, the section-fill prompts (Sections 1-8), the verify prompts, and the finalize prompt. Each pipeline prompt inherits these stage-invariant rules and adds only its stage-specific behavior. When a pipeline prompt conflicts with this contract, the pipeline prompt's stage-specific scope takes precedence for that stage only; the evidence-only prohibitions below are never overridden.

Use [Application Platform Context](hve-resiliency-platform-context.instructions.md) for inherited platform scenarios, dependency applicability rules, and P0-P3 definitions.

## Pipeline Overview

The consolidation workflow is a bounded pipeline that replaces the single monolithic consolidate prompt:

1. Scaffold: run discovery once, emit the consolidated skeleton plus a frozen manifest sidecar.
2. Section fill (Sections 1-8): each prompt reads only its granted scope and writes one section fragment file.
3. Verify (Sections 1-4 and 5-8): audit the section fragments against routed source artifacts.
4. Finalize: assemble fragments, run index-level dedup and section precedence, reconcile IDs, set status once, build the Section 9 index.

Every consolidated artifact uses schema version `hve-resiliency-consolidation/v1` and targets the current repository.

## Evidence-Only Prohibitions

Preserve the evidence-only contract end to end. Do not introduce assessment areas or produce alternatives, recommendations, selected approaches, examples, implementation details, design changes, remediation, or advisory language. Skip Task Researcher Phase 2 and all deeper-research handoffs. Emit only sanitized, retained, evidence-backed records.

## Status and Failure Semantics

Every prompt ends in exactly one terminal state: `Complete`, `Incomplete`, or `Blocked`. Blocking is reserved for one condition only and is never used for anything discovered inside the repository under assessment or inside an accepted source artifact. This section is never overridden by a pipeline prompt's stage-specific rules.

**Repository and content conditions are findings, never failures.** Anything learned from the repository under assessment or from accepted source artifacts is recorded in-band and the run continues. Never stop `Blocked` and never mark the run `Incomplete` for any of these:

* Ambiguous, contradictory, or unprovable evidence: render the affected field or finding with the schema's `Unknown` / `Unknown: evidence unavailable` value and continue.
* A dependency, service, or file that is out of scope or owned by another repository: record it as an out-of-scope finding that names the boundary and, where useful, notes that the owning repository should verify it. Do not issue instructions to that other repository beyond that suggestion.
* Source content that cannot be safely rendered (for example a secret value): sanitize and keep the finding using only its safe location metadata, per Sanitization. Never block for unsafe content.
* No evidence found for an in-scope check: record the schema's negative value (`Not observed in completed sources`, `None found`, or `Not Applicable`). Absence of evidence is a valid completed result.

**The only `Blocked` condition is a broken pipeline.** Stop `Blocked` only when a required input produced by a prior pipeline step (a prerequisite artifact or a frozen manifest sidecar) is genuinely absent, unreadable, or structurally invalid, meaning a prior step failed or the steps ran out of order. The orchestrator gates each step on the prior step returning `Complete`, so in a correctly orchestrated run this state cannot occur; when it does it is a pipeline defect, not a property of the repository. Stop with a single message of the form `prerequisite from a prior step is missing or invalid - rerun <the producing step>`, and never synthesize the missing input. Do not use `Blocked` as a graceful branch for repository or artifact content, and do not enumerate content-based block reasons. The manifest auto-location rules below are the concrete application of this single condition.

## Frozen Manifest Sidecar Contract

The scaffold prompt emits one frozen manifest sidecar next to the consolidated document (for example `<consolidated-doc-basename>.manifest.md`). Every downstream stage reads this manifest and never repeats discovery. The manifest is deterministic and stable across reads.

The manifest records, per accepted artifact:

* `promptId`: one of `0`, `1a`, `1b`, `2` through `19`.
* `path`: normalized workspace-relative path (`/` separators, repository path case preserved).
* `completionStatus`: the artifact's own completion status.
* `contentSha256`: lowercase SHA-256 hexadecimal digest of the artifact's sanitized bytes.

The manifest also records the section-routing map and a frozen coverage snapshot:

* Primary section: each accepted artifact declares exactly one primary output section (1-8) from the section-to-source mapping below.
* Cross-artifact read scopes (grant read access without duplicating rendering):
  * Section 2.1 service-finding scope: service artifacts (8-19) contribute dependency findings to Section 2.1 in addition to their category section.
  * Section 7 secret sweep scope: sanitized hard-coded secret or value findings from any accepted artifact route to Section 7.
  * Section 8 residual scope: retained evidence from any artifact that maps to no other section routes to Section 8.
* Coverage snapshot: required prompt IDs present or absent, and the applicable optional service IDs (applicability determined solely by accepted Prompt 1a and 1b Section 1 evidence).

Each finding routes to exactly one primary section. The scopes above define which artifacts a fill prompt may read, not duplicate rendering of the same finding.

## Manifest Auto-Location

When a prompt's manifest path input is omitted, auto-locate the frozen outer consolidation manifest sidecar instead of asking the user. Enumerate `.md` files whose name ends with `-research.manifest.md` directly under `.copilot-tracking/research/` and under any `.copilot-tracking/research/YYYY-MM-DD/` dated subdirectory, excluding anything under `sections/`, `subagents/`, `validator/`, or `sandbox/`. Prefer a candidate whose body declares schema version `hve-resiliency-consolidation/v1`. Select the candidate under the lexicographically largest `YYYY-MM-DD` dated segment; if dated segments tie or are absent, select the one whose normalized path sorts last using ordinal comparison. Never use file modification time. If exactly one manifest resolves, use it. If none resolve, stop `Blocked` with `outer manifest not found; run hve-resiliency-consolidate-0-scaffold first`. An explicitly supplied path always overrides auto-location.

## Section-to-Source Mapping

| Output section | Primary source artifacts |
| --- | --- |
| 1 Repository Context | Prompt 0, 1a Section 1, 1b Section 1 |
| 2 Dependency Inventory | Prompt 1a, 1b (Sections 1-3) |
| 3 Region and Zone Assumptions | Prompt 2 |
| 4 State and Data Characteristics | Prompt 3 |
| 5 Failure and Degraded-Mode Behavior | Prompt 4, 5 |
| 6 Shared and Cross-Repository Dependencies | Prompt 6 |
| 7 Hard-Coded Values or Secrets | Prompt 7 plus the secret sweep scope over any artifact |
| 8 Other Findings | Residual scope over any artifact |
| 9 Research Findings Index | Aggregated finding IDs from Sections 2.1 and 3-8 |

Service findings (prompt IDs 8-19) render into Sections 2.1 and 3-8 by category, per the read scopes above.

## Required and Optional Prompt IDs

Required prompt IDs are `0`, `1a`, `1b`, `2`, `3`, `4`, `5`, `6`, and `7`. Service prompt IDs `8` through `19` are optional and applicable only when their dependency category or service appears in Section 1 of an accepted Prompt 1a or Prompt 1b artifact. An absent service artifact is not a conflict when that service is inapplicable.

## Sanitization

Sanitize raw content immediately after reading and before any write, hash, comparison, index entry, normalized record, or output. Never retain or reproduce secret values. Normalize workspace-relative paths to `/` while preserving repository path case, collapse prose whitespace to one ASCII space, encode text as UTF-8 without a byte-order mark, and use lowercase SHA-256 hexadecimal digests for content and records.

For potential secrets, retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity derived from sanitized metadata. If an individual secret value cannot be safely sanitized, drop that value and keep the finding using only its safe location metadata; never write the raw value and never block for this reason. Reserve `Blocked` for an artifact that cannot be safely read or processed at all. Do not hash, compare, transfer, or write unsafe raw content.

## Line Number Integrity Rules

* Never estimate line numbers.
* Never merge line ranges.
* Never recalculate line numbers.
* Copy file paths and line numbers verbatim from source research artifacts.
* If multiple research artifacts reference different line ranges, preserve each separately.
* If line numbers cannot be validated, mark: `Line number requires manual verification`.
* Never paraphrase referenced code. Copy any quoted code verbatim so every snippet matches the source file exactly at the cited path and lines.

## Normalized-Record Identity and ID Allocation

Convert each source finding into a normalized source record and preserve every record and provenance ID through terminal disposition. Each record carries: a stable record ID, source prompt ID, artifact path, original finding ID, dependency or category, scenario, failure mode, priority, ownership, impacts, evidence, existing mitigations, constraints, citation-validation state, conflict state, disposition, and output finding ID when retained.

The source-record canonical identity tuple is an object with exactly these properties: `dependencyOrCategory`, `failureMode`, `lineRange`, `path`, `scenario`, and `sourceFindingIdentity`. Populate it only after sanitization and normalization. Serialize it as canonical JSON with lexicographically sorted property names, no insignificant whitespace, and UTF-8 without a byte-order mark. Compute its lowercase SHA-256 hexadecimal digest.

Allocate normalized-record IDs after sorting canonical tuples by their serialized bytes using ordinal comparison. Start with `NR-` plus the first 12 digest characters. For colliding prefixes from unequal tuples, extend every colliding prefix by two hexadecimal characters and repeat until unique. If full digests collide for unequal canonical tuples, stop `Blocked`. Exact canonical tuple matches are duplicates, not collisions.

Deduplicate source records only on exact source-record canonical identity matches. The finite failure-mode classes are `startup failure`, `request failure`, `timeout`, `DNS failure`, `authentication failure`, `partial outage`, `data loss`, `data inconsistency`, `blocked failover`, `degraded operation`, and `unknown observed failure`. Use `unknown observed failure` only when validated evidence demonstrates an observed failure that does not map to another class; it is not a fallback for a missing failure mode. Never combine zone and regional evidence in one finding.

Merge semantically equivalent source records into one rendered finding that carries every contributing retained record ID. Keep findings separate when scenario, failure-mode class, priority, ownership, impacts, existing mitigations, constraints and limitations, or evidence chain materially differs. Apply source precedence only to equivalent claims: validated file-line evidence over uncited summaries, service-specific evidence over general evidence for that service, and Prompt 1a or 1b over later prompts for dependency applicability.

## Section-Scoped Finding IDs

Section-fill prompts allocate section-scoped finding IDs of the form `F-<section>-00X` (for example `F-1-001`, `F-3-002`) so parallel fill prompts never collide. The finalize prompt reconciles section-scoped IDs into the authoritative sequential `F-00X` scheme exactly once. Never renumber into the `F-00X` scheme before finalize.

## Schema-Safe Values

Keep every required field label present without inventing evidence.

Render a finding only when it has a canonical dependency or category, P0-P3 priority, exactly one allowed scenario, a material failure mode, and at least one validated file-line citation mapped to retained source IDs. Never use `Unknown` in these closed fields.

Permit `Unknown: evidence unavailable` only in these nullable prose fields: ownership boundary, impacts, existing mitigations, constraints and limitations, and notes or unknowns. Ownership remains nullable and a schema-safe ownership value does not block `Complete`.

Use bounded `Not observed in completed sources` only in nullable prose fields under partial coverage. Reserve `None found` for complete accepted-artifact coverage validated for that scope. Permitted nullable prose values do not by themselves force `Incomplete`. Retain without rendering any record missing a closed field, then select status through the finalize conflict matrix.

## Required Finding Schema

Use this schema exactly once for every finding rendered into Sections 2.1 and 3-8. During fill, use the section-scoped ID (`F-<section>-00X`); finalize replaces it with the authoritative `F-00X`.

### Finding F-00X

* Dependency or Category: <canonical dependency or category>
* Priority: P0 | P1 | P2 | P3
* Ownership: <evidence-backed owner or schema-safe value>
* Scenario: West US 2 zone failure | West US 2 to West US regional failover
* Description: <evidence-based current behavior>
* Failure Mode and Scenario-Specific Risk: <evidence-based risk>
* Impacts: <operational, data, financial, and customer impacts supported by evidence>
* Evidence: `<normalized-path>:L<start>-L<end>`
* Source Record IDs: <one or more retained NR IDs>
* Existing Mitigations: <evidence-backed mitigations or schema-safe value>
* Constraints and Limitations: <evidence-backed constraints or schema-safe value>

## Consolidated Document Structure

The consolidated document uses the direct Sections 1-9 structure below. Section fragments produced by fill prompts assemble into these headings at finalize.

* Assessment Scope header and Notes
* 1. Repository Context
* 2. Dependency Inventory (2.1 Used Dependencies, 2.2 Checked but Not Present, 2.3 Not Applicable Dependency Categories)
* 3. Region and Zone Assumptions
* 4. State and Data Characteristics
* 5. Failure and Degraded-Mode Behavior
* 6. Shared and Cross-Repository Dependencies
* 7. Hard-Coded Values or Secrets in Code or Files
* 8. Other Findings Not Categorized Above
* 9. Research Findings Index (Authoritative)
