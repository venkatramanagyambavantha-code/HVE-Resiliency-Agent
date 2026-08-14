---
description: Run Prompt 19 APIM resiliency analysis for Application
agent: "Task Researcher"
---

# Application HVE Researcher 19 APIM Optimized

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md).

## Eligibility Gate

Run Prompt 19 directly. Before any repository discovery, use only Prompt 1a or
Prompt 1b inventory confirmation to identify eligible APIM dependencies. Treat
Prompt 1a `Section 1 - Used Azure Services (Evidence Confirmed)` and Prompt 1b
`Section 1 — Used External Dependencies (Evidence Confirmed)` as equivalent positive
APIM inventory gates. These are the sole eligibility gates. Do not infer APIM use
from repository matches, another prompt, or architecture assumptions.

If the supplied Prompt 1 inventory is missing or structurally unusable, stop at
round 0 with status `Invalid-input`. If APIM is absent from the applicable positive
inventory section or appears in any exclusion section, including Checked But Not
Present or Not Applicable, stop at round 0 with status `Not Applicable`. Perform zero
repository or production discovery for either state.

## Task Researcher Boundary

Direct Prompt 19 invocation overrides conflicting inherited Task Researcher workflow,
delegation, output, and next-step requirements. Execute only evidence collection for
Prompt 19. Bounded delegation is allowed only under this target contract, including
its shared counters, rounds, scope, evidence, output, and stopping rules. Suppress all
implementation and remediation phases, recommendations, alternatives, examples,
selected approaches, actionable next steps, code or configuration changes, and
implementation guidance. Do not invoke earlier prompts, restart the full workflow,
or broaden this assessment.

## Architecture Assumptions

Evaluate repository evidence against these existing assumptions without treating an
assumption as evidence:

* APIM is deployed as two independent instances, one in West US and one in West US 2.
* A Global Load Balancer routes traffic regionally, and failover occurs at the
  application level rather than per service.
* An application operating in one region does not depend on Azure services in the
  other region because of latency.
* Other Azure services use multi-region or replicated patterns.
* A zone failure within a region is survivable without customer impact.

## Assessment Scope

For each eligible APIM dependency, assess both zone failure within West US 2 and
regional failover from West US 2 to West US. Evaluate exactly these existing
criteria:

1. Alignment of Global Load Balancer and backend health probes.
2. Application and data behavior during a zone or regional outage.
3. Retries, timeouts, and exponential backoff.
4. Stateless operation or correct active-active or active-passive behavior.
5. Pre-scaling or autoscaling of AKS, App Service, or VM backends for failover traffic.
6. Region-local certificate and secret sourcing from application Key Vaults through
   managed identity.
7. Protection against data loss, duplicate charges, and prolonged downtime during
   regional failover.

The two preserved failure scenarios are zone failure within West US 2 and regional
failover from West US 2 to West US. For one eligible APIM dependency, the seven
criteria across these two scenarios create fourteen scenario-specific
dependency-criterion pairs. Evaluate every pair independently within the dependency's
shared counters. Keep distinct evidenced failure modes in separate issue rows; never
combine scenarios.

## Cumulative Discovery Limits

For each eligible APIM dependency, initialize one non-resetting set of counters:

* At most 2 searches across repository and approved production sources.
* At most 3 reads, each limited to one file's smallest relevant line range or one
  returned production result or smallest relevant result range.
* At most 2 traversal hops along returned links, related sources, repository-evidenced
  references, configuration includes, callers, or callees.
* At most 1 focused repository or production follow-up for one unresolved criterion.

Apply these counters cumulatively across all criteria, aliases, environments, rounds,
repository and approved production sources, parent activity, delegated activity, and
subagent calls. A production query consumes one search. Inspecting one returned result
or its smallest relevant result range consumes one read. Following a returned link or
related source consumes one traversal hop. A focused production follow-up consumes the
one focused-follow-up allowance. Increment a counter when its action occurs. Never
reset, duplicate, transfer, or reassign counters by source or delegation. Reuse
evidence already read and stop work on a pair as soon as it has a terminal outcome.

Use one prompt-wide round counter with a maximum of two rounds. Start round 1 before
the first discovery action. Start round 2 before the focused follow-up or any other
second-pass action. The counter is cumulative across parent and delegated activity,
never resets, and never enters round 3.

## Repository And Production Sources

Use the current repository as the default and primary discovery source. Exclude tests,
fixtures, samples, generated output, documentation, local-only configuration, prompts,
tracking artifacts, and prior research unless cited production repository evidence
directly requires one of those sources.

Production discovery is prohibited unless all of the following are supplied before
access:

1. A named production source.
2. Explicit user approval for production access.
3. A read-only access method.
4. A query limit.
5. A result limit.
6. A time window.
7. A follow-up limit.

Do not invent contract values or access live systems, telemetry, credentials, or
endpoints without the complete contract. Approved production actions must stay within
the contract and consume the dependency's remaining cumulative counters. If production
evidence is required to continue and the contract is incomplete, denied, or the named
source is unavailable, stop immediately with status `Blocked-production`. Record the
production evidence gap in the report-level status block and do not create an issue row
for the blocked state.

## Evidence And Exhaustion

Every finding requires causal repository or approved production evidence with a file
and line range or an equivalently precise approved-source location. Repository absence
does not prove runtime behavior. Never invent evidence, locations, behavior, impacts,
mitigations, or priorities.

Assign exactly one terminal outcome to each eligible APIM dependency and assessment
criterion:

* Cited evidence that establishes an issue or confirms the assessed behavior.
* `Unknown: not found after bounded repository discovery <named source class>` after
  the permitted repository source class and applicable counters are exhausted.
* `Unknown: external evidence required <named evidence gap>` when the value depends on
  production evidence that was not required to begin or continue repository research.
* `Unknown: two-round prompt budget exhausted` when the prompt-wide round limit is
  reached before another terminal outcome.

The exact value at the round limit is `Unknown: two-round prompt budget exhausted`.
Use no alternate wording. Stop all discovery when every eligible pair has a terminal
outcome or the two-round limit is reached, whichever occurs first. Do not repeat or
broaden discovery to improve confidence.

Unknown and blocked outcomes are not findings. Keep them in the report-level status
block. When an evidence-backed issue has an unresolved existing field, use the
applicable schema-safe Unknown wording in that field. Emit distinct issue rows for
distinct evidenced failure modes. Do not combine unrelated failure modes in one row.

## Priority Classification

Classify each evidence-backed issue using the Application Platform Context:

* P0: Critical or blocking. Causes outage, data loss, duplicate charges, or inability
  to fail over safely during zone or regional failure.
* P1: Required, non-blocking. Materially increases application risk, data risk, or
  customer impact during failure without fully blocking failover.
* P2: Improvement or best practice. Weakens resilience posture or operational clarity
  without materially affecting failover correctness.
* P3: Non-blocking code consistency. Covers maintainability, readability, duplication,
  or inconsistent patterns that are non-blocking.

Explain why the selected priority applies using cited evidence. Do not include
remediation language.

## Report Outcomes And Immediate Stopping

Place exactly one of these mutually exclusive statuses in the report-level status
block. Apply them in this order and stop immediately when a round-0 or production
blocking status applies:

1. `Invalid-input`: the supplied Prompt 1a `Section 1 - Used Azure Services (Evidence Confirmed)`
  or Prompt 1b `Section 1 — Used External Dependencies (Evidence Confirmed)` inventory is missing
  or structurally unusable.
2. `Not Applicable`: a usable positive inventory section does not confirm APIM as used
  or an exclusion section classifies APIM as excluded.
3. `Blocked-production`: eligible research requires production access, but its complete
   bounded contract is absent, denied, or unavailable.
4. `Partial/exhausted`: at least one evidence-backed issue exists and at least one
  eligible pair remains Unknown because a source, action, or round limit was exhausted
  or a non-blocking external evidence gap remains.
5. `Bounded no-evidence`: eligible bounded discovery produces no evidence-backed issue
   rows and every eligible pair is accounted for by a non-finding or bounded Unknown
   outcome.
6. `Complete`: one or more evidence-backed issue rows exist, every eligible pair has a
   terminal outcome, and none remains Unknown because of exhaustion or blocked access.

## Output Format

Write the authoritative research artifact to `.copilot-tracking/research/` with the
repository name as the filename prefix. Keep non-finding and blocked states outside
issue rows in this compact report-level block:

* Status: <one report outcome>
* Eligibility: <Prompt 1a Used Azure Services or Prompt 1b Used External Dependencies Section 1 evidence or terminal gate reason>
* Discovery outcome: <terminal outcomes or Not started>
* Finding count: <count>
* Limitations: <named Unknown or production gaps, or None>

For every evidence-backed issue, repeat exactly these six fields in this order:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app, zone or region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):

Do not add, remove, rename, or duplicate issue fields. The impact field is the sole
impact requirement. Omit issue rows when the finding count is zero. For this direct
invocation, emit no inherited or actionable next step and no full-workflow restart.
