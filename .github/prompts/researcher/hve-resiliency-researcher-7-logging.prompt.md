---
description: Assess production logging and silent-outage diagnostics with repository evidence
---

# Application HVE Researcher 7 Logging

## Prerequisite Gate

Run Prompt 7 only; do not launch earlier prompts. An artifact in the inherited research location qualifies only when it starts with YAML frontmatter containing these values and has the matching Section 1 heading listed below:

* Prompt 1a: `source-prompt: hve-resiliency-researcher-1a`, `schema-version: 1`, `status: current`, and `## Section 1 - Used Azure Services (Evidence Confirmed)`
* Prompt 1b: `source-prompt: hve-resiliency-researcher-1b`, `schema-version: 1`, `status: current`, and `## Section 1 — Used External Dependencies (Evidence Confirmed)`

Frontmatter controls identity and status; filename, title, and body never override it. Reject any missing or wrong metadata and every non-`current` status; `status: superseded` is stale. Exactly one artifact per prompt must qualify; zero or multiple block. Consume only confirmed Section 1 dependencies, never fallback or excluded dependencies.

When blocked, write this exact ordered schema without YAML frontmatter or successful sections, then stop before repository traversal:

```text
# Prompt 7 Logging Blocked Result

Status: Blocked
Prompt 1a qualifying count: <integer>
Prompt 1a candidates: <path with rejection reason, or None>
Prompt 1b qualifying count: <integer>
Prompt 1b candidates: <path with rejection reason, or None>
Repository traversal: Not started
Limitations: <limitations>
Next step: generate/identify exactly one current schema-version 1 artifact for each prerequisite
```

## Execution Boundary

Use evidence only: no remediation, recommendations, alternatives, implementation intent, patterns, acceptance criteria, or code examples. Retain inherited path, naming, evidence, and priority rules. A supplied sandbox-local destination overrides the normal destination.

## Bounded Production Discovery

Per-dependency budgets never reset for aliases, environments, or wording:

* Two logging, configuration, or telemetry owner queries; one refinement each only when capped or truncated; 20 displayed matches per ownership surface; five owner or configuration file reads; two production hops
* One negative check per unresolved `Unknown`-eligible field; one corrective search for one ledger-named missed production path

Count objectively:

* A query is one tool invocation with one expression against one ownership category; glob expansion adds none. Its deduplicated category result set is one ownership surface.
* A refinement is one replacement query narrowing that category; it replaces displayed results. A file read opens a new file or focused region; rereading it counts again.
* A hop follows one repository-evidenced edge from owner or configuration to a directly referenced production caller, callee, or configuration include. A corrective search is one query for one ledger-named missed production path.

* Exclude tests, fixtures, samples, generated output, docs, and local-only configuration unless production evidence points there.
* Record all counters per dependency in the execution log and output `Limitations:`.
* Complete the ledger when every required finding field is established or no row emits, every eligible optional field is evidenced or has one bounded `Unknown` check, payment is resolved, and corrective search is used or waived. Then do one tool-free ledger review that adds no candidate, evidence, or unresolved eligible field. Stop.

## Assessment Coverage

Assess confirmed dependencies and workflows for:

* Startup, readiness, liveness, dependency health, retries, failures, and capacity
* Applicable transaction or payment lifecycle, idempotency, dependency calls, outcomes, latency, and failure categories
* Inbound correlation, log context, outbound or message propagation, async or reactive context, and formatter fields
* Structure, levels, sinks, payload exposure, redaction, secrets, PCI data, and PII
* Health and dependency diagnostics, healthy-process silent failure, and safe metrics, traces, spans, tags, and dependency signals

Evaluate payment only when repository-confirmed. Otherwise run one negative payment search, record its scope as Not Applicable, and create no substitute workflow or payment finding.

## Evidence and Finding Controls

* Positive claims require causal repository file-line evidence; never infer defaults or runtime behavior.
* `NOT FOUND` states searched production roots or surfaces, exact symbol or query classes, result count, exclusions, and corrective search. Never fabricate a citation or treat absence as runtime proof.
* Finding identity is dependency or workflow + concern or category + production owner or entrypoint + diagnostic outcome. Separate distinct outcomes or priorities; retain every citation.
* Emit only after establishing identity, observed behavior, P0-P3 priority, and causal file-line evidence.
* `Unknown: not found after bounded search <scope>` is allowed only for optional impact, diagnostic, operational, mitigation, constraint, or workaround values, never identity, behavior, priority, or evidence.

## Priority Definitions

* P0: Critical / Blocking. Causes outage, data loss, duplicate charges, or unsafe regional failover.
* P1: Required, Non-Blocking. Materially increases application risk, data risk, or customer impact during failure without blocking failover.
* P2: Improvement / Best Practice. Weakens resilience or operational clarity without materially affecting failover correctness.
* P3: Non-Blocking Code Consistency. Covers non-blocking maintainability, readability, duplication, or inconsistent patterns.

## Output Artifact

For success, use the inherited research path and repository-prefixed name with exactly these sections:

## Section 1 Current Logging Inventory

Table: component or module; dependency or workflow; logged events or states; fields; level and format; sink or telemetry; repository file-line evidence. Include payment Not Applicable when needed. End with `Limitations:` and each dependency's query, ownership-surface, refinement, file-read, hop, negative-check, and corrective-search counters.

## Section 2 Prioritized Gaps and Risks

List `F-###` findings with ID; dependency or workflow; concern or category; production owner or entrypoint; diagnostic outcome; observed behavior; P0-P3 priority; optional impact, diagnostic impact, operational impact, mitigation, constraints, workaround; repository file-line evidence.

End with `Can we diagnose a silent payment outage?` when applicable, otherwise `Can we diagnose a silent transaction outage?`. Synthesize only finding IDs and confirmed inventory evidence; do not repeat impacts.

## Section 3 Evidence-Backed Planning Handoff

For Section 2 findings only, list ID, observed missing capability, evidence, constraints, and planner owner or scope only when repository-evidenced. Add no finding or prescriptive content.

## Final Response

Return only the artifact path, status, limitations, and next step.

---

Execute this prompt's prerequisite gate, bounded production assessment, and output workflow to completion.
