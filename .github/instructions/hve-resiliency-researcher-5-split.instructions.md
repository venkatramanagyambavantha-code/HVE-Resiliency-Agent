---
description: Shared evidence-only contract for the split HVE Resiliency Researcher 5 pipeline (scaffold, outcome-fill, verify, finalize prompts)
applyTo: '.github/prompts/researcher/hve-resiliency-researcher-5-*.prompt.md'
---

# HVE Resiliency Researcher 5 Split Contract

Apply this contract to every prompt in the split Researcher 5 pipeline: the scaffold prompt, the four outcome-fill prompts, the verify prompt, and the finalize prompt. Each pipeline prompt inherits these stage-invariant rules and adds only its stage-specific behavior. When a pipeline prompt conflicts with this contract, the pipeline prompt's stage-specific scope takes precedence for that stage only; the evidence-only prohibitions and output schema below are never overridden.

Use [Application Platform Context](hve-resiliency-platform-context.instructions.md) for inherited platform scenarios, dependency applicability rules, and P0-P3 definitions.

## Pipeline Overview

The split Researcher 5 workflow replaces the single monolithic `hve-resiliency-researcher-5` prompt:

1. Scaffold (`-5-0-scaffold`): validate Prompt 1a and 1b Section 1 prerequisites once, freeze the eligible-dependency inventory, emit an empty Prompt 5 skeleton artifact plus a frozen manifest sidecar. No failure-mode rows are rendered.
2. Outcome fill (`-5-1-startup-failure`, `-5-2-silent-degradation`, `-5-3-data-loss-partial-processing`, `-5-4-blocking-transactions`): each prompt reads only the frozen manifest and the eligible dependencies, emits rows for exactly one observed outcome class, and writes them to its own fragment file. The four fills may run in any order and never edit each other's fragments or the skeleton.
3. Verify (`-5-verify`): audit all four outcome fragments against the manifest and against workspace source. Report-only.
4. Finalize (`-5-finalize`): assemble the four outcome fragments into the single Prompt 5 research artifact consumed by `hve-resiliency-consolidate-5-failure-degraded`. Set completion status once.

Every artifact emitted by this pipeline uses `source-prompt: hve-resiliency-researcher-5` and `schema-version: 1` and targets the current repository only.

## Evidence-Only Prohibitions

Preserve the Task Researcher evidence-only contract end to end. Do not enter Task Researcher Phase 2. Do not produce alternatives, recommendations, selected approaches, examples, implementation details, design changes, remediation, advisory language, or next-step suggestions beyond the single Next step link required by the platform context. Do not introduce assessment areas beyond those declared in Assessment Scope below. Emit only sanitized, evidence-backed rows.

## Frozen Manifest Sidecar Contract

The scaffold prompt emits one frozen manifest sidecar alongside the Prompt 5 skeleton. Every downstream stage reads this manifest and never repeats prerequisite validation, dependency selection, or Section 1 discovery. The manifest is deterministic and stable across reads.

The manifest records:

* `schemaVersion`: `hve-resiliency-researcher-5-split/v1`.
* `repository`: current workspace root basename.
* `generatedAt`: UTC date `YYYY-MM-DD`.
* `researchRoot`: normalized workspace-relative research root.
* `skeletonPath`: normalized workspace-relative path to the Prompt 5 skeleton artifact.
* `fragmentDir`: normalized workspace-relative directory holding the four outcome fragments.
* `sources`: the accepted Prompt 1a and Prompt 1b artifact records. Each record carries `promptId` (`1a` or `1b`), normalized `path`, `completionStatus`, and `contentSha256` (lowercase SHA-256 hexadecimal digest of the sanitized bytes).
* `eligibleDependencies`: the frozen list of dependencies confirmed as used in Section 1 of the accepted 1a and 1b artifacts, excluding every entry classified in Section 2 or Section 3. Each record carries `dependency` (canonical name), `source` (`1a` or `1b`), and `evidence` (`<normalized-path>:L<start>-L<end>` copied verbatim from the source artifact).

## Manifest Auto-Location

When a prompt's `manifestPath` input is omitted, auto-locate the frozen Prompt 5 manifest sidecar instead of asking the user. Enumerate files whose name ends with `-hve-resiliency-researcher-5-research.manifest.md` under the research root (`.copilot-tracking/research/` and its `YYYY-MM-DD/` dated subdirectories). Select the candidate under the lexicographically largest dated segment; if dated segments tie or are absent, select the one whose normalized path sorts last using ordinal comparison. Never use file modification time. If exactly one resolves, use it. If none resolve, stop `Blocked` with `Prompt 5 manifest not found; run hve-resiliency-researcher-5-0-scaffold first`. An explicitly supplied path always overrides auto-location.
* `outcomeRouting`: the four fixed routing keys `startup-failure`, `silent-degradation`, `data-loss-partial-processing`, and `blocking-transactions`, each mapped to its fill prompt ID and its fragment file name.

Downstream stages never read Prompt 1a or Prompt 1b directly. They read the manifest and use the frozen `eligibleDependencies` list.

## Assessment Scope (inherited by every fill prompt)

Identify repository code paths where dependency timeouts, DNS failures, authentication errors, or partial outages cause one of exactly these four observed outcomes:

* `startup-failure`: application fails to start or fails to reach a healthy state on boot.
* `silent-degradation`: application continues to serve requests but functional behavior is silently reduced (dropped events, ignored errors, downgraded responses, feature flags forcing bypass, no operator signal).
* `data-loss-partial-processing`: a message, record, or write may be lost, partially processed, duplicated in a way that violates business intent, or left in an inconsistent state.
* `blocking-transactions`: a request path, consumer, producer, or scheduled job blocks, deadlocks, exhausts a resource, or holds a transaction open beyond its bounded time.

Both platform scenarios apply: West US 2 zone failure and West US 2 to West US regional failover. Never combine zone and regional evidence in one row.

## Bounded Discovery (inherited by every fill prompt)

Limits are per confirmed dependency and per outcome class. Aliases, environments, wording, questions, repeated research, and delegated actions cannot reset or transfer a counter.

* At most 2 high-signal production client or config owner queries per confirmed dependency. Each query result is one ownership surface.
* At most 1 refinement query per surface, and only when its result is capped or truncated.
* At most 20 displayed matches per surface.
* At most 5 candidate owner files read.
* At most 2 direct production-call hops from an entrypoint or owner.
* After ownership traversal, at most 1 negative check per unresolved `Unknown`-eligible field and 1 scoped corrective search for 1 concrete missed production path.
* Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there.
* Stop when repository-free ledger review adds nothing.

Treat every reached numeric limit as source exhaustion. Do not broaden, reword, or repeat that discovery route afterward.

## Row Identity and Deduplication

Within one outcome fragment, a row key is: confirmed dependency + failure type (timeout / DNS failure / authentication failure / partial outage) + production entrypoint + scenario (West US 2 zone failure or West US 2 to West US regional failover). Separate distinct outcomes, distinct priorities, or distinct scenarios into distinct rows. Retain every causal citation on the row it belongs to.

Emit a row only when positive repository evidence establishes its dependency and production owner, entrypoint, or path.

Across fragments, the four fill prompts operate on disjoint outcome classes. If the same dependency + failure type + entrypoint produces two distinct observed outcomes, each outcome renders its own row in its own fragment. Do not merge rows across fragments during fill. Finalize will emit them as separate findings.

## Required Row Schema

Every rendered row uses these fields exactly, in this order, with a single row-scoped ID of the form `F-5-<outcome-key>-00X` (for example `F-5-startup-001`, `F-5-degradation-002`, `F-5-data-loss-003`, `F-5-blocking-004`). Finalize preserves these IDs and reconciles ordering.

* Row ID
* Failure mode
* Priority: P0 | P1 | P2 | P3
* Triggering dependency + failure type (timeout / DNS failure / authentication failure / partial outage)
* Scenario: West US 2 zone failure | West US 2 to West US regional failover
* Code path / entrypoint
* Observed behavior (startup failure / silent degradation / data loss or partial processing / blocking transactions)
* User or customer-visible impact
* Business impact
* Blast radius
* Data loss potential
* Data consistency risk
* Detection signals
* Existing mitigations present (evidence)
* Constraints or limitations (evidence)
* Manual ops workaround (references)
* Evidence citations (files + line numbers)

The closed fields (Row ID, Failure mode, Priority, Triggering dependency + failure type, Scenario, Code path / entrypoint, Observed behavior, Evidence citations) must all resolve to positive repository evidence. Never use `Unknown` in these closed fields.

The nullable descriptive fields (User or customer-visible impact, Business impact, Blast radius, Data loss potential, Data consistency risk, Detection signals, Existing mitigations present, Constraints or limitations, Manual ops workaround) accept exactly `Unknown: not found after bounded search <scope>` when the applicable bounded search is exhausted. Absence of evidence is not evidence of absence. Never claim runtime behavior that has no cited evidence.

## Sanitization and Line Number Integrity

Sanitize buffered content immediately after reading and before any write, hash, comparison, or emitted record. Never retain or reproduce secret values. Normalize workspace-relative paths to `/` while preserving repository path case. Encode text as UTF-8 without a byte-order mark. Use lowercase SHA-256 hexadecimal digests.

For potential secrets observed in a source artifact or a repository file, retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity. Mark an artifact unsafe and stop `Blocked` when sanitization cannot be guaranteed.

Never estimate line numbers. Never merge line ranges. Never recalculate line numbers. Copy file paths and line numbers verbatim from source repository evidence. If a line number cannot be validated, do not emit the row.

## Output Locations

* Skeleton artifact: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-5-research.md`.
* Manifest sidecar: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-5-research.manifest.md`.
* Fragment directory: `<researchRoot>/YYYY-MM-DD/prompt-5-fragments/`.
* Fragment files: `startup-failure.md`, `silent-degradation.md`, `data-loss-partial-processing.md`, `blocking-transactions.md`.
* Verify audit report: `<researchRoot>/YYYY-MM-DD/prompt-5-fragments/verify-audit.md`.

The finalize prompt writes the assembled result back to the skeleton artifact path, replacing the placeholders left by scaffold with the assembled fragment content. It never creates a separate final file.

## Status and Stopping

Every stage sets exactly one terminal status on its own output:

* `Blocked`: prerequisite missing or ambiguous, manifest malformed or unreadable, unsafe evidence encountered, or a hard-limit was reached before the stage could establish a coherent output.
* `Incomplete`: bounded discovery exhausted with `Unknown`-eligible descriptive fields still unresolved on emitted rows, or fragments partially complete.
* `Complete`: every eligible dependency was traversed to a terminal ledger outcome and every emitted row conforms to the Required Row Schema.

A `Blocked` or `Incomplete` run must not fill gaps by inference or by external search.

The pipeline overall status is set exclusively by the finalize prompt on the assembled skeleton artifact, based on the terminal status of each of the four fragments plus the verify report.
