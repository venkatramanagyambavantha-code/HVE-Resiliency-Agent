---
description: Establish bounded repository context for application resiliency research
agent: Task Researcher
---

# Application Resiliency Researcher 0 Optimized

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md) as the sole authority for failure scenarios, priorities, evidence-only and no-remediation boundaries, file-line citations, and artifact location.

## Objective

Establish the repository context frame: architecture, application flow, observed behavior, assumptions, constraints, mitigations, and each evidence-backed resiliency risk, rationale, and impact.

## Bounded Execution

Keep compact root, transition, boundary, owner, finding, and evidence-gap ledgers. Capture citations on first read.

* Run one inventory pass over production source, build, configuration, and deployment paths, then one production-root discovery pass for startup, HTTP, message, event, and background roots.
* Trace at most four application-owned transitions per flow. Stop at a boundary, repeated owner, third-party implementation, repository exit, or evidence gap.
* Analyze every shared owner, helper, configuration source, and boundary once; reuse its evidence across flows and assess its degraded behavior and controls.
* Give an unresolved symbol or artifact at most two exact checks. Record the question and checks in the evidence-gap ledger, then stop that branch.
* After coverage evaluation, allow at most one corrective scoped search for the uncovered production path or root family. Never restart broad discovery.

Merge only identical risk mechanisms with the same owner, failure scenario, and impact. Preserve affected flows and evidence. Impose no finding count or priority quota; retain every distinct evidence-backed finding and limit only repetition.

## Completion Criteria

Stop after all roots resolve to boundaries or evidence gaps, every boundary is assessed, every finding is complete, and one full queue pass adds no new root, boundary, transition, owner, or risk mechanism. Two recorded exact checks complete an unresolved branch.

## Output Contract

Use this section order:

1. Scope
2. High-Level Architecture
3. Application Flow
4. Observed Implementation Behavior
5. Assumptions and Constraints

Use one concise entry per unique component, boundary, or flow family. Put the evidence-gap ledger in Assumptions and Constraints. Each substantive finding includes:

* Priority and rationale
* Observed behavior
* Risk and failover impact
* Existing mitigations, with evidence when present
* Constraints or limitations, with evidence when present
* File and line-level evidence
