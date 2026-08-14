---
description: "Creates the Code-Level Resiliency Assessment report header, Table of Contents, and Section 1 (Assessment Overview)"
argument-hint: "serviceName=... [reportTitle=...] [targetDeployment=...]"
---

# Resiliency Report Generator — Part A: Header and Assessment Overview

## Inputs

* ${input:serviceName}: (Required) Service name matching the repo name; used to locate artifacts and populate all headers, sections, and repo references throughout the report.
* ${input:reportTitle}: (Optional) H1 title. Default: "Code-Level Resiliency Assessment".
* ${input:targetDeployment}: (Optional) Target deployment model. Default: "Active/Active".

## Source Artifacts

Read **only** the following before generating. Do **not** read the Developer Guide or subagent files for this prompt.

* `.copilot-tracking/plans/` — locate `{serviceName}-Master.md`. Read the Overview Summary, Priority Legend, Application Summary, Architecture and Dependency Map, the finding count per priority tier, and the Open Questions section. This is sufficient for the Assessment Overview.
* `.copilot-tracking/research/` — locate `*-{serviceName}-research.md`. Read only the Repository Context section (Section 1) for the opening paragraph.

## Critical Context

This report serves the Albertsons engagement. The customer is transitioning from a single-region deployment with a passive DR target to an active/active deployment across two regions. Every finding must be evaluated through this lens. Use the classification rules and decision tree defined in `hve-resiliency-planner-context.instructions.md`   for all priority assignments.

All section headers, H3 group names, finding titles, and repo references must use `{serviceName}` (the repo name), not hardcoded service names like "Braintree" or "Fiserv".

## Region-Agnostic Language Rule

The generated report must **never** reference "East US", "eastus", or any East region variant anywhere in the report. Prefer region-agnostic terms:

* **Primary region** — the current production region
* **Secondary region** or **failover region** — the target active/active peer
* **Both regions** — when referring to symmetric requirements

"West US" and "West US 2" may be used when necessary (e.g., describing the customer's actual topology), but prefer the generic terms above when the statement applies to any multi-region deployment.

## What to Generate

Create a **new file** at `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md` containing **only** the following sections. Subsequent prompts (3b, 3c, 3d) will append the remaining sections.

### 1. Document Header

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

### 2. Navigation and Table of Contents

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

### 3. Section 1 — Assessment Overview

Use `# 1. Assessment Overview` as the heading. Include all of the following sub-sections:

1. **Opening paragraph**: Describe what the service does, its tech stack, and the scope of the analysis. Reference the evidence-only methodology.

2. **Assessment Themes**: A numbered list of the top 3-5 themes that emerged from the research, each with a brief description and cross-references to the relevant finding IDs. Derive finding IDs from the Master Report finding numbers using the `PX-NNN` format. Map F-001 through F-060 to their priority-specific sequential IDs (P0-001 through P0-010, P1-001 through P1-030, etc.).

3. **Albertsons Azure Services Reference Architectures**: Include this exact static table:

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

4. **Summary Findings Table**: Counts broken down by Section and Priority. Derive counts from the Master Report finding tallies:

    | Section            | Priority  | Count | Description                                                                    |
    |--------------------|-----------|-------|--------------------------------------------------------------------------------|
    | **Resiliency**     | **P0**    | N     | Blocks failover from functioning or renders multi-region deployment meaningless |
    | **Resiliency**     | **P1**    | N     | Materially increases risk during failure; procedural workarounds or limited blast radius |
    | **Resiliency**     | **P2**    | N     | Weakens resilience posture; best-practice improvements for zone/region survivability |
    | **Resiliency**     | **P3**    | N     | Referential entries or compound interaction descriptions                       |
    | **Non-Resiliency** | **P2**    | N     | Code quality, security hygiene, observability, and configuration improvements  |
    | **Non-Resiliency** | **P3**    | N     | Security-only observations and configuration hygiene items                     |
    |                    | **Total** | **N** |                                                                                |

    To split findings between Resiliency and Non-Resiliency sections: all P0 and P1 findings are Resiliency. P2 and P3 findings are classified using the litmus test — findings that pass the active/active litmus test (behavior changes in multi-region) are Resiliency; findings with identical behavior regardless of topology are Non-Resiliency.

5. **IMPORTANT callout**: End with this exact blockquote:

    > **IMPORTANT:** Throughout this guidance, hard numbers used for retry counts, timeout settings, interval timings, thread pool sizes, and circuit breaker thresholds are provided as examples. In code, these should be configurable variables sourced from environment-specific configmaps. Treat all code snippets as illustrative patterns, not prescriptive implementations.

End the section with `[Back to Top](#top)`.

## Formatting Conventions

* Aligned pipe tables — all pipes vertically aligned across all rows.
* Blank lines before and after tables, code blocks, headings, and lists.
* `---` horizontal rules between major sections.
* All repo references use `{serviceName}`, never a hardcoded service name.
* Report file must NOT include `<!-- markdownlint-disable-file -->` — this is a customer-facing deliverable.

## Output Location

Write the generated report to:

`Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md`

Create the file new. Subsequent prompts (3b, 3c, 3d) will append to this file.

## Next Step

After completing this prompt:

> **Next step:** Run `/hve-resiliency-planner-3b`
