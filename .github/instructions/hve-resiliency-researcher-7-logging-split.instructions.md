---
description: Shared evidence-only contract for the split HVE Resiliency Researcher 7 Logging pipeline (scaffold, category-fill, verify, finalize prompts)
applyTo: '.github/prompts/researcher/hve-resiliency-researcher-7-logging-*.prompt.md'
---

# HVE Resiliency Researcher 7 Logging Split Contract

Apply this contract to every prompt in the split Researcher 7 Logging pipeline: the scaffold prompt, the five category-fill prompts, the verify prompt, and the finalize prompt. Each pipeline prompt inherits these stage-invariant rules and adds only its stage-specific behavior. When a pipeline prompt conflicts with this contract, the pipeline prompt's stage-specific scope takes precedence for that stage only; the evidence-only prohibitions and output schema below are never overridden.

Use [Application Platform Context](hve-resiliency-platform-context.instructions.md) for inherited platform scenarios, dependency applicability rules, and P0-P3 definitions.

## Pipeline Overview

The split Researcher 7 Logging workflow replaces the single monolithic `hve-resiliency-researcher-7-logging` prompt:

1. Scaffold (`-7-logging-0-scaffold`): validate Prompt 1a and 1b Section 1 prerequisites once, freeze the eligible-dependency inventory, emit an empty Prompt 7 skeleton artifact plus a frozen manifest sidecar. No inventory rows or findings are rendered.
2. Category fill (`-7-logging-1-startup-health`, `-7-logging-2-transactions`, `-7-logging-3-correlation-context`, `-7-logging-4-log-hygiene`, `-7-logging-5-silent-outage-diagnostics`): each prompt reads only the frozen manifest and the eligible dependencies, emits Section 1 inventory rows and Section 2 findings for exactly one assessment category, and writes them to its own fragment file. The five fills may run in any order and never edit each other's fragments or the skeleton.
3. Verify (`-7-logging-verify`): audit all five category fragments against the manifest and against workspace source. Report-only.
4. Finalize (`-7-logging-finalize`): assemble the five category fragments into the single Prompt 7 research artifact consumed downstream. Set completion status once. Build Section 3 planning handoff from the assembled Section 2 findings.

Every artifact emitted by this pipeline uses `source-prompt: hve-resiliency-researcher-7-logging` and `schema-version: 1` and targets the current repository only.

## Evidence-Only Prohibitions

Preserve the Task Researcher evidence-only contract end to end. Do not enter Task Researcher Phase 2. Do not produce alternatives, recommendations, selected approaches, examples, implementation details, design changes, remediation, advisory language, or next-step suggestions beyond the single Next step link required by the platform context. Do not introduce assessment categories beyond the five declared in Assessment Categories below. Emit only sanitized, evidence-backed inventory rows and findings.

## Frozen Manifest Sidecar Contract

The scaffold prompt emits one frozen manifest sidecar alongside the Prompt 7 skeleton. Every downstream stage reads this manifest and never repeats prerequisite validation, dependency selection, or Section 1 discovery. The manifest is deterministic and stable across reads.

The manifest records:

* `schemaVersion`: `hve-resiliency-researcher-7-logging-split/v1`.
* `repository`: current workspace root basename.
* `generatedAt`: UTC date `YYYY-MM-DD`.
* `researchRoot`: normalized workspace-relative research root.
* `skeletonPath`: normalized workspace-relative path to the Prompt 7 skeleton artifact.
* `fragmentDir`: normalized workspace-relative directory holding the five category fragments.
* `sources`: the accepted Prompt 1a and Prompt 1b artifact records. Each record carries `promptId` (`1a` or `1b`), normalized `path`, `completionStatus`, and `contentSha256` (lowercase SHA-256 hexadecimal digest of the sanitized bytes).
* `eligibleDependencies`: the frozen list of dependencies confirmed as used in Section 1 of the accepted 1a and 1b artifacts, excluding every entry classified in Section 2 or Section 3. Each record carries `dependency` (canonical name), `source` (`1a` or `1b`), and `evidence` (`<normalized-path>:L<start>-L<end>` copied verbatim from the source artifact).

## Manifest Auto-Location

When a prompt's `manifestPath` input is omitted, auto-locate the frozen Prompt 7 Logging manifest sidecar instead of asking the user. Enumerate files whose name ends with `-hve-resiliency-researcher-7-logging-research.manifest.md` under the research root (`.copilot-tracking/research/` and its `YYYY-MM-DD/` dated subdirectories). Select the candidate under the lexicographically largest dated segment; if dated segments tie or are absent, select the one whose normalized path sorts last using ordinal comparison. Never use file modification time. If exactly one resolves, use it. If none resolve, stop `Blocked` with `Prompt 7 Logging manifest not found; run hve-resiliency-researcher-7-logging-0-scaffold first`. An explicitly supplied path always overrides auto-location.
* `categoryRouting`: the five fixed routing keys `startup-health`, `transactions`, `correlation-context`, `log-hygiene`, and `silent-outage-diagnostics`, each mapped to its fill prompt ID and its fragment file name.
* `paymentApplicability`: `applicable` when payment evidence is confirmed in Section 1 of either accepted 1a or 1b artifact, otherwise `not-applicable`. This value is frozen; downstream stages do not re-derive it.

Downstream stages never read Prompt 1a or Prompt 1b directly. They read the manifest and use the frozen `eligibleDependencies` list.

## Assessment Categories (inherited by every fill prompt)

The five assessment categories are the only assessment axes for this pipeline. Each fill prompt owns exactly one category and emits rows and findings only for that category.

* `startup-health`: startup, readiness, liveness, dependency health, retries, failures, and capacity signals.
* `transactions`: applicable transaction or payment lifecycle, idempotency, dependency calls, outcomes, latency, and failure categories. Payment sub-scope renders only when the manifest's `paymentApplicability` is `applicable`.
* `correlation-context`: inbound correlation, log context, outbound or message propagation, async or reactive context, and formatter fields.
* `log-hygiene`: log structure, levels, sinks, payload exposure, redaction, secrets, PCI data, and PII.
* `silent-outage-diagnostics`: health and dependency diagnostics, healthy-process silent failure, and safe metrics, traces, spans, tags, and dependency signals.

Both platform scenarios apply: West US 2 zone failure and West US 2 to West US regional failover. Never combine zone and regional evidence in one row or finding.

## Bounded Discovery (inherited by every fill prompt)

Limits are per confirmed dependency and per category. Aliases, environments, wording, questions, repeated research, and delegated actions cannot reset or transfer a counter.

* At most 2 logging, configuration, or telemetry owner queries per confirmed dependency. Each query result is one ownership surface.
* At most 1 refinement query per surface, and only when its result is capped or truncated.
* At most 20 displayed matches per surface.
* At most 5 candidate owner or configuration files read.
* At most 2 direct production hops from an entrypoint or owner.
* After ownership traversal, at most 1 negative check per unresolved `Unknown`-eligible field and 1 scoped corrective search for 1 concrete missed production path.
* Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there.
* Stop when repository-free ledger review adds nothing.

Treat every reached numeric limit as source exhaustion. Do not broaden, reword, or repeat that discovery route afterward.

## Inventory Row Identity and Deduplication

Within one category fragment, an inventory row key is: production component or module + confirmed dependency or workflow + log sink or telemetry surface. Separate distinct sinks, distinct owners, or distinct workflows into distinct rows. Retain every causal citation on the row it belongs to.

Emit an inventory row only when positive repository evidence establishes its production component or module, its dependency or workflow, and at least one logged event or state.

## Finding Identity and Deduplication

Within one category fragment, a finding key is: confirmed dependency or workflow + concern or sub-category + production owner or entrypoint + diagnostic outcome. Separate distinct outcomes, distinct priorities, or distinct scenarios into distinct findings. Retain every causal citation.

Emit a finding only when positive repository evidence establishes its dependency or workflow, its production owner or entrypoint, and its observed behavior.

Across fragments, the five fill prompts operate on disjoint assessment categories. If the same dependency + entrypoint produces two distinct concerns that fall in two different categories, each concern renders its own finding in its own fragment. Do not merge findings across fragments during fill. Finalize will emit them as separate findings.

## Required Inventory Row Schema

Every Section 1 inventory row uses these fields exactly, in this order, with a single row-scoped ID of the form `I-7-<category-key>-00X` (for example `I-7-startup-health-001`, `I-7-log-hygiene-002`). Finalize preserves these IDs.

* Row ID
* Component or module
* Dependency or workflow
* Logged events or states
* Fields
* Level and format
* Sink or telemetry
* Evidence citations (files + line numbers)

Every closed field must resolve to positive repository evidence. Never use `Unknown` in an inventory row's closed fields; drop the row instead.

When payment is `not-applicable` per the manifest and a category would otherwise render a payment-specific row, render exactly one summary row with Component or module `payment`, Dependency or workflow `payment`, Logged events or states `Not Applicable`, remaining fields `Not Applicable`, and Evidence citations pointing to the manifest's `paymentApplicability` record.

## Required Finding Schema

Every Section 2 finding uses these fields exactly, in this order, with a single finding-scoped ID of the form `F-7-<category-key>-00X` (for example `F-7-startup-health-001`, `F-7-log-hygiene-002`). Finalize preserves these IDs and reconciles ordering.

* Finding ID
* Dependency or workflow
* Concern or sub-category
* Production owner or entrypoint
* Diagnostic outcome
* Observed behavior
* Priority: P0 | P1 | P2 | P3
* Scenario: West US 2 zone failure | West US 2 to West US regional failover
* Optional impact (nullable)
* Diagnostic impact (nullable)
* Operational impact (nullable)
* Mitigation (nullable)
* Constraints (nullable)
* Workaround (nullable)
* Evidence citations (files + line numbers)

The closed fields (Finding ID, Dependency or workflow, Concern or sub-category, Production owner or entrypoint, Diagnostic outcome, Observed behavior, Priority, Scenario, Evidence citations) must all resolve to positive repository evidence. Never use `Unknown` in these closed fields.

The nullable descriptive fields (Optional impact, Diagnostic impact, Operational impact, Mitigation, Constraints, Workaround) accept exactly `Unknown: not found after bounded search <scope>` when the applicable bounded search is exhausted. Absence of evidence is not evidence of absence. Never claim runtime behavior that has no cited evidence.

## Sanitization and Line Number Integrity

Sanitize buffered content immediately after reading and before any write, hash, comparison, or emitted record. Never retain or reproduce secret values. Normalize workspace-relative paths to `/` while preserving repository path case. Encode text as UTF-8 without a byte-order mark. Use lowercase SHA-256 hexadecimal digests.

For potential secrets observed in a source artifact or a repository file, retain only the secret type, normalized file path and line, key or symbol name, and a stable redacted identity. Mark an artifact unsafe and stop `Blocked` when sanitization cannot be guaranteed.

Never estimate line numbers. Never merge line ranges. Never recalculate line numbers. Copy file paths and line numbers verbatim from source repository evidence. If a line number cannot be validated, do not emit the row or finding.

## Output Locations

* Skeleton artifact: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-7-logging-research.md`.
* Manifest sidecar: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-7-logging-research.manifest.md`.
* Fragment directory: `<researchRoot>/YYYY-MM-DD/prompt-7-logging-fragments/`.
* Fragment files: `startup-health.md`, `transactions.md`, `correlation-context.md`, `log-hygiene.md`, `silent-outage-diagnostics.md`.
* Verify audit report: `<researchRoot>/YYYY-MM-DD/prompt-7-logging-fragments/verify-audit.md`.

The finalize prompt writes the assembled result back to the skeleton artifact path, replacing the placeholders left by scaffold with the assembled fragment content. It never creates a separate final file.

## Status and Stopping

Every stage sets exactly one terminal status on its own output:

* `Blocked`: prerequisite missing or ambiguous, manifest malformed or unreadable, unsafe evidence encountered, or a hard-limit was reached before the stage could establish a coherent output.
* `Incomplete`: bounded discovery exhausted with `Unknown`-eligible descriptive fields still unresolved on emitted findings, or fragments partially complete.
* `Complete`: every eligible dependency was traversed to a terminal ledger outcome and every emitted inventory row and finding conforms to the Required Schemas.

A `Blocked` or `Incomplete` run must not fill gaps by inference or by external search.

The pipeline overall status is set exclusively by the finalize prompt on the assembled skeleton artifact, based on the terminal status of each of the five fragments plus the verify report.
