---
description: Run Prompt 3 dependency survivability analysis for Application resiliency research
agent: Task Researcher
argument-hint: "prompt1a=... prompt1b=..."
---

# Application HVE Researcher 3

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

## Inputs

* `${input:prompt1a}`: Optional path to the completed Prompt 1a artifact for the current repository. If omitted, auto-discover from the inherited research location.
* `${input:prompt1b}`: Optional path to the completed Prompt 1b artifact for the current repository. If omitted, auto-discover from the inherited research location.

## Execution Precedence

This direct Prompt 3 contract overrides conflicting inherited Task Researcher, skill, and platform workflow behavior. Retain inherited artifact location, repository-prefix naming, file-line evidence, and P0-P3 definitions where they do not conflict with this contract.

Run only Prompt 3 evidence collection. Do not restart at Prompt 0 or run later research, planning, remediation, or implementation phases. Do not provide recommendations, alternatives, selected approaches, code examples, implementation guidance, or actionable next steps. Delegation is optional and bounded by this contract; a delegated action consumes the same counters as a parent action and cannot start another workflow.

## Eligibility Gate

Resolve each prerequisite in this order and prefer proceeding over blocking:

1. If `${input:prompt1a}` or `${input:prompt1b}` is supplied, use it. Read each supplied path exactly once.
2. If either input is not supplied, auto-discover the corresponding artifact from the inherited research location using the repository-prefixed naming convention. Use it when exactly one candidate qualifies.
3. Do not infer, reconstruct, or substitute the prerequisite inventory from arbitrary repository contents beyond the auto-discovery step above.

Build the eligible-dependency inventory from Section 1 of whichever qualifying artifacts are available; ignore Sections 2 and 3. If only one of Prompt 1a or Prompt 1b qualifies, proceed with the Section 1 inventory from the qualifying artifact and record the missing side as an `Unknown: external evidence required` entry at the report level. If Section 1 exists but a subset of its entries is ambiguous, use the unambiguous subset and record each ambiguous entry the same way; do not block.

Emit `Blocked: missing prerequisite or ineligible` only when neither Prompt 1a nor Prompt 1b can be resolved (both supplied paths unreadable or belong to another repository, and auto-discovery yields zero qualifying candidates for both). Include the supplied paths and the auto-discovery search scope in the reason, then stop before repository or production discovery.

If both prerequisites resolve but the combined Section 1 inventory contains zero dependencies eligible for Prompt 3, do not block; emit `Complete: bounded no evidence` with a single note that no eligible dependency was in scope, and list the resolved prerequisite paths.

## Prerequisite Evidence Admissibility

The prerequisite inventory constraint above governs which dependencies are eligible. It does not restrict which evidence Prompt 3 may cite.

A file-and-line citation already recorded in Prompt 1a `Section 1` or Prompt 1b `Section 1` is admissible Prompt 3 evidence without re-derivation. Carry the citation forward verbatim, restate its normalized repository-relative path and line in the Prompt 3 finding row, and attribute it to the originating prerequisite artifact. Reading the prerequisite artifacts consumes no per-dependency allowance.

This applies in particular to the Prompt 1b `Section 1` fields that answer Prompt 3 schema fields directly: existing mitigations, health check present, how health is determined, whether dependency health is surfaced to GLB health evaluation, what GLB probes hit, and constraints or limitations. Do not spend per-dependency allowances rediscovering a value the prerequisite artifact already carries with evidence.

Re-verify a carried-forward citation only when it is internally contradictory, cites a path that does not resolve, or is required for a scenario the prerequisite did not evaluate. Re-verification is optional and consumes the dependency's allowances when performed. A carried-forward citation that cannot be re-verified is recorded as an Unknown; it is never converted into a negative finding.

## Assessment Scope

Analyze each eligible Azure and non-Azure dependency used by this repository for survivability during both scenarios:

* Full regional failover between West US 2 and West US

Determine from code or configuration whether endpoints, credentials, or identities assume a single region and whether fallback or multi-region logic exists. For each Azure dependency, verify whether the application implements a dependency health check and reflects that health state in readiness or health endpoints that drive GLB routing decisions.

Do not add assessment areas beyond dependency survivability, regional assumptions, fallback or multi-region behavior, existing mitigations, constraints, and Azure dependency health-to-GLB linkage.

## Discovery Limits

Default to repository-only discovery. Initialize the prompt round counter and every per-dependency counter once. Counters are cumulative and never reset by round, source, dependency criterion, alias, environment, or delegation.

The entire prompt has at most two rounds:

1. Round 1 runs the repository survey pass, then performs initial bounded per-dependency discovery for all eligible dependencies and both failure modes.
2. Round 2 uses remaining counters only to close unresolved criteria identified in Round 1.

After Round 2, stop all discovery. Classify each still-unresolved criterion using the Unknown Vocabulary and Outcome Effects section below.

### Repository Survey Pass

Run exactly one repository survey pass at the start of Round 1, before any per-dependency action. The survey pass is prompt-wide and consumes no per-dependency allowance.

Build one path-only manifest of production application source, configuration, infrastructure as code, deployment manifests, and pipeline definitions. Exclude `.git/**`, `.copilot-tracking/**`, generated outputs, caches, binaries, vendored dependencies, and prompt artifacts.

Across that manifest, run one broad multi-pattern scan covering every eligible dependency identity and alias together with the survivability signal families in the Assessment Scope: endpoint, host, and connection targets; region identifiers; credential and identity bindings; retry, timeout, circuit-breaker, and fallback constructs; multi-region or failover selection logic; health check registration; and readiness or liveness probe definitions. One scan may bundle multiple expressions in one tool invocation or one local scanner pass. Result pagination and refinement of a truncated query belong to this single pass and do not make it a second pass.

Record the survey results as a candidate ledger holding only a stable candidate ID, canonical path, line range, matched signal family, and the dependency it binds to. Do not open files during the survey pass; the pass locates evidence, it does not read it.

The survey pass runs once and is never repeated. If a manifest cannot be built at all, stop with `Blocked: missing prerequisite or ineligible` naming the failure. Truncated or partial scan coverage does not force a block; record the shortfall as a limitation, list the affected scope, and proceed with per-dependency discovery on the coverage that was achieved.

### Per-Dependency Allowances

Per-dependency allowances fund confirmation and traversal of survey candidates and carried-forward prerequisite citations. They do not fund broad discovery, which the survey pass already performed.

Each dependency has one cumulative allowance shared across parent and delegated work and across repository and approved production sources:

* Four searches
* Six smallest-relevant-range reads
* Four traversal hops
* Two focused follow-ups

For each Azure dependency, the health-to-GLB linkage sub-check has an additional isolated allowance of one search and two reads that cannot be spent on other criteria.

A search is one tool invocation containing one search expression. A read is one opening of the smallest relevant file range; rereading counts again. A hop follows one evidenced reference from the current source to a directly related owner, caller, callee, configuration include, or runtime source. A focused follow-up is one targeted action for one unresolved criterion; it draws from its own allowance and does not additionally consume a search, read, or hop. Glob expansion and result pagination do not grant additional actions.

Before delegation, pass the dependency's remaining allowances and current round. Merge consumed actions into the same ledger when delegation returns. Stop work on a dependency when a required action allowance is exhausted; do not substitute another action type to bypass a limit.

## Production Discovery Contract

Production discovery is prohibited by default. Permit it only when the invocation supplies all of the following:

* Named production source
* Explicit approval to access that source
* Read-only access method
* Query limit
* Result limit
* Time window
* Follow-up limit

Supplied limits can narrow but cannot expand the prompt-wide or per-dependency allowances. Every production query, read, hop, or follow-up consumes the same `4/6/4/2` dependency allowances used for repository discovery.

If production discovery is requested and approval is denied or any contract element is missing, make no production call. Emit `Blocked: production discovery contract denied or incomplete` with the missing or denied elements, then stop. Repository evidence never implies production approval.

## Evidence And Finding Controls

* Support every positive or negative finding claim with causal repository or approved production evidence, or with a citation carried forward under Prerequisite Evidence Admissibility. Repository citations include file path and line number. Production citations identify the approved source, bounded query or record reference, and time window without exposing secrets.
* Absence of evidence is not evidence of absence. When bounded sources are exhausted, place each unresolved existing criterion in the report-level Unknown summary and do not fabricate a citation or finding.
* Emit a finding row only for an evidenced dependency and failure-mode pair. Use distinct rows for distinct pairs. Do not merge findings for different dependencies, failure modes, or criteria.
* Keep report status, Unknown summaries, checked-without-finding dependencies, source limitations, counters, and blocked or non-finding states outside repeated finding rows. Never create a synthetic finding row for an Unknown or terminal state.
* Record required usage information only in the existing usage field. In the existing material-impact field, record Yes or No, one P0-P3 classification, and the evidence-backed impact rationale exactly once. Do not duplicate impact prose elsewhere in the row.
* Use only evidenced values in finding rows. For optional mitigation or constraint details not established within the allowance, state that no value was evidenced within bounded discovery without claiming that none exists, and list the unresolved criterion in the report-level Unknown summary.
* Record missing health-to-GLB linkage as a finding only when evidence establishes the missing linkage. Otherwise, keep the criterion as a report-level Unknown.

## Unknown Vocabulary and Outcome Effects

Record every unresolved criterion in the report-level Unknown summary using exactly one of these three forms and no other wording:

* `Unknown: not found after bounded search <scope>`: the survey pass and the dependency's allowances completed without locating evidence for the criterion. Name the scanned scope. Downgrades the outcome to `Partial: exhausted with Unknowns` when the criterion is resiliency-material.
* `Unknown: external evidence required <named evidence gap>`: the criterion's value is established only by a source outside this repository. Name the specific source, for example a centralized configuration service, an external deployment repository, or a runtime environment value with no repository-side default. Where the source is a packaged internal artifact, use the `platform library:` qualifier defined under Platform Library Dependencies instead of a bare source name. Does not downgrade the outcome.
* `Unknown: two-round prompt budget exhausted`: Round 2 ended with the criterion unresolved because an allowance was exhausted. Downgrades the outcome to `Partial: exhausted with Unknowns` when the criterion is resiliency-material.

Every Unknown entry carries dependency, failure mode, criterion, source scope, and the selected form. Do not invent, abbreviate, merge, or paraphrase these forms. Do not apply a single form uniformly across unrelated criteria.

Unresolved items outside the Assessment Scope (for example licensing, cost, unrelated feature flags) are not Unknowns. Drop them from the report entirely; do not record them under any of the three forms.

An Unknown requires that work was attempted. Do not record an Unknown for a dependency that has no consumed action in its ledger and no carried-forward prerequisite citation; such a dependency has not been assessed, and the report is not eligible for a `Partial` outcome while it remains unassessed.

When identity, failure-mode pair, and at least one causal citation are established for a resiliency-material concern but the impact severity, mitigation, or constraint context cannot be fully evidenced within the allowance, still emit the finding row rather than dropping to Unknown-only. Cap the row's priority at P2, tag the material-impact field with `partial evidence: <missing element>` before the rationale, and record the missing element in the report-level Unknown summary using one of the three forms above. A finding may be downgraded this way only once and never to below P3.

## Platform Library Dependencies

A platform library dependency is a versioned internal artifact that is declared in a repository build manifest, consumed by production code in this repository, and supplies behaviour inside the Assessment Scope - retry, timeout, backoff, client construction, endpoint or connection selection, or failover logic - where no repository-side override is evidenced.

Do not record a platform library dependency solely as a report-level Unknown. Its control location is established by repository evidence even when its values are not. Emit a finding under the Repeated Finding Schema built from the evidenced facts:

* The declaring build manifest coordinate and version, cited to file and line.
* Every production injection, construction, or call site in this repository, cited to file and line.
* The configuration sources checked for a repository-side override, and the cited negative establishing that none sets the relevant values.

State the material impact in terms of control location rather than value: the cited criterion is determined by an artifact this repository does not own, cannot change without an upstream release, and whose effective values are not visible from repository evidence at deploy time. Classify the priority from that control-location effect and the criticality of the affected dependency path.

Attach the unresolved values to that finding, and mirror them in the report-level Unknown summary, using exactly:

`Unknown: external evidence required <platform library: <groupId>:<artifactId>:<version> - <symbol>>`

The `platform library:` qualifier is required so these entries can be separated from infrastructure and platform-service gaps and aggregated across services that share the artifact.

Never state, infer, or estimate a packaged value. Never read, unpack, decompile, disassemble, or traverse into a packaged artifact, and never admit one to the survey manifest. A platform library dependency is established from repository evidence only.

## Repeated Finding Schema

For each finding include these fields exactly once and in this order. Do not add, remove, rename, or reorder fields:

* Evidence (file path + line number)
* Brief description of how it is used
* Whether it materially impacts regional failover (Yes/No + description of why this could impact regional failover)
* Existing mitigations present (if any): retries/timeouts/fallbacks/multi-region selection/failover logic, with evidence (file path + line number)
* Constraints/limitations (if any): dependency/platform capabilities or configuration/operational constraints that shape failover behavior, with evidence (file path + line number) when present
* For each Azure service dependency, explicitly verify whether the application implements a health check for that dependency and whether the resulting health state is reflected in the service's readiness/health endpoints that drive GLB routing decisions (cite file + line evidence). If no health-to-GLB linkage exists, record that as a finding with evidence.

## Report-Level Outcomes

Use exactly one outcome from this closed set. Apply the first matching outcome in precedence order and stop immediately when it becomes terminal:

1. `Blocked: missing prerequisite or ineligible`: The eligibility gate fails per the Eligibility Gate section, or the survey pass cannot build a manifest at all. Perform no further discovery.
2. `Blocked: production discovery contract denied or incomplete`: Production discovery was requested but its contract is denied or incomplete. Perform no production call.
3. `Partial: exhausted with Unknowns`: At least one downgrading Unknown (`Unknown: not found after bounded search <scope>` or `Unknown: two-round prompt budget exhausted`) on a resiliency-material criterion remains after source, action, or two-round exhaustion. `Unknown: external evidence required` entries do not select this outcome. Requires that the survey pass completed and that every dependency carrying an Unknown shows at least one consumed action or one carried-forward prerequisite citation in its ledger.
4. `Complete: bounded no evidence`: No downgrading Unknown remains, no finding qualifies, and all checked-without-finding dependencies are listed. `Unknown: external evidence required` entries may be present in the summary. This outcome does not assert that unsearched evidence or runtime behavior is absent.
5. `Complete: findings`: No downgrading Unknown remains and at least one evidenced finding row qualifies. `Unknown: external evidence required` entries may be present in the summary.

Before any finding rows, report the selected outcome, assessed scenarios, source limitations, the survey pass manifest scope and candidate count, per-dependency `search/read/hop/follow-up` counters, the count of carried-forward prerequisite citations, the platform library dependency count and the artifacts involved, round count, Unknown summary or `None`, and checked-without-finding dependencies or `None`. For blocked outcomes, emit only this report-level envelope and no finding rows.

Return only the inherited research artifact path, selected outcome, and limitations. Add no workflow continuation or next-step suggestion.

---

Execute this Prompt 3 contract to its first terminal report-level outcome.