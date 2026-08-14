---
description: Fill the log-hygiene fragment of the split Prompt 7 Logging pipeline - emit inventory rows and findings only for the log-hygiene assessment category
agent: Task Researcher
argument-hint: "[manifestPath=...]"
---

# HVE Resiliency Researcher 7 Logging - 4 - Log Hygiene

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) and the [Researcher 7 Logging Split Contract](../../instructions/hve-resiliency-researcher-7-logging-split.instructions.md). This prompt fills the log-hygiene fragment only. It does not read Prompt 1a or Prompt 1b directly, does not modify the skeleton, does not read or edit other category fragments, and does not set the pipeline-level status.

## Inputs

* `${input:manifestPath}`: (Optional) Workspace-relative path to the frozen manifest sidecar emitted by `hve-resiliency-researcher-7-logging-0-scaffold`. When omitted, auto-locate it per the Manifest Auto-Location rule in the Researcher 7 Logging Split Contract.

## Direct Invocation and Prerequisite

* Run only the log-hygiene fill stage. Do not run any other category fill, verify, or finalize behavior.
* Require the manifest produced by the scaffold step to exist, be readable, and be well-formed per the Frozen Manifest Sidecar Contract. If it is missing, unreadable, or structurally invalid, a prior step failed or ran out of order: stop `Blocked` per Status and Failure Semantics and do not create a fragment file. If the manifest is well-formed but lists zero eligible dependencies, do not block: emit this stage's fragment file with no rows and terminal status `Complete`, note that no eligible dependency was in scope, then stop.

## Read Scope

Load the manifest, confirm `schemaVersion: hve-resiliency-researcher-7-logging-split/v1`, and enumerate the frozen `eligibleDependencies` list. Confirm `sources` still resolve to readable paths and that their `contentSha256` values match; if any source digest disagrees, stop `Blocked` with `manifest source drift`.

The only inputs to this stage are the manifest, the frozen eligible dependency list, and repository source files. Do not read Prompt 1a or Prompt 1b directly. Do not read other category fragments. Do not re-derive the eligible dependency list.

## Category Focus

Emit inventory rows and findings only for the assessment category `log-hygiene`: log structure, levels, sinks, payload exposure, redaction, secrets, PCI data, and PII. Skip any evidence that maps to startup and health, transactions, correlation and context propagation, or silent-outage diagnostics; those categories belong to their own fragments.

Log-hygiene discovery hints (evidence-only):

* Logger configuration files (`logback-spring.xml`, `log4j2.xml`, `application.yml` logging sections) and their declared structure, levels, and sinks.
* Formatter or encoder pattern definitions and their fields (JSON encoders, `PatternLayout`, custom converters).
* Production log statements that emit full request or response payloads, headers, tokens, cookies, or downstream response bodies.
* Redaction, masking, or filter appenders (regex masks, custom `TurboFilter`, message converters).
* Log lines that reference secret-shaped identifiers, PCI-scoped fields (`pan`, `cvv`, `cardholder`, `expiry`), or PII fields (`ssn`, `phone`, `email`, `address`, `dob`) on production paths.
* Sink configuration for stdout, files, aggregator agents, or SIEM shippers.

Never emit a row or finding solely because redaction documentation is unavailable; require positive repository evidence of a hygiene surface, payload-exposure site, or missing redaction on a cited production statement.

## Sanitization Extra Care

Log-hygiene fills observe secret-shaped and PII-shaped values with higher likelihood than other categories. Sanitize immediately after read and before hash, comparison, or emission. Retain only the type, path, line, and a stable redacted identity. If an individual observed value cannot be sanitized safely, drop that value and keep the finding using only its safe location metadata (type, path, line, redacted identity); never render the raw value and never block for this reason, per Status and Failure Semantics.

## Bounded Discovery

Apply the bounded-discovery limits in the shared contract per eligible dependency and per this category only. Counters do not carry over from another category fill and cannot be reset by aliases, environments, or wording.

Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points there. Stop when repository-free ledger review adds nothing.

## Emission

For every log-hygiene inventory row, emit the Required Inventory Row Schema from the shared contract using section-scoped IDs of the form `I-7-log-hygiene-00X`, assigned in emission order starting at `I-7-log-hygiene-001`.

For every log-hygiene finding, emit the Required Finding Schema from the shared contract using section-scoped IDs of the form `F-7-log-hygiene-00X`, assigned in emission order starting at `F-7-log-hygiene-001`.

Never combine regional-failover and partial-outage evidence in one row. If the same dependency plus entrypoint applies to both scenarios with materially different behavior, emit two findings.

## Output

Write the fragment to `<fragmentDir>/log-hygiene.md`, where `<fragmentDir>` is the `fragmentDir` recorded in the manifest. Begin the file with frontmatter recording `source-prompt: hve-resiliency-researcher-7-logging-4-log-hygiene`, `category-key: log-hygiene`, and the fragment's terminal status. Follow the frontmatter with two subsections in this fixed order:

* `## Category log-hygiene Inventory Rows` containing every emitted inventory row.
* `## Category log-hygiene Findings` containing every emitted finding.

Do not modify the skeleton artifact. Do not touch any other fragment.

## Completion

Report the inventory row count, the finding count, the count of findings carrying any `Unknown: not found after bounded search <scope>` descriptor, the fragment path, and the terminal fragment status.

> **Next step:** Run `/hve-resiliency-researcher-7-logging-5-silent-outage-diagnostics`
