---
description: "Audit and correct the source evidence in a Code-Level Resiliency Assessment — verify every citation, enforce verbatim quoted code, validate each remediation against its recommendation, and keep all cross-references consistent — for a single finding, one priority tier, or the entire report. Typical run: one finding ~3–6 min, a tier ~20–50 min, the full report ~1.5 h."
---

# Fix Assessment Findings

## Objective

Guarantee that every piece of source evidence in a Code-Level Resiliency Assessment is faithful to the repository — each citation resolves to the correct line range, each quoted `**File:**` block is an exact copy of the real file, each `**Fix:**` block satisfies its stated recommendation, and every cross-reference to a finding stays in sync — all without altering the analyst's prose.

## Invocation

Invoke with a single `<SCOPE>` argument:

| `<SCOPE>` | Meaning |
|---|---|
| A finding ID (`P0-004`, `P1-025`, `P2-007`, `P3-001`) | Process that one finding. |
| A priority tier (`P0`, `P1`, `P2`, `P3`) | Process every finding in that tier, in ascending numeric order. |
| `all` | Process every finding, tier by tier, in the fixed order `P0 → P1 → P2 → P3`, pausing after each tier for the user to accept its report before continuing. |

The editing rules (R1–R10) are identical in every mode. Scope changes only orchestration: single-finding mode applies the rules once; tier and `all` modes batch the shared work — file reads, sibling harmonization, and cross-reference synchronization — so each occurs once per tier rather than once per finding.

## Definitions

- **Finding** — one H4 entry in the assessment, headed `#### <TIER>-<n>: <title>`, containing analyst prose plus a `**File:**` citation, a verbatim code block, and a `**Fix:**` code block.
- **Citation (cite)** — a `path/to/file.ext:Lx` or `:Lx-Ly` reference. It appears on the `**File:**` line and may also appear inline within prose.
- **Verbatim block** — the fenced code block immediately following `**File:**`. It must reproduce the cited source exactly.
- **Fix block** — the fenced code block following `**Fix:**`. It proposes the remediation and may introduce new code.
- **Sibling findings** — two or more findings that cite the same source file.
- **Harmonization** — reconciling sibling findings so their line ranges for the same construct agree.

## Fixed assessment structure

The assessment always has the same shape; nothing here is configurable per repository:

- **Location** — the report is the sole Markdown file under `Microsoft Assessment/`. Its filename varies per repository, so Step 0 discovers it rather than hard-coding it.
- **Priority tiers** — `P0` (highest) through `P3` (lowest). Tier and `all` modes always proceed in the order `P0 → P1 → P2 → P3`.
- **Finding headings** — every finding is an H4 matching `^#### <TIER>-\d+:`. Enumerating a tier means grepping this pattern with `<TIER>` substituted.
- **Cross-reference sections** — three sections restate each finding's citation and must remain synchronized with it:
  - **Section 4 — IaC Gap Analysis**: citation column, for rows keyed to a finding.
  - **Section 5 — Full Finding Matrix**: Files column.
  - **Section 6 — Microsoft Standards Alignment**: finding-ID references; usually no citation to synchronize, but verify.

## Editable and protected content

Edit only the following:

- The `**File:**` citation (path and line range).
- The verbatim block following `**File:**`.
- The `**Fix:**` block.
- Any `file.ext:Lx-Ly` citation embedded in prose — the line numbers only, never the surrounding wording.
- The row for each in-scope finding in the three cross-reference sections.

Leave the following unchanged:

- All analyst prose — Issue, Impact, Recommended Fix, Notes, and any conceptual framing (for example, "primary / secondary" language).
- Finding priority, ordering, titles, and reference links.
- Any finding outside the current `<SCOPE>`.

If prose states a literal that the real file contradicts (for example, a configuration key that does not exist), do not silently edit the prose — raise it under R7, Contradiction protocol.

## Workflow

### Step 0 — Inventory (mandatory, before any edit)

Compile and hold a consolidated inventory for `<SCOPE>`. In single-finding mode the "set" is one finding; in tier and `all` modes the set is every finding in the current tier. Do not begin editing until the inventory is complete.

- **0.1 — Locate the assessment file.** Glob `Microsoft Assessment/*.md`. If exactly one file matches, that is the assessment. If several match, select the one whose name ends `-Code-Level-Resiliency-Assessment.md`. Use this path throughout.
- **0.2 — Resolve the finding set.**
  - Single ID: the set is that one finding.
  - Tier: grep the assessment for `^#### <TIER>-\d+:` with `<TIER>` substituted; list every match in ascending order.
  - `all`: resolve the set per tier as each tier begins, following `P0 → P1 → P2 → P3`. Never enumerate all four tiers in advance.
- **0.3 — Map all citations.** For each finding in the set, grep its body for the extension-agnostic pattern `[\w./-]+\.[A-Za-z0-9]+:L\d+` — this discovers every cited file and its extension without a preset list. Record every citation (the `**File:**` cite and every in-prose cite) in a file-keyed index: `{ filepath → [ (finding_id, cite_range, location: File | Issue | Notes | Fix | …), … ] }`. R9 harmonization uses this index directly.
- **0.4 — Map asserted literals.** For each finding, list every real-file literal the prose asserts exists — field and method names, configuration and JSON keys, exception types, secret names, workflow filenames, log messages, and count claims (for example, "four Maven repositories"). Index these by file. R3 and R10 verify each against the real file.
- **0.5 — Map the cross-reference footprint.** For each finding, grep the whole assessment for its finding ID and record the referencing rows in Sections 4, 5, and 6. Step 4 synchronization uses this footprint directly.
- **0.6 — Identify siblings.** From the citation index (0.3), note every file cited by more than one finding in the set, together with each finding's current range, so R9 can flag mismatches.
- **0.7 — Build the read plan.** Deduplicate the file list from 0.3. This is the set of source files to open once each in Step 1.

### Step 1 — Read each cited file once

Open each file from the read plan (0.7) exactly once. For each, record:

- The real line number of every construct any in-scope finding references.
- The exact content — including whitespace — at every cited line range, so verbatim blocks can be reproduced without a second read.
- Any divergence between the file and the prose's asserted literals (feeds R7 and R10).

Do not re-read a file per finding. If a later step needs a construct not captured in the first pass, reopen only that file and only that range.

### Step 2 — Harmonize sibling ranges (tier and `all` modes only)

Using the citation index (0.3), decide the final line range for every file cited by more than one in-scope finding **before editing any of them**, so all siblings are written consistently on the first pass:

- Findings describing the same construct converge on one shared range.
- Findings describing different constructs in the same file each receive their own tight range; ranges must not overlap by accident (for example, `L2-L8` and `L30-L38`, never `L2-L8` and `L7-L15`).
- Record each decision for the deliverable's harmonization table.

Single-finding mode skips this step; R9 is applied directly during Step 3 instead.

### Step 3 — Apply edits

Apply R1–R7 and R10 to each finding, using the data gathered in Steps 0–2.

- **Single-finding mode.** Edit the one finding, then apply R8 (cross-reference sync) and R9 (harmonization) immediately.
- **Tier and `all` modes.** Edit findings in ascending numeric order. R9 ranges are already fixed by Step 2, so edits simply apply them; R8 synchronization is deferred to Step 4 so all cross-reference rows are updated in a single sweep.

Use `multi_replace_string_in_file` for independent edits, in batches of no more than eight replacements per call.

### Step 4 — Synchronize cross-references and validate

- **Single-finding mode.** After the `**File:**` citation settles, apply R8 to that finding's rows in Sections 4, 5, and 6. Then run `get_errors` on the assessment; expect none.
- **Tier and `all` modes.** After every finding in the current tier is edited:
  1. **Synchronize cross-references.** Using the footprint (0.5), update every referencing row in Sections 4, 5, and 6 whose finding's `**File:**` citation changed. Batch with `multi_replace_string_in_file` (≤ 8 per call).
  2. **Post-sweep grep.** Re-run `[\w./-]+\.[A-Za-z0-9]+:L\d+` across the assessment, filter to lines referencing tier findings, and confirm they match the harmonized ranges. Zero drift is the exit condition.
  3. **Validate.** Run `get_errors` on the assessment; expect none.

## Editing rules (R1–R10)

**R1 — Verify every citation, not only the `**File:**` cite.** For each citation in the inventory, confirm against the real file that:

- The range resolves to the described construct.
- The range ends at the last meaningful content line — exclude trailing blank lines (for example, use `L26-L29`, not `L26-L30`, when L30 is blank).
- Single-line citations use `L8`, not `L8-L8`.
- A range spanning multiple methods or blank-line-separated blocks is tightened to the actual span.
- If the file no longer contains the cited construct, stop and apply R7.

**R2 — Every literal is drawn from the real file, on demand.** Prose keeps its conceptual framing. Every literal in a code block or citation — job name, secret name, workflow filename, registry FQDN, input key, configuration key, method name, field name, URL — must be exactly what the real cited file says, as read in Step 1. Never write a value from memory, from a maintained list, or because it looks plausible. If a finding uses a value you cannot confirm in the real files, treat it as an R7 contradiction rather than "correcting" it to a guess.

**R3 — The `**File:**` block is strict verbatim.** Reproduce the exact content at the corrected line range, with zero fabrication:

- Exact method signatures, parameter names, return types, and `throws` clauses.
- Exact field and variable names as written (for example, `persistence`, not `persistenceService`).
- Exact string literals — log messages, error messages, URLs, JSON keys.
- Exact annotations and their contents (for example, `@ResponseStatus(HttpStatus.NOT_FOUND)`).
- Exact whitespace — preserve tabs versus spaces, indentation width, and internal blank lines.
- No editorial headers (`# — before`, `# (current)`), no `{ ... }` placeholders, no templated tokens such as `{secondaryRegion}`, no `/* … elided … */` markers, and no cross-finding pointers such as `// See P1-XXX file block`.

**R4 — The `**Fix:**` block may introduce new code, under four constraints.**

- **a. Recommendation adherence.** Walk each numbered sub-item in the Recommended Fix prose and confirm the code demonstrates or references it. If a sub-item cannot be expressed in the target file's language (for example, a values file in an external chart repository), represent it with a single-line inline comment rather than dropping it.
- **b. Retained code stays verbatim.** Any code carried over from the real file must be identical to it (real variable names, exception clauses, annotations, and error-handling patterns). New literals may extend or replace existing code, never masquerade as it.
- **c. Repository shape.** New workflow, IaC, or configuration content must match the target repository's conventions — naming, secret placement, input-key casing, gate expressions, and configuration-key names — drawn from real sibling files read on demand. Do not invent placeholder key names when a real one exists.
- **d. Header comments.** A single-line comment naming the new file (for example, `# .github/workflows/regional-parity-check.yml — deploy-time gate`) is permitted in a Fix block. Such headers are forbidden in a `**File:**` verbatim block (R3).

**R5 — Wire gates so they gate.** If the recommendation calls for a gate (parity check, verification job, approval), attach it with `needs:` to the jobs it must block, so it enforces rather than merely runs in parallel.

**R6 — Comment only what code cannot show.** Add a code comment solely for a fact the code cannot express, in one short line. Never restate what the next line does.

**R7 — Contradiction protocol.** If the real file contradicts anything the finding asserts — the Issue statement, an asserted literal, a claimed signature, a supposed filename — stop before editing and present:

- The specific contradiction (real file line versus the finding's claim).
- Two or three rescope options that preserve the prose framing where possible.
- A recommendation.

Then wait for the user's decision.

**R8 — Synchronize cross-references after every edit.** Once a finding's `**File:**` citation is final, update every other row in the assessment that restates it:

- Section 5, Full Finding Matrix — the Files column for the finding's row.
- Section 4, IaC Gap Analysis — any row keyed to the finding.
- Section 6, Microsoft Standards Alignment — usually finding-ID only; verify, and synchronize if a citation is present.

Single-finding mode runs this immediately; tier and `all` modes defer it to Step 4.

**R9 — Harmonize sibling ranges.** When the cited file is shared by other findings, the chosen range must either match the siblings' ranges or differ deliberately, with a one-line rationale in the deliverable. Never leave two findings disagreeing about the same construct's range silently. Tier and `all` modes decide this in Step 2, before editing.

**R10 — No fabricated content anywhere.** Verify against the real file every literal the finding asserts exists, not only those inside code blocks — configuration values, JSON keys, dependency coordinates, workflow step names, secret names, and count claims. Confirm each by reading the real file. If prose asserts a literal absent from the file, apply R7.

## Deliverables

### Single-finding mode

1. **Recommendation walkthrough** — each sub-item marked ✅ / ⚠️ / ❌ with a one-line reason.
2. **Citation table** — every citation from the inventory, with before → after ranges, one row each, including the Section 4, 5, and 6 rows.
3. **Sibling check** — other findings citing the same file and their current ranges, each marked "harmonized" or "intentional difference: …".
4. **Contradiction flags** — anything ⚠️ or ❌ requiring user input.

### Tier and `all` modes

Produce one report per tier (no per-finding deliverable):

1. **Scorecard** — findings edited versus total in the tier, with a one-line status per finding (edited / skipped / flagged).
2. **Citation table** — every citation with before → after ranges, grouped by finding, with Section 4, 5, and 6 rows as their own entries.
3. **Harmonization table** — one row per file cited by two or more findings, showing the range decision for each finding.
4. **Recommendation matrix** — one row per finding, one column per sub-item, cells ✅ / ⚠️ / ❌.
5. **Contradiction flags** — anything ⚠️ or ❌ requiring the user's decision before the next tier, grouped by root cause.
6. **Next-tier readiness** — confirmation of zero drift from the Step 4 post-sweep grep and explicit user approval to proceed.

## Stop conditions

Stop and wait for the user when any of the following occurs:

- An R7 contradiction fires on a finding. Do not edit that finding; in tier mode, continue with its siblings and record it in the report.
- Step 2 harmonization cannot converge because two findings describe genuinely incompatible constructs in the same file.
- Step 4 synchronization reveals cross-reference drift that cannot be resolved without prose changes.
- The Step 4 post-sweep grep shows residual drift.
- In `all` mode, a tier's report has not been explicitly accepted before the next tier would begin.
