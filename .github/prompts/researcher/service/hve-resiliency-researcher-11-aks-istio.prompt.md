---
description: Run Prompt 11 AKS and Istio resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 11 AKS and Istio

Use [Application Platform Context](../../../instructions/hve-resiliency-platform-context.instructions.md)
as supporting context. Apply every safety-critical control in this prompt directly, regardless of
whether that instructions file is auto-applied.

Act as a cloud resiliency architect focusing on AKS and Istio. This application
runs on AKS with Istio in a multi-region setup, with traffic routed through a
Global Load Balancer.

## Assessment Scope

Assess only application code and configuration, not infrastructure, for regional failover between West US 2 and West US.
Evaluate these ten questions without adding assessment areas:

* Are timeouts defined for all outbound calls?
* Are retries bounded and using backoff + jitter?
* Are retries idempotent and safe?
* Any assumptions that dependencies are always available?
* Unbounded retries or retry storms?
* Blocking or synchronous fan-out calls?
* Are health probes aligned between GLB and backend services?
* Risk of thread, connection, or resource exhaustion during partial failures?
* Do readiness probes reflect real dependency health?
* Could unhealthy pods still receive traffic?

## Bounded Evidence Protocol

Apply this protocol only to dependencies confirmed by the inherited service
exclusion rule.

1. For each confirmed dependency, allow at most 2 repository searches, 3 file
   reads, 2 repository traversal hops, and 1 follow-up discovery action. Start
   each dependency's counters at zero, increment a counter after its action,
   and never reset or transfer counters across questions, repeated research,
   or subagent calls. A single action may answer multiple questions without
   consuming another action.
2. Allow at most 2 total research rounds for the prompt. The prompt-wide round
   counter starts at zero, becomes 1 before the first discovery action, and
   becomes 2 before the first follow-up or second-pass action. It never resets
   across dependencies, questions, repeated research, or subagent calls. Do
   not start a third round.
3. Prohibit production discovery by default. Access production only when the
   user supplies both an approved source and a bounded access method. Stay
   within the user-supplied bounds and the remaining counters above. Otherwise,
   record the required production value as `Unknown` with a named external
   evidence gap; do not inspect live systems, telemetry, credentials, or
   endpoints.
4. One source is one unique repository search result or one user-approved
   external artifact. A source is exhausted only when every result returned by
   the bounded searches has either been read within the read budget or
   explicitly left unread because the read budget is exhausted, and no legal
   bounded search, read, traversal hop, or follow-up remains. Processing results
   from the final permitted search within the remaining read and traversal-hop
   budgets is legal and is not a prohibited revisit. After exhaustion, do not
   broaden or repeat a query, revisit a source, add a traversal, or reset a
   counter.
5. Give every question for every eligible dependency exactly one terminal
   outcome: cited file-and-line evidence; `Unknown` after bounded repository
   evidence is exhausted; not applicable under the inherited exclusion rule;
   or `Unknown` because a named external evidence gap blocks the value.
6. Stop discovery when all question-and-dependency pairs have terminal
   outcomes or round 2 is exhausted, whichever occurs first. At the round
   limit, serialize every unresolved value as `Unknown: two-round prompt budget
   exhausted`. During final consolidation after round 2, assert that every
   still-unresolved existing schema value equals that exact text. Fail
   consolidation if any unresolved value uses another form, or if unresolved
   values exist and the exact-text count is zero. Do not research further to
   improve confidence.

Track counters cumulatively in execution state, but omit tool calls, counters,
search narration, file-analysis narration, and repeated evidence from the
authoritative research artifact. Read only the smallest relevant line ranges.

## Evidence and Output Contract

Use `Unknown` only in an existing schema field and append either the exhausted
repository source class or the named external evidence gap. Never invent a
file, line, mitigation, constraint, impact, rationale, or priority. A finding
still requires file-and-line evidence; `Unknown` alone does not establish one.

Emit a separate canonical finding row for each independently actionable
failure mode. Add `Failure Mode ID` as the first field, derive it consistently
from the dependency and failure mode, and reuse it across repeated runs. Do
not merge modes that share a dependency, location, or priority.

Use every field from the inherited canonical service-specific finding schema,
including mitigations, constraints, and `Remediation guidance: None (HVE Task
Researcher role is evidence-only)`. Do not restate, rename, remove, or add any
other schema field. Apply the inherited P0-P3 definitions and file-and-line
evidence requirements.

These evidence-only instructions override inherited requests for remediation,
examples, alternatives, a selected approach, implementation details,
implementation next steps, and general next-step suggestions. Provide none of
them. The authoritative artifact must contain exactly three section classes: a
concise scope summary, a terminal-outcome summary, and canonical finding rows.
Do not emit a separate `Preserved Questions` section or any other fourth
section.
