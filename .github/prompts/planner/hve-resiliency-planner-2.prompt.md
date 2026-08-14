---
description: Run Task Planner Prompt 2 to create the developer guide with code-level remediation guidance
---

# Application HVE Planner 2 Developer Guide

Use [Application Task Planner Context](../../instructions/hve-resiliency-planner-context.instructions.md).

---

Run `/hve-resiliency-planner-0` first to lock in evidence constraints.

```text
Using the HVE research artifact, create or update <repo-name>-Developer-Guide.md.

Include a dedicated "Priority Legend" section near the top using exactly:
- P0 - Blocking/Critical Risk
- P1 - High Priority
- P2 - Improvement/Best Practice (Non-Blocking)
- P3 - Non-Blocking Code Consistency (Best Practices / Maintainability)

For each finding (do not add new findings):
- Reference the exact evidence
- Capture any code shown verbatim from the cited repository file - exact text, whitespace, signatures, field and variable names, string literals, and annotations - and record the precise `path:Lx-Ly` (use `Lx` for a single line) for each snippet, so the downstream assessment prompts (`planner-3b`/`3c`/`3d`) can reuse it without re-reading source. Do not paraphrase, fabricate, or insert placeholder tokens into quoted code. If the repository contradicts the finding, surface the contradiction rather than guessing.
- Explain the resiliency risk
- Describe the recommended pattern
- Provide code examples in the repository's primary language
- Assign a priority (P0/P1/P2/P3) using the Priority Legend above
- Check for hard-coded security-related values that could fail or weaken security during regional failover (e.g., secrets, API keys, connection strings with embedded credentials, certificates, private keys, client secrets, signing keys, pinned issuer/audience/tenant IDs, hard-coded Key Vault URIs, hard-coded endpoints used for token acquisition/JWKS retrieval). If found, document the risk and prescribe moving them to the appropriate secure/config mechanism (e.g., Key Vault + managed identity, workload identity, App Configuration, environment variables/secret stores), including failover-safe lookup behavior.


OUTPUT FORMAT for <repo-name>-Developer-Guide.md (use this exact section order):
1) Title: <repo-name> - Developer Guide (Code-Level Guidance)
2) Priority Legend
3) How to Use This Guide (short paragraph)
4) Findings and Recommended Patterns (grouped and ordered P0 then P1 then P2 then P3). Use the following template per finding:
   - Finding ID: F-### (must match <repo-name>-Master.md)
   - Priority: P0/P1/P2/P3
   - Evidence reference(s):
   - Risk explanation (what breaks during zone loss / regional failover):
   - Hard-coded security values check: list any hard-coded secrets/keys/certs/security endpoints or explicitly state "No hard-coded security values found for this finding."
   - Recommended pattern (named):
   - Implementation guidance (step-by-step):
   - Code examples (repo's language), quoted verbatim from the cited file with its `path:Lx-Ly`, and where to apply them:
   - Testing/validation notes (how to prove it works):
   - Health then GLB readiness contract (if applicable): (a) what /ready (or equivalent) means, including which dependencies are included/excluded, and (b) GLB probe expectations (path/port/method/thresholds/timeouts) expressed as testable acceptance criteria.

INCREMENTAL WRITE (avoid one oversized write that is prone to transient network failures):
- First create or update <repo-name>-Developer-Guide.md with only sections 1-3 (Title, Priority Legend, How to Use This Guide) plus an empty "Findings and Recommended Patterns" heading. This is one small write.
- Then append findings into that section one finding at a time, each as a separate edit, in P0, then P1, then P2, then P3 order. Never regenerate the whole document in a single write and never hold more than one finding's rendered body in a single write.
- Treat the operation as resumable and idempotent: before appending a finding, check whether its Finding ID (F-###) already appears in the file; if it does, skip it. A re-dispatched run continues from a partially written guide without duplicating or reordering findings.
- Preserve the exact section order and per-finding template above; only the write is incremental, not the output format.
```
