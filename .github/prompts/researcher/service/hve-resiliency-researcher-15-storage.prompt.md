---
description: Assess confirmed Azure Storage dependencies for regional resilience
agent: "Task Researcher"
---

# Application HVE Researcher 15 Azure Storage

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

## Objective And Execution Boundary

Assess only evidence-confirmed Azure Storage dependencies in the current
repository. Evaluate these two scenarios independently:

1. Full regional failover between West US 2 and West US

This invocation executes only Prompt 15. Keep all repository interaction
read-only except for the Prompt 15 research artifact. Do not perform another
resiliency prompt, planning, remediation, alternative analysis, implementation
examples, configuration examples, or generic Task Researcher recommendations.
Do not delegate unless the active agent requires one non-delegating researcher
to use the same bounds and return only sanitized evidence and ledger updates.

## Closed Assessment Scope

Evaluate exactly these seven areas for each confirmed Azure Storage dependency
or service type. Do not introduce another service concern or assessment area.

1. Writes across regions, including evidenced concurrent or single-region behavior
2. Idempotency, retries, and conflict resolution through evidenced ETags, metadata, or versioning
3. Read and write behavior during regional Storage or service failure, including evidenced fallback
4. Evidenced synchronous and asynchronous replication paths and their implications
5. Blob Storage and Azure Files dependencies and evidenced disaster-recovery assumptions
6. Evidenced operational failover and failback steps and runbook gaps
7. Alignment between GLB health probes and backend service health

Azure Queue Storage or Table Storage can identify the confirmed Storage service
type, but does not add an assessment area. Analyze it only through the seven
areas above.

## Prerequisite Scope Contract

Derive `<repository-name>` once from the case-preserving root-directory basename.
Derive `<YYYY-MM-DD>` once as the current UTC assessment date. Read exactly these
prerequisite artifacts and no substitutes; match the `<repository-name>` segment
case-insensitively per the normalization rules below:

* `.copilot-tracking/research/<YYYY-MM-DD>/<repository-name>-hve-resiliency-researcher-1a-research.md`
* `.copilot-tracking/research/<YYYY-MM-DD>/<repository-name>-hve-resiliency-researcher-1b-research.md`

Each artifact must use this producer grammar. Frontmatter starts with a `---`
fence, optionally preceded by a single `<!-- markdownlint-disable-file -->`
HTML comment as the first line only. The frontmatter uses YAML with ASCII
space indentation; treat any hard tab used for YAML indentation as malformed
input. The frontmatter must contain at least these lowercase keys, each once,
with scalar values; additional keys are allowed but ignored:

```yaml
---
title: <any nonempty string>
description: <any nonempty string>
ms.date: <YYYY-MM-DD>
ms.topic: research
source-prompt: <hve-resiliency-researcher-1a or hve-resiliency-researcher-1b>
schema-version: <positive integer>
status: current
---
```

Prompt 1a must use `source-prompt: hve-resiliency-researcher-1a`; Prompt 1b
must use `source-prompt: hve-resiliency-researcher-1b`. `status: current` is
the producer-completed signal. `ms.date` must match the `<YYYY-MM-DD>` segment
of the artifact path. After frontmatter, require one H1 with any nonempty
text, then these three H2 headings once and in order with no other H1 or H2;
accept either ASCII hyphen `-` or em-dash `—` as the separator in each H2. The
Section 1 heading text differs by producer:

1. `## Section 1 - Used Azure Services (Evidence Confirmed)` for Prompt 1a, or
   `## Section 1 — Used External Dependencies (Evidence Confirmed)` for Prompt 1b
2. `## Section 2 - Checked but Not Present`
3. `## Section 3 - Not Applicable`

Each section contains either the exact empty token `* None` or one or more
dependency entries, never both. Each dependency entry starts with an H3 whose
text is the canonical dependency name (any leading numeric ordinal and period
such as `1. ` is stripped for identification), followed by a bulleted list
under that H3 containing at least:

* A name field labeled `Service name:` (Prompt 1a) or `Service / Dependency name:` (Prompt 1b) whose value repeats or clarifies the canonical name.
* An evidence field labeled `Evidence:` (Prompt 1a) or `Evidence (binding):` (Prompt 1b) whose child bullets each contain at least one `<repository-relative-path>:<line>` citation. A citation path uses `/`, is relative to the repository root, contains no `..`, and ends in a positive decimal line number. Every entry requires at least one citation whose line exists and supports the section classification.

For canonical name `Azure Storage`, derive the subtype from the H3 name using
this rule set, comparing case-insensitively after stripping any leading ordinal:

* `Blob Storage` when the H3 contains `Blob`
* `Azure Files` when the H3 contains `Files`
* `Queue Storage` when the H3 contains `Queue`
* `Table Storage` when the H3 contains `Table`
* `Unspecified` otherwise, including a generic `Azure Storage` H3 with no subtype qualifier

Treat an H3 as canonical name `Azure Storage` when its ordinal-stripped text
starts with `Azure` and contains any of `Storage`, `Blob`, `Files`, `Queue`,
or `Table` in the sense of a Microsoft Azure Storage account service.

For equality and duplicate checks, trim surrounding ASCII whitespace, collapse
internal ASCII whitespace to one space, normalize `\` to `/` in identifiers and
paths, and compare repository, source-prompt, canonical name, and subtype
values case-insensitively. The `<repository-name>` segment of each artifact
path must equal the case-preserving root-directory basename under
case-insensitive comparison. Both artifacts must share the same `ms.date`
value under exact comparison. Preserve source-prompt spelling and body text
for output; normalization never repairs an input.

Within an artifact, duplicate normalized `<canonical-name>|<canonical-subtype>`
keys are malformed. A normalized canonical name appearing in multiple sections,
with any subtype, is conflicting. Across Prompt 1a and Prompt 1b, the same
normalized canonical name in different sections is conflicting. Any missing,
unreadable, malformed, duplicate, citation-invalid, or conflicting artifact,
and any artifact whose `status` is not `current`, is `Blocked: prerequisite`.

Prompt 1a is the Azure dependency authority. Continue only when its Section 1
explicitly confirms canonical name `Azure Storage` with one or more accepted
subtypes. Prompt 1b is required for metadata and cross-artifact consistency but
cannot place `Azure Storage` in Section 1; doing so is conflicting. When valid
Prompt 1a evidence places `Azure Storage` only in Section 2 or Section 3, stop as
`Not applicable / excluded`. When valid Prompt 1a evidence does not classify it
in any section, stop as `Blocked: prerequisite`. Ignore non-Storage item content
after completing the grammar, duplicate, and conflict checks required by this
gate.

For every artifact finalized after both prerequisites validate, record in the
prerequisite or coverage section the exact Prompt 1a and Prompt 1b artifact-line
citations that establish metadata agreement and the Azure Storage inclusion or
exclusion decision. This applies to excluded, blocked-tool, bounded-partial,
completed-with-findings, completed-with-zero-findings, unsafe-evidence, and
generic-Storage outcomes. Keep these as prerequisite coverage citations only.
Never copy them into a finding or use them to satisfy finding evidence.

## Immutable Production Source Manifest
* Why this is a risk to app or region failover:
After the prerequisite gate passes, create one sorted, deduplicated, text-only
manifest and never enumerate files again. Include existing files only from
these roots, in this precedence order:

1. Production-bound deployment and operations: `Actionsfile/**`, `.github/workflows/**`, `deploy/**`, `deployment/**`, `manifests/**`, `helm/**`, `charts/**`, `k8s/**`, `infra/**`, `terraform/**`, `bicep/**`, and `runbooks/**`
2. Application production code and configuration: `src/main/**`, `config/**`, and `scripts/**`
3. Root build and packaging files: `pom.xml`, `Dockerfile`, `*.sh`, and `*.properties`
4. `docs/**` as corroboration only, never as sole proof of deployed behavior

Exclude `src/test/**`, `target/**`, build output, generated files, caches,
`.git/**`, editor metadata, `.copilot-tracking/**` except the two prerequisite
artifacts, certificates, binary files, archives, wrappers, vendored dependencies,
and secret-value files. Include extensionless files only when they are text and
reside in an included operations root.

Resolve conflicting values by this evidence precedence: an explicit production
deployment invocation or resource binding; a production overlay named `prod`,
`prodsre`, or `*-prod`; a deployment base/default; an application source
default; corroborating documentation. Preserve a conflict at the same level as
an evidence gap. Never infer that a source default is production-bound.

Classify every retained configuration assertion as one of: source default,
production-bound value, or unavailable operational evidence. The last category
is an evidence gap, not proof of absence or a finding by itself.

## Bundled Query Matrix

Define one research unit for each unique normalized Azure Storage subtype in
Prompt 1a Section 1 after prerequisite deduplication. `Unspecified` is one unit;
do not also create an account-level or generic Azure Storage unit. For each unit,
run each query family once against the immutable manifest. Bundle all family
terms into one tool invocation when the tool supports alternation or multiple
terms; that invocation counts once regardless of term count. If a tool requires
separate invocations, each invocation counts and all invocations together are
the unit's single family execution. Cache sanitized results by research unit and
family. Reuse the cache without another invocation, and never repeat a family
because results were sparse.

1. Service identity and binding: Blob, Files, Queue, Table, SDK/client/API, Azure resource type or ID, endpoint, connection binding, deployment resource
2. Writes and consistency: write/create/update/upload, concurrent or single writer, retry, idempotency, ETag, metadata, version, conflict
3. Failure behavior: timeout, exception, fallback, alternate endpoint, endpoint selection, failover, failback, degraded read or write
4. Replication and topology: region, West US 2, West US, primary, secondary, redundancy, LRS, ZRS, GRS, GZRS, RA-GRS, RA-GZRS, synchronous, asynchronous
5. Operations: runbook, manual step, account failover, DNS, routing, recovery, rollback, data-loss statement
6. Health signaling: health, ready, live, probe, GLB, upstream routing, dependency readiness

Generic `storage`, filesystem paths, certificates, build artifacts, Maven terms,
local persistence, comments, imports, package dependencies, or names do not prove
an Azure Storage service. Service identity requires an Azure Storage SDK or API
bound to use, an Azure Storage endpoint, an Azure resource declaration or ID, a
deployment binding, or a connection setting whose non-secret structure identifies
the service. A library or import requires a second binding signal.

Treat regions, redundancy modes, replication, topology, fallback, failover,
failback, and data-loss behavior as claims to verify. Unsupported values become
field-safe `Unknown` or evidence gaps. Do not substitute Azure defaults, product
documentation, common architecture, or operator knowledge for repository evidence.

## Hard Run Caps

Enforce every cap across the entire Prompt 15 run, not separately per research
unit, service, scenario, agent, or phase. Delegated work uses the same ledgers.
Count each inventory or search tool invocation once, including failed calls. A
single invocation that inventories multiple roots counts once; constructing or
sorting the manifest from returned data adds no invocation.

Count every file-read tool invocation against the 64-read cap, including a
failed read. Track successful first reads as unique cached paths. Reusing a
cached result consumes no read. A deliberate read of an already cached path
counts against both the 64-read cap and the six-reread cap, whether it succeeds
or fails. A read reached through a retained source counts against the read cap
and records its depth; cached reuse does not increase depth or counts.

| Resource | Hard cap |
| --- | ---: |
| Manifest files retained | 240 |
| Total inventory and query/search invocations | 25 |
| File-read invocations, including prerequisites and failed reads | 64 |
| Corrective rereads of an already cached file | 6 |
| Indirection depth from a retained source | 2 |
| Canonical candidates | 48 |
| Rendered findings | 24 |
| Sanitized evidence retained for the run | 65,536 bytes |

If eligible manifest files exceed 240, retain the first 240 by root precedence
and canonical path order and record omitted counts. A cap flips the run
irreversibly to `Bounded partial` immediately when usage reaches the cap while
required work remains, or before the next operation would exceed it. Stop all
new inventory, searches, reads, candidate creation, and finding creation at that
event; preserve only already validated results. Exact cap usage can complete
only when no required work remains. Do not evict evidence to make room.

## Trusted Transient Evidence Boundary

Ordinary search and read tools may return raw text. Treat each raw tool result as
trusted transient input only. Before retaining, deriving a claim, quoting,
logging, hashing, caching, or writing any content, sanitize credentials,
connection strings, URI user information, Authorization values, passwords,
tokens, SAS parameters and signatures, account keys, encryption keys, and PII.
Replace values with `<redacted>` while retaining safe setting names, resource
types, endpoint hostnames, regions, redundancy tokens, structural context, paths,
and line numbers.

Audit sanitized content before use. If safe sanitization or line attribution is
uncertain, discard the content and record an evidence gap. Count UTF-8 bytes only
after sanitization. A retained evidence slice is the exact sanitized set of
source lines, including the minimum context lines retained with a match, keyed by
canonical path, inclusive line range, and sanitized content. Count each unique
slice once when it first enters a prerequisite or source-evidence cache. Merge
overlapping slices from the same path and count only newly retained UTF-8 bytes.
Cached reuse and repeated citation rendering add zero bytes. Generated artifact
prose, ledger labels, IDs, and status text add zero bytes. Failed calls and
discarded unsafe results add zero bytes. Whole raw tool results remain transient
and are never byte-cap input. Never persist raw search output, raw read output,
or a secret value in the research artifact, ledger, ID input, quotation, or
response.

## Candidate And Evidence Control

Create candidates in canonical manifest order. Assign stable IDs `STO-C001`,
`STO-C002`, and so on after sorting by this deduplication key:
`<service-type>|<scenario>|<failure-mode>|<behavior-owner-path>|<production-binding>`.
Merge only identical keys. Give each candidate exactly one terminal disposition:
finding, evidence gap, covered with no issue, false positive, out of scope, or
duplicate of another candidate ID.

For each retained assertion, map the assertion to one or more sanitized
`repository-relative-path:line` citations. Validate that every cited path is in
the immutable manifest, every line exists, and the cited text supports the
adjacent assertion. Correct or discard unsupported mappings once; do not search
for replacement evidence after saturation.

Negative claims are bounded only to the manifest, query matrix, cached results,
and read ledger. State `No evidence found within bounded coverage`, never a
universal absence. Coverage entries can cite the prerequisite, manifest, query,
and disposition ledgers, but a finding must cite substantive repository evidence.
Do not fabricate a finding citation from a coverage citation.

Assign finding IDs `STO-F001`, `STO-F002`, and so on after sorting accepted
candidates by service type, scenario order, failure mode, and owner path. Emit
separate finding rows for materially distinct failure modes. When evidence
supports both authoritative scenarios, emit a distinct row for each scenario,
even when they share source evidence. Do not collapse scenario-specific behavior,
failure effects, mitigations, constraints, or unknowns.

## Priority Framework

Use these definitions once for all findings:

* P0: Critical or blocking evidence shows outage, data loss, duplicate charges, or inability to fail over safely during the assessed scenario.
* P1: Required but non-blocking evidence shows materially increased application risk, data risk, or customer impact during the assessed scenario.
* P2: Evidence shows a non-blocking resilience or operational-clarity weakness that does not materially affect failover correctness.
* P3: Evidence shows non-blocking maintainability, readability, duplication, or pattern inconsistency.

Every priority requires an evidence-bound failure effect and scenario rationale.
`Unknown` cannot receive a priority. Keep an unsupported or incomplete candidate
as an evidence gap rather than a finding.

## Deterministic Completion

Saturation occurs when all prerequisite-confirmed Storage dependencies have all
six query families dispositioned, every retained candidate has one terminal
disposition, every accepted finding has validated assertion-level citations,
all seven focus areas and both scenarios have a coverage disposition, and the
single corrective review creates no new candidate. After saturation, prohibit
new searches and reads. A validated evidence-gap disposition completes its
coverage cell and permits `Completed with zero findings` when every other
saturation condition succeeds. Only an undispositioned or unvalidated required
cell, family, candidate, citation, or corrective review leaves coverage
incomplete and forces `Bounded partial`.

End with exactly one terminal status using this precedence:

1. `Blocked: prerequisite` for a missing, unreadable, malformed, duplicate, non-completed, or conflicting prerequisite
2. `Not applicable / excluded` for a valid Prompt 1a Section 2 or Section 3 Azure Storage classification
3. `Blocked: tool` when required inventory, search, read, sanitization, or write capability is unavailable before any validated research result exists
4. `Bounded partial` when a cap is reached, a required capability fails after validated work exists, coverage remains incomplete, or safe citation validation cannot finish
5. `Completed with findings` when saturation succeeds with at least one finding
6. `Completed with zero findings` when saturation succeeds with no finding

Do not claim completion from elapsed time, token pressure, sparse matches, or a
subjective sufficiency judgment. Prompt 11 handoff is authorized only by a
completed status or a `Bounded partial` artifact that preserves validated
research and identifies incomplete coverage. Never issue it for either blocked
status or `Not applicable / excluded`. Suppress the generic planning handoff in
all statuses.

## Research Artifact

Write progressively to exactly
`.copilot-tracking/research/<repository-name>-hve-resiliency-researcher-15-storage-research-output.md`.
Before any prerequisite read, atomically create or replace this artifact with
the assessment contract, `Run State: In progress`, and no terminal status. Do
not start prerequisite or production work unless that write succeeds. Each
progress update writes one complete replacement and must not expose a partial
document. Finalization atomically replaces `Run State` with exactly one
`Terminal Status` from the precedence list.

If a prerequisite is missing, malformed, duplicate, non-completed, conflicting,
or unreadable, perform no manifest or production query work and atomically
finalize the minimal artifact as `Blocked: prerequisite`. Include only the
contract, sanitized reason, available validated prerequisite citations, and
terminal status. If initial artifact creation is unavailable, no artifact can be
created: return `Blocked: tool`, report `Artifact: unavailable`, perform no
reads, and issue no handoff. If any later required tool fails, finalize the
existing artifact as `Blocked: tool` before a validated research result exists,
or `Bounded partial` after one exists. If the final atomic write itself fails,
report the same computed status and `Artifact: unavailable or not finalized` in
the response, leave the last complete document unchanged, and issue no handoff.
Never report a stale in-progress document as a terminal artifact.

The artifact contains, in order: assessment contract, prerequisite result,
immutable manifest summary, coverage and cap ledger, candidate disposition
ledger, evidence gaps, findings, and terminal status. Ledgers are control
sections and do not add finding fields or assessment areas. On a prerequisite
or pre-research tool block, use the minimal form defined above.

## Authoritative Finding Schema

Render each finding with exactly these seven fields, names, and order. Add no
field to a finding row and do not repeat field semantics elsewhere.

* `Issue Description:` Begin with `<finding-id> | <scenario> | <Storage service type> | <failure mode>`, followed by the evidence-bound observation. None of the four required identifiers can be `Unknown`.
* `Risk Level (P0/P1/P2/P3):` Use one priority from the authoritative framework. `Unknown` is prohibited.
* `Code location (file + line number):` Provide one or more validated, sanitized repository-relative file-line citations. `Unknown` is prohibited.
* `Why this is a risk to app region failover:` State the evidenced scenario-specific failure effect that supports the priority. `Unknown` is prohibited.
* `Impact(s) if this is not changed:` State only evidenced impacts; use `Unknown` when repository evidence does not establish the impact beyond the supported failure effect.
* `Existing mitigations present (evidence):` State evidenced mitigations with citations, `None found within bounded coverage`, or `Unknown` when operational evidence is unavailable.
* `Constraints/limitations (evidence):` State evidenced constraints with citations, `None found within bounded coverage`, or `Unknown` when operational evidence is unavailable.

`Unknown` is allowed only in the last three fields as defined above. It is never
valid for a priority, terminal status, citation, candidate ID, finding ID,
scenario, service type, failure mode, repository identifier, producer identifier,
or other required identifier. Evidence gaps remain outside finding rows.

## Response Contract And Handoff

Return exactly this concise summary with values and a clickable relative artifact
link when a finalized artifact exists. Do not repeat findings or add remediation
content.

* `Artifact:` Prompt 15 artifact link, or the exact unavailable state defined above
* `Terminal status:` Exact terminal status
* `Findings:` Rendered finding count
* `Evidence gaps:` Evidence-gap count
* `Coverage:` Manifest files, search invocations, read invocations, unique cached paths, corrective rereads, and sanitized retained bytes as used/cap

For `Completed with findings`, `Completed with zero findings`, or `Bounded
partial`, end with the platform HVE next step: run the next
applicable service-specific prompt confirmed by the prerequisite scope contract,
or `/hve-resiliency-researcher-consolidate` when none remains. For either blocked
status, name only the prerequisite or capability that must be restored before
rerunning Prompt 15. For `Not applicable / excluded`, direct the user to the next
applicable service-specific prompt or consolidation. Authorize a Prompt 11
handoff only when the Prompt 15 artifact finalized successfully as completed or
`Bounded partial`. Never issue Prompt 11 for either blocked status, `Not
applicable / excluded`, or an unavailable or unfinalized artifact. Never hand
off directly to planning from Prompt 15.
