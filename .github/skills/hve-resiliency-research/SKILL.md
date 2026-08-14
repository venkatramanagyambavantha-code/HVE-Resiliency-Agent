---
name: hve-resiliency-research
description: Use for application resiliency research covering regional failover between West US 2 and West US with the task-researcher workflow, evidence-only outputs, and P0-P3 priority classification.
---

# HVE Resiliency Research

Use this skill when you need the full resiliency research sequence for this repository.

Use [Resiliency Research Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

## Activation Guidance

Auto-load this skill for requests related to resiliency, Azure regional failover survivability research.

## Activation Behavior

When this skill is activated (via `/hve-resiliency-research` or by matching the activation guidance), the agent MUST immediately begin executing the Required Workflow starting at Phase 1, Prompt 0. Do not prompt the user for which prompt to run. Do not skip to service-specific prompts (8-19) without completing Prompts 0-7 first.

## Automated Orchestration (Recommended)

For a one-invocation run of each phase, use the orchestrator agents instead of running prompts one at a time:

* Select **Resiliency Research Orchestrator** from the agent picker to run Phases 1-3 (produces the consolidated research document).
* Select **Resiliency Planning Orchestrator** to run Phases 4-5 (produces the Code-Level Resiliency Assessment report). Pass `audit=on` to also run the optional Phase 6 evidence audit per tier after the report is assembled.

The orchestrators dispatch each step below to a fresh subagent, so they parallelize independent steps and manage context automatically. No manual `/clear` is needed when using them. The Required Workflow below is the manual, one-prompt-per-turn path.

## Context Management

A context reset (`/clear` or a new chat) is a clarity and cost tool, not a correctness requirement: durable artifacts in `.copilot-tracking/research/` carry context forward between prompts. In the manual workflow below, a reset before each prompt keeps the input scoped to the prior artifact plus the current prompt (the Mode A cost optimization); it is recommended for cost and optional for correctness. At minimum, reset at phase boundaries and when switching agents. When using the orchestrator agents, context is managed automatically and no manual reset is needed.

## Required Workflow

Phases are strictly sequential. Each phase must complete before the next phase begins.

### Phase 1: Core Research (Prompts 0-7) — Start Here

Phase 1 is mandatory and sequential. Always begin with Prompt 0.

1. Run `/hve-resiliency-researcher-0` first to establish the repository context frame.
2. Review the resulting research artifact in `.copilot-tracking/research/`.
3. Run `/hve-resiliency-researcher-1a`, review its Section 1 Azure services, then run `/hve-resiliency-researcher-1b` and review its Section 1 external dependencies.
4. Treat the combined Prompt 1a and Prompt 1b Section 1 entries as the evidence-confirmed dependency set. Exclude every dependency classified only in either artifact's Section 2 or Section 3 from subsequent prompts.
5. Run `/hve-resiliency-researcher-2`.
6. Run `/hve-resiliency-researcher-3`.
7. Run `/hve-resiliency-researcher-4`.
8. Prompt 5 has been split into a bounded pipeline. Run these in order:
    1. `/hve-resiliency-researcher-5-0-scaffold` (validates Prompt 1a and 1b Section 1, freezes the eligible-dependency inventory, emits skeleton + manifest sidecar).
    2. `/hve-resiliency-researcher-5-1-startup-failure`.
    3. `/hve-resiliency-researcher-5-2-silent-degradation`.
    4. `/hve-resiliency-researcher-5-3-data-loss-partial-processing`.
    5. `/hve-resiliency-researcher-5-4-blocking-transactions`.
    6. `/hve-resiliency-researcher-5-verify` (audits the four fragments against the manifest and workspace source).
    7. `/hve-resiliency-researcher-5-finalize` (assembles fragments into the single Prompt 5 artifact consumed by consolidation).
    * The four outcome fills are disjoint and may run in parallel chats when time-boxing allows; only the scaffold must precede them and only verify + finalize must follow.
    * `/hve-resiliency-researcher-5` is retained as a deprecated redirect to the scaffold entry point.
9. Run `/hve-resiliency-researcher-6` when shared dependency risk analysis is needed.
10. Run `/hve-resiliency-researcher-7-logging` (Logging).

### Phase 2: Service-Specific Research (Prompts 8-19, Circumstantial)

Phase 2 runs only after Phase 1 is complete. Run only the prompts matching dependencies confirmed in Section 1 of Prompt 1a or Prompt 1b. Skip services found only in Sections 2-3 or not found. Recommend applicable prompts from the combined Prompt 1a and Prompt 1b results.

11. Run `/hve-resiliency-researcher-8-appgw` (App Gateway)
12. Run `/hve-resiliency-researcher-9-functions` (Azure Functions)
13. Run `/hve-resiliency-researcher-10-keyvault` (Key Vault)
14. Run `/hve-resiliency-researcher-11-aks-istio` (AKS and Istio)
15. Run `/hve-resiliency-researcher-12-cosmosdb` (Cosmos DB)
16. Run `/hve-resiliency-researcher-13-sql` (SQL Server)
17. Run `/hve-resiliency-researcher-14-redis` (Redis)
18. Run `/hve-resiliency-researcher-15-storage` (Azure Storage)
19. Determine whether Cosmos DB and/or Azure SQL were confirmed in Prompt 1a Section 1, then run the matching Kafka prompt per the Database-to-Kafka Pairing Standard (see [Resiliency Research Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md)). Kafka runs on Confluent Cloud; do not ask which Kafka provider is in use.
    * Cosmos DB confirmed, Azure SQL not confirmed -> Run `/hve-resiliency-researcher-16-kafka-active-active`
    * Azure SQL confirmed, with or without Cosmos DB -> Run `/hve-resiliency-researcher-16-kafka-active-standby-confluent`
    * Neither confirmed -> Do not auto-select; ask the user which Kafka topology the application uses before proceeding
20. Run `/hve-resiliency-researcher-17-networking` (Networking)
21. Run `/hve-resiliency-researcher-18-entraid` (Entra ID)
22. Run `/hve-resiliency-researcher-19-apim` (APIM)

### Phase 3: Consolidation

Consolidation has been split into a bounded pipeline. Run these in order:

23. Run `/hve-resiliency-consolidate-0-scaffold` (enumerates accepted researcher artifacts, emits the consolidated skeleton and the frozen manifest sidecar).
24. Run each section-fill prompt against the manifest emitted in step 23. Fills write to independent fragment files under `<consolidatedDocDir>/sections/` and may run in parallel chats:
    * `/hve-resiliency-consolidate-1-repository-context`
    * `/hve-resiliency-consolidate-2-dependency-inventory`
    * `/hve-resiliency-consolidate-3-region-zone`
    * `/hve-resiliency-consolidate-4-state-data`
    * `/hve-resiliency-consolidate-5-failure-degraded`
    * `/hve-resiliency-consolidate-6-shared-cross-repo`
    * `/hve-resiliency-consolidate-7-secrets`
    * `/hve-resiliency-consolidate-8-other`
25. Run `/hve-resiliency-consolidate-verify-1-4` to audit Sections 1-4 fragments against routed source artifacts (report-only).
26. Run `/hve-resiliency-consolidate-verify-5-8` to audit Sections 5-8 fragments against routed source artifacts (report-only).
27. Run `/hve-resiliency-consolidate-9-finalize` to assemble the fragments, run index-level dedup and section precedence, reconcile finding IDs into the authoritative `F-00X` scheme, and build the Section 9 index.
28. Review the consolidated report at `.copilot-tracking/research/`.

### Phase 4: Planning

29. Run `/hve-resiliency-planner-0` to lock in evidence constraints from the consolidated research.
30. Run `/hve-resiliency-planner-1` to create the Executive / Master Resiliency Report.
31. Run `/hve-resiliency-planner-0` again to re-establish evidence lock-in.
32. Run `/hve-resiliency-planner-2` to create the Developer Guide with code-level remediation.

### Phase 5: Code-Level Resiliency Assessment Report

33. Run `/hve-resiliency-planner-3a` to create the report header, Table of Contents, and Assessment Overview (Section 1).
34. Run `/hve-resiliency-planner-3b` to append P0 and P1 Resilient Focused Recommendations (Section 2, partial).
35. Run `/hve-resiliency-planner-3c` to append P2/P3 resiliency findings and Non-Resilient Focused Recommendations (Sections 2 completion + Section 3).
36. Run `/hve-resiliency-planner-3d` to append IaC Gap Analysis, Full Finding Matrix, and Microsoft Standards Alignment (Sections 4-6) with final validation.
37. Review the completed report at `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md`.

### Phase 6: Assessment Evidence Audit (Optional)

Phase 6 verifies that every source citation, verbatim code block, and fix block in the completed assessment is faithful to the repository, and keeps all cross-references in sync. It is optional: when the Phase 5 builders followed the Evidence Fidelity Contract (see [Resiliency Task Planner Context](../../instructions/hve-resiliency-planner-context.instructions.md)), this pass should find little to correct. Run it as a backstop, or when the report was assembled quickly.

38. Run `/fix-assessment-finding` with a scope argument. Process tiers in ascending order so edits to the single report file never collide:
    1. `/fix-assessment-finding P0`
    2. `/fix-assessment-finding P1`
    3. `/fix-assessment-finding P2`
    4. `/fix-assessment-finding P3`
    * `/fix-assessment-finding all` runs every tier in one pass, pausing after each tier for review. Prefer per-tier invocation for the tightest context.
    * Scope may also be a single finding ID (e.g. `/fix-assessment-finding P1-025`) for a targeted correction.
39. Review the corrected report at `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md`.

## Execution Rules

* Keep research findings (Phases 1-3) evidence-only and forensic
* Do not include remediation recommendations in research phases
* Do not include code examples in research phases
* Classify every finding using P0 / P1 / P2 / P3 priorities
* Cite file and line-level evidence for every substantive claim
* Write each research output to `.copilot-tracking/research/` and use the repository name as the prefix for all output files (e.g., `<repo-name>-research-output.md`).
* Planning outputs (Phase 4) may include remediation and code examples

## Priority Definitions

* P0: Critical / Blocking. Causes outage, data loss, duplicate charges, or inability to fail over safely.
* P1: Required, Non-Blocking. Materially increases application risk, data risk, or customer impact during failure.
* P2: Improvement / Best Practice. Does not materially impact correctness but weakens resilience posture.
* P3: Non-Blocking Code Consistency. Maintainability, readability, duplication, or inconsistent patterns that are non-blocking.

## Service Exclusion Rule

* After Prompts 1a and 1b complete, dependencies classified only in Section 2 (Checked But Not Present) or Section 3 (Not Applicable) are dropped from scope
* Prompts 2-7, service-specific prompts (8-19), and the consolidation report analyze only dependencies confirmed in Section 1 of Prompt 1a or Prompt 1b
* In Phase 2, run only the service-specific prompts for dependencies found in either producer's Section 1

## Deliverable Templates

Use these templates as the expected output shape per prompt.

### Prompt 0 Deliverable Template

```text
# Prompt 0 Research Output

## Scope
- Repository and bounded focus area

## Observed Implementation Behavior
- Finding
  - Priority: P0 / P1 / P2 / P3
  - Evidence: <file path>:<line>
  - Existing mitigations: <if any, with evidence>
  - Constraints/limitations: <if any, with evidence>

## Application Flow
- Finding
  - Priority: P0 / P1 / P2 / P3
  - Evidence: <file path>:<line>
  - Existing mitigations: <if any, with evidence>

## Assumptions and Constraints
- Finding
  - Priority: P0 / P1 / P2 / P3
  - Evidence: <file path>:<line>
  - Constraints/limitations: <if any, with evidence>
```

### Prompt 1a Deliverable Template

```text
---
source-prompt: hve-resiliency-researcher-1a
schema-version: 1
status: current
---

## Section 1 - Used Azure Services (Evidence Confirmed)
- Service name:
- Azure service category:
- Evidence class: Explicit Use or Implicit Dependency
- Evidence (file path + line number):
- Brief description of how it is used:
- Region / failover sensitivity (Yes/No/Unclear + evidence-only rationale):

## Section 2 - Checked but Not Present
- Service / trigger name:
- Result: Bounded negative or Unconfirmed trigger
- Reason it was evaluated or trigger evidence (file path + line number):
- Checked scope and indicator families:
- Confirmation gap or terminal label:

## Section 3 - Not Applicable
- Service / Category name:
- Evidence (file path + line number):
- Reason it does not apply:
```

### Prompt 1b Deliverable Template

```text
---
source-prompt: hve-resiliency-researcher-1b
schema-version: 1
status: current
---

## Section 1 — Used External Dependencies (Evidence Confirmed)
- Service / Dependency name:
- Evidence (file path + line number):
- Brief description of how it is used:
- Whether it materially impacts region failover:
- Existing mitigations present (if any), with evidence:
- Health check present for this dependency?:
- How health is determined, with evidence:
- Is dependency health surfaced to GLB health evaluation?:
- What GLB probes or upstream probes hit, with evidence:
- Constraints/limitations (if any), with evidence:

## Section 2 — Checked but Not Present
- Service / Dependency name:
- Reason it was evaluated:
- Explicit statement: No references found in code, config, IaC, or pipelines

## Section 3 — Not Applicable
- Service / Category name:
- Reason it does not apply:
```

### Prompt 2 Deliverable Template

```text
# Prompt 2 Research Output

## Region Assumptions
- Assumption:
- Priority: P0 / P1 / P2 / P3
- Failover relevance (West US 2 to West US):
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence
- Constraints/limitations (if any): with evidence
```

### Prompt 3 Deliverable Template

```text
# Prompt 3 Research Output

## Dependency Survivability Findings
- Service:
- Priority: P0 / P1 / P2 / P3
- Region assumption in endpoint/credential/identity:
- Fallback or multi-region logic present:
- Health check present / health-to-GLB linkage:
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence
- Constraints/limitations (if any): with evidence
```

### Prompt 4 Deliverable Template

```text
# Prompt 4 Research Output

## State and Data Characteristics
- Characteristic:
- Priority: P0 / P1 / P2 / P3
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence
- Constraints/limitations (if any): with evidence

## Data Loss Potential (Facts Only)
- Where loss could occur:
- Failure condition (regional failover/partial outage):
- Writes/messages/records at risk:
- Priority: P0 / P1 / P2 / P3
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence

## Failover Risk Observations
- Observation:
- Priority: P0 / P1 / P2 / P3
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence
- Constraints/limitations (if any): with evidence
```

### Prompt 5 Deliverable Template

The Prompt 5 pipeline emits four outcome fragments plus a manifest sidecar, and finalize assembles them into a single artifact with four subsections. The Required Row Schema is defined in the [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md) and applies uniformly to every rendered row.

Outputs produced by the pipeline:

* Skeleton and final artifact: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-5-research.md`
* Manifest sidecar: `<researchRoot>/YYYY-MM-DD/<repo-name>-hve-resiliency-researcher-5-research.manifest.md`
* Fragments: `<researchRoot>/YYYY-MM-DD/prompt-5-fragments/{startup-failure,silent-degradation,data-loss-partial-processing,blocking-transactions}.md`
* Verify audit: `<researchRoot>/YYYY-MM-DD/prompt-5-fragments/verify-audit.md`

Row shape (each row is emitted with an outcome-scoped ID such as `F-5-startup-001`, `F-5-degradation-001`, `F-5-data-loss-001`, or `F-5-blocking-001`):

```text
### F-5-<outcome>-00X

- Failure mode:
- Priority: P0 / P1 / P2 / P3
- Triggering dependency + failure type (timeout / DNS failure / authentication failure / partial outage):
- Scenario: Between West US 2 and West US regional failover
- Code path / entrypoint:
- Observed behavior (startup failure / silent degradation / data loss or partial processing / blocking transactions):
- User or customer-visible impact:
- Business impact:
- Blast radius:
- Data loss potential:
- Data consistency risk:
- Detection signals:
- Existing mitigations present (evidence):
- Constraints or limitations (evidence):
- Manual ops workaround (references):
- Evidence citations (files + line numbers):
```

Finalized artifact structure (assembled by `/hve-resiliency-researcher-5-finalize`):

```text
# <repo-name> Failure and Degraded Mode Behavior (Researcher 5)

## Scope and Assumptions
## Task Implementation Requests
## 5.1 Startup Failure
## 5.2 Silent Functional Degradation
## 5.3 Data Loss or Partial Processing
## 5.4 Blocking Transactions
## Ledger and Terminal Outcomes
```

### Prompt 6 Deliverable Template

```text
# Prompt 6 Research Output

## Shared and Cross-Repository Dependencies
- Dependency:
- Priority: P0 / P1 / P2 / P3
- Ownership boundary or entrypoint:
- Evidence-backed causal chain of repository facts and deterministic code-semantics inferences:
- Regional failover risk implication:
- Evidence: <file path>:<line>
- Existing mitigations present (if any): with evidence
- Constraints/limitations (if any): with evidence
```

### Service-Specific Prompts (8-19) Deliverable Template

```text
# Prompt N Research Output — <Service Name>

(repeat per issue)
- Issue Description:
- Risk Level (P0/P1/P2/P3):
- Code location (file + line number):
- Why this is a risk to app, regional failover:
- Impact(s) if this is not changed:
- Existing mitigations present (evidence):
- Constraints/limitations (evidence):
- Remediation guidance: None (HVE Task Researcher role is evidence-only)
```

### Consolidated Report Deliverable Template

The consolidated report is produced by the split consolidation pipeline (scaffold, section-fill, verify, finalize). The Required Finding Schema for Sections 2.1 and 3-8 is defined in the [Consolidation Shared Contract](../../instructions/hve-resiliency-consolidation-shared.instructions.md); finalize reconciles section-scoped finding IDs into the authoritative `F-00X` scheme.

```text
# HVE Task Research - <repo-name>

Assessment Scope:

* Repository: <repo-name>
* Focus: Between West US 2 and West US regional failover
* Regions Evaluated: West US 2 to West US
* Assessment Date: YYYY-MM-DD
* Generated By: HVE Task Researcher
* Schema Version: hve-resiliency-consolidation/v1

## 1. Repository Context

## 2. Dependency Inventory
### 2.1 Used Dependencies (Evidence Found)
### 2.2 Checked but Not Present
### 2.3 Not Applicable Dependency Categories

## 3. Region Assumptions

## 4. State and Data Characteristics

## 5. Failure and Degraded-Mode Behavior

## 6. Shared and Cross-Repository Dependencies

## 7. Hard-Coded Values or Secrets in Code or Files

## 8. Other Findings Not Categorized Above

## 9. Research Findings Index (Authoritative)
```

Each rendered finding under Sections 2.1 and 3-8 uses the Required Finding Schema:

```text
### Finding F-00X

* Dependency or Category:
* Priority: P0 | P1 | P2 | P3
* Ownership:
- Scenario: Between West US 2 and West US regional failover
* Description:
* Failure Mode and Scenario-Specific Risk:
* Impacts:
* Evidence: <normalized-path>:L<start>-L<end>
* Source Record IDs:
* Existing Mitigations:
* Constraints and Limitations:
```

