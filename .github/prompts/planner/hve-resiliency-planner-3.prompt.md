---
description: "Creates a Code-Level Resiliency Assessment report from HVE research and planner outputs for any Application service repository"
argument-hint: "serviceName=... [reportTitle=...] [targetDeployment=...] [reviewPromptFiles={true|false}]"
---

# Resiliency Report Generator — Code-Level Assessment

## Inputs

* ${input:serviceName}: (Required) Service name matching the repo name; used to locate artifacts and populate all headers, sections, and repo references throughout the report.
* ${input:reportTitle}: (Optional) H1 title. Default: "Code-Level Resiliency Assessment".
* ${input:targetDeployment}: (Optional) Target deployment model. Default: "Active/Active".
* ${input:reviewPromptFiles:false}: (Optional) When true, cross-reference subagent research files against planner outputs; flag discrepancies in the Assessment Overview.

## Source Artifacts

Locate and read all of the following in full before generating the report. All files live under `.copilot-tracking/research/` (search recursively).

* `{serviceName}-Master.md` — priorities, remediation, owners, open questions.
* `{serviceName}-Developer-Guide.md` — code examples per finding (primary source for all code blocks).
* `*-{serviceName}-research.md` — evidence-only consolidated research.
* `subagents/` — all `prompt-N-topic.md` files under `.copilot-tracking/research/subagents/`.

Use the Developer Guide for code samples, Master Report for priorities and remediation, Consolidated Research for evidence citations.

## Critical Context

This report serves the {customer} engagement. The customer is transitioning from a single-region deployment with a passive DR target to an active/active deployment across two regions. Every finding must be evaluated through this lens. Use the classification rules and decision tree defined in `Application-planner-context.instructions.md` for all priority assignments.

All section headers, H3 group names, finding titles, and repo references must use `{serviceName}` (the repo name), not hardcoded service names like "Braintree" or "Fiserv". The H3 shared-service groups should reflect the service's actual dependencies as discovered in the research (e.g., "Payment Gateway / Transaction Processing", "Azure SQL / Data Integrity", "AKS / Pod Lifecycle").

## Region-Agnostic Language Rule

The generated report must **never** reference "East US", "eastus", or any East region variant anywhere in the report, including section headers, finding descriptions, recommendations, code examples, and IaC tables. East US is a legacy DR target that is not part of the active/active architecture.

Prefer region-agnostic terms throughout:

* **Primary region** — the current production region
* **Secondary region** or **failover region** — the target active/active peer
* **Both regions** — when referring to symmetric requirements

"West US" and "West US 2" may be used when necessary (e.g., describing the customer's actual topology or referencing specific Helm values files), but prefer the generic terms above when the statement applies to any multi-region deployment.

In code examples and fix blocks, use placeholder values like `{primaryRegion}`, `{secondaryRegion}`, or generic names (e.g., `apim-prod-region1.example.com`, `apim-prod-region2.example.com`) rather than region-specific hostnames.

## Report Structure

### Incremental Write

Build the report with in-place edits, never a single oversized write that is prone to transient network failures:

* First create the file with the Document Header, Table of Contents, and Section 1 (Assessment Overview) only. This is one bounded write.
* Then append findings under Sections 2 and 3 one finding at a time, each as a separate edit, in P0, P1, P2, then P3 order.
* Then append Sections 4, 5, and 6 as separate edits, one section per write.
* Never regenerate previously written content and never hold more than one finding's rendered body (including its two code blocks) in a single write.
* Treat the operation as resumable and idempotent: before appending a finding, check whether its `PX-NNN` ID already appears in the file; if it does, skip it. Before appending a section, check whether its H1 heading already appears; if it does, skip it. A re-dispatched run continues from a partial report without duplicating or reordering content.

### Document Header

```text
# Code-Level Resiliency Assessment

**{serviceName}**

**Assessment Date:** {date or date range}

**Repo Scope:** {serviceName}

**Current Deployment:** {current deployment from research}

**Target Deployment:** {targetDeployment}

**Version:** {semver}

---
```

### Navigation and Table of Contents

Place `<a id="top"></a>` immediately after the header horizontal rule, then `## Table of Contents` with a numbered list of fragment links for every H1 section. No auto-generation markers. Fragment pattern: lowercase, hyphens, no special chars; number-prefixed.

```text
<a id="top"></a>

## Table of Contents

1. [Assessment Overview](#1-assessment-overview)
2. [Resilient Focused Recommendations](#2-resilient-focused-recommendations)
3. [Non-Resilient Focused Recommendations](#3-non-resilient-focused-recommendations)
4. [IaC Gap Analysis](#4-iac-gap-analysis)
5. [Full Finding Matrix](#5-full-finding-matrix)
6. [Microsoft Standards Alignment](#6-microsoft-standards-alignment)
```

### Section 1 — Assessment Overview

Use `# 1. Assessment Overview` as the heading. Include:

1. **Opening paragraph**: Describe what the service does, its tech stack, and the scope of the analysis. Reference the evidence-only methodology.

2. **Assessment Themes**: A numbered list of the top 3-5 themes that emerged from the research, each with a brief description and cross-references to the relevant finding IDs.

3. **{customer} Azure Services Reference Architectures**: Include this exact table in every assessment. It is static and applies to all Application services.

    | Azure Shared Service                | Link to Reference Architecture                |
    | ----------------------------------- | --------------------------------------------- |
    | Azure API Management                | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Integration%20Platform/APIM/Design/APIM%20-%20Albertsons%20Multi-Region%20Design%20v5.docx?d=w7f65ea542cc7491687202cfa68599d7b&csf=1&web=1&e=dhPvP3) |
    | Azure Application Gateway           | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Integration%20Platform/AppGW/Design/Albertsons%20Architecture%20Design_Application%20Gateway_v1.0.docx?d=w3126f533271842c9a75d83ae93b6b6db&csf=1&web=1&e=hmksie) |
    | Azure Key Vault                     | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Cloud%20Foundation/Design/Albertsons%20Azure%20Key%20Vault%20Architecture%20Design%20Proposal.docx?d=wf1abecab2812460a8cadd6e5956d5bb8&csf=1&web=1&e=yzvvQh) |
    | Kafka                               | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Integration%20Platform/Kafka/Approved_Albertsons_RegionResiliency_Kafka-MultiRegion.docx?d=w08142308135244de855f4dab4c49ca2d&csf=1&web=1&e=kueuJ9) |
    | Azure Entra ID                      | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Security/IAM/Design/ACI%20Entra%20ID%20Draft%20v1.0.docx?d=wad696d3ecdae4d84a6a1ea5675d3aec6&csf=1&web=1&e=rCLr5y) |
    | Azure Storage                       | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Database%20Platform/Storage/Albertsons%20Architecture%20Design_Storage_v1.0.docx?d=w97ad6ce3e77348e09a1ee3e676bc3ac0&csf=1&web=1&e=C4SVMy) |
    | Azure SQL Database                  | [Reference](https://rxsafeway.sharepoint.com/:f:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Database%20Platform/SQL%20DB?csf=1&web=1&e=xMauSY) |
    | Azure Cosmos DB                     | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Database%20Platform/Cosmos/Albertsons_Architecture_Design_MongoDB_RU_v1.0.docx?d=wa68893488e094fef9b5506690c685847&csf=1&web=1&e=YDVc7g) |
    | Azure Functions                     | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Cloud%20Foundation/Design/Albertsons%20Azure%20Functions%20Architecture%20Design%20Proposal.docx?d=w0c59f970929f47f2a6dcef096fffd7f2&csf=1&web=1&e=tXAxCU) |
    | Azure Networking                    | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Network/Design/Albertsons%20Architecture%20Design%20-%20Networking%20-%20Draft%201.3.docx?d=w6adb9edef1754753a259b296fffa4b1d&csf=1&web=1&e=IshBZT) |
    | Azure Managed Redis                 | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Database%20Platform/Redis/Design/Managed%20Redis%20-%20Albertsons%20Multi-Region%20Design%20v3.docx?d=wad90acec4c154b2498d899a2ffcdc9d4&csf=1&web=1&e=L7pVbQ) |
    | Azure Kubernetes Service (AKS)      | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Container%20Platform/Design/Albertsons%20Architecture%20Design_AKS%20and%20Istio_v1.0.docx?d=w97c0edfea59d466e80af843958d95c5c&csf=1&web=1&e=7UJSQS) |
    | Azure Storage Blobs and Files       | [Reference](https://rxsafeway.sharepoint.com/:w:/r/sites/Cloud2.0/Shared%20Documents/I11%20Resiliency%20Program/Discovery/Storage/Architecture%20Options%20for%20Storage%20Blobs%20and%20Azure%20Files_v04.docx?d=w5d8203dcf43c41438843a71219ec05d8&csf=1&web=1&e=kTl0dg) |

4. **Summary Findings Table**: Counts broken down by Section and Priority:

    | Section            | Priority  | Count | Description                                                                    |
    |--------------------|-----------|-------|--------------------------------------------------------------------------------|
    | **Resiliency**     | **P0**    | N     | Blocks failover from functioning or renders multi-region deployment meaningless |
    | **Resiliency**     | **P1**    | N     | Materially increases risk during failure; procedural workarounds or limited blast radius |
    | **Resiliency**     | **P2**    | N     | Weakens resilience posture; best-practice improvements for zone/region survivability |
    | **Resiliency**     | **P3**    | N     | Referential entries or compound interaction descriptions                       |
    | **Non-Resiliency** | **P2**    | N     | Code quality, security hygiene, observability, and configuration improvements  |
    | **Non-Resiliency** | **P3**    | N     | Security-only observations and configuration hygiene items                     |
    |                    | **Total** | **N** |                                                                                |

5. **IMPORTANT callout**: End with a blockquote about configurable values:

    > **IMPORTANT:** Throughout this guidance, hard numbers used for retry counts, timeout settings, interval timings, thread pool sizes, and circuit breaker thresholds are provided as examples. In code, these should be configurable variables sourced from environment-specific configmaps. Treat all code snippets as illustrative patterns, not prescriptive implementations.

End with `[Back to Top](#top)`.

### Sections 2–3 — Grouped Findings

Organize all findings under exactly two top-level H1 sections:

* `# 2. Resilient Focused Recommendations` — findings where `Resiliency Related: Yes` (directly affect zone survivability, regional failover, data integrity, or recovery time).
* `# 3. Non-Resilient Focused Recommendations` — findings where `Resiliency Related: No` (security hygiene, configuration consistency, operational best practices).

Four-level hierarchy within each H1:

* **H2** — priority block with finding count: `## P0 — Critical Resiliency Risks (N)` / `## P1 — High Priority Resiliency (N)` / `## P2 — Improvement / Best Practice (N)` / `## P3 — Code Consistency (N)`. For the Non-Resilient section, adjust labels (e.g., `## P2 — Improvement / Best Practice (Non-Resiliency) (N)`).
* **H3** — shared-service group derived from findings: `### Azure SQL / Data Integrity`, `### Payment Gateway / Transaction Processing`, `### Health Probes / GLB Readiness`, `### AKS / Pod Lifecycle`, `### Azure Key Vault / Secrets Sync`, `### Resilience Patterns`, `### Observability`, etc. Use generic names; do not hardcode vendor names like "Braintree" or "Fiserv" in H3 headings. Derive group names from the actual dependency categories found in the research.
* **H4** — individual finding: `#### P0-001: Short Title`

End each H1 section with `[Back to Top](#top)`.

### Individual Finding Template

Every P0, P1, P2, and P3 finding uses this exact format (field order must be preserved):

**Fields in order:**

1. `#### PX-NNN: Short Title` — H4 heading
2. `**Priority: PX — {Priority Label}**` — on its own line
3. `**Resiliency Related:** Yes / No`
4. `**Issue:**` — description of the problem
5. `**What does this solve:**` — one sentence, the outcome achieved
6. `**Resiliency Impact:**` — 1–3 sentences (required for Resiliency Related: Yes). For Resiliency Related: No findings, use `**Impact:**` instead
7. `**Recommended Fix:**` — concrete narrative action
8. `**File:** file/path.ext:line` — followed by a fenced code block with the current problematic code (must include a language identifier)
9. `**Fix:**` — followed by a separate fenced code block with the corrected implementation (must include a language identifier)
10. `**Notes:**` — context, rationale, or implementation guidance
11. `<span style="font-size: 14px;">**MSFT Reference:** [Pattern Name](URL)</span>` — when a WAF pattern or Azure guidance page applies

**Finding field guidance:**

* **Issue** (P0/P1): Explain how the issue is introduced or worsened by the transition from single-region to active/active. (P2/P3): Note that behavior is identical regardless of topology.
* **Resiliency Impact**: Frame in terms of zone failure or regional failover impact. Required for all `Resiliency Related: Yes` findings.
* **Recommended Fix**: Must be specific enough for the customer's developers to implement independently without the team's involvement.

Priority labels by level:

* P0: `Failover-Blocking Risk`
* P1: `Multi-Region Resiliency Gap`
* P2: `Code Quality / Best Practice`
* P3: `Code Consistency` or `Noted for Completeness`

Finding rules:

* IDs: `PX-NNN` — zero-padded sequential per priority (P0-001, P1-012, etc.).
* Separate findings with `---` (horizontal rule).
* Always use two separate fenced code blocks — one under `**File:**` showing the current code and one under `**Fix:**` — each with a language identifier. Pull samples from the Developer Guide. Never combine both into one block.
* Configurable values in code use `// e.g., 3` comments.
* `Resiliency Related: Yes` = directly affects failover/survivability/data integrity per the litmus test. `No` = security, consistency, or hygiene.
* `What does this solve` is required on all findings, one sentence.
* `Resiliency Impact` is required on all `Resiliency Related: Yes` findings.
* For `Resiliency Related: No` findings, use `**Impact:**` instead of `**Resiliency Impact:**`.
* Include MSFT Reference when a WAF pattern or Azure guidance page applies.
* When a finding references cross-dependencies to other findings, use the `PX-NNN` format (e.g., "Coordinate with P0-001 and P1-015").

### Section 4 — IaC Gap Analysis

Use `# 4. IaC Gap Analysis` as the heading. Begin with a paragraph explaining what infrastructure was visible in the repo (Helm charts, configmaps, deployment manifests, ServiceEntry/VirtualService resources, HPA configuration, probe definitions) vs. what lives in external repos (Terraform, ARM, SKU/tier settings).

Follow with two tables:

**Available to Review:**

| Configuration                | Current Value                          | Resiliency Assessment                            |
|------------------------------|----------------------------------------|--------------------------------------------------|
| Item                         | Value                                  | Assessment with finding cross-reference (PX-NNN) |

**Not Available (External Repos/Platform):**

| Configuration                | Needed For                             |
|------------------------------|----------------------------------------|
| Item                         | Why this matters for resiliency        |

End with `[Back to Top](#top)`.

### Section 5 — Full Finding Matrix

Use `# 5. Full Finding Matrix` as the heading. Complete table of all findings sorted P0 → P1 → P2 → P3:

| ID                                                                   | Priority | Category           | Finding                              | Repo(s)         |
|----------------------------------------------------------------------|----------|--------------------|--------------------------------------|-----------------|
| [PX-NNN](#px-nnn-short-title-kebab-case)                             | **PX**   | Category           | Short description                    | {serviceName}   |

All IDs link to their H4 anchor (lowercase, hyphens, special chars removed).

End with `[Back to Top](#top)`.

### Section 6 — Microsoft Standards Alignment

Use `# 6. Microsoft Standards Alignment` as the heading.

| Pattern                                                                   | Status                                             | Findings              |
|---------------------------------------------------------------------------|----------------------------------------------------|-----------------------|
| [Pattern Name](URL)                                                       | Not Implemented / Partial (reason) / Misconfigured / Not followed | PX-NNN, PX-NNN        |

End with `[Back to Top](#top)`.

## Formatting Conventions

* Aligned pipe tables — all pipes vertically aligned across all rows.
* Blank lines before and after tables, code blocks, headings, and lists.
* `---` horizontal rules between major sections and between individual findings within a group.
* `**Priority: PX — Label**` on its own line (no `| Repos:` inline).
* All code blocks have a language identifier (`java`, `yaml`, `properties`, `bash`, `text`).
* Inline code for env vars, function names, file paths, and config keys.
* Report ends with `[Back to Top](#top)`.
* Use `[Back to Top](#top)` (not `[⬆ Back to Top](#top)`).
* All repo references in Repo(s) columns, headers, and finding metadata use `{serviceName}`, never a hardcoded service name.

## Validation Checklist

Before finalizing, confirm:

* Every H1 section has a working fragment link in the Table of Contents.
* Every finding has a unique `PX-NNN` ID; no duplicates.
* Finding counts in the Summary Findings Table match actual counts per section and priority.
* Every finding has `Resiliency Related` and `What does this solve` populated.
* Every `Resiliency Related: Yes` finding has `Resiliency Impact` populated.
* Every finding with code has two separate labeled blocks (current code under `**File:**` and `**Fix:**`), each with a language fence.
* All `Resiliency Related: Yes` findings appear under Resilient Focused Recommendations; `No` findings under Non-Resilient Focused Recommendations.
* All six H1 sections appear in the Table of Contents.
* Full Finding Matrix includes every finding from every section, with linked IDs.
* P3 findings use the full finding template format (same as P0–P2), nested under `## P3 — Code Consistency` blocks in each H1 section.
* All Back to Top links use `#top`.
* Every P0/P1/P2 finding draws from both the Master Report and the Developer Guide.
* No hardcoded service names (e.g., "Braintree", "Fiserv") appear in H2, H3, or Repo(s) columns; use the generic shared-service group names and `{serviceName}`.
* No references to "East US" or any East region variant appear anywhere in the report.
* Region-specific names ("West US", "West US 2") are used only when necessary; generic terms ("primary region", "secondary region", "failover region") are preferred.
* When `reviewPromptFiles: true`, all research findings are accounted for.
* Assessment Overview themes cross-reference finding IDs.
* IaC Gap Analysis has both "Available to Review" and "Not Available" tables.

## Output Location

Write the generated report to:

`Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md`

Overwrite if the file already exists.

## Reference

Use the existing `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md` in the repo as the canonical formatting example. When ambiguity exists between these instructions and the existing assessment, the existing assessment takes precedence for visual formatting choices.
