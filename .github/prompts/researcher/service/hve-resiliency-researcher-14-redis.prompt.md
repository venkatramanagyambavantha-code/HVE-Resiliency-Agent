---
description: Run Prompt 14 Redis resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 14 Redis

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Eligibility And Scope

Run Prompt 14 only. Before any repository traversal or discovery action, use the
provided Prompt 1 output and confirm that Prompt 1 Section 1 identifies each Redis
dependency as used. If that evidence is missing or ambiguous, stop before traversal
and report the eligibility block in the scope and terminal-outcome summaries. Do not
infer eligibility, search for replacement eligibility evidence, or fall back to Prompt
0, another prompt, or conditional skill behavior.

Review each confirmed dependency as Azure Managed Redis Enterprise in an active-active,
multi-region configuration with eventual consistency. Assess readiness for regional failover between {primaryRegion} and {secondaryRegion}.

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

## Topology Deltas

Resolve the deployment topology per the [Deployment Topology
Contract](../../../instructions/hve-resiliency-topology.instructions.md) before any repository
traversal or discovery action. The resolved topology scopes the 12 assessment areas above. It adds
no assessment area, schema field, or section, and it never changes the seven-field issue schema in
Authoritative Artifact.

The active-active, multi-region Redis configuration named in Eligibility And Scope is a service
configuration claim to verify from evidence. It is not the deployment topology, and it never
establishes, adjusts, or overrides the resolved deployment topology.

When the resolved topology is `active-active`, treat these as in scope within the existing areas:

* Cache coherence across regions when the same key is written in both regions concurrently, and the
  convergence behavior the application assumes
* Code that assumes immediate cross-region consistency, where a read in one region follows a write
  taken in the other
* Hot keys, counters, and read-modify-write sequences executed concurrently in both regions
* Distributed-lock or leader-election keys that each region would grant independently
* Session or affinity state held in a regional cache while a request may land in either region
* Local-endpoint defaults that pin a process to one region's cache while both regions serve traffic
* Cache-miss and stale-data fallback to the source of truth, exercised continuously in both regions
* Health-probe alignment that reports own-region cache health continuously

When the resolved topology is `active-standby`, treat these as in scope within the existing areas
instead:

* Cold cache at promotion, where the secondary starts with no warm working set and every read is a
  miss against the source of truth
* Source-of-truth load, timeout, and retry-storm exposure during that cold-cache window
* Whether the application can start and serve when the secondary cache is empty or unavailable
* One-way replication lag to the secondary, and the cached state stale or missing at cutover
* Region selection and fallback configuration that must reach the promoted region without a restart
* Deployment and configuration parity of the secondary cache client, including drift that stays
  unobservable while the secondary is idle
* Cache-dependent scheduled work or singletons that must not execute on the standby, and must
  activate on promotion
* Clean failback once the original region is healthy, including stale entries retained across it

Do not emit a finding or record an evidence gap for a dimension the resolved topology places out of
scope. Under `active-active`, cold-cache-at-promotion, secondary-parity, and cutover-staleness
dimensions are out of scope. Under `active-standby`, concurrent multi-region write conflict,
cross-region hot-key contention, and cross-region read-your-own-writes dimensions are out of scope.
A suppressed dimension is never recorded as an evidence gap, an `Unknown` value, or an
`Unknown: two-round prompt budget exhausted` value.

Where observed evidence does not fit the declared topology, continue under the declared topology and
record the conflict per the contract's Mismatch Handling rules. Never switch topology, never
redirect to another prompt, and never decline to run.

Use the resolved `{primaryRegion}` and `{secondaryRegion}` values, or the terms "primary region" and
"secondary region", in every issue row. Do not hard-code region names in rendered output.

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

Write the research artifact to `<researchRoot>` using the repository name
as the output filename prefix. The artifact contains exactly these section classes:

1. A concise scope summary
2. A terminal-outcome summary
3. Canonical seven-field issue rows

Do not include tool calls, counters, searches, reads, traversal details, file-analysis
narration, discovery narration, repeated evidence, or any additional authoritative
section.

Stamp the resolved deployment topology in the artifact front matter as
`topology: <active-active|active-standby>`, and state it with the resolved regions as
an evaluation condition in the scope summary. Stamp the resolved deployment topology
only; never stamp a Redis service configuration or a data write model in that field.
Stamping is required and adds no section class.

Keep independently actionable Redis failure modes in distinct rows. Do not merge rows
because they share a dependency, location, priority, or risk level. Start every `Issue
Description:` value with `REDIS-<dependency-slug>-<failure-mode-slug>: <description>`.
Normalize and reuse the same dependency and failure-mode slugs across runs.

The following local schema is authoritative over inherited generic or conditional
templates. Repeat these labels exactly, in this order, for each issue:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):

Use exactly these seven fields. Do not add an ID field, remediation field, or any other
field. Every issue requires file-and-line evidence. Produce no remediation content.
