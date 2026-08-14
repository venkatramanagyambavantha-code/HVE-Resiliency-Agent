---
description: Fill the startup-failure fragment of the split Prompt 5 pipeline - emit rows only for the startup-failure observed outcome
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 5 - 1 - Startup Failure

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). This prompt fills the startup-failure fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other outcome fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-5-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 5 Split Contract.

## Direct Invocation and Prerequisite

* Run only the startup-failure fill stage. Do not run any other outcome fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-5-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other outcome fragments. Do not re-derive the eligible dependency list.

## Outcome Focus

Emit rows only for the observed outcome `startup-failure`: application fails to start or fails to reach a healthy state on boot when a dependency exhibits a timeout, DNS failure, authentication failure, or partial outage. Skip any evidence that maps to silent degradation, data loss or partial processing, or blocking transactions during steady-state request handling; those outcomes belong to their own fragments.

Startup-failure discovery hints (evidence-only):

* Bootstrap configuration sources that must resolve before the application context can start (for example config server clients, secret providers, truststore assembly, credential fetches).
* Constructor or `@PostConstruct` code paths that call a dependency synchronously during startup and rethrow on failure.
* Fail-fast client factories, connection pool warmups, DNS lookups, and TLS handshakes performed on the startup thread.
* Kubernetes readiness or startup probe endpoints whose success depends on a dependency being reachable at boot.
* Missing or misconfigured retry, fallback, or timeout on any of the above.

Never emit a row solely because startup-related retry or fallback is absent; require positive repository evidence that a boot-time failure of the dependency produces the observed startup failure.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this outcome only. Counters do not carry over from another outcome fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Row Emission

For every startup-failure row, emit the Required Row Schema from the shared contract. Use section-scoped IDs of the form `F-5-startup-00X`, assigned in emission order starting at `F-5-startup-001`.

Never combine regional-failover and partial-outage evidence in one row. If the same dependency plus failure type plus entrypoint applies to both scenarios with materially different behavior, emit two rows.

## Output

Write the fragment to `<fragmentDir>/startup-failure.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with the `## 5.1 Startup Failure` heading followed by frontmatter recording `source-prompt: hve-resiliency-researcher-5-1-startup-failure`, `outcome-key: startup-failure`, and the fragment's terminal status (`Blocked`, `Incomplete`, or `Complete`). Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the row count, the count of rows carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-5-2-silent-degradation`
