---
description: Run Prompt 11 AKS and Istio resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 11 AKS and Istio

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Act as a cloud resiliency architect focusing on AKS and Istio. This application
runs on AKS with Istio in a multi-region setup, with traffic routed through a
Global Load Balancer.

## Assessment Scope

Assess only application code and configuration, not infrastructure, for regional failover between {primaryRegion} and {secondaryRegion}.
Evaluate these ten questions without adding assessment areas:

* Are timeouts defined for all outbound calls?
* Are retries bounded and using backoff + jitter?
* Are retries idempotent and safe?
* Any assumptions that dependencies are always available?
* Unbounded retries or retry storms?
* Blocking or synchronous fan-out calls?
* Are health probes aligned between GLB and backend services?
* Risk of thread, connection, or resource exhaustion during partial failures?
* Do readiness probes reflect real dependency health?
* Could unhealthy pods still receive traffic?

## Topology Deltas

Resolve the deployment topology per the [Deployment Topology
Contract](../../../instructions/hve-resiliency-topology.instructions.md) before any repository
search, file read, or traversal hop. The resolved topology scopes the ten existing questions in
the Assessment Scope above. It adds no assessment area, question, finding field, or section,
and it never changes the canonical finding schema.

When the resolved topology is `active-active`, treat these as in scope within the existing
questions:

* Replica counts and provisioned capacity per cluster, given that each cluster absorbs full
  load on partner loss
* HorizontalPodAutoscaler minimum replicas and maximum headroom measured against full
  single-region load, not against steady-state split load
* PodDisruptionBudget `minAvailable` or `maxUnavailable` values that block drain, rollout, or
  node loss while a cluster is carrying surge traffic
* `topologySpreadConstraints`, pod anti-affinity, and zone spread within each live cluster
* Readiness and liveness probe semantics that decide whether a pod in a live cluster keeps
  receiving traffic, and probe alignment with the Global Load Balancer while both clusters are
  in rotation
* Istio connection-pool ceilings, outlier detection, retry budgets, and timeouts sized for one
  cluster's share rather than the whole load
* Locality load balancing and failover priority that shifts traffic cross-cluster while both
  clusters serve
* Session affinity, sticky routing, and in-cluster cache assumptions that hold only while a
  caller stays in one cluster

When the resolved topology is `active-standby`, treat these as in scope within the existing
questions instead:

* Standby replica counts, including zero-replica or scaled-down workloads, and the scale-up
  that is the promotion path
* HorizontalPodAutoscaler minimums on the standby, and whether scaling from that minimum to
  full load completes within RTO
* Cold start on the standby: image pull, node pool warm-up, cluster autoscaler node
  provisioning, and application startup, which are the promotion path
* Provisioned standby node and pod capacity, distinct from capacity that is only defined in a
  manifest or chart
* PodDisruptionBudget, rollout, and disruption settings on the standby that no live traffic has
  exercised
* Manifest, chart value, and Istio configuration parity between the clusters, including drift
  that stays unobservable while the standby is idle
* Readiness and liveness probes on the standby that must prove readiness without live traffic,
  including probes that only pass once traffic arrives
* CronJobs, leader-elected controllers, and singleton workloads that must not run on the
  standby, and must activate on promotion
* Failback and re-quiescing of the former standby after the primary region returns

Do not emit a finding and do not record an evidence gap for a dimension the resolved topology
places out of scope. Under `active-active`, standby scale-from-zero, cold start and warm-up,
standby configuration parity, and promotion-path dimensions are out of scope. Under
`active-standby`, simultaneous dual-cluster traffic handling, cross-cluster session affinity
and cache coherence, and concurrent execution of the same workload in both clusters are out of
scope. A suppressed dimension is never recorded as an evidence gap, an `Unknown` value, or a
finding row.

Where observed evidence does not fit the declared topology, continue under the declared
topology and record the conflict per the contract's Mismatch Handling rules. Never switch
topology, never redirect to another prompt, and never decline to run.

Use the resolved `{primaryRegion}` and `{secondaryRegion}` values, or the terms "primary
region" and "secondary region", in every finding. Do not hard-code region names in rendered
output.

## Bounded Evidence Protocol

Apply this protocol only to dependencies confirmed by the inherited service
exclusion rule.

1. For each confirmed dependency, allow at most 2 repository searches, 3 file
   reads, 2 repository traversal hops, and 1 follow-up discovery action. Start
   each dependency's counters at zero, increment a counter after its action,
   and never reset or transfer counters across questions, repeated research,
   or subagent calls. A single action may answer multiple questions without
   consuming another action.
2. Allow at most 2 total research rounds for the prompt. The prompt-wide round
   counter starts at zero, becomes 1 before the first discovery action, and
   becomes 2 before the first follow-up or second-pass action. It never resets
   across dependencies, questions, repeated research, or subagent calls. Do
   not start a third round.
3. Prohibit production discovery by default. Access production only when the
   user supplies both an approved source and a bounded access method. Stay
   within the user-supplied bounds and the remaining counters above. Otherwise,
   record the required production value as `Unknown` with a named external
   evidence gap; do not inspect live systems, telemetry, credentials, or
   endpoints.
4. One source is one unique repository search result or one user-approved
   external artifact. A source is exhausted only when every result returned by
   the bounded searches has either been read within the read budget or
   explicitly left unread because the read budget is exhausted, and no legal
   bounded search, read, traversal hop, or follow-up remains. Processing results
   from the final permitted search within the remaining read and traversal-hop
   budgets is legal and is not a prohibited revisit. After exhaustion, do not
   broaden or repeat a query, revisit a source, add a traversal, or reset a
   counter.
5. Give every question for every eligible dependency exactly one terminal
   outcome: cited file-and-line evidence; `Unknown` after bounded repository
   evidence is exhausted; not applicable under the inherited exclusion rule;
   or `Unknown` because a named external evidence gap blocks the value.
6. Stop discovery when all question-and-dependency pairs have terminal
   outcomes or round 2 is exhausted, whichever occurs first. At the round
   limit, serialize every unresolved value as `Unknown: two-round prompt budget
   exhausted`. During final consolidation after round 2, assert that every
   still-unresolved existing schema value equals that exact text. Fail
   consolidation if any unresolved value uses another form, or if unresolved
   values exist and the exact-text count is zero. Do not research further to
   improve confidence.

Track counters cumulatively in execution state, but omit tool calls, counters,
search narration, file-analysis narration, and repeated evidence from the
authoritative research artifact. Read only the smallest relevant line ranges.

## Evidence and Output Contract

Stamp the resolved deployment topology in the artifact's front matter as
`topology: <active-active|active-standby>`, and state it with the resolved
regions as an evaluation condition in the concise scope summary. Stamping is
required, is not a fourth section class, and is not a schema field.

Use `Unknown` only in an existing schema field and append either the exhausted
repository source class or the named external evidence gap. Never invent a
file, line, mitigation, constraint, impact, rationale, or priority. A finding
still requires file-and-line evidence; `Unknown` alone does not establish one.

Emit a separate canonical finding row for each independently actionable
failure mode. Add `Failure Mode ID` as the first field, derive it consistently
from the dependency and failure mode, and reuse it across repeated runs. Do
not merge modes that share a dependency, location, or priority.

Use every field from the inherited canonical service-specific finding schema,
including mitigations, constraints, and `Remediation guidance: None (HVE Task
Researcher role is evidence-only)`. Do not restate, rename, remove, or add any
other schema field. Apply the inherited P0-P3 definitions and file-and-line
evidence requirements.

These evidence-only instructions override inherited requests for remediation,
examples, alternatives, a selected approach, implementation details,
implementation next steps, and general next-step suggestions. Provide none of
them. The authoritative artifact must contain exactly three section classes: a
concise scope summary, a terminal-outcome summary, and canonical finding rows.
Do not emit a separate `Preserved Questions` section or any other fourth
section.
