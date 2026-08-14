---
description: Deprecated - the monolithic Prompt 5 has been split into a scaffold-fill-verify-finalize pipeline. Redirects to the new scaffold entry point.
agent: Task Researcher
---

# Application HVE Researcher 5 (Deprecated Redirect)

The single monolithic `hve-resiliency-researcher-5` prompt has been replaced with a bounded, staged pipeline that mirrors the split consolidation pipeline. Run the new pipeline instead. Do not attempt to reconstruct the prior schema or run any evidence collection from this file.

## Pipeline Entry

The new pipeline is:

1. `/hve-resiliency-researcher-5-0-scaffold` - validate Prompt 1a and 1b Section 1 prerequisites, freeze the eligible-dependency inventory, emit the Prompt 5 skeleton and a frozen manifest sidecar.
2. `/hve-resiliency-researcher-5-1-startup-failure` - fill the startup-failure fragment.
3. `/hve-resiliency-researcher-5-2-silent-degradation` - fill the silent-degradation fragment.
4. `/hve-resiliency-researcher-5-3-data-loss-partial-processing` - fill the data-loss / partial-processing fragment.
5. `/hve-resiliency-researcher-5-4-blocking-transactions` - fill the blocking-transactions fragment.
6. `/hve-resiliency-researcher-5-verify` - audit the four outcome fragments against the manifest and workspace source.
7. `/hve-resiliency-researcher-5-finalize` - assemble the fragments into the single Prompt 5 research artifact consumed by `hve-resiliency-consolidate-5-failure-degraded`.

The shared contract for the split pipeline is defined in [Researcher 5 Split Contract](../../instructions/hve-resiliency-researcher-5-split.instructions.md). Platform inheritance is unchanged and continues to come from [Application Platform Context](../../instructions/hve-resiliency-platform-context.instructions.md).

Do not render failure-mode rows from this file. Do not read Prompt 1a or Prompt 1b from this file. Do not modify any downstream fragment, manifest, skeleton, or verify audit from this file.

## Completion

Report that the monolithic Prompt 5 is deprecated and direct the operator to the pipeline entry point.

> **Next step:** Run `/hve-resiliency-researcher-5-0-scaffold`
