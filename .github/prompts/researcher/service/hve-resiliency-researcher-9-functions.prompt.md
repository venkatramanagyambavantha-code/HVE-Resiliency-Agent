---
description: Run Prompt 9 Azure Functions resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 9 Azure Functions

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Define the required regional-failover expectations for
{customerName} Azure Functions in West US 2 and West US. Assess only Azure
Functions behavior and requirements that directly affect regional failover.

## Functions Requirements

* Deployment follows an active-active model across West US 2 and West US
* Both regions continuously serve production traffic
* Each region can handle 100% of peak load during a regional outage
* Azure Front Door provides global traffic management
* Automatic failover uses health probes
* Health probes validate functional readiness of critical downstream
  dependencies, including storage, Key Vault, and messaging, rather than only
  HTTP reachability

## Bounded Evidence Protocol

Apply this protocol only to dependencies confirmed by the inherited service
exclusion rule.

1. For each confirmed dependency, use at most two repository searches, three
  file reads, two repository traversal hops, and one follow-up discovery
  action. Counters begin at zero, increase after each action, and never reset,
  including across repeated research or subagent calls. Limit each read to the
  smallest relevant line range; read a whole file only when that range cannot
  answer the research question.
2. Use at most two research rounds for this prompt. Round 1 begins with the
  first dependency discovery action. The first follow-up action closes round 1
  and starts round 2; increment the prompt round counter exactly once at that
  transition. Never reset it across dependencies, repeated research, or
  subagent calls.
3. Stop work on a research question at the first terminal outcome: cited
  evidence found; `Unknown` after its bounded repository sources are
  exhausted; not applicable under the service exclusion rule; or blocked by
  a named external evidence gap.
4. Source exhaustion occurs when the applicable numeric budget is consumed or
  all search results within that budget have been read. Do not broaden the
  query, revisit a source, start another traversal, or reset a counter after
  source exhaustion.
5. Stop discovery and produce the output when every research question has a
  terminal outcome or the two-round limit is reached. Do not repeat research
  to improve confidence after a terminal outcome. Do not include discovery
  narration or duplicate the same evidence within a row.
6. Before accepting or consolidating a delegated terminal outcome or finding,
  verify from already-read evidence that each cited file exists, each cited
  range lies within lines actually read, and the dependency remains eligible
  under inherited Prompt 1 exclusions. Reject or correct invalid delegated
  content without consuming another search, read, traversal hop, follow-up, or
  round. Preserve the immutable raw violation and correction in the action
  ledger.

Use `Unknown` only when bounded evidence is unavailable. For an existing field
that requires evidence, write `Unknown` followed by the exhausted source class
or named external evidence gap. Never invent a file, line number, mitigation,
constraint, impact, or risk rationale. Findings still require file-and-line
evidence; an `Unknown` outcome alone does not establish a finding.

Create a separate row for each independently actionable failure mode. Assign a
stable `Failure Mode ID` derived from the dependency and failure mode, and reuse
that ID for the same failure mode across repeated runs. Do not merge failure
modes because they share a dependency, file, or risk level.

The evidence-only rules override inherited requests for remediation,
code or configuration examples, alternatives, a selected approach, and
implementation next steps. Do not provide any of them.

## Output Format

Limit the authoritative final research artifact to a concise scope summary,
terminal-outcome summary, and the canonical finding rows below. Keep search,
read, tool-call, counter, file-analysis, and discovery narration only in
execution logs or delegated artifacts.

Repeat for each finding:

* Failure Mode ID:
* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app regional failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None (HVE Task Researcher role is evidence-only)
