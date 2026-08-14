---
description: Consolidate completed Application resiliency evidence into the authoritative Task Planner research handoff
agent: "Task Researcher"
argument-hint: "(no required arguments; optional: researchRoot=.copilot-tracking/research/)"
---

# Application HVE Researcher Consolidate

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) for inherited platform scenarios, dependency applicability rules, and P0-P3 definitions. If inherited instructions conflict with this prompt, this consolidation-only evidence contract takes precedence.

## Inputs

* ${input:researchRoot}: (Optional) Workspace-relative research root. Defaults to `.copilot-tracking/research/` when unset, empty, or whitespace. Must resolve to an existing directory inside the workspace.

## Scope and Override

Consolidate completed evidence-only research for the current repository into one authoritative artifact at `.copilot-tracking/research/YYYY-MM-DD-<repo-name>-research.md`. Assess only regional failover between West US 2 and West US.

Enter consolidation directly. Skip Task Researcher Phase 2, recommendation-oriented completion criteria, and all deeper-research handoffs. Do not introduce assessment areas or produce alternatives, recommendations, selected approaches, examples, implementation details, design changes, remediation, or advisory language.

Run at most one subagent invocation total, and only when bounded citation or conflict validation cannot be completed directly. Transfer only sanitized retained normalized records and require the subagent to return citation validity or conflict disposition without recommendations.

## Discovery Contract

Treat the resolved research root as the only input root. Enumerate `.md` files under it recursively and sort by normalized workspace-relative path using ordinal comparison. Do not use file modification time to select among candidates. Do not read files outside the research root, follow symbolic links out of it, accept absolute paths, or accept paths containing traversal segments or alternate separators. Normalize paths to `/` while preserving repository path case.

Extract each candidate's prompt ID from its filename. Match the first case-insensitive occurrence of one of these anchored tokens: `researcher-<id>`, `prompt-<id>`, or `research-<id>`, where `<id>` is exactly one of `0`, `1a`, `1b`, or `2` through `19`. Reject filenames whose extracted ID is missing, whose match resolves to more than one distinct ID, or whose ID falls outside the allowed set.

Confirm the extracted prompt ID against the artifact body. Read the file's first non-empty heading plus its front matter or first 40 lines and require an explicit reference to the same prompt ID (for example `Prompt <id>`, `Researcher <id>`, or a producer schema identifier of the form `hve-resiliency-researcher-<id>`). Reject any candidate whose filename ID and body ID disagree, and any candidate that carries no body reference to a prompt ID.

Exclude the following even when their filenames match a prompt ID token:

* Any file whose normalized workspace-relative path is under `<researchRoot>/subagents/`, `<researchRoot>/validator/`, or `<researchRoot>/sandbox/`.
* Any prior consolidation output, identified by a title that starts with `# HVE Task Research -` or a body that declares schema version `hve-resiliency-consolidation/v1`.
* Planner outputs, optimization or update studies, subagent studies, sandboxes, unrelated repositories, and incomplete, blocked, malformed, unreadable, or unsafe artifacts. Do not admit an artifact by filename alone.

Required prompt IDs are `0`, `1a`, `1b`, `2`, `3`, `4`, `5`, `6`, and `7`. Service prompt IDs `8` through `19` are optional and applicable only when their dependency category or service appears in Section 1 of an accepted Prompt 1a or Prompt 1b artifact. Applicability is determined solely by accepted 1a and 1b evidence; an absent service artifact is not a conflict when that service is inapplicable.

When more than one candidate resolves to the same prompt ID after body confirmation, select the candidate whose normalized workspace-relative path has the lexicographically largest dated ancestor segment matching `YYYY-MM-DD`. If no candidate carries a dated segment, or if dated segments tie, select the candidate whose normalized path sorts last using ordinal comparison. Record every non-selected duplicate as a retained normalized record with disposition `exact duplicate` and preserve its provenance. Do not use file modification time.

Read each accepted artifact's bytes exactly once and validate:

* Presence of the expected producer heading and the artifact's completion status.
* Conformance to the producer body schema for its prompt ID, including required sections, required field labels, and file-line citations.
* Repository relevance: identifiers, paths, and workspace references cited by the artifact belong to the current workspace.
* Dependency applicability: contents cover only dependencies confirmed in Prompt 1a or 1b Section 1; dependencies in Prompt 1a or 1b Sections 2 and 3 are excluded from downstream and service evidence.

Compute a lowercase SHA-256 hexadecimal digest over each accepted artifact's sanitized bytes to derive stable identity for retained records. This digest is internal integrity metadata; it does not need to match an external value and does not gate acceptance beyond confirming that the same bytes are used for parsing, sanitization, and record identity.

Stop `Blocked` with no fallback when the research root is missing, unreadable, or empty of admissible artifacts; when any required prompt ID has zero admitted candidates; when an admitted candidate is malformed, unreadable, or unsafe; or when accepted candidates disagree on repository identity.

Freeze the discovery result after selection. Duplicate prompt IDs are resolved by the tie-break above rather than by stopping. Never choose an artifact by filename alone and never infer coverage from an artifact whose body did not confirm its prompt ID.

## Discovery and Read Bounds

Sort discovered candidates by normalized workspace-relative path using ordinal comparison, then process no more than 100 candidates and retain no more than 2,000 normalized findings. Reaching either cap stops new admission but permits bounded reconciliation of already retained records.

Read each accepted artifact's bytes exactly once for baseline processing. From that same in-memory buffer, parse metadata, headings, and body and compute the stable SHA-256 identity digest. Permit at most one defect-specific corrective reread per artifact tied to a named parse or citation defect and at most one owner or source indirection read for each evidence-backed dependency, at depth 1.

Total owner or source indirection reads must not exceed the 2,000 normalized-record cap. Do not repeat discovery. Do not reread an artifact for confidence or broader exploration.

## Sanitization

Sanitize raw content immediately after reading and before any write, hash, comparison, index entry, normalized record, subagent transfer, or output. Never retain or reproduce secret values. Normalize workspace-relative paths to `/` while preserving repository path case, collapse prose whitespace to one ASCII space, encode text as UTF-8 without a byte-order mark, and use lowercase SHA-256 hexadecimal digests for content and records.

For potential secrets, retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity derived from sanitized metadata. Mark an artifact unsafe and stop `Blocked` when sanitization cannot be guaranteed. Do not hash, compare, transfer, or write unsafe raw content.

## Line Number Integrity Rules

* Never estimate line numbers.
* Never merge line ranges.
* Never recalculate line numbers.
* Copy file paths and line numbers verbatim from source research artifacts.
* If multiple research artifacts reference different line ranges, preserve each separately.
* If line numbers cannot be validated, mark: `Line number requires manual verification`.

## Normalization and Reconciliation

Convert each source finding into a normalized source record and preserve every record and provenance ID through terminal disposition. Each record contains:

* Stable record ID derived from a hash of the sanitized canonical identity tuple
* Source prompt ID, artifact path, and original finding ID
* Dependency or category, scenario, failure mode, priority, ownership, impacts, evidence, existing mitigations, and constraints
* Citation-validation state, conflict state, disposition, and output finding ID when retained

The source-record canonical identity tuple is an object with exactly these properties: `dependencyOrCategory`, `failureMode`, `lineRange`, `path`, `scenario`, and `sourceFindingIdentity`. Populate it only after sanitization and normalization. Serialize it as canonical JSON with lexicographically sorted property names, no insignificant whitespace, and UTF-8 without a byte-order mark. Compute its lowercase SHA-256 hexadecimal digest.

Allocate IDs after sorting canonical tuples by their serialized bytes using ordinal comparison. Start with `NR-` plus the first 12 digest characters. For colliding prefixes from unequal tuples, extend every colliding prefix by two hexadecimal characters and repeat until unique. If full digests collide for unequal canonical tuples, stop `Blocked`. Exact canonical tuple matches are duplicates, not collisions.

Deduplicate source records only on exact source-record canonical identity matches. Separate source-record identity from rendered claim identity. Derive each canonical claim key from normalized dependency or category, scenario, the normalized evidence-location set, and one controlled failure-mode class. The finite classes are `startup failure`, `request failure`, `timeout`, `DNS failure`, `authentication failure`, `partial outage`, `data loss`, `data inconsistency`, `blocked failover`, `degraded operation`, and `unknown observed failure`.

Merge semantically equivalent source records into one rendered finding that carries every contributing retained record ID. Keep findings separate when scenario, failure-mode class, priority, ownership, impacts, existing mitigations, constraints and limitations, or evidence chain materially differs. Never combine regional-failover and partial-outage evidence in one finding. Use `unknown observed failure` only when validated evidence demonstrates an observed failure that does not map to another class; it is not a fallback for a missing failure mode.

Apply source precedence only to equivalent claims: validated file-line evidence over uncited summaries, service-specific evidence over general evidence for that service, and Prompt 1a or 1b over later prompts for dependency applicability. Preserve conflicting priorities and source values in normalized source records. Do not select a value without evidence.

Apply the conflict matrix before rendering:

* Required conflicts cover repository identity, required prompt coverage, dependency applicability, priority, scenario, failure mode, citation, finding or output identity, and unsafe evidence. Any unresolved required conflict stops `Blocked`.
* Optional gaps cover only missing, rejected, unreadable, unresolved, or hard-limit-truncated applicable optional artifacts or records after required core coverage succeeds, plus unresolved optional conflicts after bounded correction. Successfully accepted, validated, and rendered applicable service artifacts increase coverage and never force `Incomplete`.

Every retained record receives one terminal disposition: rendered, exact duplicate, excluded by Prompt 1a or 1b, rejected with reason, or unresolved. Every rendered finding and evidence-derived substantive claim must map to one or more retained terminal record IDs. Status reasons, coverage metrics, and schema-safe empty-state text map to the frozen discovery result and accepted artifact set and need no normalized finding ID. Do not render raw or unretained evidence.

## Schema-Safe Values

Keep every required field label present without inventing evidence.

Render a finding only when it has a canonical dependency or category, P0-P3 priority, exactly one allowed scenario, a material failure mode, and at least one validated file-line citation mapped to retained source IDs. Never use `Unknown` in these closed fields.

Permit `Unknown: evidence unavailable` only in these nullable prose fields: ownership boundary, impacts, existing mitigations, constraints and limitations, and notes or unknowns. Ownership remains nullable and a schema-safe ownership value does not block `Complete`. Preserve every field label. Retain without rendering any record missing a closed field, then select status through the conflict matrix.

Use bounded `Not observed in completed sources` only in nullable prose fields under partial coverage. Reserve `None found` for complete accepted-artifact coverage validated for that scope. Permitted nullable prose values do not by themselves force `Incomplete`.

## Status and Stopping

Set one explicit status with reasons and coverage metrics. Status precedence is `Blocked`, then `Incomplete`, then `Complete`.

Stop `Blocked` for a missing, unreadable, or empty research root; for any required prompt ID with zero admitted candidates; for unsafe evidence; for required artifacts that are unreadable, malformed, or fail body-schema validation; for disagreement on repository identity across accepted artifacts; or for any unresolved required conflict.

Stop `Incomplete` only for missing, rejected, unreadable, unresolved, or hard-limit-truncated applicable optional artifacts or records after required core coverage succeeds, or unresolved optional conflicts after bounded correction, when no `Blocked` condition exists.

Stop `Complete` only after the discovery result is frozen, every accepted artifact is processed once, every retained record has a terminal disposition, no conflicts remain, all citations validate, every required section and index entry reconciles, and one full bounded verification pass produces no changes. Accepted applicable service artifacts and permitted nullable prose values remain compatible with `Complete`.

Do not continue exploring after a terminal status is established. A `Blocked` or `Incomplete` artifact remains evidence-only and must not fill gaps by inference.

## Render Protocol

After sanitization, citation validation, normalization, and ID allocation, release each raw artifact buffer and canonical tuple serialization. Retain only fields required for reconciliation and rendering, digest and ID, source provenance, terminal disposition, and the validated citation map. Retain a full canonical tuple only for records that actually participate in a prefix collision and release it after collision resolution.

Measure peak simultaneously retained source bytes, total sanitized source bytes, and post-release retained normalized-record bytes. Do not call the retained representation compact or claim retention or processing efficiency unless measured post-release retained normalized-record bytes are lower than sanitized source bytes.

Sort retained normalized records by section number, priority from P0 through P3, dependency or category, scenario, normalized evidence path and line, and record ID. Assign stable sequential `F-00X` IDs after sorting.

Render once from the sorted retained normalized records. Permit at most one corrective render total for a named verification defect. Include schema version, status, reasons, coverage metrics, accepted prompt coverage, rejected artifact counts by reason, citation totals, conflict totals, hard-limit state, normalized-record totals, peak simultaneously retained source bytes, sanitized source bytes, and post-release retained normalized-record bytes in the assessment scope and notes. Do not add assessment domains or additional numbered sections.

Use schema version `hve-resiliency-consolidation/v1` and the following direct Sections 1-9 structure.

## Required Output Schema

# HVE Task Research - <repo-name>

Assessment Scope:

* Repository: <repo-name>
* Focus: Between West US 2 and West US regional failover
* Regions Evaluated: West US 2 and West US
* Assessment Date: YYYY-MM-DD
* Generated By: HVE Task Researcher
* Schema Version: hve-resiliency-consolidation/v1
* Consolidation Status: Blocked | Incomplete | Complete
* Status Reasons: <sanitized reasons>
* Coverage: <accepted>/<required>, <accepted>/<applicable optional>, <rejected by reason>
* Processing Metrics: <candidates>, <accepted>, <normalized>, <rendered>, <duplicates>, <citation results>, <conflicts>, <hard-limit state>, <peak retained source bytes>, <sanitized source bytes>, <post-release retained normalized-record bytes>

Notes:

* This document is the evidence-only authoritative research input for HVE Task Planner.
* Every rendered finding and evidence-derived substantive claim maps to retained normalized record IDs; status, coverage, and empty-state text map to the accepted artifact set discovered under the research root.
* No remediation or design guidance is included.

## 1. Repository Context

Document service purpose, application overview, execution model, runtime environment, explicit repository boundaries, and key business processes. Append retained record IDs to every substantive bullet.

## 2. Dependency Inventory

### 2.1 Used Dependencies (Evidence Found)

Render applicable dependency findings using the required finding schema.

### 2.2 Checked but Not Present

| Dependency | Reason Checked | Evidence Result |
| --- | --- | --- |

Include retained record IDs in `Evidence Result`.

### 2.3 Not Applicable Dependency Categories

| Category | Reason Not Applicable |
| --- | --- |

Include retained record IDs in `Reason Not Applicable`.

## 3. Region Assumptions

Render evidence-backed region assumptions from code, configuration, deployment, or startup logic using the required finding schema.

## 4. State and Data Characteristics

Render evidence-backed statefulness, data access, replication, consistency, idempotency, and replay findings using the required finding schema.

## 5. Failure and Degraded-Mode Behavior

Render evidence-backed startup failure, runtime degradation, partial processing, and retry behavior findings using the required finding schema.

## 6. Shared and Cross-Repository Dependencies

Render evidence-backed region coupling, zone dependency, and ownership boundary findings from shared libraries, centralized configuration, or platform utilities using the required finding schema.

## 7. Hard-Coded Values or Secrets in Code or Files

Render sanitized evidence of hard-coded secrets or values using the required finding schema. Never render a secret value or reversible derivative.

## 8. Other Findings Not Categorized Above

Render only retained, meaningful evidence that cannot map to Sections 2-7. Do not use this section to expand assessment scope.

## 9. Research Findings Index (Authoritative)

| Finding ID | Priority | Category | Short Description | Evidence (File:Line) |
| --- | --- | --- | --- | --- |

Include source record IDs in the `Evidence (File:Line)` cell. The index is the canonical Task Planner reference.

## Required Finding Schema

Use this schema exactly once for every finding in Sections 2.1 and 3-8:

### Finding F-00X

* Dependency or Category: <canonical dependency or category>
* Priority: P0 | P1 | P2 | P3
* Ownership: <evidence-backed owner or schema-safe value>
* Scenario: Between West US 2 and West US regional failover
* Description: <evidence-based current behavior>
* Failure Mode and Scenario-Specific Risk: <evidence-based risk>
* Impacts: <operational, data, financial, and customer impacts supported by evidence>
* Evidence: `<normalized-path>:L<start>-L<end>`
* Source Record IDs: <one or more retained NR IDs>
* Existing Mitigations: <evidence-backed mitigations or schema-safe value>
* Constraints and Limitations: <evidence-backed constraints or schema-safe value>

## Verification

Perform at most two verification passes total: one initial pass and, only after the single permitted corrective render, one post-correction pass. Confirm that discovery ran only under the resolved research root; the discovery result is frozen after selection; every required prompt ID has at least one accepted artifact with a body-confirmed prompt ID; each accepted artifact used one baseline byte read; sanitization preceded all retention and transfer; raw buffers and noncollision canonical serializations were released; required byte metrics reconcile; semantically equivalent claims merged with all contributing IDs while material differences remained separate; accepted service evidence and permitted nullable prose did not cause `Incomplete`; Sections 1-9 remain in order; every finding has canonical dependency or category, all required field labels, P0-P3, one allowed scenario, a material failure mode, at least one validated file-line citation, and retained record IDs; every index entry maps to one finding; no unretained evidence appears; and no prohibited recommendation or implementation content is present.

If verification identifies a specific render-only defect, correct it once and repeat verification without rediscovery or source rereads. Otherwise apply the stopping rules.
