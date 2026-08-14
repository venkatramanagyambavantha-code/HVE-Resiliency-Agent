---
description: Run a bounded external dependency inventory for Application resiliency research
agent: "Task Researcher"
---

# Application HVE Researcher 1b Optimized

## Required Protocol

* Build one production manifest from dependencies, production source/configuration, IaC, deployments, and invoked workflows; exclude nonproduction surfaces absent production evidence. Scan once with high-signal structural anchors or externally qualified identifiers. Display at most 20 candidate matches per ownership surface; refine capped/truncated queries before reading. Initial-pass refinement does not consume corrective search.
* Ledger each candidate as confirmed runtime, confirmed pipeline-only, configured but unconfirmed, bounded negative, or not applicable. Permit two confirmation actions maximum; one is one targeted query or owner-file read. Runtime requires binding plus construction/invocation; pipeline use requires an invoked production workflow.
* For confirmed runtime, one owner analysis is one trace through its owning production component for mitigations, readiness, health probes, and GLB wiring. Check missing health/GLB artifacts twice maximum, then record constraints. Retain pipeline-only entries with evidence and runtime health/GLB values `Not applicable: no application runtime request path`.
* Check identity, payment, search, commerce APIs, messaging/streaming, data stores, file transfer, telemetry, feature/configuration, delivery, and evidenced categories once. One corrective search targets one concrete missed production path. Stop after all states/analyses and a ledger-only, repository-search-free no-change review adds nothing. Section mapping: confirmed to 1, unconfirmed/negative to 2, architecture-disproved to 3. Preserve `Explicit statement`; use its quoted value for negatives, or trigger and confirmation gap for unconfirmed entries. Put P0-P3 in existing failover-impact or substantive reason values; add no field/section.

## Output Requirements

Begin the artifact with YAML Markdown metadata containing `title`, `description`, `ms.date`, `ms.topic`, `source-prompt: hve-resiliency-researcher-1b`, and `schema-version: 1`. Set `status: current` only when the bounded inventory completes and all required Sections 1-3 are committed. Set `status: incomplete` when the inventory or any required section is incomplete. The metadata does not replace or add to the required sections.

Produce exactly these sections and fields in this order.

### Section 1 — Used External Dependencies (Evidence Confirmed)

* Service / Dependency name
* Evidence (file path + line number)
* Brief description of how it is used
* Whether it materially impacts zone or region failover (Yes/No + description of why this could impact zone or region failover)
* Existing mitigations present (if any): retries/timeouts/fallbacks/feature flags/runbooks, with evidence (file path + line number)
* Health check present for this dependency? (Yes/No + evidence)
* How health is determined (e.g., ping/query/auth call/SDK check/timeouts) + evidence
* Is dependency health surfaced to GLB health evaluation? (Yes/No/Unclear + evidence of the wiring)
* What GLB probes (or upstream probes) hit (endpoint/path/port) and what conditions cause unhealthy vs healthy, as expressed in config/code + evidence
* Constraints/limitations (if any): dependency/platform capabilities or configuration/operational constraints that shape failover behavior, with evidence (file path + line number) when present

### Section 2 — Checked but Not Present

* Service / Dependency name
* Reason it was evaluated (e.g., common pattern, failover relevance)
* Explicit statement: "No references found in code, config, IaC, or pipelines"

### Section 3 — Not Applicable

* Service / Category name
* Reason it does not apply (e.g., no messaging, no streaming, no batch jobs)