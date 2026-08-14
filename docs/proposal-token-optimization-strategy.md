# Token Optimization Strategy

A 10,000-foot overview of how HVE Resiliency can reduce the per-assessment token cost called out in the [README token table](../README.md#token-consumption-estimates), without weakening evidence-only rules or the P0-P3 classification.

## Table of Contents

- [Where the tokens go today](#where-the-tokens-go-today)
- [Optimization levers at a glance](#optimization-levers-at-a-glance)
- [1. Pre-indexed code intelligence (CodeGraph)](#1-pre-indexed-code-intelligence-codegraph)
- [2. Repository pre-flight + scope manifest](#2-repository-pre-flight--scope-manifest)
- [3. Artifact-first prompt inputs (drop chat history, attach files)](#3-artifact-first-prompt-inputs-drop-chat-history-attach-files)
- [4. Mode A by default, Mode B by exception](#4-mode-a-by-default-mode-b-by-exception)
- [5. Service prompt scoping](#5-service-prompt-scoping)
- [6. Output shape discipline](#6-output-shape-discipline)
- [7. Caching consolidation outputs across re-runs](#7-caching-consolidation-outputs-across-re-runs)
- [Adoption sequencing](#adoption-sequencing)
- [Out of scope](#out-of-scope)
- [References](#references)

---

## Where the tokens go today

Per the [README token estimates](../README.md#token-consumption-estimates), a Medium engagement (5-service platform, ~30K LOC) consumes roughly **1.0M-1.7M tokens** in Mode A and 30-50% more in Mode B. The dominant input costs are:

- **Phase 1-2 repository scanning.** Every researcher prompt rediscovers structure from scratch via `grep` / `file_search` / `read_file`. The same source files are re-read across sibling prompts.
- **Phase 3 consolidation.** A single prompt ingests 5-12 prior research artifacts.
- **Phase 4-5 planner inputs.** The consolidated document is re-attached on every planner / assessment-builder turn.
- **Mode B context carry.** The orchestrating agent retains conversation context across phases even though each prompt runs as an isolated subagent.

The optimizations below target these four buckets.

## Optimization levers at a glance

| # | Lever | Primary phase impacted | Effort | Expected input-token savings (Medium) |
|---|-------|------------------------|--------|---------------------------------------|
| 1 | Pre-indexed code intelligence (CodeGraph MCP) | 1, 2, 4 | Medium | 30-45% |
| 2 | Repository pre-flight + scope manifest | 1, 2 | Low | 10-20% |
| 3 | Artifact-first prompt inputs | 3, 4, 5 | Low | 10-15% |
| 4 | Mode A default, Mode B by exception | All | Low | 20-35% (vs. Mode B) |
| 5 | Service prompt scoping | 2 | Low | 15-25% on Phase 2 |
| 6 | Output shape discipline | All | Low | 5-10% (output side) |
| 7 | Consolidation caching across re-runs | 3 | Medium | 60-90% on incremental re-runs |

Savings stack partially (not additively). Combined, a Medium Mode A run could plausibly drop from **~1.0M-1.7M to ~0.5M-0.9M tokens**. Validate empirically before re-baselining the README table.

## 1. Pre-indexed code intelligence (CodeGraph)

**Idea.** Replace the bulk of `grep` / `file_search` / `read_file` loops in researcher and planner prompts with targeted queries against a local pre-indexed knowledge graph. [CodeGraph](https://github.com/colbymchenry/codegraph) is an MIT-licensed, 100% local MCP server that parses 20+ languages with tree-sitter and stores symbols, edges, and FTS5 indexes in a per-project SQLite database. Published benchmark across 7 open-source repos: ~25% cheaper, ~57% fewer tokens, ~62% fewer tool calls at the median for architecture-style questions.

**Where it helps in this workflow.**

| Activity today | CodeGraph replacement |
|---|---|
| Enumerate services / entry points | `codegraph_files` + `codegraph_search` |
| "What calls this retry helper?" | `codegraph_callers` (one call, body inline) |
| "Does this controller reach a Cosmos write?" | `codegraph_trace` (hops inline) |
| Build per-service Phase 2 context | `codegraph_context` scoped to service entry symbols |
| Phase 4 impact estimation | `codegraph_impact` |

**Adoption cost.** `npx @colbymchenry/codegraph` + `codegraph init -i` in the target repo. Opt-in, reversible, no data leaves the machine. Prompts gain a one-line "prefer `codegraph_*` if `.codegraph/` exists, else native tools" preamble. Evidence-only rules and `file:line` citations are preserved.

**Caveats.** Smallest wins on Small repos (already cheap via native grep). Requires the target repo's language to be supported. Customer environments that forbid third-party local tooling cannot use it.

## 2. Repository pre-flight + scope manifest

**Idea.** Add a deterministic, non-AI pre-flight step (`scripts/preflight.ps1` or similar) that produces a small JSON manifest of:

- File counts by extension and directory.
- Detected IaC providers (Terraform / Bicep / ARM / Helm).
- Top-level service folders.
- Languages present.
- Files matching exclusion patterns (`bin`, `obj`, `node_modules`, generated code).

Phase 1 prompts ingest this manifest as their first input instead of discovering it via `file_search` calls. Phase 2 service prompts ingest the matching service slice.

**Why it works.** A 2-5 KB manifest can replace 50-200 KB of discovery-phase tool calls. Deterministic output also stabilizes the workflow across re-runs.

**Adoption cost.** One script, one prompt edit per researcher prompt to accept the manifest path.

## 3. Artifact-first prompt inputs (drop chat history, attach files)

**Idea.** Each prompt's input should be **the prior phase's artifact file plus the current prompt body**, nothing else. The chat-history `/clear` rule in [Quick start](../README.md#purpose-of-clear-between-prompts) already enforces this for Mode A. Extend the same discipline to Mode B by making the orchestrator subagent re-read the artifact file on each handoff instead of carrying summarized state.

**Why it works.** The README notes Mode B is 30-50% more expensive because of context carry. Most of that is summarization of prior turns the next prompt does not actually need - the canonical state is on disk.

**Adoption cost.** Update the Mode B handoff guidance in [hve-resiliency-research SKILL.md](../.github/skills/hve-resiliency-research/SKILL.md) to say "subagent input = prompt + artifact path; do not pass conversational summary".

## 4. Mode A by default, Mode B by exception

**Idea.** Make Mode A the documented default and treat Mode B as opt-in for users who explicitly trade tokens for wall-clock speed. The current Quick start lists them as equivalent choices; the token table shows they are not.

**Why it works.** Largest single lever for users who currently default to Mode B without realizing the cost premium.

**Adoption cost.** Documentation-only change in the README and [docs/resiliency-researcher-workflow.md](resiliency-researcher-workflow.md).

## 5. Service prompt scoping

**Idea.** Phase 2 prompts under [.github/prompts/researcher/service/](../.github/prompts/researcher/service/) currently receive the full Phase 1 consolidated context even when a given service prompt only needs the matching subset. Add a scope header at the top of each service prompt that tells the researcher to load only the matching service's slice from the Phase 1 artifact (or, with CodeGraph, only the matching service's symbol set).

**Why it works.** Phase 2 runs N times (one per applicable Azure service). Per-prompt overhead multiplies.

**Adoption cost.** Edit each `researcher-*-service-*` prompt to add the scoping clause. The split between [hve-resiliency-researcher-1a.prompt.md](../.github/prompts/researcher/hve-resiliency-researcher-1a.prompt.md) (Azure services) and [hve-resiliency-researcher-1b.prompt.md](../.github/prompts/researcher/hve-resiliency-researcher-1b.prompt.md) (external dependencies) already supports this - the "scope contract" from 1a is the natural input.

## 6. Output shape discipline

**Idea.** Every prompt's output template should be **explicit** (numbered sections, fixed table columns). Vague "produce a report" instructions invite verbose prose. The recent edit to [hve-resiliency-researcher-0.prompt.md](../.github/prompts/researcher/hve-resiliency-researcher-0.prompt.md) adding an `OUTPUT FORMAT` section with numbered tables is the pattern to replicate.

**Why it works.** Output tokens scale with output size. Tables compress what prose inflates. Downstream prompts also parse tables more cheaply.

**Adoption cost.** One pass through the prompt library to add explicit output templates where missing.

## 7. Caching consolidation outputs across re-runs

**Idea.** Phase 3 consolidation and Phase 5 assessment are expensive and often re-run after small Phase 1 / 2 corrections. Add an artifact-hash header (`Inputs-Hash: sha256:...`) to each consolidated document. On re-run, if the listed input artifacts are unchanged, skip re-running Phase 3 and reuse the prior output.

**Why it works.** Iterative engagements typically re-touch one or two service findings, not the whole consolidation surface. Avoiding the 70K-200K-input Phase 3 prompt entirely on those iterations is a large win.

**Adoption cost.** Add hash header emission to the consolidator and assessment-builder prompts; add a one-line pre-flight check in the workflow guide.

## Adoption sequencing

Lowest-effort, highest-leverage first:

1. **Docs only:** items 4 (Mode A default) and 6 (output shape) - no code, immediate effect.
2. **One-off scripting:** item 2 (pre-flight manifest) and item 7 (artifact hashing).
3. **Prompt edits:** items 3 (artifact-first inputs) and 5 (service scoping).
4. **Tooling adoption:** item 1 (CodeGraph) - pilot on the [Microsoft-Assessment](../Microsoft-Assessment/) example, measure, then recommend.

Re-baseline the [Token consumption estimates](../README.md#token-consumption-estimates) table with two columns ("Baseline" and "Optimized") once items 1-5 are in.

## Out of scope

- Model selection / pricing changes (orthogonal to prompt design).
- Changes to the export / import skills - they operate on assessment markdown, not source code, and are already cheap.
- Replacing or restructuring the P0-P3 classification, the evidence-only rules, or the five-phase workflow.

## References

- [README token consumption estimates](../README.md#token-consumption-estimates) - baseline this proposal optimizes against.
- [Resiliency Researcher Workflow](resiliency-researcher-workflow.md) - phase structure and Mode A/B definitions.
- [hve-resiliency-platform-context.instructions.md](../.github/instructions/hve-resiliency-platform-context.instructions.md) and [hve-resiliency-planner-context.instructions.md](../.github/instructions/hve-resiliency-planner-context.instructions.md) - evidence-only rules preserved by every lever above.
- [CodeGraph](https://github.com/colbymchenry/codegraph) - MIT-licensed local MCP code-intelligence server (lever 1).
