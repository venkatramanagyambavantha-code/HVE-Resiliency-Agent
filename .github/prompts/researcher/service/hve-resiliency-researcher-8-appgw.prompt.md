---
description: Assess repository evidence for Application Gateway regional resiliency
---

# Application HVE Researcher 8 App Gateway

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Run Prompt 8 only. Do not invoke earlier workflow prompts or another agent.

## Scope

Assess Application Gateway for regional loss of West US 2 or West US;
regional/global routing; scaling, capacity, probes, backend
health, WAF, policy, DNS, configuration, endpoints, direct DNS/IP dependencies,
retries/timeouts/exponential backoff, application state, backend failover scaling, cold starts,
region-local certificate/secret sourcing, cross-region dependencies, and impacts.

Evidence only; cite causal file-lines; absence is no proof. No remediation,
recommendations, alternatives, or code examples.

## Required Steps

### Step 1: Validate Prerequisites

1. In inherited `.copilot-tracking/research/`, require one Prompt 1a and 1b.
1. Qualify only frontmatter with exact `source-prompt`
   `hve-resiliency-researcher-1a` or `hve-resiliency-researcher-1b`, plus
   `schema-version: 1`, `status: current`, and the matching body heading:
   `## Section 1 - Used Azure Services (Evidence Confirmed)` for Prompt 1a or
   `## Section 1 — Used External Dependencies (Evidence Confirmed)` for Prompt 1b.
   Frontmatter controls identity/status.
1. Other counts are Blocked. Read only both Section 1 bodies. Absent Application
   Gateway/App Gateway is Not Applicable. Stop before traversal.

### Step 2: Discover Production Evidence

One non-resetting budget: maximum two initial queries plus one replacement
refinement per capped/truncated query, maximum four query invocations total;
20 matches per deduplicated ownership surface; five new owner/configuration/region
reads; two cited configuration/include/call hops; one negative check per eligible
Unknown. Refinement replaces displayed results but increments queries. Spend one
unused query on one ledger path or waive it.

Count invocation/expression/category as query, results as surface, opened
file/region as read, followed cited edge as hop. Record all. Exclude tests,
fixtures, samples, generated output, docs, local config, prompts, tracking, and
prior research unless production evidence leads there.

### Step 3: Assess Scenarios

For each Scope concern, classify topology `Confirmed`,
`Contradicted`, or `Unknown`; never assume it. Identify rows by concern, owner,
failure scenario, and outcome; split differing outcomes/priorities. Emit only
with identity, behavior, inherited P0-P3, and causal file-line evidence.

Use `Unknown: not found after bounded search <scope>` only for optional impacts,
mitigations, constraints, topology, health/probes, and values; never identity,
behavior, priority, or evidence.

### Step 4: Stop And Write

Stop when fields exist or no row qualifies, optional fields are evidenced/bounded
Unknown, branches resolve, and ledger query is used/waived. After one tool-free
empty ledger review, write inherited
`.copilot-tracking/research/<repo-name>-prompt-8-appgw-research-output.md`; a
supplied sandbox-local path overrides it.

## Output Schemas

Prepend to every body:

```yaml
---
title: Prompt 8 App Gateway Research Output
description: Evidence-only App Gateway resiliency research result
---
```

### Completed

Completed summary:

* Status: Completed
* Searched scope: <production ownership surfaces checked>
* Exclusions: <excluded paths or categories>
* Counters: <queries, surfaces, reads, hops, and negative checks>
* Negative checks: <scopes and outcomes or None>
* Finding count: <count>
* Limitations: <evidence limits or None>

Repeat per finding:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app regional failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None

Omit rows when count is zero.

### Blocked

Body:

* Status: Blocked
* Prerequisite count: Prompt 1a=<count>; Prompt 1b=<count>
* Candidates: <paths or None>
* Repository traversal: Not started
* Limitations: <invalid, missing, duplicate, or non-current metadata>
* Next step: <inherited prerequisite correction or rerun step>

### Not Applicable

Body:

* Status: Not Applicable
* Applicability count: 0
* Applicability evidence: <Prompt 1a and Prompt 1b Section 1 citations>
* Repository traversal: Not started
* Limitations: Application Gateway was not confirmed in qualifying Section 1 artifacts
* Next step: <inherited next applicable service prompt or consolidation step>

## Final Response

Return once:

* Artifact: <path>
* Status: <Blocked, Not Applicable, or Completed>
* Finding count: <count>
* Counters: <Completed discovery counters; or prerequisite/applicability counts plus queries=0, reads=0, hops=0>
* Limitations: <limitations or None>

> **Next step:** <inherited clickable next step>

Add nothing else.

---

Proceed with Prompt 8 App Gateway following the Required Steps.