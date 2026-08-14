---
description: Research Entra ID resiliency for Application Platform regional failure
---

# Application HVE Researcher 18 Entra ID

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Scope

Research only the existing Entra ID assessment surfaces:

* Token acquisition, validation, and refresh behavior
* JWT signing key (JWKS) retrieval and caching
* Conditional Access or MFA-dependent flows
* Synchronous calls to Entra ID during request handling
* Hybrid identity dependencies such as AD FS or on-premises services
* Health-probe alignment between global load balancing and backend services

Assess each applicable surface independently for:

* Full regional failover between West US 2 and West US

Use repository evidence only. Do not provide remediation, recommendations, tuning,
implementation guidance, or code examples. Do not infer Entra service topology,
externally administered policy, deployment state, or outage behavior from generic
authentication, OAuth2, OIDC, JWT, or Spring Security evidence.

## Prerequisite Gate

Before source discovery, read the completed Prompt 1a and Prompt 1b research artifacts
for the current repository. Use their authoritative Section 1, Section 2, and Section 3
dependency dispositions.

Proceed only when all conditions are true:

* Both prerequisite artifacts exist, are complete, and identify the current repository.
* Microsoft Entra ID is confirmed in Section 1 of at least one artifact.
* Neither artifact places Microsoft Entra ID in Section 2 or Section 3 or otherwise
   contradicts its inclusion.

Do not replace missing, incomplete, stale, ambiguous, or contradictory prerequisite
evidence with repository guesses. End with the applicable terminal status:

* `BLOCKED_PREREQUISITES` when either artifact is unavailable or incomplete
* `NOT_APPLICABLE` when Entra ID is excluded by the closed Prompt 1a/1b contract
* `EVIDENCE_INSUFFICIENT` when the prerequisite dispositions conflict or are ambiguous
* `READY` when the closed gate passes

After the gate passes, require positive deployed Entra ID proof before assessing any
surface. The threshold is one direct Microsoft Entra ID marker and one production-
controlling binding that governs the same behavior. A direct marker may be an explicit
Entra authority, issuer, discovery or JWKS reference, Entra-specific dependency, or
identity configuration key. A production-controlling binding must show that the marker
is selected by a deployment manifest, infrastructure definition, pipeline input,
production environment overlay, runtime configuration, or its traced source default.
Generic security or token terminology does not satisfy either part. Use
`ENTRA_PROOF_NOT_MET` when no surface meets this threshold within the discovery budget.

## Evidence Rules

Apply this production evidence precedence from highest to lowest:

1. Deployment manifests and production infrastructure definitions
2. Production pipeline inputs and environment overlays
3. Runtime configuration selected by those deployment controls
4. Source configuration defaults traced to a production control
5. Application source that implements the selected behavior

Higher-precedence evidence overrides lower-precedence defaults. Record provenance and
the controlling relationship before making a production claim. Local, test, sample,
development-only, generated, compiled, packaged, vendored, and dependency-cache content
cannot establish production behavior. Exclude `target/`, build output, test trees,
local profiles, secret values, and files outside the current repository. A secret
reference may prove a binding, but its value must never be read or retained.

Sanitize evidence before retaining, comparing, summarizing, or deriving claims. Replace
tenant IDs, client IDs, object IDs, tokens, credentials, certificate material, secret
values, and sensitive URL parameters with descriptive redaction markers. Retain only
the minimum excerpt needed to support a claim.

Every substantive finding claim must map to a semantic citation containing a verified
workspace-relative path, current line number, symbol or configuration key, and minimal
sanitized excerpt. Confirm after writing the artifact that each citation still supports
the exact claim. Do not cite a keyword-only match or use one citation to support an
unrelated claim.

Negative claims are limited to the exact searched roots, query families, file types,
and budgets recorded in the evidence ledger. Write `not found within the recorded
bounded search`, never an unqualified assertion that a dependency or behavior does not
exist.

## Bounded Discovery

Treat Microsoft Entra ID as one dependency and use these maximum budgets for the run:

* 48 total tool calls for the complete run, with calls 45 through 48 reserved for
   terminal artifact writing and validation
* 8 prerequisite lookup tool calls, counted within the 48-call total
* 6 cached query families, each executed at most once across the allowed roots
* 8 search operations, including at most one direct-listing fallback
* 12 unique file reads with no rereads
* 2 levels of reference indirection and 2 queued references per candidate
* 16 unique candidate files and 12 unique issue candidates
* 12 final finding rows across both failure scenarios
* 3 semantic citations per finding row
* 2 retained excerpts per finding row, each at most 240 bytes
* 12,000 bytes of retained sanitized evidence for the complete artifact

Count every individual tool operation against the run-wide total. Count prerequisite artifact searches
and directory listings. Also count direct-listing fallback, reads, writes, and validation calls. Stop
prerequisite lookup before a ninth prerequisite lookup call. If
the prerequisite disposition is still unresolved when 8 prerequisite lookup calls or
44 total tool calls have been consumed, set terminal status `BUDGET_EXHAUSTED` and use
only the reserved calls to write and validate the required non-finding artifact. Never
exceed 48 total tool calls.

Search production-controlling surfaces before source implementation. Limit discovery
to repository-root deployment and build controls, `Actionsfile/`, production
configuration under `src/main/`, and source files reached from those controls. Cache
query-family results, normalized paths, file hashes, candidate dispositions, citations,
and sanitized excerpts. Reuse the cache instead of traversing or reading again. Merge
path aliases and duplicate content before candidate or evidence counting.

Use query families for only the assessment surfaces listed in Scope. A search operation
may combine related terms and file patterns. Follow references only when they can resolve
production precedence or a listed surface, and count every followed file against the
read and candidate budgets.

Reach deterministic fixed-point saturation when one complete pass over all cached query
families and the candidate queue produces no new normalized candidate, citation, or
applicable surface, and every queued candidate has a disposition. Stop immediately at
saturation or when any budget is reached. Do not widen roots, add query families, or
reread files to seek more findings.

Use one terminal status:

* `COMPLETE_WITH_FINDINGS` when saturation is reached with supported findings
* `ZERO_FINDINGS` when saturation is reached with no supported findings
* `BUDGET_EXHAUSTED` when a numeric limit stops discovery before saturation
* `BLOCKED_PREREQUISITES`, `NOT_APPLICABLE`, `EVIDENCE_INSUFFICIENT`, or
   `ENTRA_PROOF_NOT_MET` as defined above


## Research Artifact

Create `.copilot-tracking/research/<repo-name>-hve-resiliency-researcher-18-entraid.md`,
where `<repo-name>` is the current repository name. Create the artifact after the
prerequisite gate and update it progressively after gate disposition, production
discovery, candidate disposition, finding creation, and validation.

Use these top-level sections in order:

1. `Run Status`
2. `Prerequisite and Entra Proof Disposition`
3. `Scope and Evidence Ledger`
4. `Findings`
5. `Validation`
6. `Handoff`

Record the terminal status, budget counters, query families, searched roots, exclusions,
candidate dispositions, production precedence decisions, sanitization confirmation,
and bounded negative-claim scope outside the per-finding schema.

Under `Findings`, repeat this exact field schema for every finding row:

* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None (HVE Task Researcher role is evidence-only)

Give each finding row a unique heading containing a finding ID and exactly one scenario.
When the same issue affects both authoritative scenarios, emit two distinct rows with
separate evidence, risk, and impact. Never combine zone-failure and regional-failover
outcomes in one row.

Every field must be present, in the stated order, and nonempty. When evidence cannot
resolve a value, write `Unknown:` and the bounded reason inside that field. Unknown must
not change headings, list nesting, field count, or row count.

For `ZERO_FINDINGS`, write exactly `No evidence-backed Entra ID resiliency findings.`
under `Findings` and emit no finding rows. For all other non-finding terminal statuses,
write exactly `No finding rows emitted for terminal status: <status>.` under `Findings`.

## Final Validation and Handoff

Before completion, validate that:

* The Prompt 1a/1b gate and positive Entra proof disposition support the terminal status.
* Both authoritative scenarios were independently assessed for every applicable surface.
* Finding rows use the exact schema and separate scenarios.
* Priority definitions, citations, sanitization, counters, evidence limits, and negative
   claims comply with this prompt.
* The artifact path starts with the repository name and the file ends with one newline.

End the artifact and response with the next applicable service-specific prompt confirmed
by Prompt 1 Section 1. When no confirmed service remains, use
`/hve-resiliency-researcher-consolidate`. Format the response handoff as:

> **Next step:** Run `/command-name`

---

Run the prerequisite gate first, then execute this workflow to one terminal status.
