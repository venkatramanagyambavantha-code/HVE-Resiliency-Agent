---
description: Fill the transactions fragment of the split Prompt 7 Logging pipeline - emit inventory rows and findings only for the transactions assessment category
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 7 Logging - 2 - Transactions

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt fills the transactions fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other category fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-7-logging-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 7 Logging Split Contract.

## Direct Invocation and Prerequisite

* Run only the transactions fill stage. Do not run any other category fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-7-logging-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other category fragments. Do not re-derive the eligible dependency list.

## Category Focus

Emit inventory rows and findings only for the assessment category `transactions`: applicable transaction or payment lifecycle, idempotency, dependency calls, outcomes, latency, and failure categories. Skip any evidence that maps to startup and health, correlation and context propagation, log hygiene, or silent-outage diagnostics; those categories belong to their own fragments.

Transactions discovery hints (evidence-only):

* Request-path controllers, consumers, producers, and scheduled jobs that log a transaction start, dependency call, outcome, latency, or failure category.
* Idempotency guards, dedupe keys, and unique-index violations logged on production paths.
* Distributed or database transaction begin, commit, rollback, and timeout log lines.
* Retry, backoff, and dead-letter routing that records the transaction and failure category.
* Payment lifecycle log surfaces (authorize, capture, refund, reversal) when the manifest's `paymentApplicability` is `applicable`.

Payment scope: read the manifest's frozen `paymentApplicability` value.

* When `paymentApplicability` is `applicable`, evaluate the payment sub-scope with the same bounded-discovery limits as any other dependency and emit inventory rows and findings for payment lifecycle logging.
* When `paymentApplicability` is `not-applicable`, run one negative payment search inside the bounded discovery limits, record its scope in the ledger, emit exactly one summary inventory row that marks payment as `Not Applicable` per the shared contract, and emit no payment finding. Do not create a substitute payment workflow.

Never emit a row or finding solely because a log line is missing; require positive repository evidence of a logged transaction signal or of a production path whose failure would remain undiagnosable given the observed logging.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this category only. Counters do not carry over from another category fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Emission

For every transactions inventory row, emit the Required Inventory Row Schema from the shared contract using section-scoped IDs of the form `I-7-transactions-00X`, assigned in emission order starting at `I-7-transactions-001`.

For every transactions finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-7-transactions-00X`, assigned in emission order starting at `F-7-transactions-001`.

Never combine zone-failure and regional-failover evidence in one row or finding. If the same dependency plus entrypoint applies to both scenarios with materially different behavior, emit two findings.

## Output

Write the fragment to `<fragmentDir>/transactions.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-researcher-7-logging-2-transactions`, `category-key: transactions`, `payment-applicability: <value from manifest>`, and the fragment's terminal status. Follow the frontmatter with two subsections in this fixed order:

* `## Category transactions Inventory Rows` containing every emitted inventory row.
* `## Category transactions Findings` containing every emitted finding.

Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the inventory row count, the finding count, the count of findings carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-7-logging-3-correlation-context`
