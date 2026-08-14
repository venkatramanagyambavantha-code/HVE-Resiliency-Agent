---
description: Run Prompt 9 Azure Functions resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 9 Azure Functions

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Define the required regional-failover expectations for
{customerName} Azure Functions in {primaryRegion} and {secondaryRegion}. Assess only Azure
Functions behavior and requirements that directly affect regional failover.

## Functions Requirements

* Deployment follows an active-active model across {primaryRegion} and {secondaryRegion}
* Both regions continuously serve production traffic
* Each region can handle 100% of peak load during a regional outage
* Azure Front Door provides global traffic management
* Automatic failover uses health probes
* Health probes validate functional readiness of critical downstream
  dependencies, including storage, Key Vault, and messaging, rather than only
  HTTP reachability

## Topology Deltas

Resolve the deployment topology per the [Deployment Topology
Contract](../../../instructions/hve-resiliency-topology.instructions.md) before any repository
search, file read, or traversal hop. The resolved topology scopes the existing Functions
Requirements and failure-mode assessment above. It adds no assessment area, finding field, or
section, and it never changes the Output Format below. The resolved topology governs even where
the requirements above state a topology; wording inside this prompt is never a topology
resolution source.

When the resolved topology is `active-active`, treat these as in scope within the existing
assessment:

* Timer, schedule, and cron-triggered functions that fire in both regions at once, and the
  double execution that results
* Singleton, host-scoped, and function-scoped lock or lease behavior that assumes one active
  host across both regions
* Blob, queue, and stream lease or checkpoint ownership shared between regions, and the
  competing-consumer semantics that follow
* Durable Function orchestration, entity, and task-hub state where both regions run against the
  same hub or against divergent hubs
* Idempotency of steady-state trigger processing, given that both regions process concurrently
* Identifier, sequence, or key generation inside a function that must stay unique across both
  regions
* Per-region plan sizing, instance limits, and concurrency ceilings, given that each region
  absorbs full load on partner loss

When the resolved topology is `active-standby`, treat these as in scope within the existing
assessment instead:

* Timer, schedule, and cron-triggered functions that must not fire on the standby, and must
  activate on promotion
* The mechanism that disables or suppresses standby triggers, and whether promotion re-enables
  it within RTO
* Durable Function task-hub, orchestration, and entity state on the standby, and what is
  rebuilt rather than carried at promotion
* Lease, checkpoint, and consumer-group state the standby has never held, and the recovery
  point exposed at cutover
* Deployment, application-setting, and binding-configuration parity of the standby, including
  drift that stays unobservable while the standby is idle
* Cold start, plan warm-up, pre-warmed instance counts, and scale-from-zero on the standby,
  which are the promotion path
* Provisioned standby capacity, distinct from capacity that is only defined
* Health and readiness surfaces that must prove standby readiness without live traffic
* Failback and trigger re-suppression after the primary region returns

Do not emit a finding and do not record an evidence gap for a dimension the resolved topology
places out of scope. Under `active-active`, standby trigger suppression, standby deployment and
configuration parity, cold start and scale-from-zero, and promotion-path dimensions are out of
scope. Under `active-standby`, concurrent double execution of triggers, cross-region lease or
checkpoint contention between live regions, cross-region identifier collision, and
read-your-own-writes dimensions are out of scope. A suppressed dimension is never recorded as
an evidence gap, an `Unknown` outcome, or a finding row.

Where observed evidence does not fit the declared topology, continue under the declared
topology and record the conflict per the contract's Mismatch Handling rules. Never switch
topology, never redirect to another prompt, and never decline to run.

Use the resolved `{primaryRegion}` and `{secondaryRegion}` values, or the terms "primary
region" and "secondary region", in every finding. Do not hard-code region names in rendered
output.

## Bounded Evidence Protocol

Apply this protocol only to dependencies confirmed by the inherited service
exclusion rule.

1. For each confirmed dependency, use at most two repository searches, three
  file reads, two repository traversal hops, and one follow-up discovery
  action. Counters begin at zero, increase after each action, and never reset,
  including across repeated research or subagent calls. Limit each read to the
  smallest relevant line range; read a whole file only when that range cannot
  answer the research question.
2. Use at most two research rounds for this prompt. Round 1 begins with the
  first dependency discovery action. The first follow-up action closes round 1
  and starts round 2; increment the prompt round counter exactly once at that
  transition. Never reset it across dependencies, repeated research, or
  subagent calls.
3. Stop work on a research question at the first terminal outcome: cited
  evidence found; `Unknown` after its bounded repository sources are
  exhausted; not applicable under the service exclusion rule; or blocked by
  a named external evidence gap.
4. Source exhaustion occurs when the applicable numeric budget is consumed or
  all search results within that budget have been read. Do not broaden the
  query, revisit a source, start another traversal, or reset a counter after
  source exhaustion.
5. Stop discovery and produce the output when every research question has a
  terminal outcome or the two-round limit is reached. Do not repeat research
  to improve confidence after a terminal outcome. Do not include discovery
  narration or duplicate the same evidence within a row.
6. Before accepting or consolidating a delegated terminal outcome or finding,
  verify from already-read evidence that each cited file exists, each cited
  range lies within lines actually read, and the dependency remains eligible
  under inherited Prompt 1 exclusions. Reject or correct invalid delegated
  content without consuming another search, read, traversal hop, follow-up, or
  round. Preserve the immutable raw violation and correction in the action
  ledger.

Use `Unknown` only when bounded evidence is unavailable. For an existing field
that requires evidence, write `Unknown` followed by the exhausted source class
or named external evidence gap. Never invent a file, line number, mitigation,
constraint, impact, or risk rationale. Findings still require file-and-line
evidence; an `Unknown` outcome alone does not establish a finding.

Create a separate row for each independently actionable failure mode. Assign a
stable `Failure Mode ID` derived from the dependency and failure mode, and reuse
that ID for the same failure mode across repeated runs. Do not merge failure
modes because they share a dependency, file, or risk level.

The evidence-only rules override inherited requests for remediation,
code or configuration examples, alternatives, a selected approach, and
implementation next steps. Do not provide any of them.

## Output Format

Stamp the resolved deployment topology in the artifact's front matter as
`topology: <active-active|active-standby>`, and state it with the resolved
regions as an evaluation condition in the concise scope summary. Stamping is
required and is not one of the finding fields below.

Limit the authoritative final research artifact to a concise scope summary,
terminal-outcome summary, and the canonical finding rows below. Keep search,
read, tool-call, counter, file-analysis, and discovery narration only in
execution logs or delegated artifacts.

Repeat for each finding:

* Failure Mode ID:
* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app regional failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None (HVE Task Researcher role is evidence-only)
