---
description: Run bounded Prompt 16 Kafka Active-Standby-Confluent resiliency research
---

# HVE Resiliency Researcher 16 Kafka Active-Standby-Confluent

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Execute this self-contained, read-only research workflow to completion. Do not use generic Task Researcher alternatives or rely on nested instruction, skill, or agent resolution.

## Scope And Safety Controls

Assess only application code and configuration that produces to or consumes from Kafka under the Confluent Cloud active-standby scenario. Do not assess, redesign, recommend, configure, or provide examples for Confluent provisioning or operations. Do not provide remediation, implementation guidance, configuration examples, or a planning handoff.

Apply these controls directly:

* Scope the repository to application behavior before, during, and after a managed Kafka cluster flip.
* Evaluate both authoritative scenarios: zone failure within West US 2, and regional failover from West US 2 to West US.
* Treat independent regional clusters, an active cluster, a standby cluster, managed replication, mirror-topic state, offset synchronization, promotion, failover, and failback as user-confirmed scenario assumptions only. Never present them as repository facts.
* Treat bootstrap selection as application behavior and platform failover orchestration as out of scope.
* Use Apache Kafka client 3.8 or later as the application client threshold only when a prerequisite-confirmed Confluent product or feature supplies an authoritative citation for that claim.
* Produce evidence-only findings with repository-relative file and line citations. Never convert absent external control-plane material into an application finding.
* Keep all tools and repository operations read-only except progressive and final writes to the Prompt 16 output artifact.
* Preserve secrets and personal data through the trusted transient processing rules below.

## Topology Deltas

Resolve the deployment topology per the [Deployment Topology Contract](../../../instructions/hve-resiliency-topology.instructions.md) before the prerequisite gate, the manifest freeze, or any concern query family. This prompt is the `active-standby` member of the topology-selected Prompt 16 pair and runs when the resolved deployment topology is `active-standby`. Topology comes from the run context lock, never from database evidence, Kafka evidence, or any other repository content. When the lock resolves `active-active`, this prompt is not the selected member: stop `blocked prerequisite/tool` with `wrong topology for this prompt - run /hve-resiliency-researcher-16-kafka-active-active` before any repository traversal.

The resolved topology scopes the closed application concern taxonomy. It adds no concern ID, output field, or section, and it never changes the seven-field finding schema in Authoritative Finding Schema.

Independent regional clusters, an active cluster, a standby cluster, managed replication, mirror-topic state, promotion, and failback remain user-confirmed scenario assumptions per Scope And Safety Controls. They are service-configuration claims, not the deployment topology, and they never establish, adjust, or override it.

The data write model derived from prerequisites is discovered evidence about a datastore, distinct from the declared deployment topology. It never selects this prompt, never establishes or overrides a topology, and never silences a run.

Under the resolved `active-standby` topology, treat these as in scope within the existing concern IDs:

* One-way managed replication from the active to the standby cluster, mirror lag, and the records at risk at promotion (`KAS-11`, `KAS-18`)
* Offset continuity, synchronized-offset use across promotion, and the bounded replay window promotion opens (`KAS-06`, `KAS-09`)
* Cold client construction, startup-only client wiring, and warm-up on the standby, which is the promotion path (`KAS-01`, `KAS-16`)
* Deployment and configuration parity of standby bootstrap endpoints, topics, group IDs, credentials, client versions, and observability, including drift that stays unobservable while the standby is idle (`KAS-14`, `KAS-19`)
* Runtime cutover configuration and routing state that must reach the promoted cluster without a restart (`KAS-04`, `KAS-08`)
* Idempotency and duplicate processing bounded to the cutover window rather than steady state (`KAS-05`, `KAS-09`, `KAS-13`)
* Schedulers, singletons, and worker ownership that must not run against the standby and must activate on promotion (`KAS-16`)
* Failback, reverse replication, backlog processing, and restored steady state (`KAS-18`)
* Standby readiness proven without live traffic, aligned with global load balancer health and application readiness (`KAS-21`)

Concurrent multi-region writes, cross-region unique identifier or sequence collision, cross-region read-your-own-writes, and steady-state duplicate processing arising from two simultaneously writable clusters are out of scope under `active-standby`. Do not admit a candidate, emit a finding, or record an evidence gap for a suppressed dimension; a suppressed dimension is never recorded as an `unknown/evidence gap`.

Where prerequisite or repository evidence does not fit the declared topology, continue under the declared topology and record the conflict on `KAS-20` per the contract's Mismatch Handling rules. Never switch topology, never redirect to the sibling prompt, and never decline to run.

Use the resolved `{primaryRegion}` and `{secondaryRegion}` values, or the terms "primary region" and "secondary region", in analysis and finding prose. Do not introduce region names beyond the authoritative scenario labels this prompt already requires.

## Prerequisite Contract

Derive `<repo-name>` from the workspace root as the case-preserving
root-directory basename. Derive `<YYYY-MM-DD>` as the current UTC assessment
date. Read only these repository-prefixed prerequisites; match the `<repo-name>`
segment case-insensitively per the normalization rules below:

* `.copilot-tracking/research/<YYYY-MM-DD>/<repo-name>-hve-resiliency-researcher-1a-research.md`
* `.copilot-tracking/research/<YYYY-MM-DD>/<repo-name>-hve-resiliency-researcher-1b-research.md`
* `.copilot-tracking/research/<YYYY-MM-DD>/<repo-name>-hve-resiliency-researcher-12-cosmosdb-research.md`, when present
* `.copilot-tracking/research/<YYYY-MM-DD>/<repo-name>-hve-resiliency-researcher-13-sql-research.md`, when present

Each producer artifact must begin with YAML frontmatter, optionally preceded by a single `<!-- markdownlint-disable-file -->` HTML comment on the first line only. The frontmatter must contain at least these lowercase keys, each once, with scalar values; additional keys are allowed but ignored:

```yaml
---
title: <any nonempty string>
description: <any nonempty string>
ms.date: <YYYY-MM-DD>
ms.topic: research
source-prompt: <hve-resiliency-researcher-1a|-1b|-12-cosmosdb|-13-sql>
schema-version: <positive integer>
status: current
---
```

`source-prompt` must exactly identify Prompt 1a, 1b, 12, or 13 by matching the corresponding filename infix (`hve-resiliency-researcher-1a`, `hve-resiliency-researcher-1b`, `hve-resiliency-researcher-12-cosmosdb`, or `hve-resiliency-researcher-13-sql`). `status: current` is the producer-completed signal. `ms.date` must match the `<YYYY-MM-DD>` segment of the artifact path, and all consumed artifacts must share the same `ms.date` under exact comparison.

The artifact body must contain, in order, the fixed H2 headings `## Section 1 - Used Azure Services (Evidence Confirmed)` for Prompt 1a or `## Section 1 — Used External Dependencies (Evidence Confirmed)` for Prompt 1b (Prompt 12 and Prompt 13 use their own producer-declared Section 1 heading text), then `## Section 2 - Checked but Not Present`, and `## Section 3 - Not Applicable`; accept either ASCII hyphen `-` or em-dash `—` as the separator, and reject any other H1 or H2. Each dependency entry starts with an H3 whose ordinal-stripped text is its canonical name and is followed by a bulleted list containing at least a name field (`Service name:` in Prompt 1a, `Service / Dependency name:` in Prompt 1b, or the analogous producer-declared name field in Prompt 12 or Prompt 13) and an evidence field (`Evidence:` or `Evidence (binding):`) whose child bullets each contain at least one `<repository-relative-path>:<line>` citation. A citation path uses `/`, is relative to the repository root, contains no `..`, and ends in a positive decimal line number.

Derive per-producer verdicts from the body without inference:

* Prompt 1a and 1b Kafka verdict is `used` when a Section 1 H3 (ordinal-stripped, case-insensitive) contains `Kafka` or identifies an equivalent Kafka-protocol service such as `Event Hubs` with a documented Kafka-protocol endpoint or a Confluent product, and its evidence field carries at least one citation. It is `not-used` when the same canonical Kafka name appears only in Section 2 or Section 3 with a citation. It is `unknown` when neither section presents a citation-backed classification.
* Prompt 12 and 13 data write model is `single-master`, `multi-master`, or `mixed` when a Section 1 H3 (ordinal-stripped) identifies the covered database and a bulleted field labeled `Data write model:` states one of those hyphenated values with at least one supporting citation. Accept `Topology verdict:`, `Topology classification:`, or an equivalent producer-declared field as deprecated legacy labels for the same field, and prefer `Data write model:` when more than one label is present. It is `unknown` in any other case. The data write model describes how a datastore accepts writes; it is never a deployment topology and never selects a prompt.

Normalize source-prompt names case-insensitively after trimming whitespace. Normalize verdict and write-model values to lowercase and the exact hyphenated values above. Do not normalize any other value by synonym or inference.

Apply prerequisite consistency rules before repository discovery:

1. Reject unreadable, malformed, wrong-repository, wrong-producer, nonterminal, or citation-free artifacts as blocked prerequisites.
2. Reject duplicate artifacts for one producer as blocked unless their normalized verdicts and citation sets are byte-for-byte identical after line-ending normalization; retain one and record the duplicate.
3. Kafka use is determined primarily by Prompt 1b, because Prompt 1a is scoped to Azure services and Prompt 1b is scoped to non-Azure services. Continue when the Prompt 1b Kafka verdict is `used`, regardless of the Prompt 1a Kafka verdict, provided the two verdicts do not directly contradict on the same Kafka-protocol backend. A direct contradiction exists only when Prompt 1a Section 1 identifies an Azure Kafka-protocol backend such as Event Hubs with a Kafka-protocol endpoint that Prompt 1b Section 2 or Section 3 disproves for the same broker set with a citation, or vice versa; classify a direct contradiction of that shape as blocked. Classify a Prompt 1b Kafka verdict of `unknown` as blocked. Classify a Prompt 1b Kafka verdict of `not-used` as not applicable, regardless of the Prompt 1a verdict.
4. When Prompt 1a Section 1 identifies Cosmos DB or Azure SQL as used, require at least one matching Prompt 12 or Prompt 13 artifact and derive the data write model from it (derive `mixed` only when one proves `single-master` and the other proves `multi-master`; identical normalized values remain that value; any other conflict, malformed combination, or `unknown` yields `unknown`). When Prompt 1a places both Cosmos DB and Azure SQL in Section 2 or Section 3 and Prompt 1b Section 1 identifies a non-Azure database (for example, MongoDB Atlas) with a `Data write model:` field, or a deprecated `Topology verdict:`, `Topology classification:`, or equivalent producer-declared field, carrying a citation-backed hyphenated value, accept that Prompt 1b field under the same normalization rules and do not require Prompt 12 or Prompt 13. When neither Prompt 1a Section 1 nor Prompt 1b Section 1 establishes a citation-backed value, the derived write model is `unknown`. The derived write model is a cross-check against the declared deployment topology and feeds the `KAS-20` assessment only. It never selects this prompt, never gates the run, and a missing, conflicting, or `unknown` write model is recorded as an evidence gap on `KAS-20` rather than blocking.
5. Cross-check the derived write model against the declared `active-standby` topology and record the result on `KAS-20` per the Mismatch Handling rules: `single-master` fits the declared topology and is recorded as consistent; `mixed` is recorded as consistent for its single-master portion, with its multi-master portion handled by the next clause; `multi-master` is capability beyond what `active-standby` uses, so record a P2 mismatch finding naming the declared topology, the observed write model, and its prerequisite citations; `unknown` is an evidence gap. No write-model value changes eligibility, selects another prompt, suppresses a concern, or alters the terminal status.
6. Treat the Kafka platform as Confluent Cloud, a confirmed engagement platform fact; do not ask the operator which Kafka provider or Confluent product is in use. The deployment topology is already established by the lock, so this rule decides only whether Confluent active-standby feature evidence is established: Cluster Linking, Replicator, MirrorMaker, or a user-named equivalent, from a cited prerequisite or the conversation. When the feature is established, run in Tier A and enable Confluent-specific concerns (`KAS-11`, and the managed-replication portions of `KAS-14`, `KAS-18`, and `KAS-20`). When the feature is not established, run in Tier B: disposition every managed-replication-dependent assertion as `unknown/evidence gap` mapped to the missing feature detail, do not enter the Conditional External Evidence Protocol, and continue with the vendor-agnostic Kafka concerns. Absent feature evidence never blocks the run and never makes it not applicable.
7. A prerequisite that classifies the Kafka deployment as Active-Active, or an equivalent multi-active label, with a citation contradicts the declared `active-standby` topology. Record a P0 mismatch finding on `KAS-20` naming the declared topology, the cited contrary classification, and the failure it implies, then continue under the declared topology. Never switch topology, never redirect to `hve-resiliency-researcher-16-kafka-active-active`, and never classify the run as not applicable for that reason.

Do not infer Kafka use, Confluent identity, database service identity, or a data write model from generic repository evidence. Stop immediately after rendering the status-aware artifact when the gate is not applicable or blocked. Record the selected tier (Tier A or Tier B) and its evidence pointers in the prerequisite ledger.

## Assumption And Evidence-State Register

Assign every retained assertion exactly one state:

* `repository fact`: proven by a sanitized repository citation
* `prerequisite fact`: proven by a valid prerequisite artifact and its cited source
* `user-confirmed scenario assumption`: explicitly confirmed but not repository-proven
* `external-platform fact`: supported by a minimal authoritative product citation
* `external-platform unknown`: not established by eligible evidence
* `rejected inference`: a tempting conclusion that eligible evidence does not prove

Generic Kafka clients, bootstrap properties, configuration, or a Confluent dependency repository remain generic Kafka evidence. They cannot prove Confluent Cloud or Confluent Platform, Cluster Linking or Replicator, active-standby regions, replication, promotion, failback, synchronized offsets, ACLs, schemas, lag, RPO, overlap, or data loss.

## Conditional External Evidence Protocol

Enter this branch only in Tier A, after the prerequisite gate confirms the exact Confluent product and active-standby feature, and only when a specific platform-behavior assertion needed to validate the causal chain of an otherwise in-scope application finding remains unresolved by repository and prerequisite evidence. Tier B runs never enter this branch; they disposition managed-replication-dependent assertions as `unknown/evidence gap` and select a completed status from bounded repository evidence only. Never fetch to identify the product or feature, fill missing topology proof, or establish deployed configuration, topology, runtime state, regions, replication health, lag, offsets, ACLs, schemas, RPO, or data loss.

Use only authoritative Confluent vendor documentation for the confirmed product and feature. Access a page only by a claim-specific canonical URL already supplied by eligible evidence or the user; do not use broad web search, search-engine results, recursive link traversal, or links discovered from a fetched page. Enforce a run-wide maximum of two external retrieval attempts or pages and two retained external citations. Count every attempted page, including unavailable or failed retrievals, against the fetch cap. Fetch each canonical URL at most once, cache its sanitized result, and reuse that cache for every later assertion.

For each fetched page, retain only the minimum text needed for the claim. Record `External platform evidence: EXT-### | <source title> | <canonical URL> | retrieved <date>; currentness <published-or-updated indicator, not stated, or stale> | supports: <exact platform-semantics assertion>`. A canonical page with no published or updated indicator may be used only when it is not marked retired, superseded, or version-inapplicable; record `currentness not stated`. External evidence may support only platform semantics for the confirmed product and feature. It cannot supply a repository code location or prove any deployed or runtime fact prohibited above.

Apply these evidence-state transitions without additional discovery:

1. When a fetched authoritative page directly and currently supports the exact assertion, assign that assertion `external-platform fact`, create one `EXT-###` mapping, and map the application-side portion of any finding separately to eligible repository evidence.
2. When the page or canonical URL is unavailable, inapplicable, stale, or lacks enough claim-specific support, assign `external-platform unknown`, disposition the unsupported candidate as `unknown/evidence gap`, and record the exact reason. Select `completed with unknowns/evidence gaps` when this is the only material unresolved application assertion and no higher-precedence status applies.
3. When eligible external sources contradict one another or contradict an attempted inference, retain the minimal contradictory `EXT-###` mappings, assign `rejected inference`, record the contradiction in Rejected Candidates and Unknowns And Evidence Gaps, and do not emit the candidate as a finding. Use `completed with unknowns/evidence gaps` when the contradiction leaves a material assertion unresolved and no higher-precedence status applies.
4. When the external fetch tool is unavailable or fails before the allowed attempt can be evaluated, record an external evidence gap and select `completed bounded partial` as a nonessential tool failure unless a higher-precedence prerequisite, required-tool, artifact, or validation failure requires `blocked prerequisite/tool`. External-tool unavailability alone is never a blocked prerequisite.
5. When the two-attempt or two-citation cap is exhausted before the needed assertion is resolved, stop external access, record the exhausted cap and unexamined assertion, assign `external-platform unknown`, disposition the candidate as `unknown/evidence gap`, and select `completed bounded partial` unless a higher-precedence status applies.

Keep evidence classes mechanically distinct in the artifact and every assertion mapping. Use `Repository evidence: REPO-### | <repository-relative-path>:<exact-line-or-range> | <symbol-or-property> | <minimal sanitized excerpt>` for repository facts. Use `Prerequisite evidence: PRE-### | <producer-artifact>:<exact-line-or-range> | source <repository-relative-path>:<line> | <normalized verdict>` for prerequisite facts. Use the `External platform evidence: EXT-###` format above only in a separate external-source ledger within Assumptions And Evidence States. A finding may reference an `EXT-###` identifier only for its platform-semantics causal link; `Code location (file + line number)` and all application-behavior proof must reference `REPO-###`. Never substitute `PRE-###` or `EXT-###` for repository finding evidence.

## Immutable Production Source Manifest

Construct one immutable text-only manifest before concern searches. Include at most 80 unique files, sorted by repository-relative path, from these roots only:

* Build manifests and resolved dependency reports already present in the repository root
* `src/main/` application source and resources
* `Actionsfile/`, deployment manifests, infrastructure files, container files, and production build or packaging scripts
* Production-bound configuration files directly referenced by an included deployment or runtime binding

Exclude `.git/`, `.copilot-tracking/`, `target/`, generated output, vendored dependencies, binaries, certificates and private-key material, tests, fixtures, samples, documentation, and local or developer profiles unless an included production source explicitly binds them. Include text files only.

Record each manifest item as a default, production-bound value, or unavailable operational value. Apply this effective-value precedence from strongest to weakest: deployment or runtime binding, production profile override, application default, then code default. A stronger source wins only when it explicitly binds the same property. Do not guess unavailable deployment, secret-store, runtime, or external control-plane values.

Follow at most one level of indirection from an included production source. Read no more than 12 indirection targets. Do not mutate the manifest after concern searches begin; newly mentioned out-of-manifest files become evidence gaps.

## Closed Application Concern Taxonomy

Use only the following concern IDs and meanings. Do not add, split, rename, or expand assessment topics:

1. `KAS-01`: Kafka bootstrap and DNS usage, hard-coded brokers, cached IP addresses, endpoint refresh, region-specific settings, and startup-only client construction
2. `KAS-02`: `advertised.listeners` metadata caching and reuse of broker addresses that bypass bootstrap re-resolution after a cluster flip
3. `KAS-03`: Direct and transitive Apache Kafka client version 3.8 or later
4. `KAS-04`: Recovery of producers, consumers, stream processors, admin clients, schema clients, and health checks without restart, redeployment, manual configuration, or cache clearing
5. `KAS-05`: Producer idempotence, acknowledgements, delivery callbacks, retry safety, buffering, flush behavior, ambiguous outcomes, and message-loss tolerance
6. `KAS-06`: Consumer commit timing, stable group identity, synchronized-offset use, reset policy, replay tolerance, revocation, rebalance, and duplicate handling
7. `KAS-07`: Reconnect and retry backoff, request and delivery timeouts, metadata refresh, retry exhaustion, cancellation, and exception handling
8. `KAS-08`: Runtime cutover configuration or routing state loaded only at startup or cached for process lifetime
9. `KAS-09`: Duplicate and idempotent processing after retry, replay, redelivery, failover, or rebalance
10. `KAS-10`: Fire-and-forget sends, ignored failures, premature success, unsafe shutdown, commits before processing, and unhandled offset gaps
11. `KAS-11`: Workflows that assume the standby has every latest record immediately after platform failover
12. `KAS-12`: Workflows, state transitions, or transactions that cannot tolerate delayed, replayed, duplicated, or out-of-order events
13. `KAS-13`: Non-idempotent business side effects that can create duplicate outcomes after retry or resume
14. `KAS-14`: Cluster-specific schema, authentication, authorization, endpoint, credential, certificate, trust-store, principal, ACL, or cached-state dependencies
15. `KAS-15`: Backpressure and catch-up behavior, bounded queues, poll starvation, max-poll intervals, memory growth, dropped work, and downstream overload
16. `KAS-16`: Startup, dependency injection, singleton ownership, worker cancellation, graceful shutdown, readiness, restart loops, and permanently stopped clients
17. `KAS-17`: Database writes, external API calls, Kafka transactions, outbox or inbox patterns, commit boundaries, poison messages, dead letters, and interrupted partial completion
18. `KAS-18`: Failback and regional recovery, reconnection, replay, offset continuity, backlog processing, and restored steady state
19. `KAS-19`: West US and West US 2 symmetry for bootstrap endpoints, topics, group IDs, retry policies, credentials, client versions, and observability
20. `KAS-20`: Database-to-Kafka pairing cross-check between the derived data write model and the declared active-standby deployment topology, including mismatch findings and write-model evidence gaps
21. `KAS-21`: Alignment among GLB health, application readiness, Kafka connectivity, and downstream processing health

## Bounded Discovery And Read Protocol

Create one bundled query family for each concern ID using only terms already named by that concern and confirmed repository identifiers. Search each concern family exactly once against the immutable manifest, cache the result, and reuse that cache. Use one additional bundled dependency query for Kafka client declarations and resolved runtime versions. Do not perform broad rediscovery, synonym expansion, or repeated searches.

Enforce these run-wide hard caps:

* 80 manifest files
* 2 discovery rounds
* 24 bundled repository search or query invocations, including manifest construction and dependency resolution
* 60 unique file reads
* 6 corrective rereads total, with at most one corrective reread per file
* 1 indirection level and 12 indirection reads
* 100 retained candidates
* 40 finding rows
* 3 citations per finding row
* 65,536 sanitized retained evidence bytes
* 2 conditional external documentation fetches and 2 external citations total

Round 1 executes the cached query families and creates candidates. Round 2 reads only owning code or configuration needed to verify Round 1 candidates and their assertion relationships. A complete round is saturated when it adds no eligible candidate and no assertion-to-evidence relationship. Stop at saturation, after Round 2, or when any cap is reached, whichever occurs first.

When a threshold is reached, stop new discovery immediately, finish classification from already sanitized retained evidence, record the exact exhausted cap and unexamined manifest or candidates, and use `completed bounded partial` unless terminal-status precedence requires `blocked prerequisite/tool`. Never exceed a cap to complete a finding.

## Trusted Transient Processing

Raw-returning tools may expose source text transiently. Use raw output only to identify and redact sensitive spans. Before retaining, deriving an assessment assertion, quoting, logging, caching, or writing output, replace credentials, passwords, API keys, SASL secrets, JAAS values, certificates, private material, trust-store secrets, tokens, secret-bearing endpoints, and PII with `<redacted:type>`.

Never retain raw tool dumps, secret values, certificate bodies, private keys, or binary content. Count UTF-8 bytes only after sanitization and only for retained excerpts, mappings, candidate records, and coverage records. Discard transient raw output after producing its sanitized representation.

## Candidate And Evidence Controls

Assign candidates stable IDs `CAND-001` onward after sorting by concern ID, repository-relative path, first line, and normalized assertion text. Use the deduplication key `concern ID | scenario | failure mode | owning code path | observable effect`.

Give every candidate exactly one terminal disposition: `finding`, `rejected false positive`, `rejected inference`, `duplicate of <candidate ID>`, or `unknown/evidence gap`. A duplicate may point only to an earlier candidate. Never merge materially distinct failure modes. Emit separate finding rows for the West US 2 zone-failure and West US 2-to-West US regional-failover scenarios when evidence supports both and their outcome, causal chain, priority, or constraints differ. Use one row marked `Both scenarios` in `Issue Description` only when all those semantics are identical.

Map every substantive assertion to a sanitized citation containing repository-relative path, exact line or line range, symbol or property, and a minimal excerpt. Validate that each cited line exists, the excerpt matches, the evidence state is eligible, and the citation supports the assertion rather than merely mentioning a keyword.

Negative repository claims must name the manifest subset, cached query family, and reads that bound the claim. Coverage citations may support an absence statement in Production Coverage or Unknowns and Evidence Gaps. They cannot serve as finding evidence or justify a priority.

## Priority Classification

Assign priority only from a cited causal chain connecting observed application behavior to an authoritative scenario impact:

* `P0`: Causes outage, data loss, duplicate charges, or inability to fail over safely during zone or regional failure
* `P1`: Materially increases application, data, or customer risk during failure without fully blocking failover
* `P2`: Weakens resilience posture or operational clarity without materially affecting failover correctness
* `P3`: Non-blocking maintainability, readability, duplication, or consistency concern

Do not assign or escalate priority solely from an unknown, rejected inference, external assumption, or missing external-platform evidence. Findings contain no remediation wording.

## Terminal Status

Select exactly one status using this precedence:

1. `blocked prerequisite/tool`: A prerequisite is invalid or a required tool failure prevents prerequisite, manifest, or citation validation.
2. `not applicable`: Valid prerequisites exclude Kafka (Prompt 1b Kafka verdict `not-used`). Kafka being unused is the only route to this status; direct the user to the next applicable service-specific prompt. A `multi-master` or `unknown` write model, a prerequisite that classifies the Kafka deployment as Active-Active, and absent Confluent feature evidence are findings or evidence gaps under Prerequisite Contract Rules 5 through 7 and never select this status.
3. `completed bounded partial`: A hard cap or nonessential tool failure leaves declared manifest or candidate coverage incomplete.
4. `completed with unknowns/evidence gaps`: Eligible bounded research completes, but one or more material application assertions remain unknown.
5. `completed with findings`: Eligible bounded research completes with one or more validated findings and no material unknowns.
6. `completed zero findings`: Eligible bounded research completes with no validated findings and no material unknowns.

Artifact write or validation failure changes any otherwise completed status to `blocked prerequisite/tool`. Status selection is deterministic and final.

## Canonical Output Artifact

Write progressively to `.copilot-tracking/research/<repo-name>-hve-resiliency-researcher-16-kafka-active-standby-confluent-research.md`. Write to a temporary sibling file, validate it, then atomically replace the final artifact. On interruption, preserve the latest valid temporary artifact and report its path without presenting it as final.

Stamp the resolved deployment topology in the artifact front matter as `topology: <active-active|active-standby>`, and state it with the resolved regions as an evaluation condition in `Scope And Terminal Status`. Stamp the resolved deployment topology only; never stamp a data write model in that field. Stamping is required and adds no section.

Use this section order:

1. `Scope And Terminal Status`
2. `Prerequisite Ledger`
3. `Assumptions And Evidence States`
4. `Production Source Manifest And Coverage`
5. `Database-To-Kafka Pairing Verdict`
6. `Findings`
7. `Rejected Candidates`
8. `Unknowns And Evidence Gaps`
9. `Zero Findings Statement`
10. `Validation And Handoff`

The prerequisite ledger records producer, normalized verdict, citations, duplicate or conflict handling, and gate result. The coverage section records budgets consumed, saturation, caps reached, manifest exclusions, query families, reads, and bounded negative claims. The pairing section records the declared deployment topology, the derived data write model with its prerequisite citations, and the `KAS-20` cross-check result as `consistent`, `mismatch`, or `evidence gap`; it never records a prompt-selection outcome. Sections outside Findings carry candidate IDs, rejected inferences, unknowns, and coverage; do not add fields to finding rows.

When status is `completed zero findings`, state that no validated findings were produced within the declared bounded coverage. Otherwise write `Not applicable for this status` in Zero Findings Statement.

## Authoritative Finding Schema

Render every finding with these field names in this exact order and no additional fields:

1. `Issue Description:` Include finding ID, concern ID, and `West US 2 zone failure`, `West US 2 to West US regional failover`, or `Both scenarios`.
2. `Risk Level (P0/P1/P2/P3):`
3. `Code location (file + line number):`
4. `Why this is a risk to app, zone or region failover:`
5. `Impact(s) if this is not changed:`
6. `Existing mitigations present (evidence):`
7. `Constraints/limitations (evidence):`

Only `Existing mitigations present (evidence)` and `Constraints/limitations (evidence)` may render `Unknown`, and each such value must reference a corresponding entry in Unknowns And Evidence Gaps. Never use `Unknown` for priority, terminal status, finding or candidate IDs, concern IDs, code locations, citations, prerequisite producers, repository identifiers, scenarios, or required identifiers. If any other finding field cannot be supported, disposition the candidate as `unknown/evidence gap` instead of emitting a finding.

## Validation And Response

Before atomic replacement, verify frontmatter, the resolved topology stamp in front matter and scope, repository name, exact section order, exactly one terminal status, prerequisite normalization, immutable manifest accounting, all hard-cap totals, candidate dispositions, deduplication keys, finding limits, exact finding field names and order, scenario separation, priority causal chains, citation existence and semantic support, redaction, retained byte count, zero-findings consistency, and absence of recommendations, examples, remediation, or planning content.

Include an HVE next step for `completed with findings`, `completed zero findings`, or `completed with unknowns/evidence gaps`; suggest the next applicable service-specific prompt confirmed by Prompt 1a and 1b, or `/hve-resiliency-researcher-consolidate` when no applicable service remains. In `not applicable` status, which Kafka being unused is the only route to, direct the user to the next applicable service-specific prompt confirmed by Prompt 1a and 1b, or `/hve-resiliency-researcher-consolidate` when no applicable service remains, and issue no other HVE next step for that status. Never route to `hve-resiliency-researcher-16-kafka-active-active` for a write-model mismatch or a contrary Kafka topology classification; those are `KAS-20` findings in this run's artifact. Do not include an HVE next step for `blocked prerequisite/tool` or `completed bounded partial`. Mention Prompt 11 only when the HVE sequence and confirmed dependency inventory make it the next applicable service prompt; never route backward, and never suggest it for blocked or bounded-partial status.

Return only:

* Final artifact path, or latest valid temporary path when finalization is blocked
* Terminal status
* Prerequisite gate result, resolved deployment topology, and the derived data write model with its `KAS-20` cross-check result
* Findings, rejected candidates, and unknown/evidence-gap counts
* Budget consumption and any exhausted cap
* Validation result
* Allowed HVE next step, when status permits

## Output Review

Review every claim against its cited line and semantic mapping. Reconcile contradictions through the declared candidate dispositions and status precedence without additional discovery after saturation or a cap.
