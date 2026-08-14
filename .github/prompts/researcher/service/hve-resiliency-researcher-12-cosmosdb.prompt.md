---
description: "Assess Cosmos DB Mongo API regional failover evidence with bounded repository research"
argument-hint: "prompt1aArtifactPath=... prompt1bArtifactPath=..."
---

# Application HVE Researcher 12 Cosmos DB

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Inputs

* `${input:prompt1aArtifactPath}`: (Required) Exact workspace-relative path to the completed Prompt 1a
  Azure dependency inventory artifact under `.copilot-tracking/research/`.
* `${input:prompt1bArtifactPath}`: (Required) Exact workspace-relative path to the completed Prompt 1b
  external dependency inventory artifact under `.copilot-tracking/research/`.

Use only these paths for prerequisite artifacts. Do not search, glob, select a recent file, or infer a
prerequisite path.

## Scope and execution contract

Execute only this Prompt 12 research workflow. Do not start another resiliency prompt, delegate work, or
perform recommendation or implementation work. Keep all repository interaction read-only. Use only
repository evidence and report factual evidence gaps instead of assumptions.

Assess only the current repository for these authoritative scenarios, one scenario per finding:

* Full regional failover between West US 2 and West US

Treat East US, active-active or multi-region writes, Last Write Wins, the RU model, Mongo API behavior,
and no-data-loss expectations as claims to verify or as constraints or evidence gaps. Do not assume they
describe the production architecture. Repository evidence cannot prove unavailable runtime replication,
acknowledgement, conflict, recovery, or global load balancer behavior.

Keep the Cosmos DB scope closed to these eight assessment areas:

1. Preferred-region selection and avoidance of hard-coded endpoints
2. MongoDB driver retries, timeouts, and failover configuration
3. Transient write failures, 429 throttling, and region-outage handling without restart
4. Session-token preservation and read-your-writes behavior across regions
5. Write idempotency and conflict behavior, including Last Write Wins only when evidenced
6. Mid-request behavior when a write region becomes unavailable
7. Backend health-probe and global load balancer health alignment
8. Evidence-bound data-loss exposure and any stated no-data-loss acceptance boundary

Do not add assessment areas, ownership fields, recommendations, alternatives, examples, or code changes.

## Prerequisite gate

Validate both input artifacts before repository discovery:

1. Normalize each path and require a regular workspace-relative file under
   `.copilot-tracking/research/`, without traversal, absolute paths, links, or repository escape.
2. Parse YAML frontmatter and require non-empty string fields `repository`, `assessmentId`, `revision`,
   `status`, `generatedAt`, and `promptId`. Require the current repository name, the exact current commit
   SHA, `status: Complete`, RFC 3339 UTC ending in `Z`, and the matching `promptId` value `1a` or `1b`.
3. Require equal `repository`, `assessmentId`, and `revision` across the artifacts. Require timestamps no
   more than 24 hours apart and neither later than current UTC plus five minutes. Artifact age does not
   establish currency; exact current-revision equality does.
4. Validate the producer body schema and every prerequisite file-line citation. Map Prompt 1a
   `Section 1 - Used Azure Services (Evidence Confirmed)`, `Section 2 - Checked but Not Present`, and
   `Section 3 - Not Applicable`, and Prompt 1b
   `Section 1 — Used External Dependencies (Evidence Confirmed)`, `Section 2 — Checked but Not Present`, and
   `Section 3 — Not Applicable`. Reject malformed or
   conflicting mappings.
5. Enter discovery only when Prompt 1a confirms Azure Cosmos DB through product-specific production
   binding evidence. Generic MongoDB dependencies, names, protocols, or configuration alone do not
   confirm Cosmos DB. Prompt 1b must not contradict repository identity, revision, run, or applicability.

Parse producer bodies with this deterministic grammar:

* A section begins at a level-2 heading and ends at the next level-2 heading or end of file. Normalize
   heading whitespace and case. Require the three producer-specific headings listed above once and in
   order. Reject duplicate sections or a missing required section.
* Prompt 1a and Prompt 1b Section 1 mean `Confirmed`, Section 2 means `Checked But Not Present`, and
   Section 3 means `Not Applicable`.
* Each section contains Markdown table rows or contiguous labeled list records with exactly these
   semantic fields: `Service`, `Classification`, `Production binding`, and `Evidence`. Accept the sole
   marker `None` when a section has no records. Normalize field names and values by trimming, collapsing
   internal whitespace, and comparing case-insensitively; preserve citations byte-for-byte after path
   normalization. Reject unlabelled prose as a record.
* `Classification` accepts only `Confirmed`, `Checked But Not Present`, or `Not Applicable` and must
   equal the containing section meaning. `Production binding` accepts only `Confirmed`, `Not evidenced`,
   or `Not applicable`. It must be `Confirmed` for a confirmed Cosmos DB record, `Not evidenced` for a
   checked-but-not-present record, and `Not applicable` for a not-applicable record or a non-Cosmos
   external dependency.
* Normalize `Service` by trimming, collapsing whitespace, and comparing case-insensitively. Only
   `Azure Cosmos DB`, `Cosmos DB`, `Azure Cosmos DB for MongoDB`, and `Cosmos DB Mongo API` identify
   Cosmos DB. Do not normalize generic `MongoDB`, `Mongo`, a protocol, driver, endpoint, or configuration
   name to Cosmos DB.
* A confirmed Cosmos DB record requires at least one workspace-relative `path:line` citation in
   `Evidence` that supports product-specific production binding. Citations are optional for exclusion
   records and non-Cosmos records; validate every citation that is present. Missing required fields,
   empty required values, unsupported values, malformed citations, or an undecidable Cosmos DB
   classification select `blocked-prerequisite`.
* Collapse duplicate records only when normalized service, classification, production binding, and
   normalized citation sets are equal. Conflicting duplicates or the same normalized service in more
   than one section select `blocked-prerequisite`. Prompt 1a is authoritative for Azure Cosmos DB.
   Prompt 1b may neither confirm nor exclude a Cosmos DB service alias inconsistently with Prompt 1a;
   generic MongoDB records in Prompt 1b neither confirm nor exclude Cosmos DB.

Select `excluded/not-applicable` only when both valid artifacts consistently place Cosmos DB outside the
confirmed dependency scope. Select `blocked-prerequisite` for a missing, malformed, stale, ambiguous,
conflicting, cross-run, cross-revision, or unverifiable artifact, unavailable current revision, invalid
citation, or absent Cosmos DB applicability decision. Do not scan the repository as a fallback.

## Minimum capabilities and safety boundary

Require deterministic path enumeration, bounded text search over an explicit file list, bounded file and
line reads, current repository name and revision reads, and atomic Markdown artifact writing. Prohibit
builds, tests, network calls, application execution, mutation of repository source, and subagent use.

Select `blocked-prerequisite` when a required capability is unavailable before the manifest freezes. If a
capability fails after evidence collection begins, stop new discovery, dispose retained work within the
remaining bounds, and select the applicable `bounded-partial` status.

Treat ordinary bounded repository search and read results as a trusted transient processing boundary.
Raw tool output may exist only ephemerally in tool transport and the current processing step long enough
to sanitize it. Do not copy raw output into retained ledgers, artifacts, logs, responses, caches, hashes,
comparisons, quotations, candidates, evidence stores, or derived values. Sanitize each current result
before any retention or derivation, retain only the sanitized form, and discard the raw response from
further processing. Do not require a search or read tool to sanitize bytes before returning them.

Never retain raw credentials, secrets, tokens, connection strings, URI user information, sensitive query
values, account keys, authorization values, request or response bodies, raw logs, or PII. Retain only a
normalized workspace-relative path and line, generalized key or symbol category, non-sensitive behavior,
stable redacted identity derived from sanitized content, and the minimum sanitized excerpt needed to
audit a claim. Charge the 65,536-byte evidence cap to the UTF-8 byte length of all sanitized content
retained in caches, ledgers, candidates, evidence stores, and the artifact. Select `blocked-prerequisite`
if caller-side sanitization cannot be guaranteed before the first retention or derivation, or a
`bounded-partial` status if sanitization fails after retained evidence collection begins.

## Immutable production manifest

After the prerequisite gate, enumerate paths once and freeze one normalized, sorted, text-only production
manifest. Admit at most 240 files from only these roots and file classes:

* `pom.xml`
* `src/main/java/**`
* `src/main/resources/**`
* `Actionsfile/**`
* `.github/workflows/**`
* Root `Dockerfile`, `*.sh`, `*.properties`, `*.xml`, `*.json`, `*.yml`, and `*.yaml` files
* Existing `bicep/**`, `terraform/**`, `helm/**`, `k8s/**`, and `deploy/**` trees

Exclude `.git/**`, `.copilot-tracking/**`, `.github/prompts/**`, `target/**`, tests, generated output,
caches, vendored dependencies, reports, prior research, documentation, local-only profiles, certificates,
keys, trust stores, binaries, archives, and files outside the current repository. Tests and documentation
may not be reintroduced as production evidence. Record an external production value, secret-resolved
value, control-plane setting, or deployment binding unavailable from this manifest as an evidence gap.
Do not admit files after the manifest freezes or perform another path traversal.

## Finite bundled query matrix

Run exactly one bounded search invocation for each query family below, in order, against the frozen
manifest. Bundle all listed terms for that family into its single invocation, cache the complete sanitized
result set, and never repeat a family or use a result to begin broad rediscovery.

1. Cosmos binding: `cosmos`, `mongodb`, `mongo`, `ru`, client construction, connection keys, and endpoints
2. Region and endpoint selection: preferred regions, West US 2, West US, East US, hosts, URIs, DNS, and fallback selection
3. Retry and throttling: retry, timeout, backoff, transient errors, 429, throttling, and exception handling
4. Session behavior: session tokens, consistency, causal consistency, read concern, write concern, and read-your-writes
5. Write safety and conflicts: idempotency, duplicate suppression, conflict resolution, Last Write Wins, versioning, and acknowledgements
6. Mid-request failure: region unavailability, failover, reconnect, partial write, restart, fallback, and degraded behavior
7. Health alignment: health, readiness, liveness, probes, global load balancer, routing, dependencies, and status propagation
8. Data-loss boundary: RPO, durability, replication, recovery, data loss, no data loss, and operational constraints

Read only cached hits and the minimum owning context required to classify them. Follow at most two
evidence-backed source or configuration indirections per candidate, with depth at most 2, and only when
the destination is already in the frozen manifest. Cache each baseline file read by normalized path.

Apply these hard caps:

* 240 manifest files
* 8 search invocations and 8 completed query families
* 120 unique baseline file reads
* 20 corrective rereads total, at most one per file
* 2 indirections per candidate at depth 2
* 96 retained candidates
* 48 rendered findings
* 65,536 total bytes of retained sanitized evidence
* Zero subagent invocations
* One no-change saturation review
* One corrective render and two full validation passes total

Reaching a cap immediately stops new searches, reads, indirections, candidate admission, and finding
admission governed by that cap. Complete bounded disposition and rendering for already retained records,
then select the applicable `bounded-partial` status. Never evict an earlier record to admit a later one.

## Candidate and assertion ledger

Sort cached hits by normalized path, line, query family, and sanitized identity before candidate admission.
Create each candidate ID from the deterministic tuple of assessment area, authoritative scenario,
failure-mode class, normalized path and line, and sanitized identity. Use that same tuple as the
deduplication key. Give every admitted candidate exactly one terminal disposition: `rendered`, `merged`,
`validated-non-finding`, `evidence-gap`, `invalid-citation`, `insufficient-evidence`, `conflict`, or
`unresolved-at-limit`.

Maintain candidate-to-finding, finding-to-candidate, assertion-to-candidate, and candidate-to-assertion
mappings. Validate every cited path, line, and range against a cached baseline read or the one allowed
corrective reread. A citation is valid only when its sanitized content semantically supports the mapped
assertion; line existence alone is insufficient. Narrow unsupported prose to the evidence. If no
material supported assertion remains, retain an evidence-gap disposition and do not render a finding.

Emit separate finding rows for every materially different failure mode and for each authoritative
scenario when evidence supports both. Never combine zone and regional outcomes in one row. Deduplicate
only identical assertions with the same scenario, failure mode, outcome, priority, mitigations,
constraints, and evidence owners. Preserve all merged candidate IDs.

## Evidence, priority, and field semantics

Every substantive positive claim and source-local negative configuration value, including each issue,
scenario effect, impact, mitigation, constraint, and priority rationale, requires assertion-level
file-and-line evidence. A bounded absence claim instead requires a coverage citation tied to the frozen
coverage ledger. Render it as `Coverage: manifest=<sanitized-manifest-id>; roots=<checked-roots>;
classes=<checked-classes>; query-families=<completed-ids>; reads=<completed>/<required>`. Derive the
manifest ID only from the sanitized normalized frozen manifest. The roots, classes, query families, and
read counts must equal the immutable manifest, query, and read ledgers; incomplete coverage cannot support
an absence claim. Never fabricate a file or line citation for absence. Use `Not observed in the checked
manifest` rather than `not used` and include the coverage citation in the same finding field. Coverage
citations do not replace file-and-line evidence for positive or source-local assertions.

Classify each rendered finding with exactly one evidence-supported priority:

* P0: Critical or blocking behavior that causes outage, data loss, duplicate charges, or inability to fail over safely during regional failure
* P1: Required, non-blocking behavior that materially increases application risk, data risk, or customer impact during failure
* P2: An improvement or best practice that does not materially impact correctness during failover but weakens resilience posture or operational clarity
* P3: Non-blocking maintainability, readability, duplication, or consistency behavior

The risk field must connect cited behavior to one named authoritative scenario and failure effect. Never
derive priority from an unverified no-data-loss, active-active, East US, or Last Write Wins premise.

Use the exact field-safe value `Unknown: evidence unavailable (<evidence-gap-id>)` only in the impact,
existing-mitigation, or constraint prose field when that field cannot be supported from repository
evidence. In a mitigation field, `None observed in the checked manifest (<bounded scope>)` is valid only
after complete coverage. Never use Unknown for terminal status, priority, issue or candidate identity,
scenario, code location, citations, or required identifiers. Do not render a record that cannot satisfy
a non-nullable field.

## Deterministic completion and terminal status

Discovery saturates only after the manifest is frozen, all eight cached query families complete, every
admitted hit is read or terminally limited, every candidate has one terminal disposition, every rendered
assertion and citation validates, and one no-change saturation review adds no candidate, mapping,
disposition, or finding. Do not reopen discovery after saturation.

Select exactly one terminal status using this precedence:

1. `blocked-prerequisite`: Prerequisite, initial capability, repository identity, or pre-collection sanitization failure
2. `excluded/not-applicable`: Valid compatible prerequisite evidence excludes Cosmos DB
3. `bounded-partial-with-findings`: A cap or post-collection failure leaves partial coverage and at least one valid finding
4. `bounded-partial-zero-findings`: A cap or post-collection failure leaves partial coverage and no valid finding
5. `completed-with-findings`: Applicability and all completion conditions pass with at least one valid finding
6. `completed-zero-findings`: Applicability and all completion conditions pass with no valid finding

Permit at most one corrective render. Run one full validation pass; if it changes output, run one final
post-correction pass. A remaining invalid citation, unsupported assertion, conflict, unresolved candidate,
or incomplete source or query family requires a `bounded-partial` status unless a higher status applies.

## Output and handoff

Write one sanitized artifact to
`.copilot-tracking/research/<repository-name>-hve-resiliency-researcher-12-cosmosdb-research-output.md`,
where `<repository-name>` is the sanitized current repository root directory name. Include the single
terminal status, checked manifest roots and exclusions, completed query and read coverage, evidence gaps,
hard-cap usage, compact candidate disposition and assertion-mapping counts, and zero-finding statement
when applicable.

Render each valid finding once with exactly these fields and in this order:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):

These seven fields are the complete finding schema. Do not add fields or repeat their concepts elsewhere.
Keep the artifact evidence-only and omit remediation guidance, recommendations, examples, and next-step
text from the artifact.

End the response, outside the artifact, with exactly one status-aware handoff. For
`blocked-prerequisite`, route to `/hve-resiliency-researcher-1a` when Prompt 1a is missing or invalid;
otherwise route to `/hve-resiliency-researcher-1b`. When both are missing or invalid, Prompt 1a takes
precedence. Do not derive applicability routing from invalid artifacts. For `excluded/not-applicable`,
select the next applicable service-specific prompt after Prompt 12 from the validated artifacts,
beginning with `/hve-resiliency-researcher-13-sql`, or select
`/hve-resiliency-researcher-consolidate` when none remains. Never route a blocked or excluded Prompt 12
run to Prompt 11. For every successful or bounded-partial applicable Prompt 12 run, preserve the normal
validated-artifact routing to the next applicable service-specific prompt beginning with Prompt 13, or
to consolidation when no applicable service prompt remains:

> **Next step:** Run `/<selected-command>`

---

Execute from the prerequisite gate and stop after writing the artifact and response handoff.
