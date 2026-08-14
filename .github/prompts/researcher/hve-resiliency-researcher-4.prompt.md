---
description: Research Prompt 4 state, data, and consistency characteristics for Application Platform resiliency
agent: Task Researcher
---

# Application HVE Researcher 4

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

## Direct Invocation And Prerequisite

* Run Prompt 4 only. Do not run or reconstruct any earlier prompt.
* For each applicable Prompt 1a or Prompt 1b source, require exactly one eligible research artifact with the inherited research location, matching prompt identity, and a Section 1 confirmed-dependency inventory. An explicitly superseded artifact is stale; age alone is not.
* Use only dependencies confirmed in those Section 1 inventories that are relevant to state and data management. If an applicable inventory is missing or has multiple eligible artifacts, name the missing or ambiguous prerequisite and stop before repository traversal. Do not use fallback discovery or analyze excluded dependencies.

## Task Researcher Boundary

* Execute evidence-only Task Researcher Phase 1. Do not enter Phase 2 or provide alternatives, recommendations, selected approaches, implementation steps, remediation, code examples, configuration examples, or next-step suggestions.
* Repository file-line evidence, inherited platform output location and naming, P0-P3 classifications, and this Prompt 4 schema override conflicting delegated-agent behavior.
* Use repository evidence only. State each substantive claim as a repository fact or deterministic code-semantics inference. Cite every causal step for an inference and leave unsupported runtime outcomes unknown.

## Assessment Scope

Analyze only these existing state and data areas:

* Read and write regions
* Preferred locations
* Caching behavior
* Event ordering
* Idempotency or its absence
* Facts-only data-loss potential: where loss could occur, the zone-loss, regional-failover, or partial-dependency-outage condition, and the writes, messages, or records at risk
* Existing mitigations already present, including idempotency guards, retry or timeout policies, fallback logic, and feature flags
* Constraints or limitations that affect correctness during zone or regional failure, including consistency models, replication lag, write restrictions, and operational failover steps
* Risks that could surface during zone or regional failover

Do not add an assessment topic. Cite repository file-lines for every known characteristic, causal behavior, mitigation, constraint, limitation, and failover-risk claim.

## Bounded Discovery

* Apply all limits cumulatively per confirmed dependency. Aliases, environments, wording, questions, repeated research, and subagent calls cannot reset or transfer a counter.
* Reuse one ownership traversal and its citations across the three output sections. Do not repeat traversal by field or section.
* Start with at most 2 high-signal production owner queries. Each query result is an ownership surface. Allow at most 1 refinement per query, and only when its result is capped or truncated; display at most 20 matches per ownership surface.
* Read at most 5 candidate owner files, then follow at most 2 direct production-call hops from an entrypoint or owner.
* Exclude tests, fixtures, samples, generated output, documentation, and local-only configuration unless cited production evidence points to them.
* After ownership traversal, allow at most 1 negative check per unresolved `Unknown`-eligible field and 1 scoped corrective search for 1 concrete missed production path identified by the ledger.
* Treat every reached numeric limit as source exhaustion. Do not broaden, reword, or repeat that discovery route afterward.

## Terminal Outcomes And Finding Rows

* Give each confirmed dependency and existing Prompt 4 field one ledger outcome: cited repository evidence, exactly `Unknown: not found after bounded search <scope>` after the applicable search is exhausted, or `Unknown` naming a specific external evidence gap. Do not search external sources.
* Use `Unknown` only inside an existing descriptive field. Never replace `Priority: P0 / P1 / P2 / P3`, add a field or section, infer runtime absence from missing repository evidence, or create a finding solely from absence.
* Emit a row only when positive repository evidence establishes its dependency and production owner, entrypoint, or path. Use unknown outcomes only to complete eligible descriptive fields in that established row; keep ledger-only absences out of the output.
* Keep independently actionable outcomes or priorities in distinct rows and retain every causal citation. Encode stable identity without adding fields:
  * State and Data Characteristics: dependency + characteristic category + production owner or entrypoint + observed characteristic in `Characteristic`
  * Data Loss Potential: dependency + failure condition + production owner or path + writes, messages, or records at risk across the first three fields
  * Failover Risk Observations: dependency + failure condition + production owner or entrypoint + observed risk in `Observation`
* Stop repository traversal when every existing field has a terminal ledger outcome. Complete one repository-free ledger review and stop when it adds nothing.

## Output Schema

Write exactly these three sections, labels, and order. Add no field or section. Repeat a section's field set only for distinct stable rows.

1. `State and Data Characteristics`
	* `Characteristic:`
	* `Priority: P0 / P1 / P2 / P3`
	* `Evidence: <file path>:<line>`
	* `Existing mitigations present (if any): with evidence`
	* `Constraints/limitations (if any): with evidence`
2. `Data Loss Potential (Facts Only)`
	* `Where loss could occur:`
	* `Failure condition (zone loss/regional failover/partial outage):`
	* `Writes/messages/records at risk:`
	* `Priority: P0 / P1 / P2 / P3`
	* `Evidence: <file path>:<line>`
	* `Existing mitigations present (if any): with evidence`
3. `Failover Risk Observations`
	* `Observation:`
	* `Priority: P0 / P1 / P2 / P3`
	* `Evidence: <file path>:<line>`
	* `Existing mitigations present (if any): with evidence`
	* `Constraints/limitations (if any): with evidence`
