---
description: Run Prompt 14 Redis resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 14 Redis

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

## Eligibility And Scope

Run Prompt 14 only. Before any repository traversal or discovery action, use the
provided Prompt 1 output and confirm that Prompt 1 Section 1 identifies each Redis
dependency as used. If that evidence is missing or ambiguous, stop before traversal
and report the eligibility block in the scope and terminal-outcome summaries. Do not
infer eligibility, search for replacement eligibility evidence, or fall back to Prompt
0, another prompt, or conditional skill behavior.

Review each confirmed dependency as Azure Managed Redis Enterprise in an active-active,
multi-region configuration with eventual consistency. Assess readiness for zone failure
within West US 2 and regional failover from West US 2 to West US.

## Task Researcher Boundary

Execute Task Researcher Phase 1 only as evidence-only research. Do not enter or produce
Phase 2. This local boundary controls over inherited requests for alternatives,
recommendations, selected approaches, implementation details or steps, implementation
guidance, remediation, code examples, configuration examples, or next-step suggestions.
Do not produce any of those materials.

## Assessment Areas

Evaluate all 12 areas for every confirmed Redis dependency:

1. Does the app connect to a local Redis endpoint by default?
2. Is region selection explicit and configurable?
3. How does the app detect Redis failure (timeouts/errors)?
4. Is there clear fallback logic to secondary/tertiary regions?
5. Are retries bounded with backoff (no retry storms)?
6. Does the app assume immediate cross-region consistency?
7. On cache miss or stale data, does it safely fall back to the source of truth?
8. Are hot keys or concurrent multi-region writes likely?
9. Is Redis treated strictly as a cache (no durability assumptions)?
10. Can the app start if Redis is unavailable?
11. Does it fail back cleanly once the local region is healthy again?
12. Are health probes aligned between GLB and backend services?

For each evidence-backed issue, assess the impact if it remains unchanged. Classify the
issue as P0, P1, P2, or P3 under the Application Platform Context, explain why the
classification applies, and cite the smallest supporting file and line range.

## Cumulative Discovery Limits

For each confirmed Redis dependency, initialize these action counters to zero and apply
them cumulatively across all 12 assessment areas:

* At most 2 repository searches
* At most 3 file reads, each restricted to the smallest relevant line range
* At most 2 repository traversal hops
* At most 1 focused follow-up

Increment a counter immediately after its action. Never reset, transfer, or duplicate a
counter across assessment areas, aliases, environments, repeated research, delegated
work, or subagent calls. Reuse one action's evidence for every area it answers without
repeating the action.

Use one prompt-wide round counter for the entire invocation. It starts at 0. Transition
from 0 to 1 before the first discovery action. Transition from 1 to 2 before the first
focused follow-up or other second-pass action. Increment only at those transitions,
never reset the round counter, and never start round 3. The prompt-wide maximum is 2
rounds.

## Sources And Exhaustion

Repository discovery is limited to the current repository. Production discovery is
allowed only when the user supplies or approves both a bounded production source and a
bounded access method. Stay within that approval and the remaining action limits. When
either approval is absent, record a named external evidence gap in an existing schema
field. Do not inspect live systems, telemetry, credentials, or endpoints.

One source is one unique repository search result or one user-approved external
artifact. A source class is exhausted only when every result from the permitted bounded
searches has been read within the file-read limit or explicitly left unread because the
limit is exhausted, and no permitted search, read, traversal hop, or focused follow-up
remains. Processing results from the final permitted search within remaining limits is
allowed. After exhaustion, do not broaden or repeat a query, revisit a source, add a
traversal hop, or reset a counter.

## Terminal Outcomes And Stopping

Assign exactly one terminal outcome to every eligible Redis dependency and assessment
area pair:

* Cited file-and-line evidence
* Unknown after exhausting a named repository source class
* Not applicable under the inherited service exclusion rule
* Unknown because a named external evidence gap blocks the value

Stop when every pair has a terminal outcome or round 2 is exhausted, whichever occurs
first. Do not repeat research after a terminal outcome or to improve confidence.

At the round limit, serialize every unresolved value in an existing schema field
exactly as `Unknown: two-round prompt budget exhausted`. No other serialization is
valid for round-limit exhaustion. For other unknown values, use `Unknown` only in an
existing schema field and name the exhausted repository source class or external
evidence gap. `Unknown` alone does not establish a finding. Never invent evidence,
locations, mitigations, constraints, impacts, rationales, or priorities.

## Pre-Consolidation Validation

Before consolidation, use only evidence already read to verify that every cited file
exists, every cited range was read, and every dependency remains eligible under Prompt
1 Section 1. This validation consumes no discovery action and does not change the round
counter. Reject or correct invalid delegated content without additional discovery.
Consolidation fails until all unresolved round-limit values use the exact required
serialization and every eligible dependency and assessment-area pair has one terminal
outcome.

## Authoritative Artifact

Write the research artifact to `.copilot-tracking/research/` using the repository name
as the output filename prefix. The artifact contains exactly these section classes:

1. A concise scope summary
2. A terminal-outcome summary
3. Canonical seven-field issue rows

Do not include tool calls, counters, searches, reads, traversal details, file-analysis
narration, discovery narration, repeated evidence, or any additional authoritative
section.

Keep independently actionable Redis failure modes in distinct rows. Do not merge rows
because they share a dependency, location, priority, or risk level. Start every `Issue
Description:` value with `REDIS-<dependency-slug>-<failure-mode-slug>: <description>`.
Normalize and reuse the same dependency and failure-mode slugs across runs.

The following local schema is authoritative over inherited generic or conditional
templates. Repeat these labels exactly, in this order, for each issue:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app, zone or region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):

Use exactly these seven fields. Do not add an ID field, remediation field, or any other
field. Every issue requires file-and-line evidence. Produce no remediation content.
