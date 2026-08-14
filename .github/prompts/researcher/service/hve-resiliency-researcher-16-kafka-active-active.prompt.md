---
description: "Run Prompt 16 Kafka Active-Active resiliency analysis"
agent: "Task Researcher"
---

# HVE Resiliency Researcher 16 Kafka Active-Active

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Kafka runs on Confluent Cloud; treat that as a confirmed platform fact and do not ask the operator which Kafka provider or environment is in use.

## Eligibility And Scope

Run Prompt 16 directly and only when both entry conditions hold before any repository
traversal or discovery action:

1. The resolved deployment topology is `active-active`.
2. Prompt 1 Section 1 confirms Kafka as used.

Resolve the deployment topology per the Topology Deltas section below. Topology is
declared by the run context lock, never derived from database evidence, Kafka evidence,
or any other repository content. This prompt is the `active-active` member of the
topology-selected Prompt 16 pair. When the lock resolves `active-standby`, this prompt
is not the selected member: stop at round 0 with no discovery actions and direct the
user to `hve-resiliency-researcher-16-kafka-active-standby-confluent`.

When Prompt 1 Section 1 does not confirm Kafka as used, stop at round 0 with no
discovery actions. Record the eligibility block in the concise scope summary and
terminal-outcome summary. Do not infer eligibility, search for substitute eligibility
evidence, or fall back to Prompt 0, another prompt, or conditional skill behavior.

Record the confirmed database write model as a cross-check under concern 18. It never
establishes eligibility, never selects a prompt, and never stops the run.

Apply the inherited service exclusion rule. Analyze only Kafka dependencies confirmed
as used in Prompt 1 Section 1. Treat dependencies classified as Checked But Not Present
or Not Applicable as excluded.

For every eligible Kafka dependency, assess readiness for regional failover between West US 2 and West US.

## Topology Deltas

Resolve the deployment topology per the [Deployment Topology
Contract](../../../instructions/hve-resiliency-topology.instructions.md) before any
repository traversal or discovery action. The resolved topology scopes the 18 concern
groups in Assessment Concerns. It adds no concern group, schema field, or section, and
it never changes the seven-field issue schema in Authoritative Artifact.

The Cluster Linking, mirror-topic, and feature-flag arrangement stated in Active-Active
Architecture Invariants is a service-configuration contract to verify against evidence.
It is not the deployment topology, and it never establishes, adjusts, or overrides the
resolved topology.

The database write model is discovered evidence about a datastore, distinct from the
declared deployment topology. Read it from the producer artifact's `Data write model:`
field, accepting `Topology verdict:` and `Topology classification:` as deprecated legacy
labels for the same field and preferring `Data write model:` when more than one label is
present. Normalize its value to `single-master`, `multi-master`, `mixed`, or `unknown`.

Under the resolved `active-active` topology, treat these as in scope within the existing
concern groups:

* Concurrent production and consumption in both regions under steady state, and the
  duplicate business processing that steady-state dual reads can create
* Bidirectional replication lag between the peer clusters, and stale or incomplete
  mirror state observed in either direction
* Consumer-group offset synchronization across source writable, mirror, and promoted
  topics in both directions
* Keys, identifiers, and sequences generated independently in both regions, and the
  cross-region collision that follows
* Read-your-own-writes behavior when a read resolves in the region that did not take the
  write
* Region-affinity and single-active-region assumptions that bypass the feature flag while
  both regions serve traffic
* Capacity to absorb the full load in either region on partner loss
* Own-region health reporting through global load balancer probes, continuously in both
  regions

Cold start and scale-from-zero of an idle region, standby deployment and configuration
parity drift that stays unobservable while idle, promotion-only cutover replay windows,
and single-writer promotion paths are out of scope under `active-active`. Do not emit an
issue row or record an evidence gap for a suppressed dimension; a suppressed dimension is
never recorded as an `Unknown` value or an `Unknown: two-round prompt budget exhausted`
value.

Where the observed write model or any other evidence does not fit the declared topology,
continue under the declared topology and record the conflict per the contract's Mismatch
Handling rules, under concern 18. Never switch topology, never redirect to the sibling
prompt, and never decline to run because of a mismatch.

Use the resolved `{primaryRegion}` and `{secondaryRegion}` values, or the terms "primary
region" and "secondary region", in analysis and issue prose. Do not introduce region
names beyond the authoritative scenario this prompt already names.

## Task Researcher Boundary

Execute Task Researcher Phase 1 only as evidence-only research. Do not enter or produce
Phase 2. This local boundary controls over inherited requests for alternatives,
recommendations, selected approaches, implementation details or steps, implementation
guidance, remediation, code examples, configuration examples, or next-step suggestions.
Do not produce any of those materials.

## Active-Active Architecture Invariants

Evaluate every concern and finding against this single authoritative architecture
contract:

* Each region has an independent Kafka cluster and owns a region-local writable topic.
  Cluster Linking mirrors that topic one-way into the peer region.
* The consumer-level feature flag controls regional read cutover at runtime. Consumers
  read the local writable topic and the peer mirror topic whenever the flag requires
  both so events remain complete across cutover.
* Producers write only to the current region-local writable topic in steady state and
  after regional redirection. Producers never write to a mirror or promoted topic.
* Offset handling and consumer-group offset synchronization cover source writable,
  mirror, and promoted topics across regions.
* Feature-flag transitions, dual-source reads, retries, replication, replay, and
  rebalances must not create duplicate business processing.
* DNS bootstrap, `advertised.listeners` broker metadata, GLB health routing, backend
  probes, and client reconnect behavior remain effective through broker restart, regional failover.

Region affinity in steady state is required and is not a defect. On regional failover,
consumers use the feature flag to select the failed region's mirror topic in the
surviving region. Redirected producers continue writing to the surviving region's
region-local writable topic, not to the mirror or promoted topic.

## Assessment Concerns

Evaluate all 18 concern groups for every eligible Kafka dependency:

1. Independent regional Kafka clusters, region-local writable topics, and one-way peer
   mirrors created through Cluster Linking follow the architecture invariants.
2. Consumer-level feature-flag cutover controls the read source at runtime and is not
   ignored or bypassed.
3. Producer routing targets only the surviving region's region-local writable topic in
   steady state and after traffic redirection, never a mirror or promoted topic.
4. Consumer subscriptions include the local writable topic and peer mirror topic when
   the feature flag requires both, preserving completeness across cutover.
5. Source, mirror, and promoted-topic offsets and consumer-group offset synchronization
   remain correct across regions.
6. Writable and mirror or promoted reads do not create duplicate business processing
   during feature-flag transitions.
7. Bootstrap DNS remains authoritative despite `advertised.listeners` metadata, and
   code does not persist or hard-code learned broker host and port values.
8. GLB routing, health probes, backend health, DNS bootstrap, and client reconnect
   behavior support zone and regional failover.
9. Mirror promotion selects the surviving consumer read source without allowing writes
   to the promoted topic.
10. Producer idempotence and retry behavior prevent duplicate writes.
11. Consumers tolerate replay and rebalance behavior.
12. Code and configuration avoid single-active-region, single-topic, and static-target
    assumptions that bypass the feature flag.
13. Cross-region replication dependencies tolerate lag, stale mirrors, delayed
    delivery, and temporary mirror unavailability.
14. Business workflows and state or transactional transitions tolerate delayed,
    replayed, and out-of-order events where strict ordering had been assumed.
15. Non-idempotent operations do not create duplicate business outcomes after replay,
    replication, retry, or repeated consumption.
16. Producer and consumer routing loaded or cached at startup can change at runtime
    without an application restart.
17. Failback and regional recovery cover producer and consumer routing, offset
    synchronization, mirror rebuild, replay, backlog processing, and restoration of
    normal Active-Active operation.
18. The discovered database write model cross-checked against the declared
    `active-active` deployment topology. A `multi-master` write model fits it, and
    `mixed` fits for its multi-master portion. A `single-master` write model is a
    mismatch: emit a P0 issue row naming the declared topology, the observed write model
    with its cited evidence, and the failure the mismatch implies. Record an `unknown`
    write model as a named evidence gap in an existing schema field. The write model
    never establishes, adjusts, or overrides the deployment topology, never selects a
    prompt, and never stops the run.

For each evidence-backed issue, classify the failure risk as P0, P1, P2, or P3 under
the Application Platform Context. Explain why the classification applies and cite the
smallest supporting file and line range. Unknown status alone does not establish a
finding.

## Cumulative Discovery Limits

For each eligible Kafka dependency, initialize these action counters to zero:

* At most 2 repository searches
* At most 3 file reads, each restricted to the smallest relevant line range
* At most 2 repository traversal hops
* At most 1 focused follow-up

Apply each dependency's counters cumulatively across aliases, all 18 concerns,
environments, both rounds, repeated research, delegated work, and subagent calls.
Increment a counter immediately after its action. Never reset, transfer, duplicate, or
reassign a counter. Reuse one action's evidence for every concern it answers.

Use one prompt-wide round counter for the entire invocation. Start at 0. Transition
from 0 to 1 before the first discovery action. Transition from 1 to 2 before the first
focused follow-up or other second-pass action. Increment only at those transitions.
Never reset the round counter and never start round 3.

## Sources And Exhaustion

Repository discovery is limited to the current repository by default. Production
discovery is prohibited unless the user supplies or approves every element of a bounded
production-source contract:

* A named production source
* A read-only access method
* A query limit
* A result limit
* A time window
* A follow-up limit

Do not invent any production-contract value. Do not inspect live systems, telemetry,
credentials, or endpoints without all approval elements. When approval is complete,
stay within its bounds and the remaining cumulative dependency counters. Otherwise,
record a named external evidence gap in an existing schema field.

One source is one unique repository search result or one user-approved external
artifact. A named repository source class is exhausted only when every result from the
permitted bounded searches has been read within the file-read limit or explicitly left
unread because that limit is exhausted, and no search, read, traversal hop, or focused
follow-up remains. Results from the final permitted search may still be processed
within the remaining limits. After exhaustion, do not broaden or repeat a query,
revisit a source, add a hop, or reset a counter.

## Terminal Outcomes And Stopping

Assign exactly one terminal outcome to every eligible Kafka dependency and concern
pair:

* Cited file-and-line evidence
* Unknown after exhausting a named repository source class
* Not applicable under the inherited service exclusion rule
* Unknown because a named external evidence gap blocks the value

Stop when every eligible pair has exactly one terminal outcome or round 2 is exhausted,
whichever occurs first. Do not perform confidence-improvement research or any other
research after a terminal outcome.

At the round limit, serialize every unresolved value in an existing schema field
exactly as `Unknown: two-round prompt budget exhausted`. No other round-limit value is
valid. Keep every other Unknown value inside an existing schema field and name the
exhausted repository source class or external evidence gap. Never invent evidence,
locations, mitigations, constraints, impacts, rationales, or priorities.

## Pre-Consolidation Validation

Before consolidation, use only already-read evidence to verify that every cited file
exists, every cited range was read, and every dependency remains eligible under Prompt
1 Section 1. This validation consumes no action, cannot start a round, and does not
change any counter. Reject or correct invalid delegated content without more discovery.
Consolidation fails until every eligible dependency and concern pair has exactly one
terminal outcome and every unresolved round-limit value uses the exact required text.

## Authoritative Artifact

Write the research artifact to `.copilot-tracking/research/` using the repository name
as the output filename prefix. The artifact contains exactly these three section
classes:

1. A concise scope summary
2. A terminal-outcome summary
3. Canonical seven-field issue rows

Stamp the resolved deployment topology in the artifact front matter as
`topology: <active-active|active-standby>`, and state it with the resolved regions as an
evaluation condition in the concise scope summary. Stamp the resolved deployment topology
only; never stamp a database write model in that field. Stamping is required and adds no
section class.

When eligibility fails at round 0, record the block in the first two section classes
and produce no issue row without evidence. Keep action counters, round state, tool
calls, searches, reads, traversal details, file-analysis narration, discovery
narration, and repeated evidence outside the artifact. Add no other authoritative
section class.

Emit a separate issue row for every independently actionable Kafka failure mode, even
when rows share a dependency, location, priority, or risk level. Start every `Issue
Description:` value with
`KAFKA-<dependency-slug>-<failure-mode-slug>: <description>`. Normalize and reuse the
same dependency and failure-mode slugs across runs.

The following local schema controls over inherited generic or conditional templates.
Repeat these labels exactly and in this order for every issue:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app, zone or region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):

Use exactly these seven fields. `Impact(s) if this is not changed:` is the sole impact
requirement. Do not add an ID field, remediation field, or any other field. Every issue
requires file-and-line evidence. Produce no alternatives, selected approaches,
implementation content, remediation, examples, or artifact next steps.

