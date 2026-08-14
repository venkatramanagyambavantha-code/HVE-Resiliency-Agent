---
description: Discover Azure services from repository evidence
agent: "Task Researcher"
---

# HVE Researcher 1a

Use [platform context](../../instructions/hve-resiliency-platform-context.instructions.md) for its rules.

## Objective

Produce an evidence-only Azure scope contract. Direct invocation overrides inherited workflow sequencing, delegation, result-section schema, and next-step rules only. Preserve inherited research-root, date-directory, repository-prefix, evidence, and Markdown metadata rules. Do not run another resiliency prompt. Investigate directly and do not delegate.

## Scope And Matrix

Inventory every repository file once, including extensionless operations. Exclude outputs, caches, editor metadata, tests, `.copilot-tracking/**`, reports/research/assessments, prompt artifacts, certificates, binaries, wrappers, and vendored dependencies. Keep `.github/workflows/**`; docs only trigger. Follow one reference into excluded operational text.

Resolve this bounded negative matrix:

* Compute: Azure Kubernetes Service (AKS), Azure Functions, Azure App Service
* Edge: Azure API Management, Application Gateway
* Data: Cosmos DB for MongoDB, Azure SQL Database/Managed Instance, Azure Storage by subtype, Azure Managed Redis
* Messaging: Confluent Cloud Kafka
* Identity/configuration: Entra ID, Managed/Workload Identity, Key Vault, App Configuration
* Observability: Azure Monitor
* Delivery: Azure Container Registry

Add positively evidenced services. Use specific nonduplicative names; never claim universal absence.

## Evidence Rules

Explicit Use requires an IaC resource/Azure ID, configured Azure client, pipeline target, or Azure endpoint, connection string, annotation, or runtime binding. Imports, dependencies, comments, docs, protocols, and names need a second binding signal; otherwise place them in Section 2 with the trigger.

Implicit Dependency requires an Azure binding, necessity, no evidenced substitute, and a file-line chain. Kubernetes does not prove AKS, MongoDB Cosmos DB, or Kafka Event Hubs. Keep unresolved Azure hostnames neutral without product evidence. `Not Present` requires bounded row-indicator checks.

## Required Steps

### Step 1: Inventory Sources

Verify availability without execution probes. Use one deterministic inventory method and one verified fallback at most. Build, filter, classify, and reuse one path-only manifest.

### Step 2: Discover Signals

Split the manifest by first match into three disjoint source classes: deployment and delivery; production configuration and operations; application source and build. Perform one logical initial scan per class, reading each manifested file at most once. A logical scan may bundle multiple signal expressions in one tool invocation or one local scanner pass, but it must cover Azure resource IDs and types, hosts, SDKs and clients, configuration, identity, telemetry, deployment signals, `azurecr.io`, and registry server, image, or login signals. Follow at most two direct references per candidate branch when needed to establish ownership or production binding.

Sanitize every signal before retaining, comparing, hashing, logging, or writing it. Remove credentials, tokens, keys, signatures, connection-string values, authorization values, URI user information, and sensitive query values. Retain only normalized repository-relative paths, line numbers, safe product or host indicators, identifiers, key paths, value types, API types, call structure, and the minimum sanitized excerpt needed to audit the evidence. If a signal cannot be safely sanitized or reliably attributed to a source path and line, drop that signal, note the gap in the ledger, and continue; never emit a raw secret value and never stop the run for this reason.

Group sanitized signals by canonical path, line, and family; then deduplicate, sort, and assign stable IDs. Freeze one audited in-memory evidence package containing the manifest hash, class coverage, sanitized signals and excerpts, counts, and stable-ID set hash. Do not retain or emit raw source bodies, raw matches, or secret values.

### Step 3: Reconcile And Verify

After the evidence package freezes, analyze only that package. Do not rescan or reopen repository sources. Map each stable ID to one canonical Azure candidate, neutral Azure-host trigger, false positive, semantic gap, or bounded-negative matrix row. Analyze each owner once and maintain a sanitized ledger of source coverage, IDs, candidates, and terminal dispositions.

Give every ID exactly one terminal disposition and map it once: Explicit Use and Implicit Dependency to Section 1; bounded negatives and unconfirmed weak, neutral-host, false-positive, or semantic-gap triggers to Section 2; only services or categories made inapplicable by positive architecture evidence to Section 3. A false-positive signal remains in Section 2 even when independent evidence confirms the service in Section 1. Missing signals, exhausted checks, unresolved hosts, false positives, and semantic gaps never establish Section 3.

### Step 4: Audit And Render

Require every committed signal ID exactly once in the ledger, one terminal disposition per ID, and every rendered row traced to package evidence or a bounded matrix-row check. Reconcile ledger counts and the stable-ID set hash with the committed package. Audit every claim and citation against package records, then run one package-only no-change review. Keep internal ledgers and coverage tables out of the artifact.

## Required Protocol

Run Steps 1-4 once. Use one manifest, one logical scan of each disjoint source class, one sanitized package, one owner analysis per candidate, at most two indirections per branch, and one package-only review. Before the package freezes, permit one correction only when coverage records prove that manifested files were omitted from their initial class scan; scan only those previously unscanned files. Never re-enumerate the repository or rescan a file.

Any incomplete manifest, read or scan failure, clipping, lost or unreconciled ID, package failure, count or hash mismatch, or failed audit makes the run incomplete. A signal that cannot be safely sanitized or attributed is dropped and does not, by itself, make the run incomplete. Never convert such a failure into a negative or Not Applicable result. Use one of these failure codes: `MANIFEST_INCOMPLETE`, `SCAN_FAILED`, `RECONCILIATION_FAILED`, or `COVERAGE_FAILED`. For incomplete execution, render only the exact incomplete form below.

## Output Contract

Write the result to `.copilot-tracking/research/<YYYY-MM-DD>/<repo-name>-hve-resiliency-researcher-1a-research.md`. Begin the file with required YAML Markdown metadata, including `title`, `description`, `ms.date`, `ms.topic`, `source-prompt: hve-resiliency-researcher-1a`, and `schema-version: 1`. Set `status: current` only when the run completes with all required Sections 1-3 committed. Set `status: incomplete` for every incomplete run. After the metadata, output exactly Sections 1-3 below and no other result section, remediation, advice, or example. Fold evidence into the applicable row. The metadata does not replace or add to the three result sections.

### Section 1 - Used Azure Services (Evidence Confirmed)

Include only Explicit Use or Implicit Dependency. Repeat these fields in order:

* Service name
* Azure service category
* Evidence class: Explicit Use or Implicit Dependency
* Evidence (file path + line number)
* Brief description of how it is used
* Region / failover sensitivity (Yes/No/Unclear + evidence-only rationale; include P0/P1/P2/P3 when the row states a risk finding)

`Unclear` requires a named evidence gap.

### Section 2 - Checked but Not Present

Include every bounded negative and every unconfirmed Azure-related weak trigger, neutral Azure-host trigger, false positive, or semantic gap. Repeat these fields in order:

* Service / trigger name
* Result: Bounded negative or Unconfirmed trigger
* Reason it was evaluated or trigger evidence (file path + line number)
* Checked scope and indicator families
* Confirmation gap or terminal label: weak trigger, neutral Azure-host trigger, false positive, or semantic gap

State a negative only within the named manifest and checked indicator families; never claim universal absence.

### Section 3 - Not Applicable

Include only services or categories made inapplicable by positive architecture evidence. Repeat these fields in order:

* Service / category name
* Evidence (file path + line number)
* Reason it does not apply

If none qualify, state exactly `None. No service or category was made not applicable by positive architecture evidence.`

For any incomplete run, output exactly this form. Replace angle-bracket placeholders only with audited package data or a static failure code. Add no partial rows, dispositions, evidence, raw excerpts, stable IDs, remediation, advice, examples, or next-step suggestion.

```text
## Section 1 - Used Azure Services (Evidence Confirmed)

Status: Incomplete
Completed safe coverage: <last audited package counts and hashes, or None>
Unresolved condition: <static failure code>
No Section 1 confirmed-service inventory is committed.

## Section 2 - Checked but Not Present

Not rendered because the run is incomplete. No bounded-negative or unconfirmed-trigger disposition is committed.

## Section 3 - Not Applicable

Not rendered because the run is incomplete. No Not Applicable disposition is committed.
```
