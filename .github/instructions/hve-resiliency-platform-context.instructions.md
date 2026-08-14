---
description: Application Platform context and evidence-only rules for resiliency research prompts
applyTo: '.github/prompts/researcher/hve-resiliency-researcher-*.prompt.md, .github/prompts/researcher/service/hve-resiliency-researcher-*.prompt.md'
---

# Application Platform Context

Apply this context to all Application Platform resiliency research prompts.

* Albertsons operates applications in Azure
* Validating readiness for full application regional failover between West US 2 and West US
* Scope is the current repository within the Application Platform
* HVE Task Researcher rules: evidence only, no remediation, no code examples
* All findings must cite file and line-level evidence
* Never paraphrase referenced code. If a finding quotes or describes code, copy it verbatim from the source file and confirm the cited path and line numbers match that file exactly
* Classify every finding using the priority framework: P0 (Blocking/Critical), P1 (High Priority), P2 (Improvement/Best Practice), P3 (Non-Blocking Code Consistency)
* Output research artifacts to `.copilot-tracking/research/` and use the repository name as the prefix for all output files (e.g., `<repo-name>-research-output.md`).

## Status and Failure Semantics

Status is reported on three independent axes. Never collapse them into a single value and never emit a value outside these closed lists. This section is never overridden by a prompt's stage-specific rules.

| Axis                 | Values                                                         | Reported by                                 |
|----------------------|----------------------------------------------------------------|---------------------------------------------|
| Run status           | `Complete`, `Incomplete`, `Blocked`                             | Every prompt, exactly once                  |
| Run disposition      | `Findings`, `No Findings`, `Not Applicable`, `Bounded Partial`  | Every prompt whose run status is `Complete` |
| Verification verdict | `Verified`, `Manual Review Required`                            | Verify prompts only                         |

Emit them as literal lines: `Run Status: <value>`, `Disposition: <value>`, and for verify prompts `Verdict: <value>`.

### Run Status

Run status is the only value the orchestrator gates on, and it is compared by exact string equality. Use the exact casing above. `Completed`, `COMPLETE`, `blocked-prerequisite`, and suffixed forms such as `Complete - Findings` or `Complete with no evidence` are invalid; the qualifier belongs in the disposition.

* `Complete`: this prompt finished its own stage and wrote its own output. Always accompanied by a disposition.
* `Incomplete`: this prompt could not finish its own stage and its output must not be consumed downstream. State the reason in one line. Reserve this for a defect in the run itself, never for what the repository contains.
* `Blocked`: broken pipeline only, as defined below.

A prompt sets only its own run status. It never sets the status of another stage or of the pipeline as a whole.

### Run Disposition

Disposition records what a completed run produced. It carries no failure meaning and never affects the orchestrator gate.

* `Findings`: the stage ran and produced at least one finding or row.
* `No Findings`: the stage ran to completion across its full scope and found nothing to record. This is a successful result.
* `Not Applicable`: the stage was correctly skipped because its subject is out of scope for this repository, most often a service prompt whose dependency was classified as absent in Prompt 1a or 1b Section 2 or 3. No traversal is performed and no findings are rendered.
* `Bounded Partial`: the stage stopped at a declared traversal, budget, or tool bound with usable output. Name the bound and what was left uncovered. `Bounded Partial` output is authorized to hand off downstream; `Incomplete` output is not. When choosing between the two, ask whether the next stage can safely consume the output: if it can, the run is `Complete` / `Bounded Partial`.

### Verification Verdict

Verify prompts report a verdict in addition to their own run status. A verify prompt that finishes its audit is `Complete` no matter what it found; the verdict, not the status, carries the audit result.

* `Verified`: every audited record passed every check.
* `Manual Review Required`: at least one audited record carries a non-`ok` disposition. List them. The orchestrator halts the pipeline on this verdict.

### Repository and Content Conditions Are Findings, Never Failures

Anything learned by scanning the repository under assessment is recorded in-band and the run continues. Never stop `Blocked` and never mark the run `Incomplete` for any of these:

* Ambiguous, contradictory, or unprovable evidence in the repository: render the affected field or finding with the schema's `Unknown` / `Unknown: evidence unavailable` value and continue. An `Unknown` value anywhere in the output never demotes run status.
* A dependency, service, or file that is out of scope or owned by another repository: record it as an out-of-scope finding that names the boundary and, where useful, notes that the owning repository should verify it. Do not issue instructions to that other repository beyond that suggestion.
* Source content that cannot be safely rendered (for example a secret value): sanitize and keep the finding using only its safe location metadata. Never block for unsafe content.
* No evidence found for an in-scope check: record the schema's negative value (`Not observed`, `None found`, or `Not Applicable`) and report `Complete` / `No Findings`. Absence of evidence is a valid completed result.
* A search tool that is unavailable, a query that returns nothing usable, or read access denied for part of the scope: cover what is reachable, name the bound, and report `Complete` / `Bounded Partial`.
* A dependency the operator has not authorized for deeper inspection: assess what the repository shows, name the limit, and report `Complete` / `Bounded Partial`.

### The Only `Blocked` Condition Is a Broken Pipeline

Stop `Blocked` only when a required input produced by a prior pipeline step (a prerequisite artifact or frozen manifest) is genuinely absent, unreadable, or structurally invalid, meaning a prior step failed or the steps ran out of order. The orchestrator gates each step on the prior step returning `Complete`, so in a correctly orchestrated run this state cannot occur; when it does it is a pipeline defect, not a property of the repository. Stop with a single message of the form `prerequisite from a prior step is missing or invalid - rerun <the producing step>`, and never synthesize the missing input. Do not use `Blocked` as a graceful branch for repository content, tool availability, evidence ambiguity, or authorization limits, and do not enumerate content-based block reasons.

A prerequisite artifact that is present and readable satisfies this condition. Do not block on the artifact's own recorded status value.

## Platform-Managed Regional Failover

* Albertsons uses platform-managed regional failover
* For external traffic, Akamai performs global load balancing and redirects traffic to healthy regions during regional outages
* Imperva provides WAF, DDoS protection, and security inspection but is not responsible for regional failover decisions
* For Layer 4 traffic, F5 BIG-IP DNS provides DNS-based regional failover by directing clients to healthy regional endpoints
* Do not generate findings for missing application-level load balancing or traffic routing logic; assume the platform redirects traffic to a healthy region
* Focus resiliency assessments on whether the application can operate successfully in the secondary region after failover, including deployment parity, configuration synchronization, dependency availability, data replication, state management, and regional capacity

## Priority Definitions

* P0: Critical / Blocking. Causes outage, data loss, duplicate charges, or inability to fail over safely during zone or regional failure.
* P1: Required, Non-Blocking. Does not fully block failover but materially increases application risk, data risk, or customer impact during failure.
* P2: Improvement / Best Practice. Does not materially impact correctness during failover but weakens resilience posture or operational clarity.
* P3: Non-Blocking Code Consistency. Captures maintainability, readability, duplication, or inconsistent pattern issues that are non-blocking.

## Service Exclusion Rule

* After Prompts 1a and 1b complete, dependencies classified in Section 2 (Checked But Not Present) and Section 3 (Not Applicable) are excluded from analysis in Prompts 2-7 and service-specific prompts (8-19)
* Prompts 2-7 and service-specific prompts (8-19) analyze only dependencies confirmed as used in Section 1 of the Prompt 1a and 1b outputs

## Database-to-Kafka Pairing Standard

* Kafka runs on Confluent Cloud (managed). Treat Confluent Cloud as the confirmed Kafka platform for both topologies; never ask the operator which Kafka provider, product, or environment is in use.
* Databases that support Active-Active multi-master writes (for example Cosmos DB via Mongo API) pair with Kafka Active-Active
* Databases that support only Active-Standby single-master writes (for example Azure SQL) pair with Kafka Active-Standby
* An application using both an Active-Active and an Active-Standby database pairs with Kafka Active-Standby
* Before running the Kafka service-specific prompt (16), confirm whether Cosmos DB and/or Azure SQL were confirmed in the Prompt 1 Section 1 dependency inventory, then select `hve-resiliency-researcher-16-kafka-active-active` or `hve-resiliency-researcher-16-kafka-active-standby-confluent` accordingly. When neither is confirmed, do not auto-select; ask the operator which Kafka topology the application uses before selecting the prompt.
* Kafka service-specific prompts (16) must record whether the repository's confirmed database resiliency model matches the Kafka topology assumed by the selected prompt, and flag any mismatch as a finding

## Context Management

A context reset (`/clear` or a new chat) is a clarity and cost tool, not a correctness requirement: durable artifacts under `.copilot-tracking/research/` carry context forward between prompts. For manual, one-prompt-per-turn runs, a reset before each prompt keeps input scoped to the prior artifact plus the current prompt (the Mode A cost optimization); it is recommended for cost and optional for correctness. At minimum, reset at phase boundaries and when switching agents. The resiliency orchestrator agents manage context automatically by dispatching each step to a fresh subagent, so no manual reset is needed when using them.

## Next Step Suggestions

After completing each research prompt output, end the response with a next-step suggestion the user can click. Format as:

> **Next step:** `/command-name`

Follow this sequence:

| Current Prompt                      | Next Step                                                                                                               |
|-------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `/hve-resiliency-researcher-0`            | `/hve-resiliency-researcher-1a`                                                                                               |
| `/hve-resiliency-researcher-1a`           | `/hve-resiliency-researcher-1b` (review Section 1 results first)                                                              |
| `/hve-resiliency-researcher-1b`           | `/hve-resiliency-researcher-2` (review Section 1 results from 1a and 1b; Sections 2-3 are excluded from here on)              |
| `/hve-resiliency-researcher-2`            | `/hve-resiliency-researcher-3`                                                                                                |
| `/hve-resiliency-researcher-3`            | `/hve-resiliency-researcher-4`                                                                                                |
| `/hve-resiliency-researcher-4`            | `/hve-resiliency-researcher-5-0-scaffold`                                                                                     |
| `/hve-resiliency-researcher-5-0-scaffold` | `/hve-resiliency-researcher-5-1-startup-failure`                                                                              |
| `/hve-resiliency-researcher-5-1-startup-failure` | `/hve-resiliency-researcher-5-2-silent-degradation`                                                                    |
| `/hve-resiliency-researcher-5-2-silent-degradation` | `/hve-resiliency-researcher-5-3-data-loss-partial-processing`                                                       |
| `/hve-resiliency-researcher-5-3-data-loss-partial-processing` | `/hve-resiliency-researcher-5-4-blocking-transactions`                                                    |
| `/hve-resiliency-researcher-5-4-blocking-transactions` | `/hve-resiliency-researcher-5-verify`                                                                            |
| `/hve-resiliency-researcher-5-verify`     | `/hve-resiliency-researcher-5-finalize`                                                                                       |
| `/hve-resiliency-researcher-5-finalize`   | `/hve-resiliency-researcher-6`                                                                                                |
| `/hve-resiliency-researcher-5` (deprecated redirect) | `/hve-resiliency-researcher-5-0-scaffold`                                                                          |
| `/hve-resiliency-researcher-6`            | `/hve-resiliency-researcher-7-logging`                                                                                        |
| `/hve-resiliency-researcher-7-logging`    | First applicable service-specific prompt from Phase 2, or `/hve-resiliency-consolidate-0-scaffold` if none apply              |
| Service-specific prompts (8-19)     | Next applicable service prompt for a Prompt 1 Section 1 dependency, or `/hve-resiliency-consolidate-0-scaffold` when complete  |
| `/hve-resiliency-consolidate-0-scaffold`  | `/hve-resiliency-consolidate-1-repository-context`, then `-2` through `-8` (fill each section; may run in parallel)            |
| Section-fill prompts (`-1` … `-8`)  | `/hve-resiliency-consolidate-verify-1-4` and `/hve-resiliency-consolidate-verify-5-8`                                          |
| Verify prompts (`-1-4`, `-5-8`)     | `/hve-resiliency-consolidate-9-finalize`                                                                                       |
| `/hve-resiliency-consolidate-9-finalize`  | `/hve-resiliency-planner-0`                                                                                                   |
