---
description: Establish the run context lock that fixes deployment topology and regions for every downstream resiliency prompt
argument-hint: "topology={active-active|active-standby} [primaryRegion=... secondaryRegion=...] [researchRoot=...] [confirmOverwrite=true]"
---

# HVE Resiliency Topology 0 - Run Context Lock

Establish the run context lock. Every downstream research and planning prompt resolves its deployment topology from the artifact this prompt writes, so it survives context resets, agent switches, and parallel subagent dispatch.

This prompt is exempt from the Topology Resolution rule in the [Deployment Topology Contract](../instructions/hve-resiliency-topology.instructions.md); it establishes the lock rather than resolving it. Every other rule in that contract applies.

## Inputs

* `${input:topology}`: (Required) Exactly `active-active` or `active-standby`. There is no default.
* `${input:primaryRegion:West US 2}`: (Optional) The primary region of the target deployment. Defaults to `West US 2`.
* `${input:secondaryRegion:West US}`: (Optional) The peer region of the target deployment. Defaults to `West US`.
* `${input:researchRoot}`: (Optional) Research root for this run. Defaults to `.copilot-tracking/research-<topology>/`.
* `${input:confirmOverwrite:false}`: (Optional) Permit replacing an existing lock that differs. See Idempotency.

The two region inputs are paired. Supply both or supply neither; supplying exactly one is an error rather than a partial override, so a single supplied region can never be silently paired with a default it was not chosen against.

## Transcription Boundary

This prompt transcribes operator-supplied values. It does not investigate, and it does not decide.

* Write only values supplied as arguments, plus the two derived fields named in Emission.
* Do not read application source, configuration, infrastructure definitions, dependency inventories, or prior research artifacts.
* Do not infer, guess, or default any required input from repository contents or from conversation history.
* Do not perform repository traversal or discovery of any kind.
* Do not compute content digests. This artifact carries none.

Deployment topology is a business decision supplied by the operator. Nothing in the repository establishes it.

## Validation

Stop `Blocked` with the stated message when any check fails. Perform every check before writing.

1. `topology` absent: `topology is required - supply topology=active-active or topology=active-standby`.
2. `topology` present but not exactly `active-active` or `active-standby` after lowercasing and trimming: `topology must be active-active or active-standby, received <value>`.
3. Exactly one of `primaryRegion` and `secondaryRegion` supplied: `primaryRegion and secondaryRegion must be supplied together or both omitted`. Never pair a supplied region with a defaulted one.
4. Both region inputs omitted: apply the defaults `primaryRegion=West US 2` and `secondaryRegion=West US`, and state in the echo that defaults were applied. This is not an error.
5. `primaryRegion` and `secondaryRegion` resolve to the same normalized region key: `primaryRegion and secondaryRegion must differ, both resolve to <key>`. This check runs against resolved values, so it applies equally to supplied and defaulted regions.
6. `researchRoot` supplied but not a workspace-relative path, or containing traversal segments or alternate separators: `researchRoot must be a workspace-relative path inside the workspace`.

## Region Normalization

Normalize each supplied region once, and record both forms.

* Trim surrounding whitespace and collapse internal whitespace to one ASCII space.
* Compare regions case-insensitively and ignoring spaces, so `West US 2`, `west us 2`, and `westus2` are one region for the purposes of check 4.
* Record `primaryRegion` and `secondaryRegion` in the operator's supplied display form after whitespace normalization.
* Record `primaryRegionKey` and `secondaryRegionKey` as the lowercased, space-stripped comparison forms.

Downstream prompts compare on the key forms and render the display forms.

## Idempotency

Locate any existing lock per the contract's Lock Auto-Location rule before writing.

* No existing lock: write it.
* Existing lock whose `topology`, `primaryRegionKey`, `secondaryRegionKey`, and `researchRoot` all match the resolved values: leave it unchanged, report `unchanged`, and continue to Operator Echo.
* Existing lock that differs in any of those fields and `confirmOverwrite` is not `true`: stop `Blocked` with `run context lock already exists with different values - existing <topology>/<primaryRegionKey>-><secondaryRegionKey>, requested <topology>/<primaryRegionKey>-><secondaryRegionKey>; re-run with confirmOverwrite=true to replace`.
* Existing lock that differs and `confirmOverwrite` is `true`: replace it, and state in the echo that artifacts produced under the previous lock are now invalid and must be regenerated.

Never replace a differing lock silently. Changing topology or regions invalidates every artifact already produced for the run.

## Emission

Write the lock to `.copilot-tracking/<repo-name>-resiliency-run-context.md`, where `<repo-name>` is the workspace root basename. Create `.copilot-tracking/` if absent.

The default target deployment, applied when both region inputs are omitted, is `West US 2` primary with `West US` secondary.

Two fields are derived, not supplied:

* `researchRoot`: the supplied value, or `.copilot-tracking/research-<topology>/` when omitted.
* `targetDeployment`: `Active/Active across <primaryRegion> and <secondaryRegion>` for `active-active`, or `Active/Standby with <primaryRegion> primary and <secondaryRegion> standby` for `active-standby`.

Emit exactly this structure. Add no field.

```markdown
---
schema-version: hve-resiliency-run-context/v1
topology: <active-active|active-standby>
primaryRegion: <display form>
secondaryRegion: <display form>
primaryRegionKey: <comparison form>
secondaryRegionKey: <comparison form>
researchRoot: <resolved research root>
targetDeployment: <derived>
lockedAtUtc: <YYYY-MM-DDThh:mm:ssZ>
---

# Resiliency Run Context

This file fixes the deployment topology and regions for every resiliency research and
planning prompt in this repository. It is a declaration, not evidence: nothing in the
repository establishes it, and no prompt may override it.

Downstream prompts resolve topology from this file. Replacing it invalidates every
artifact already produced for this run.

| Field | Value |
| --- | --- |
| Deployment topology | `<topology>` |
| Primary region | `<primaryRegion>` |
| Secondary region | `<secondaryRegion>` |
| Research root | `<researchRoot>` |
| Target deployment | `<targetDeployment>` |
```

## Operator Echo

After writing, read the emitted file back with a single full-range read and report, in this order:

1. The lock path, and whether it was `written`, `unchanged`, or `replaced`.
2. Each resolved field and its value, quoted from the file just read, not from memory.
3. Whether the regions were operator-supplied or defaulted, stated explicitly so a defaulted pair is never mistaken for a chosen one.
4. For `replaced`, an explicit warning that prior artifacts are invalid.
5. The resolved research root, so the operator can pass it to subsequent steps.

Report a terminal state of `Complete` once the echo matches the file on disk.

## Next Step

> **Next step:** `/hve-resiliency-researcher-0`
