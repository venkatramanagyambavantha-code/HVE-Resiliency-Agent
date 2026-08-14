---
description: "Appends Section 2 P2/P3 resiliency findings and Section 3 Non-Resilient Focused Recommendations to the Code-Level Resiliency Assessment report"
argument-hint: "serviceName=..."
---

# Resiliency Report Generator — Part C: P2, P3, and Non-Resiliency Findings

## Inputs

* ${input:serviceName}: (Required) Service name matching the repo name.

## Source Artifacts

Read **only** the following before generating. Keep context minimal.

* `.copilot-tracking/plans/` — locate `{serviceName}-Master.md`. Read the P2 and P3 sections only (skip P0, P1, Open Questions, and External Provider Considerations).
* `.copilot-tracking/plans/` — locate `{serviceName}-Developer-Guide.md`. Read the P2 and P3 sections only (skip P0 and P1). This is the primary source for all code blocks.
* `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md` — read the existing file to understand the current state and where to append.

Do **not** read the consolidated research, subagent files, or the Developer Guide P0/P1 sections for this prompt.

## Critical Context

This report serves the Albertsons engagement. Use the classification rules from `hve-resiliency-planner-context.instructions.md` for all priority assignments.

All section headers, H3 group names, finding titles, and repo references must use `{serviceName}` (the repo name), not hardcoded service names.

## Region-Agnostic Language Rule

The generated report must **never** reference "East US", "eastus", or any East region variant. Prefer region-agnostic terms:

* **Primary region** — the current production region
* **Secondary region** or **failover region** — the target active/active peer
* **Both regions** — when referring to symmetric requirements

## Classification: Resiliency vs Non-Resiliency

Use the active/active litmus test to classify each P2 and P3 finding:

> **"Does going from single-region to active/active introduce or change this issue?"**

* **YES** → `Resiliency Related: Yes` → place under Section 2 (Resilient Focused Recommendations)
* **NO** → `Resiliency Related: No` → place under Section 3 (Non-Resilient Focused Recommendations)

All P0 and P1 findings are already in Section 2 (written by prompt 3b). This prompt handles P2 and P3 findings only.

## What to Generate

**Append** the following to the existing `Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md` file. Do not overwrite or regenerate the header, Section 1, or the P0/P1 portions of Section 2.

### Part 1: Section 2 Continuation — Resiliency P2 and P3

If any P2 or P3 findings pass the litmus test (Resiliency Related: Yes), append them under Section 2 as:

* `## P2 — Improvement / Best Practice (N)` — count of resiliency-related P2 findings
* `## P3 — Code Consistency (N)` — count of resiliency-related P3 findings

End Section 2 with `[Back to Top](#top)`.

### Part 2: Section 3 — Non-Resilient Focused Recommendations

Begin with `# 3. Non-Resilient Focused Recommendations`.

Organize Non-Resiliency findings (those that do NOT pass the litmus test) under:

* `## P2 — Improvement / Best Practice (Non-Resiliency) (N)`
* `## P3 — Code Consistency (Non-Resiliency) (N)`

Within each H2, group findings under H3 shared-service groups: `### Observability`, `### Security / Configuration Hygiene`, `### Build / Packaging`, `### Data Management`, etc. Derive group names from the actual categories in the Master Report.

End Section 3 with `[Back to Top](#top)`.

#### Finding ID Assignment

Continue the `PX-NNN` ID sequence from prompt 3b:

* P2: P2-001 through P2-NNN (sequential within P2)
* P3: P3-001 through P3-NNN (sequential within P3)

Map from the Master Report finding numbers (F-NNN) to PX-NNN IDs. Maintain the same mapping used across all prompts.

#### Individual Finding Template

Every P2 and P3 finding uses this exact format (field order must be preserved):

1. `#### PX-NNN: Short Title` — H4 heading
2. `**Priority: PX — {Priority Label}**` — on its own line
3. `**Resiliency Related:** Yes / No`
4. `**Issue:**` — description of the problem. For P2/P3: note that behavior is identical regardless of topology (if Non-Resiliency), or explain the resiliency angle (if Resiliency).
5. `**What does this solve:**` — one sentence, the outcome achieved
6. For `Resiliency Related: Yes`: `**Resiliency Impact:**` — 1–3 sentences. For `Resiliency Related: No`: `**Impact:**` — 1–3 sentences.
7. `**Recommended Fix:**` — concrete narrative action
8. `**File:** file/path.ext:line` — followed by a fenced code block with the current problematic code (must include a language identifier). Pull from Developer Guide.
9. `**Fix:**` — followed by a separate fenced code block with the corrected implementation (must include a language identifier). Pull from Developer Guide.
10. `**Notes:**` — context, rationale, or implementation guidance
11. `<span style="font-size: 14px;">**MSFT Reference:** [Pattern Name](URL)</span>` — when a WAF pattern or Azure guidance page applies

Priority labels:

* P2: `Code Quality / Best Practice`
* P3: `Code Consistency` or `Noted for Completeness`

#### Finding Rules

* Separate findings with `---` (horizontal rule).
* Always use **two separate** fenced code blocks — one under `**File:**` and one under `**Fix:**` — each with a language identifier. Pull samples from the Developer Guide. Never combine both into one block.
* For findings with no code change (configuration or coordination items), use relevant config under `**File:**` and the target state under `**Fix:**`.
* Configurable values in code use `// e.g., 3` comments.
* `What does this solve` is required on all findings, one sentence.
* For `Resiliency Related: Yes` findings: `Resiliency Impact` required.
* For `Resiliency Related: No` findings: `Impact` required.
* Include MSFT Reference when a WAF pattern or Azure guidance page applies.
* When a finding references cross-dependencies to other findings, use the `PX-NNN` format.

### Incremental Write

Append findings one at a time to avoid a single oversized write that is prone to transient network failures:

* Write each section or priority-block heading first, then append each finding individually as a separate edit, in P2 then P3 order, completing the Section 2 continuation before Section 3.
* Never regenerate previously written content and never hold more than one finding's rendered body (including its two code blocks) in a single write.
* Treat the operation as resumable and idempotent: before appending a finding, check whether its `PX-NNN` ID already appears in the report file; if it does, skip it. A re-dispatched run continues from a partially written section without duplicating or reordering findings.

## Formatting Conventions

* Aligned pipe tables — all pipes vertically aligned across all rows.
* Blank lines before and after tables, code blocks, headings, and lists.
* `---` horizontal rules between individual findings within a group.
* `**Priority: PX — Label**` on its own line.
* All code blocks have a language identifier.
* Inline code for env vars, function names, file paths, and config keys.
* All repo references use `{serviceName}`, never a hardcoded service name.
* No references to "East US" or any East region variant.

## Output Location

**Append** to the existing file at:

`Microsoft Assessment/{serviceName}-Code-Level-Resiliency-Assessment.md`

Do not overwrite the existing content.

## Next Step

After completing this prompt:

> **Next step:** Run `/hve-resiliency-planner-3d`
