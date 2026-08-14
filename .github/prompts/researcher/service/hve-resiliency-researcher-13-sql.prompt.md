---
description: Run Prompt 13 SQL Server resiliency analysis for Application
agent: Task Researcher
---

# Application HVE Researcher 13 SQL Server

Use [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

Act as a cloud reliability and data consistency expert focusing on Azure SQL
Server.

## Assessment Scope

Analyze this application only when Azure SQL is confirmed by the inherited
service exclusion rule. Assess the application as using Azure SQL with zone
redundancy and Failover Groups and Managed Identity authentication.

Evaluate only the application's ability to:

* Survive zonal failures with zero data loss
* Fail over regionally with controlled write safety
* Prevent data corruption or split-brain during failover

Assess these existing areas without adding assessment areas:

* Database access through the Failover Group read-write listener rather than
  direct endpoints
* Write safety during regional failover, including write blocking, fencing,
  and maintenance mode
* Client and application retry, timeout, and circuit-breaker behavior
* Transaction idempotency and duplicate-write prevention
* Connection-pool behavior during SQL role changes
* State handling through stateless pods, externalized sessions, and queues
* Health-probe alignment between the global load balancer and backend services

## Bounded Evidence Protocol

Apply this protocol only to dependencies confirmed by the inherited service
exclusion rule.

1. For each eligible dependency, allow at most 2 repository searches, 3 file
   reads, 2 repository traversal hops, and 1 focused follow-up. Start each
   dependency counter at zero, increment the corresponding counter after each
   action, and never reset or transfer counters across questions, repeated
   research, or subagent calls. One action may answer multiple questions
   without consuming another action. Read only the smallest relevant line
   ranges.
2. Allow at most 2 prompt-wide research rounds. The prompt-wide round counter
   starts at zero, becomes 1 before the first discovery action, and becomes 2
   before the first focused follow-up or second-pass action. Increment it
   exactly at those transitions. Never reset it across dependencies,
   questions, repeated research, or subagent calls. Do not start a third
   round.
3. Discover production evidence only from sources and bounded access methods
   supplied or approved by the user. Stay within those bounds and the
   remaining counters. Otherwise, record the required value as `Unknown` with
   a named external evidence gap. Do not inspect other live systems,
   telemetry, credentials, or endpoints.
4. Treat one source as one unique repository search result or one
   user-approved external artifact. Exhaust a source only when every result
   from bounded searches has been read within the read budget or explicitly
   left unread because the read budget is exhausted, and no legal bounded
   search, read, traversal hop, or focused follow-up remains. Processing
   final-search results within the remaining budgets is legal. After source
   exhaustion, do not broaden or repeat a query, revisit a source, add a
   traversal, or reset a counter.
5. Give every research-question and eligible-dependency pair exactly one
   terminal outcome: cited file-and-line evidence; `Unknown` after bounded
   repository evidence is exhausted; not applicable under the inherited
   exclusion rule; or `Unknown` because a named external evidence gap blocks
   the value.
6. Stop discovery when all pairs have terminal outcomes or round 2 is
   exhausted, whichever occurs first. At the round limit, serialize every
   unresolved existing schema value exactly as
   `Unknown: two-round prompt budget exhausted`. During final consolidation,
   assert that every
   still-unresolved existing schema value equals that exact text. Fail
   consolidation if another form remains or if unresolved values exist and
   the exact-text count is zero. Do not repeat research after a terminal
   outcome or research further to improve confidence.
7. Before consolidation, verify from already-read evidence that every cited
   file exists, each cited range was read, and the dependency remains eligible.
   Reject or correct invalid delegated content without consuming a discovery
   action or round. Preserve the raw violation and correction in the execution
   ledger.

Track counters cumulatively in execution state. Keep tool calls, counters,
searches, reads, file analysis, discovery narration, and repeated evidence out
of the authoritative research artifact.

## Evidence and Output Contract

Outside round-limit exhaustion, use `Unknown` only in an existing schema field
and name the exhausted repository source class or external evidence gap. Never
invent a file, line number, mitigation, constraint, impact, risk rationale, or
priority. A finding requires file-and-line evidence; an `Unknown` outcome alone
does not establish a finding.

Create one canonical row for each independently actionable failure mode. Add a
stable `Failure Mode ID` as the first field, derive it consistently from the
dependency and failure mode, and reuse it for the same mode across repeated
runs. Do not merge failure modes because they share a dependency, file,
location, priority, or risk level.

Apply the inherited P0-P3 definitions and evidence requirements. The
evidence-only rules override requests for remediation, examples, alternatives,
a selected approach, implementation guidance, implementation details,
implementation next steps, general next-step suggestions, or discovery
narration. Provide none of them.

The authoritative artifact must contain exactly three section classes: a
concise scope summary, a terminal-outcome summary, and canonical finding rows.
Do not emit another section.

Repeat this canonical row for each finding:

* Failure Mode ID:
* Issue Description:
* Risk Level (P0/P1/P2/P3):
* Code location (file + line number):
* Why this is a risk to app, zone or region failover:
* Impact(s) if this is not changed:
* Existing mitigations present (evidence):
* Constraints/limitations (evidence):
* Remediation guidance: None (HVE Task Researcher role is evidence-only)
