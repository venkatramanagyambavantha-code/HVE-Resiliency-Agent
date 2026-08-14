---
description: Analyze regional failover assumptions with bounded discovery and exact evidence
agent: "Task Researcher"
argument-hint: "prompt1a=... prompt1b=..."
---

# Application HVE Researcher 2

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md)
in full. On direct invocation, begin at Step 1 of this protocol and run Prompt 2
only. This entry point overrides instructions to start or continue the broader
resiliency workflow. Do not run another resiliency prompt.
For direct Prompt 2 invocation, this prompt's Steps 1-4 and Required Protocol,
deterministic artifact path, and four terminal-state success criteria replace
any inherited `Task Researcher` phase sequencing, subagent delegation, dated
output path, research-document template, or generic success criteria that
conflict. Execute the investigation directly under this protocol and do not
create inherited primary or subagent artifacts.

## Inputs

* `${input:prompt1a}`: Required path to the completed Prompt 1a artifact for the
  current repository
* `${input:prompt1b}`: Required path to the completed Prompt 1b artifact for the
  current repository

## Objective

Identify all evidence-confirmed regional failoverassumptions in the
current repository. Evaluate each assumption for regional failover between 
West US and West US 2 as part of the target deployment.

Cover production application code, configuration, infrastructure as code,
deployment manifests, pipelines, scripts, and operational runbooks. Evaluate
hard-coded region names; security values; credentials that are hard-coded or
stored in files; implicit defaults; single-active-region
logic; endpoints, URLs, or IP addresses; resource identifiers; deployment
locations and topology; routing; affinity; and environment-specific values that
reference one region.

## Required Steps

### Step 1: Validate Prerequisites And Scope

Resolve prerequisites in this order and prefer proceeding over blocking.

1. Read each provided prerequisite artifact once. Do not search the repository
   for alternate copies.
2. Build the confirmed dependency inventory from Prompt 1a `Section 1 - Used
   Azure Services (Evidence Confirmed)` and Prompt 1b `Section 1 — Used External
   Dependencies (Evidence Confirmed)`. Use whichever qualifying Section 1
   inventories are available; an artifact marked `Status: Incomplete` still
   contributes its committed Section 1 entries.
3. Exclude Prompt 1a Sections 2 and 3 and Prompt 1b Sections 2 and 3. Do not
   analyze a dependency absent from both confirmed inventories. If only one of
   Prompt 1a or Prompt 1b qualifies, proceed with the available Section 1
   inventory and record the missing side as an `Unknown: external evidence
   required` entry at the report level.
4. Stop as `Blocked` before repository traversal only when neither Prompt 1a nor
   Prompt 1b can be resolved: every supplied input is missing, unreadable,
   belongs to another repository, or is malformed, and no qualifying Section 1
   inventory remains on either side. Report the exact prerequisite problem and
   request the corrected path. Do not write the research artifact or suggest
   Prompt 3.
5. If both prerequisites resolve but the combined confirmed Section 1 inventory
   contains zero dependencies in scope for Prompt 2, do not block; emit
   `Complete: bounded no evidence` with a single note that no confirmed
   dependency was in scope, and list the resolved prerequisite paths.

### Step 2: Build The Manifest And Candidate Ledger

1. Build and reuse one path-only manifest filtered to the production evidence
   sources in the Objective. Exclude `.git/**`, `.copilot-tracking/**`, generated
   outputs, caches, binaries, vendored dependencies, prompt artifacts, and every
   local override pattern excluded by the platform context.
2. Run one broad multi-pattern candidate scan across that manifest for all
   assumption classes in the Objective. Do not enumerate the repository or run
   another candidate scan after this scan completes.
3. Create a compact candidate ledger. Record only a stable candidate ID,
   canonical path, current line range, assumption class, confirmed dependency,
   smallest safe verbatim excerpt or `citation only`, and disposition. Do not
   retain complete raw scan output or reread files without candidates.
4. Never reproduce a credential, token, key, signature, or secret value. Use a
   verified path and line citation and, when available, a verbatim non-secret
   identifier.

### Step 3: Verify Evidence And Dispose Candidates

1. Analyze each candidate owner once. Follow at most two direct references per
   candidate, and only when needed to fill a required output field or verify an
   existing mitigation or constraint. Do not expand into adjacent architecture
   or general dependency research.
2. Verify every retained path and current line range against the current file.
   Store source text only as a character-for-character excerpt, including case,
   quoting, and whitespace. If safe exact reproduction is not possible, use
   `citation only`.
3. Assign every candidate exactly one terminal disposition: `finding`,
   `duplicate`, `excluded source`, `unrelated literal`, `unsupported claim`, or
   `evidence gap`. Do not leave a candidate undisposed.
4. Build every finding and every substantive clause only from verified ledger
   rows. Do not paraphrase, summarize, reformat, or fabricate code or
   configuration. Analytical statements must be strictly supported by the cited
   rows. Remove any statement that requires an uncited assumption.

### Step 4: Audit And Render

1. Audit every finding once against current file contents, the confirmed
   dependency inventories, and the P0-P3 definitions in the platform context.
   Correct or remove any unverifiable path, line range, excerpt, dependency,
   priority, or claim without running another scan.
2. Finish as `Incomplete` if any in-scope file cannot be read, scan coverage is
   clipped or uncertain, a candidate has the `evidence gap` disposition, or the
   evidence audit fails. Write the deterministic artifact with the status,
   completed coverage, disposed candidate IDs, and exact unresolved issue. Do
   not present a negative conclusion or suggest Prompt 3.
3. Finish as `Complete - No Findings` only when the manifest and candidate scan
   completed, every candidate has a non-gap terminal disposition, and the audit
   confirms that no valid findings remain. Write the factual empty-success form
   from the Output Contract and include the Prompt 3 next step.
4. Finish as `Complete - Findings` only when every candidate is disposed and
   every rendered finding passes the audit. Write the finding form from the
   Output Contract and include the Prompt 3 next step.

## Output Contract

Write the result to
`.copilot-tracking/research/<repo-name>-researcher-2-region-zone-assumptions.md`.
Keep it evidence-only. Do not include remediation, advice, or code examples.

For `Complete - Findings`, repeat these fields for each evidence-confirmed
assumption. Preserve the labels exactly.

```text
# Prompt 2 Research Output

Status: Complete - Findings

## Region Assumptions

* Assumption:
* Priority: P0 / P1 / P2 / P3
* Evidence (file path + line number)
* Brief description of how it is used
* Whether it materially impacts regional failover (Yes/No + description of why this could impact regional failover)
* Existing mitigations present (if any): retries/timeouts/fallbacks/feature flags/runbooks, with evidence (file path + line number)
* Constraints/limitations (if any): dependency/platform capabilities or configuration/operational constraints that shape failover behavior, with evidence (file path + line number) when present
```

For `Complete - No Findings`, write the same H1, status, and H2 followed by:

```text
No evidence-confirmed regional failover assumptions were found within the validated dependency scope and completed manifest, candidate scan, candidate disposition, and evidence audit.
```

For `Incomplete`, do not use either complete form or imply that no findings
exist. Record only verified progress and the exact condition that prevented
completion.

## Required Protocol

1. Run Steps 1-4 once in order.
2. Use one read per prerequisite, one filtered manifest, one broad candidate
   scan, one owner analysis per candidate, at most two necessary direct
   references per candidate, and one evidence audit.
3. Do not re-enumerate the repository, rescan an assumption class, rebuild the
   manifest, or add files after the manifest is fixed.
4. Apply the platform context when it is stricter. Preserve its evidence,
   P0-P3 priority, local override exclusion, and successful next-step rules.
