---
description: "Researches shared dependencies for bounded zone and regional failover risk evidence"
agent: "Task Researcher"
argument-hint: "prompt1aArtifact=... prompt1bArtifact=..."
---

# Application HVE Researcher 6 Optimized

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

## Inputs

* ${input:prompt1aArtifact}: (Required) Exact repository-relative path to the completed Prompt 1a artifact.
* ${input:prompt1bArtifact}: (Required) Exact repository-relative path to the completed Prompt 1b artifact.

## Scope

Assess only shared libraries, platform utilities, and centrally managed configuration used by this repository that affect a West US 2 zone failure or regional failover from West US 2 to West US. Dependency categories include shared libraries such as internal packages and shared build parents or plugins, platform utilities such as clients and runtime integrations, and centrally managed configuration such as shared configuration stores, templates, and pipelines.

Use evidence only. Preserve file-and-line citations, ownership boundaries, existing mitigations, constraints, and P0-P3 classification from the platform context. Do not introduce another assessment area.

## Required Protocol

Execute this prompt as an evidence-only Prompt 6 mode that overrides conflicting Task Researcher behavior.

1. Validate both prerequisite artifacts before production discovery.
2. Build the immutable production-source manifest and complete bounded discovery.
3. Consolidate and classify retained evidence, then stop.
4. Skip Task Researcher Phase 2 and any later recommendation or implementation phase.
5. Do not produce alternatives, recommendations, implementation details, code or configuration examples, or remediation.

### Prerequisite Validation

Consume only the literal `prompt1aArtifact` and `prompt1bArtifact` paths supplied through the required inputs. Do not search, glob, select the latest file, infer a path, or broad-scan as fallback.

Before reading production sources, verify each supplied file:

* Exists at the exact supplied path inside `.copilot-tracking/research/`, with no path traversal or symbolic resolution outside that directory.
* Uses the current repository name as its filename prefix and has evidence paths that resolve within the current repository.
* Has the expected producer shape and all required fields. Prompt 1a must contain `Section 1 - Used Azure Services (Evidence Confirmed)`, `Section 2 - Checked but Not Present`, and `Section 3 - Not Applicable`. Its Section 1 is the evidence-confirmed Azure dependency set and each entry must include service name, Azure service category, evidence class, file-line evidence, factual use, and region or failover sensitivity. Prompt 1b must contain `Section 1 — Used External Dependencies (Evidence Confirmed)`, `Section 2 — Checked but Not Present`, and `Section 3 — Not Applicable`; each Section 1 entry must include service or dependency name, file-line evidence, factual use, failover impact, mitigations, health-check and GLB-signaling details, and constraints or limitations.
* Is structurally usable: all producer-required sections are present and required entries are well-formed, with no blocked, failed, unresolved, clipping, or read-error state remaining. A `status: incomplete` artifact is still usable when its committed Section 1 entries are well-formed; consume those entries and record the incompleteness as a coverage gap. Do not require a producer metadata field that Prompt 1a or Prompt 1b does not emit.
* Contains deterministic content proof that it represents the current repository revision or the same current assessment run and is fresh for this invocation. Compare only explicit revision, assessment-run identity, or equivalent content already present in both artifacts and verifiable against the current repository. File timestamps, filenames, ordering, recency, and inference are not proof.

Reject a Prompt 1a artifact that contains both the current Section 1-3 shape and the legacy A-C shape because producer identity is ambiguous. Do not accept the legacy A-C shape. If revision, run compatibility, or freshness cannot be proven from artifact content, select `Blocked: prerequisite incomplete`, identify the missing proof in sanitized validation details, and stop.

If either artifact is missing, outside the allowed directory, stale, ambiguous, malformed, or incompatible, select `Blocked: prerequisite incomplete`. Stop without production discovery, broad fallback, or an empty findings result. A `status: incomplete` artifact that still supplies well-formed Section 1 entries is not a blocking condition; proceed with those entries and note the coverage gap.

Use only dependencies from validated Prompt 1a Section 1 and Prompt 1b Section 1. Exclude Prompt 1a Sections 2-3 and Prompt 1b Sections 2-3.

### Production Manifest

Build one immutable manifest of production sources before discovery. Before path normalization, hashing, or traversal, deterministically filter the enumerated source families to text files whose content type can be read as text. Record each included file once by normalized repository-relative path and source family, then traverse each included file at most once during initial discovery.

Limit the manifest to these source families:

* Dependency manifests and lockfiles
* Application imports and client construction
* Configuration key names
* Deployment manifests and infrastructure as code
* Pipeline definitions
* Shared build parents and plugins
* Documentation used only as an evidence lead

Exclude generated output, vendored code, caches, and test-only references unless a test reference is directly coupled to production behavior. Exclude trust stores, certificates, keys, archives, images, compiled artifacts, and every other binary or content-type failure. Excluded extensions include `.jks`, `.p12`, `.pfx`, `.cer`, `.crt`, `.der`, `.key`, `.zip`, `.jar`, `.war`, `.class`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.bmp`, `.webp`, `.ico`, `.tif`, `.tiff`, and `.svg`. A binary path must never enter the immutable manifest, manifest hash input, traversal, or initial-read count. Documentation alone cannot establish a finding; confirm its lead in production evidence.

### Bounded Discovery

Use these finite query families: validated dependency identities and aliases; imports and client construction; configuration key references; deployment and runtime bindings; infrastructure, pipeline, and shared-build integration; and evidence of ownership, mitigations, or constraints.

Apply every hard limit:

* One initial pass per source family
* One corrective pass per unresolved retained candidate
* One owner read per evidence-backed cross-repository indirection
* Maximum cross-repository indirection depth of 1
* Maximum subagent rounds of 1
* Maximum retained-candidate queue of 40

Treat validated prerequisite evidence used to support a finding as seeded candidates in the same queue before normalization, deduplication, sorting, and application of the 40-item cap. Do not maintain a separate prerequisite-evidence channel. Retain any seeded or discovered candidate only when sanitized evidence connects it to a validated Prompt 1a Section 1 or Prompt 1b Section 1 dependency and the Prompt 6 scope.

Normalize and deduplicate sanitized candidate tuples, sort them by dependency identity, normalized repository-relative path, numeric line, then key or symbol, and apply the 40-item cap only after sorting. Assign every retained candidate a stable terminal candidate ID based on its position in that deterministic sorted admission order. Preserve overflow accountability without retaining full overflow evidence: compute a deterministic overflow digest over the sorted canonical sanitized identities of all overflow tuples and record only its tuple count and hash. The digest input and output must not contain sensitive values. Record the overflow count and select `Incomplete: limit reached` whenever overflow is greater than zero unless a higher-precedence blocked status applies.

Restrict owner and cross-repository follow-up to references found in retained evidence. Assign the blocked-owner disposition only when ownership evidence required to classify a retained in-scope candidate cannot be accessed. Failure to obtain optional owner enrichment is an evidence gap, not owner blocking. Do not infer owner behavior or mitigations.

Every retained candidate ID must end as a finding, an evidence gap, excluded with a cited reason, or blocked owner. Give each unresolved retained candidate exactly one corrective pass. If any retained candidate remains unresolved afterward, select `Incomplete: limit reached` unless a higher-precedence blocked status applies, and report the unresolved count in coverage metrics.

Reaching a hard discovery limit stops new discovery and queue admission. It does not prevent the bounded corrective pass, bounded required-owner work, or terminal classification for candidates already retained. Finish that bounded terminal work before rendering.

Stop discovery at the first applicable condition:

1. Every finite source and query family is complete and every retained candidate is classified.
2. A complete pass produces no new retained candidates and every retained candidate has a terminal disposition.
3. A hard discovery limit is reached.

### Evidence Safety

Sanitize evidence before retaining it in any record, log, hash input, subagent artifact, or response. Retain only repository-relative path, line number, key or symbol, dependency classification, and a redacted description. Never retain credentials, tokens, keys, full connection strings, secret values, or sensitive query parameters.

## Output Contract

Write the repository-prefixed artifact to `.copilot-tracking/research/<repository-name>-hve-resiliency-researcher-6-research-output.md`.

YAML frontmatter must be the first content. Set its `title` value to exactly one allowed terminal status:

* `Complete`
* `Complete with no evidence`
* `Incomplete: limit reached`
* `Blocked: owner unavailable`
* `Blocked: prerequisite incomplete`

Include a frontmatter `description`, then start body content at H2. Do not repeat or paraphrase the selected status in the body.

After bounded terminal work, select exactly one status using this precedence order: `Blocked: prerequisite incomplete`; `Blocked: owner unavailable`; `Incomplete: limit reached`; `Complete with no evidence`; `Complete`. Owner blocking applies only to inaccessible required ownership evidence for a retained in-scope candidate. Select the incomplete status when a hard discovery limit, candidate overflow, or unresolved retained candidate prevents complete bounded coverage. Permit `Complete with no evidence` only when every finite source and query family completed, no finding evidence was retained, and every retained candidate has a terminal disposition. Select `Complete` only when those finite families completed and all retained candidates have terminal dispositions without another higher-precedence condition.

Include coverage metrics for prerequisite artifacts validated, production files manifested and traversed, source families completed, query families completed, candidates retained and classified, candidate overflow count and digest hash, unresolved candidates, corrective passes used, owner reads used, indirection depth reached, and subagent rounds used.

Emit one complete finding for each distinct dependency, resiliency scenario, and failure-mode evidence chain. Put the scenario and failure mode inside `Zone or region failover risk implication`. Do not add an eighth field or another assessment area.

For every finding and evidence-gap record, repeat this exact seven-field schema with no missing or additional finding fields:

* Dependency
* Priority
* Ownership boundary
* Zone or region failover risk implication
* Evidence
* Existing mitigations present, with evidence
* Constraints or limitations, with evidence

Within these seven fields, require every rendered citation and every substantive finding claim to reference one or more terminal retained candidate IDs. No citation or substantive claim may bypass the retained ledger. If evidence needed to support a finding claim is not retained after the cap, do not render that claim. Render the resulting evidence gap with the same seven fields, the applicable schema-safe unknown or completed-search wording, and references to the terminal retained candidate IDs that establish the bounded gap; apply the terminal status rules above.

Use `Unknown: evidence unavailable` within the applicable required field when evidence is inaccessible or conflicting. Use `Not observed in completed searches` within the applicable field only for non-exhaustive absence. Never omit a required label.

Use the priority framework from the platform context without restating its definitions. Gate exhaustive negative statements on complete bounded coverage.

End the response with the inherited next step:

> **Next step:** Run `/hve-resiliency-researcher-7-logging`
