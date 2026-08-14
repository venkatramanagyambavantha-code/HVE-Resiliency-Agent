---
description: Deployment topology contract - resolution, definitions, assessment deltas, and stamping rules for all resiliency prompts
applyTo: '.github/prompts/hve-resiliency-*.prompt.md, .github/prompts/researcher/hve-resiliency-*.prompt.md, .github/prompts/researcher/service/hve-resiliency-*.prompt.md, .github/prompts/planner/hve-resiliency-*.prompt.md'
---

# Deployment Topology Contract

Apply this contract to every resiliency research and planning prompt. It defines how a prompt learns the run's deployment topology, what that topology changes about the assessment, and how topology is recorded and enforced across artifacts.

This contract is never overridden by a prompt's stage-specific rules.

## Topology Resolution

Every prompt resolves the deployment topology before any repository traversal, discovery action, or output rendering, in exactly this order:

1. An explicitly supplied `${input:topology}` argument. Use it.
2. Otherwise, auto-locate the run context lock (see Lock Auto-Location). Use its `topology` value.
3. Otherwise, stop `Blocked` with `topology not established - run /hve-resiliency-topology-0-lock`.

Never default. Never infer. There is no fallback topology.

**Topology is declared, never discovered.** Do not derive, adjust, or override the resolved topology from repository contents, dependency inventories, database capabilities, infrastructure definitions, or any other evidence. Evidence that appears to contradict the declared topology is a finding, not a correction (see Mismatch Handling).

The `hve-resiliency-topology-0-lock` prompt is exempt from this section: it establishes the lock rather than resolving it.

## Lock Auto-Location

When `${input:topology}` is omitted, locate the run context lock instead of asking the user. Enumerate files named `*-resiliency-run-context.md` directly under `.copilot-tracking/` and under `.copilot-tracking/research*/`, excluding anything under `sections/`, `subagents/`, `validator/`, or `sandbox/`. Require a body declaring `schema-version: hve-resiliency-run-context/v1`.

If exactly one lock resolves, use it. If more than one resolves, stop `Blocked` with `multiple run context locks found - supply topology explicitly`. If none resolves, stop `Blocked` per Topology Resolution step 3. Never use file modification time. An explicitly supplied topology always overrides auto-location.

Read the lock exactly once, with a single full-range read. Carry its `topology`, `primaryRegion`, `secondaryRegion`, and `researchRoot` values verbatim; never re-derive or reformat them.

## Vocabulary

Two distinct concepts. Never conflate them, and never use the bare word "topology" for the second.

* **Deployment topology**: how the application is deployed across regions. A declared business decision. Values: `active-active`, `active-standby`. Source: the run context lock only.
* **Data write model**: whether a datastore accepts writes in one region or several. A discovered repository fact. Values: `single-master`, `multi-master`, `mixed`, `unknown`. Source: evidence, recorded by the prompt that observes it.

A deployment topology does not imply a write model, and a write model does not establish a deployment topology. An application may run `active-active` over a `single-master` store, or `active-standby` over a `multi-master` store. Where the two do not fit, record a finding.

## Topology Definitions

### active-active

Both regions serve production traffic simultaneously. A request may be handled in either region at any time, and both regions may write concurrently.

### active-standby

The primary region serves all production traffic. The secondary region is provisioned, deployed, and continuously ready, but idle until promoted.

> **Active-standby is not passive disaster recovery.** The standby region is expected to hold deployment and configuration parity with the primary, to be provisioned with real capacity, to be continuously health-probed, and to accept traffic within RTO as a routine operation. Absence of any of these is a finding. Never treat a standby region as out of scope, already-solved, or lower-stakes because it does not currently serve traffic; the failure modes that matter are precisely the ones that stay invisible while it is idle.

## Assessment Deltas

Apply the column matching the resolved topology. These deltas scope what a prompt looks for within its own existing assessment topics. They never add an output field, section, or assessment topic to a prompt's declared schema.

| Dimension | `active-active` | `active-standby` |
| --- | --- | --- |
| Concurrent multi-region writes | In scope. Conflict resolution, last-write-wins semantics, write skew. | Out of scope. Single writer. |
| Replication | Bidirectional. Lag in both directions. | One-way primary to secondary. Recovery point exposure at cutover. |
| Unique ID and sequence generation | In scope. Cross-region collision. | Not applicable. |
| Read-your-own-writes consistency | In scope. Reads may resolve in either region. | Not applicable until promotion. |
| Idempotency and duplicate processing | In scope under steady state. | In scope at cutover only, bounded window. |
| Schedulers, cron, singletons, leader election | Double execution under steady state. | Must not execute on standby, and must activate on promotion. |
| Session state, affinity, cache coherence | In scope. A request may land in either region. | State rebuilt at promotion. |
| Secondary deployment and configuration parity | Continuously exercised by live traffic. | In scope, high severity. Drift is unobservable while the standby is idle. |
| Cold start, warm-up, scale-from-zero | Not applicable. Already warm. | In scope. The startup path is the promotion path. |
| Capacity | Each region absorbs full load on partner loss. | Standby provisioned with real capacity, not defined-only. |
| Health reporting | Report own-region health continuously. | Additionally prove standby readiness without live traffic. |
| Failback | Traffic rebalance. | Explicit failback and reverse-replication path. |

Where a dimension is marked out of scope or not applicable for the resolved topology, do not emit a finding for it and do not record it as an evidence gap.

## Region Resolution

Resolve `{primaryRegion}` and `{secondaryRegion}` from the lock. Use those resolved values, or the topology-neutral terms "primary region" and "secondary region", in all analysis and output. Do not hard-code region names in findings, descriptions, or generated output.

## Artifact Stamping

Every artifact a prompt writes records the resolved topology in both places:

* Front matter: `topology: active-active` or `topology: active-standby`.
* Its scope or assumptions section, as a stated evaluation condition alongside the regions.

Stamp the resolved deployment topology only. Never stamp a write model in this field.

## Mismatch Handling

When repository evidence does not fit the declared topology, the prompt continues under the declared topology and records the conflict as a finding. It never switches topology, never redirects to another prompt, and never declines to run.

* Evidence indicates a capability the declared topology requires is absent (for example a `single-master` write model under `active-active`): record a P0 finding naming the declared topology, the observed evidence, and the failure it implies.
* Evidence indicates a capability beyond what the declared topology uses (for example a `multi-master` write model under `active-standby`): record a P2 finding noting the unused capability.

When a prompt reads an input artifact whose `topology` stamp differs from the resolved topology:

* Research prompts: continue, and record the artifact as `topology: mismatched` in the ledger alongside its own stamp.
* Consolidation prompts: stop `Blocked` with `artifact topology mismatch - <path>`.

An input artifact carrying no `topology` stamp is treated as `topology: unstamped` under the same split: research continues and records it, consolidation refuses it.
