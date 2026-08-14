---
description: "Assess Key Vault zone and regional failover evidence with bounded, sanitized repository research"
agent: "Task Researcher"
argument-hint: "prompt1aArtifactPath=... prompt1bArtifactPath=..."
---

# Application HVE Researcher 10 Key Vault

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Inputs

* `${input:prompt1aArtifactPath}`: (Required) Exact workspace-relative path to the completed Prompt
  1a dependency inventory artifact under `.copilot-tracking/research/`.
* `${input:prompt1bArtifactPath}`: (Required) Exact workspace-relative path to the completed Prompt
  1b dependency validation artifact under `.copilot-tracking/research/`.

Use only these exact paths for prerequisite artifacts. Never search, glob, select the latest file, or
infer a prerequisite path.

## Scope and execution override

Execute this Key Vault service prompt only. Do not auto-start the full resiliency workflow. Skip Task
Researcher Phase 2 and any recommendation-oriented completion behavior. Use repository evidence only.
Do not provide alternatives, recommendations, selected approaches, examples, implementation details,
remediation, or deeper research. Perform validation locally and read-only within the assertion mapping,
render, and verification bounds in this prompt.

Assess only the current repository for these scenarios:

* Zone failure within West US 2
* Full regional failover from West US 2 to West US

Assess only these seven Key Vault areas:

1. Regional vault model
2. Secret, certificate, and key consistency
3. Application behavior
4. Failover triggers
5. Platform limitations
6. Synchronization and drift controls
7. Health and global load balancer alignment

Do not add assessment areas or ownership fields. Verify architectural statements from repository
evidence. Do not assume a two-vault model, active-active behavior, automatic failover behavior, private
endpoint behavior, synchronization, or application and pipeline responsibility. Record unsupported
model, private endpoint, synchronization, or responsibility statements as evidence gaps or constraints,
without converting them into recommendations.

## Prerequisite gate

Validate both input paths before repository research:

1. Normalize each path and confirm it is a workspace-relative file beneath
   `.copilot-tracking/research/`, with no traversal, absolute-path, link, or cross-repository escape.
2. Parse YAML frontmatter from both artifacts. Require `repository`, `assessmentId`, `revision`, `status`,
   `generatedAt`, and `promptId` as non-empty strings. Require `status: Complete`; `promptId: 1a` for the
   supplied Prompt 1a artifact and `promptId: 1b` for the supplied Prompt 1b artifact; `generatedAt` as
   RFC 3339 UTC ending in `Z`; `revision` as the exact current repository commit SHA; and `repository` as
   the current repository name. Require equal `assessmentId` and `revision` values across both artifacts.
3. Define current only as exact revision equality, not artifact age. Treat `generatedAt` only as proof
   that both artifacts belong to one workflow snapshot: their timestamps must be no more than 24 hours
   apart, and neither may be later than current UTC plus five minutes. Select `Blocked` for any missing,
   empty, or invalid field; detached or unavailable current revision; repository, assessment, revision,
   status, or timestamp mismatch; future timestamp; or timestamp spread over 24 hours.
4. Confirm the producer schema, required body fields, and file-line citations are present and valid.
   Frontmatter metadata never overrides malformed producer body content. Required
   dependency records include a dependency or service identity, classification, repository and revision
   identity, producer completion state, and supporting file-line citations.
5. Map Prompt 1a `Section 1 - Used Azure Services (Evidence Confirmed)` to confirmed dependencies.
   Treat `Section 2 - Checked but Not Present` and `Section 3 - Not Applicable` as exclusions.
6. Map Prompt 1b `Section 1 — Used External Dependencies (Evidence Confirmed)` to confirmed dependencies.
   Treat `Section 2 — Checked but Not Present` and `Section 3 — Not Applicable` as exclusions.
7. Continue only when the validated confirmed-dependency sections establish Key Vault applicability.

Select `Not Applicable` only when both validated artifacts provide compatible exclusion evidence for Key
Vault. Select `Blocked` for a missing, stale, malformed, ambiguous, conflicting, cross-run, cross-revision,
or unverifiable input. Do not scan the repository as a fallback and do not emit an empty finding result
when this gate fails.

## Sanitization boundary

Sanitize data before every write, hash input, comparison, manifest record, excerpt, candidate record,
log entry, or output operation. Never retain vault names or full URIs; tenant,
subscription, object, or client identifiers; secret, certificate, or key names or values; credentials;
tokens; connection strings; sensitive query parameters; request or response bodies; or raw logs.

Retain only the generalized type, normalized workspace-relative file and line, sanitized symbol or key
category, non-sensitive behavior, and a stable redacted identity. Use the stable redacted identity for
comparisons and hashes. Select `Blocked` when safe sanitization is impossible.

## Frozen production manifest

After the prerequisite gate and before reading production source content, perform one path-enumeration
pass and create one immutable, normalized, text-only production manifest. Sanitize every manifest value
before retention. Admit at most 200 files, sorted by normalized workspace-relative path, from these source
families only:

* Dependency manifests
* Key Vault SDK imports and client construction
* Vault URI and regional configuration
* Identity and authentication
* Retry, timeout, fallback, and exception handling
* Health endpoints and global load balancer probes
* Deployment and infrastructure as code
* Pipelines, synchronization, drift controls, and write guardrails

Exclude generated or build output, dependency directories, vendored files, binaries, archives,
certificates, keys, trust stores, caches, unrelated services, and tests unless demonstrably coupled to a
production path. Treat documentation only as an evidence lead; it is not final evidence without a
validated production citation. Freeze the manifest before content reads. Do not admit additional files
after it is frozen.

## Bounded evidence collection

Run these finite query families against the frozen manifest, once each, in this order:

1. Regional vault model: regional endpoints, vault selection, deployment topology, and region binding
2. Secret, certificate, and key consistency: duplicated categories, versions, refresh, and consistency
3. Application behavior: client construction, retries, timeouts, fallback, caching, and exceptions
4. Failover triggers: health signals, trigger conditions, sequencing, timing, DNS, and endpoint changes
5. Platform limitations: service assumptions, private endpoints, identity, and unsupported failover claims
6. Synchronization and drift controls: pipelines, replication, reconciliation, writes, and guardrails
7. Health and global load balancer alignment: health endpoints, probe contracts, routing, and dependencies

Use one baseline physical read per admitted text file. Allow one defect-specific corrective reread per
file at most. Follow one owner or source indirection for each evidence-backed dependency, at depth 1
only, and record the indirection. Do not use an indirection to discover unrelated files.

Apply these run caps:

* 200 manifest files
* 80 retained evidence-bearing candidates
* 40 rendered findings
* 65,536 total bytes of retained sanitized evidence
* Zero subagent invocations
* One corrective render
* Two full verification passes, including the post-correction pass

Reaching a hard limit stops new admission and discovery. Finish bounded classification and disposition of
already retained candidates. Mark the run `Incomplete` unless a higher-precedence terminal state applies.

## Candidate ledger and finding construction

Create each stable candidate ID from the deterministic normalized tuple of assessment area, scenario,
failure-mode class, normalized path and line, and sanitized symbol or category. Sort this tuple before
applying candidate or finding caps.

Assign every retained candidate one terminal disposition: rendered finding, merged into finding,
validated non-finding, evidence gap, invalid citation, insufficient evidence, conflict, or unresolved at
limit. Maintain both candidate-to-finding and finding-to-candidate mappings. Validate every cited path,
line, and line range against the baseline read or the one permitted corrective reread.

Before rendering, map every material assertion in the issue description, scenario-specific risk or
failure mode, impacts, existing mitigations, and constraints or limitations to at least one retained
candidate ID containing a sanitized excerpt whose cited content semantically supports that assertion.
Validate support per assertion, not per finding or line existence. Record assertion-to-candidate and
candidate-to-assertion mappings in the bidirectional ledger. When support is absent or conflicting,
narrow the assertion to what the evidence supports. If no material supported assertion remains, retain
the candidate as an evidence gap and do not render it. Count unsupported and narrowed assertions in
metrics.

Emit one complete finding for every distinct dependency or category, scenario, and materially distinct
failure-mode evidence chain. Keep zone and regional findings separate when risk, priority, impacts,
mitigations, constraints, or evidence differ. Merge only exact semantic identities, retain every source
candidate ID, preserve the highest evidence-supported priority, and retain conflicting context as a
constraint or conflict disposition.

Use only P0, P1, P2, or P3 according to the inherited priority definitions. A renderable finding requires
one allowed scenario in the failover rationale field, a material failure mode, a valid priority, and at
least one validated file-line citation. Retain invalid records in the candidate ledger but do not render
them as findings. Use `Unknown: evidence unavailable` only in nullable prose fields for impacts, existing
mitigations, or constraints. Never use it for priority, scenario, issue identity, code location, or
evidence.

## Negative evidence rules

Use `Complete with no evidence` only when Key Vault applicability is confirmed and every frozen source
family and query family completes without an evidence-bearing candidate. For an absence within otherwise
partial coverage, use `Not observed in completed searches` and identify its completed scope. Do not make
exhaustive negative claims when coverage is partial.

## Terminal status and metrics

Apply terminal status precedence in this order:

1. `Blocked`: Invalid prerequisites, unavailable required sources, unsafe evidence, or an unresolved
   required conflict
2. `Not Applicable`: Validated compatible exclusion evidence from both prerequisite artifacts
3. `Incomplete`: A limit was reached, retained work remains unresolved, or source or query coverage is
   partial
4. `Complete with no evidence`: Confirmed applicability and fully completed coverage with no
   evidence-bearing candidates
5. `Complete`: Fully completed coverage with all valid findings rendered

Report counts and completion state for source families, manifest files, baseline reads, corrective
rereads, query families, candidates by disposition, findings, citations and invalid citations,
unsupported assertions, narrowed assertions, indirections, subagent invocations (always zero),
sanitization failures, retained sanitized evidence bytes, and each hard limit.

## Completion gate

Select `Complete` only after the manifest is frozen; every admitted file and finite query family is
complete; every retained candidate has a terminal disposition; required citations, output schema, and
bidirectional candidate, finding, and assertion mappings validate; every material rendered assertion has
semantic support from a mapped sanitized excerpt and citation; no required conflict remains; and one full
verification pass produces no changes. Permit at most one corrective pass and corrective render. If
correction occurs, run one post-correction verification. Do not exceed two full verification passes total.

## Output

Write one sanitized research artifact to
`.copilot-tracking/research/<repository-name>-hve-resiliency-researcher-10-keyvault-research-output.md`,
where `<repository-name>` is the sanitized current repository root directory name. Include the terminal
status, metrics, candidate disposition ledger and mappings, then render each valid finding exactly once
with this centralized service schema:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app, zone or region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None

Preserve every field. Do not add ownership or recommendation fields. End the response with the inherited
next step:

> **Next step:** Run `/hve-resiliency-researcher-11-aks-istio`
