---
description: Fill the blocking-transactions fragment of the split Prompt 5 pipeline - emit rows only for the blocking-transactions observed outcome
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - 4 - Blocking Transactions

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt fills the blocking-transactions fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other outcome fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the blocking-transactions fill stage. Do not run any other outcome fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-5-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other outcome fragments. Do not re-derive the eligible dependency list.

## Outcome Focus

Emit rows only for the observed outcome `blocking-transactions`: a request path, consumer, producer, or scheduled job blocks, deadlocks, exhausts a resource, or holds a transaction open beyond its bounded time when a dependency exhibits a timeout, DNS failure, authentication failure, or partial outage. Skip any evidence that maps to startup failure, silent degradation, or data loss or partial processing; those outcomes belong to their own fragments.

Blocking-transactions discovery hints (evidence-only):

* Synchronous client calls with no timeout, or with a timeout longer than the request path's own SLO.
* Blocking calls (`.block()`, `.blockOptional()`, `.get()` on a Future, synchronous `Thread.sleep`) invoked on reactive event-loop or scheduler threads.
* Thread-pool, connection-pool, or WebClient connection-pool exhaustion under upstream partial outage.
* Consumer poll loops that block indefinitely on a downstream call inside the message-processing pipeline, preventing rebalance or heartbeat.
* Retry-with-backoff loops with no bounded maximum, no jitter cap, and no circuit breaker on a production call.
* Distributed or database transactions whose scope covers a call to a dependency that can hang, holding locks or sessions.
* Scheduled jobs, background workers, or reconciliation loops that queue and stall on a dependency call.

Never emit a row solely because a timeout value is unknown; require positive repository evidence that a production code path can block, deadlock, or exhaust a resource under the stated dependency failure type.

## Topology Deltas

Read the resolved deployment topology from the frozen manifest, exactly as this stage reads `eligibleDependencies`. Do not re-resolve it, do not infer it from repository contents, and do not override it. If the manifest records no topology, stop `Blocked` with `topology not established - run /hve-resiliency-topology-0-lock`. The [Deployment Topology Contract](../../instructions/hve-resiliency-topology.instructions.md) governs. The resolved topology scopes the blocking-transactions discovery hints above. It adds no assessment topic, output field, or section, and it never changes the Required Row Schema.

When the resolved topology is `active-active`, treat these as in scope within the existing hints:

* Production calls that cross regions, where a dependency in the partner region stalls a request served in this region.
* Distributed locks, leases, and leader-election waits contended by both regions under steady state.
* Thread-pool, connection-pool, and scheduler exhaustion in one region while it absorbs full load on partner loss.
* Transactions held open across a cross-region coordination or conflict-resolution step.
* Schedulers, singletons, and consumers running in both regions that contend for the same lock, row, or partition and deadlock.
* Health endpoints that must report own-region health continuously but block on a partner-region dependency.

When the resolved topology is `active-standby`, treat these as in scope within the existing hints instead:

* Boot-time and promotion-time calls that block before the secondary can accept traffic, extending cutover beyond its bounded time.
* Retry and backoff loops on the standby that stall against a dependency reachable only from `{primaryRegion}`.
* Pool, thread, and connection capacity actually provisioned on the secondary, distinct from capacity that is only defined, and exhaustion when it absorbs full load at promotion.
* Consumers, producers, and scheduled jobs that must not run on the standby but still block, poll, or hold locks against shared state while idle.
* Readiness and health probes on the idle standby that block on a dependency and cannot prove readiness without live traffic.
* Failback and reverse-replication steps that hold a transaction, lock, or session open while the primary returns.

Do not emit a row and do not record an evidence gap for a dimension the resolved topology places out of scope. Under `active-active`, promotion-window blocking, standby-idle blocking, cold-start and warm-up stalls, and failback-path blocking are out of scope and must not be recorded as evidence gaps. Under `active-standby`, cross-region concurrent lock contention, dual-region singleton deadlock, and steady-state partner-region call blocking are out of scope and must not be recorded as evidence gaps.

Where observed evidence does not fit the declared topology, continue under the declared topology and record the conflict per the contract's Mismatch Handling rules. Never switch topology and never decline to run.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this outcome only. Counters do not carry over from another outcome fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Row Emission

For every blocking-transactions row, emit the Required Row Schema from the shared contract. Use section-scoped IDs of the form `F-5-blocking-00X`, assigned in emission order starting at `F-5-blocking-001`.

Never combine regional-failover and partial-outage evidence in one row. If the same dependency plus failure type plus entrypoint applies to both scenarios with materially different behavior, emit two rows.

## Output

Write the fragment to `<fragmentDir>/blocking-transactions.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with the `## 5.4 Blocking Transactions` heading followed by frontmatter recording `source-prompt: hve-resiliency-researcher-5-4-blocking-transactions`, `outcome-key: blocking-transactions`, and the fragment's terminal status. Stamp the resolved deployment topology in the same frontmatter as `topology: <active-active|active-standby>`, carried verbatim from the manifest, and state it with the resolved regions as an evaluation condition. Stamping is required and adds no field to the Required Row Schema. Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-5-verify`
