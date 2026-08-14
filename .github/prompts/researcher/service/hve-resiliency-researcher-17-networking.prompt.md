---
description: "Run bounded Prompt 17 networking resiliency research"
agent: "Task Researcher"
---

# Application HVE Researcher 17 Networking Optimized

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Eligibility And Scope

Run Prompt 17 directly. Before any repository traversal or discovery action, use the
provided Prompt 1 output to confirm every networking dependency as used in Prompt 1
Section 1. Analyze only confirmed dependencies. Apply the inherited service exclusion
rule: dependencies classified as Checked But Not Present or Not Applicable are
excluded from discovery and analysis.

Prompt 1 input is structurally usable only when it contains an identifiable Section 1
dependency inventory and classifications that can be evaluated for networking
eligibility. If the input is structurally unusable, assign report status
`Invalid-input` and stop at round 0 with zero discovery actions. If Section 1 evidence
for any dependency is missing or ambiguous, assign report status `Blocked` and stop at
round 0 with zero discovery actions. In either case, produce only the concise scope
summary and terminal summary. Do not infer eligibility, search for substitute
eligibility evidence, or fall back to Prompt 0, another service prompt, or conditional
skill behavior.

For every eligible networking dependency, assess readiness for both failure scenarios:

* Regional failover from West US 2 to West US

## Task Researcher Boundary

Execute Task Researcher Phase 1 only as evidence-only research. Do not enter or
produce Phase 2. This local boundary controls over inherited requests for remediation,
recommendations, code or configuration examples, alternatives, selected approaches,
implementation details or steps, implementation guidance, or artifact next-step
suggestions. Do not produce any of those materials.

## Architecture Assumptions

Evaluate the networking concerns against all seven assumptions without converting an
assumption into another assessment concern:

1. Public L7 traffic uses Imperva as a single edge.
2. Public and private L4 traffic uses DNS-based GLB through F5 BIG-IP DNS.
3. DNS records use a low TTL of approximately 30 seconds.
4. Private Endpoints are regional and their IP addresses do not change.
5. Regional failover is DNS-name based, not IP-based.
6. Some PaaS services require application-level failover.
7. Cross-region traffic may occur during failover.

## Networking Concerns

Evaluate exactly these seven concern groups for every eligible networking dependency:

1. DNS dependency assumptions, including caching, hardcoded IP addresses, and TTL
   handling.
2. Connection retry and timeout behavior.
3. Session-state handling across regions.
4. Dependency on region-specific endpoints or FQDNs.
5. Handling of stalled or half-open connections during regional failure.
6. Awareness of platform-driven versus application-driven failover.
7. Alignment of health probes between the GLB and backend services.

For each evidence-backed issue, classify the failure risk as P0, P1, P2, or P3 under
the Application Platform Context. Explain why the classification applies and cite the
smallest supporting file and line range. Unknown alone does not establish a finding.

## Cumulative Discovery Limits

For each eligible networking dependency, initialize these counters to zero:

* At most 2 repository searches
* At most 3 file reads, each restricted to the smallest relevant line range
* At most 2 repository traversal hops
* At most 1 focused follow-up

Apply each dependency's counters cumulatively across aliases, all seven concerns,
environments, rounds, repeated research, delegated work, and subagent calls. Increment
the applicable counter immediately after every action. Never reset, transfer,
duplicate, reassign, or otherwise reproduce a counter. Reuse already-read evidence
across every concern it answers.

Use one prompt-wide round counter. Start at 0. Transition from 0 to 1 before the first
discovery action. Transition from 1 to 2 before the first focused follow-up or other
second-pass action. Increment only at those transitions. Never reset the round counter
and never start round 3.

## Sources And Exhaustion

Default discovery to the current repository. Production discovery is prohibited
unless the user supplies or approves all six elements of a bounded production-source
contract:

1. A named production source
2. A read-only access method
3. A query limit
4. A result limit
5. A time window
6. A follow-up limit

Do not invent any production-contract value. Do not inspect live systems, telemetry,
credentials, or endpoints without complete approval. Approved production actions must
remain within that contract and consume the eligible dependency's remaining cumulative
counters. Without complete approval, do not perform substitute or fallback discovery;
name the external evidence gap in an existing schema field when an evidence-backed
issue has an unresolved value.

One source is one unique repository search result or one approved external artifact.
A named repository source class is exhausted only after every result from permitted
bounded searches is read within the file-read limit or explicitly left unread because
that limit is exhausted, and no repository search, file read, traversal hop, or focused
follow-up remains for that dependency. Results from the final permitted search may be
processed within remaining limits. After exhaustion, do not broaden or repeat a query,
revisit a source, add a traversal hop, or reset any counter.

## Terminal Outcomes And Stopping

Assign exactly one terminal outcome to every eligible networking dependency and
concern pair:

* Cited file-and-line evidence
* Unknown after exhausting a named repository source class
* Not applicable under the inherited service exclusion rule
* Unknown because a named external evidence gap blocks the value

Stop when every eligible pair has exactly one terminal outcome or round 2 is
exhausted, whichever occurs first. Do not perform confidence-improvement research or
any research after a pair reaches a terminal outcome.

At round exhaustion, serialize every unresolved pair exactly as
`Unknown: two-round prompt budget exhausted`. No alternate round-exhaustion text is
valid. Keep every other Unknown value inside an existing schema field and name the
exhausted repository source class or external evidence gap. Unknown alone is not a
finding. Keep no-evidence pair outcomes in the terminal summary and do not fabricate
issue rows. Never invent evidence, locations, mitigations, constraints, impacts,
rationales, or priorities.

## Pre-Consolidation Validation

Before consolidation, use only already-read evidence to verify that every dependency
remains eligible under Prompt 1 Section 1, every cited file exists, and every cited
line range was read. This validation consumes zero actions, cannot start a round, and
cannot change a counter. Reject or correct invalid delegated content without further
discovery. Consolidation fails until every eligible dependency and concern pair has
exactly one terminal outcome and every unresolved round-exhaustion value uses the
required exact text.

## Authoritative Artifact

Write the research artifact to `.copilot-tracking/research/` using the repository name
as the output filename prefix. Restrict the authoritative artifact to these three
section classes, in this order:

1. A concise scope summary
2. A research-status or terminal summary
3. Canonical seven-field issue rows

Use no fourth section class. Round-0 `Invalid-input` and `Blocked` runs contain only
the first two section classes. A `Bounded no-evidence` run contains no fabricated issue
row. Keep counters, round state, tool calls, searches, reads, traversal details,
file-analysis narration, discovery narration, and repeated evidence outside the
artifact.

Place exactly one report-level status in the research-status or terminal summary.
Apply this precedence from highest to lowest:

1. `Invalid-input`: the supplied Prompt 1 input cannot be structurally evaluated.
2. `Blocked`: eligibility is missing or ambiguous at round 0, or an approved source
   required to begin eligible research is unavailable.
3. `Partial/exhausted`: at least one evidence-backed result exists and at least one
   eligible pair ends Unknown because a source, action, or round limit is exhausted.
4. `Bounded no-evidence`: eligible bounded discovery completes or exhausts with no
   evidence-backed issue row, and the terminal summary accounts for every pair.
5. `Complete`: every eligible pair has a terminal outcome, no pair remains Unknown due
   to exhaustion or a blocking external gap, and every evidence-backed issue is
   emitted.

The report-level status is metadata in the second section class, not an issue field.

Emit a separate row for every independently actionable networking failure mode, even
when rows share a dependency, location, priority, risk level, mitigation, or
constraint. Merge evidence only when it proves the same dependency and failure mode.
Start every `Issue Description:` value with
`NETWORKING-<dependency-slug>-<failure-mode-slug>: <description>`. Derive the dependency
slug from the canonical Prompt 1 Section 1 dependency name and the failure-mode slug
from the independently actionable failure behavior. Normalize each stable slug to
lowercase ASCII letters, digits, and single hyphens. Reuse the same slugs across runs.

The following local schema controls over inherited generic or conditional templates.
Repeat these labels exactly and in this order for every evidence-backed issue row:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app egion failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):

Use exactly these seven fields. `Impact(s) if this is not changed:` is the sole impact
requirement. Add no ID, status, remediation, recommendation, implementation, or other
field. Every issue requires file-and-line evidence. Produce no remediation content,
examples, alternatives, implementation content, or artifact next steps.
