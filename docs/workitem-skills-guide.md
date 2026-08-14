# Work Item Skills Guide

End-to-end guide for turning a finished resiliency assessment into a backlog in Azure DevOps or Jira Cloud using the three work item skills that ship with this framework.

## Table of Contents

* [Overview](#overview)
* [Pipeline at a glance](#pipeline-at-a-glance)
* [Prerequisites](#prerequisites)
* [Step 1: Export findings to CSV](#step-1-export-findings-to-csv)
* [Step 2A: Import into Azure DevOps](#step-2a-import-into-azure-devops)
* [Step 2B: Import into Jira Cloud](#step-2b-import-into-jira-cloud)
* [Hierarchy options](#hierarchy-options)
* [Dry runs and re-runs](#dry-runs-and-re-runs)
* [Troubleshooting quick reference](#troubleshooting-quick-reference)
* [Where to look next](#where-to-look-next)

## Overview

After Phase 5 produces a `Microsoft-Assessment/*.md` report with P0-P3 findings, three skills move those findings into a real backlog:

| Skill | Slash command | Purpose |
|------|---------------|---------|
| [hve-resiliency-workitem-export](../.github/skills/hve-resiliency-workitem-export/SKILL.md) | `/hve-resiliency-workitem-export` | Convert assessment findings into an Excel-compatible CSV for either ADO or Jira. |
| [hve-resiliency-workitem-import](../.github/skills/hve-resiliency-workitem-import/SKILL.md) | `/hve-resiliency-workitem-import` | Bulk-create Azure DevOps work items from the CSV via the ADO REST API. |
| [hve-resiliency-workitem-jira-import](../.github/skills/hve-resiliency-workitem-jira-import/SKILL.md) | `/hve-resiliency-workitem-jira-import` | Bulk-create Jira Cloud issues from the CSV via the Jira REST API v3. |

The export skill is destination-aware: the same finding set is shaped into ADO columns (`Title`, `Work Item Type`, `Priority`, `Severity`, `State`, `Description`, `Acceptance Criteria`, `Tags`) or Jira columns (`Summary`, `Issue Type`, `Priority`, `Description`, `Labels`, `Components`).

Both import skills can also create a parent work item that summarizes the application, attach the assessment markdown to it, and group findings under one work item per priority bucket.

## Pipeline at a glance

```text
Microsoft-Assessment/<app>.md
        │
        │  /hve-resiliency-workitem-export   (asks: ADO or Jira?)
        ▼
Microsoft-Assessment/exports/<app>-ADO-WorkItems.csv
                       └── or  -Jira-WorkItems.csv
        │
        │  /hve-resiliency-workitem-import        (ADO)
        │  /hve-resiliency-workitem-jira-import   (Jira)
        ▼
Backlog in Azure DevOps or Jira Cloud
  └── Parent Epic (assessment markdown attached)
        ├── P0 priority group (N findings)
        ├── P1 priority group (N findings)
        ├── P2 priority group (N findings)
        └── P3 priority group (N findings)
```

## Prerequisites

Common:

* PowerShell 7 or later (`pwsh`).
* A completed assessment markdown file in `Microsoft-Assessment/` produced by Phase 5.
* The framework installed in your repo (see the [Quick start](../README.md#quick-start) in the root README).

Azure DevOps import only:

* Azure CLI 2.60 or later, signed in with `az login`.
* Permission to create work items in the target project.
* Org URL (for example `https://dev.azure.com/contoso`), project name, and process template (`Basic`, `Agile`, or `Scrum`).

Jira Cloud import only:

* A Jira Cloud site URL (for example `https://your-tenant.atlassian.net`).
* An Atlassian API token from <https://id.atlassian.com/manage-profile/security/api-tokens>.
* Permission to create issues, set parents, and add attachments in the target project.
* The target project key (for example `RES`).
* Recommended: set `$env:JIRA_EMAIL` and `$env:JIRA_API_TOKEN` so the token never appears in chat or scripts.

## Step 1: Export findings to CSV

Run the export skill in Copilot Chat:

```text
/hve-resiliency-workitem-export
```

The skill first asks one question: `Which tool should I prepare this export for: ADO or Jira?` Answer with one word (`ADO` or `Jira`). It then writes the CSV under `Microsoft-Assessment/exports/` next to the source assessment.

Direct script form (use if you prefer to run the script yourself):

```powershell
pwsh .github/skills/hve-resiliency-workitem-export/scripts/export-workitems.ps1 `
  -AssessmentPath "Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment.md" `
  -TargetTool ADO `
  -OutputPath "Microsoft-Assessment/exports/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment-ADO-WorkItems.csv"
```

Open the resulting CSV in Excel to review row counts and adjust optional columns (tags, components, severity) before importing.

The `Description` column is intentionally preserved as multi-line structured text (`Finding`, `Priority`, `Resiliency Related`, `Issue`, `File`, `Recommended Fix`) with fenced code blocks intact. The import skills convert that text into HTML (ADO) or Atlassian Document Format (Jira) on the way in.

## Step 2A: Import into Azure DevOps

Slash command form:

```text
/hve-resiliency-workitem-import
```

The skill will prompt for the org URL, project name, process template, and CSV path, then post each row.

Direct script form (full Agile example with priority groups and the assessment markdown attached to the parent Epic):

```powershell
pwsh .github/skills/hve-resiliency-workitem-import/scripts/import-ado.ps1 `
  -CsvPath "Microsoft-Assessment/exports/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment-ADO-WorkItems.csv" `
  -Organization "https://dev.azure.com/hve-test" `
  -Project "hve-resiliency" `
  -Process Agile `
  -AssessmentPath "Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment.md" `
  -GroupByPriority
```

What this produces:

* One `Epic` parent titled `Resiliency Assessment: <App> (<N> findings)` with the assessment markdown attached as `AttachedFile`.
* Four `User Story` priority groups (one each for P0/P1/P2/P3 that have rows).
* One child per CSV row: `Bug` for P0/P1, `Task` for P2/P3 by default.
* A per-row log CSV at `<csv-dir>/<csv-name>-import-log.csv` with `Index`, `Status`, `Id`, `ParentId`, `Type`, `Title`, `Error`.

Field mapping by process:

| Process | Default parent | Default group | Bug rows become | Severity | Acceptance Criteria | State |
|---------|----------------|---------------|-----------------|----------|---------------------|-------|
| `Basic` | `Epic` | `Issue` | `Issue` | dropped | dropped | `To Do` |
| `Agile` | `Epic` | `User Story` | `Bug` | `Microsoft.VSTS.Common.Severity` | `Microsoft.VSTS.Common.AcceptanceCriteria` | from CSV |
| `Scrum` | `Epic` | `Product Backlog Item` | `Bug` | `Microsoft.VSTS.Common.Severity` | `Microsoft.VSTS.Common.AcceptanceCriteria` | from CSV |

For `Bug` rows on Agile and Scrum projects, the description HTML is also written to `Microsoft.VSTS.TCM.ReproSteps` (the field the Bug form displays as primary content).

See the full parameter table in [the ADO import SKILL.md](../.github/skills/hve-resiliency-workitem-import/SKILL.md#parameters-reference).

## Step 2B: Import into Jira Cloud

Set credentials in the environment (never paste a token into chat):

```powershell
$env:JIRA_EMAIL = 'you@example.com'
$env:JIRA_API_TOKEN = '<api-token>'
```

Slash command form:

```text
/hve-resiliency-workitem-jira-import
```

The skill will prompt for the base URL, project key, and CSV path, then post each row using the credentials in your environment.

Direct script form (full example with priority groups and the assessment markdown attached to the parent Epic):

```powershell
pwsh .github/skills/hve-resiliency-workitem-jira-import/scripts/import-jira.ps1 `
  -CsvPath "Microsoft-Assessment/exports/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment-Jira-WorkItems.csv" `
  -BaseUrl "https://your-tenant.atlassian.net" `
  -ProjectKey "RES" `
  -AssessmentPath "Microsoft-Assessment/EXAMPLE_MACAESA-Code-Level-Resiliency-Assessment.md" `
  -GroupByPriority
```

What this produces:

* One `Epic` parent with the assessment markdown uploaded via `POST /rest/api/3/issue/{key}/attachments`.
* Four `Story` priority groups (one each for P0/P1/P2/P3 that have rows).
* One child per CSV row using the `Issue Type` column (`Bug` for P0/P1, `Task` for P2/P3), or force a single type with `-ChildType`.
* Descriptions rendered as Atlassian Document Format (ADF): `Key:` prefixes as bold text, backticked terms as inline `code`, fenced blocks as `codeBlock`.
* A per-row log CSV at `<csv-dir>/<csv-name>-jira-import-log.csv` with `Index`, `Status`, `Key`, `ParentKey`, `Type`, `Summary`, `Error`.

**Company-managed projects:** the `parent` field is used for hierarchy, which works for team-managed projects and modern Jira Cloud projects. If your project requires the legacy Epic Link custom field, pass `-EpicNameField customfield_10011` (or your project's Epic Name field id) and link via the Epic Link field after import.

See the full parameter table in [the Jira import SKILL.md](../.github/skills/hve-resiliency-workitem-jira-import/SKILL.md#parameters-reference).

## Hierarchy options

Both import scripts support the same three hierarchy shapes:

| Flag combination | Result |
|------------------|--------|
| (default) | Parent created from the assessment; every finding linked directly to the parent. |
| `-GroupByPriority` | Parent + one priority group work item per non-empty P0-P3 bucket; findings linked to their priority group. |
| `-NoParent` | Flat list of findings, no parent, no grouping. |
| `-ParentId <id>` (ADO) / `-ParentKey <key>` (Jira) | Use an existing parent instead of creating a new one. |

`-GroupByPriority` is the most useful option for backlog grooming because each priority bucket becomes a single roll-up you can prioritize, assign to a sprint, or burn down independently.

## Dry runs and re-runs

Both import scripts accept `-DryRun`. Use it to validate the CSV and confirm the bucketing before any work items are created:

```powershell
pwsh .github/skills/hve-resiliency-workitem-import/scripts/import-ado.ps1 `
  -CsvPath "Microsoft-Assessment/exports/<app>-ADO-WorkItems.csv" `
  -Organization "https://dev.azure.com/<org>" `
  -Project "<project>" `
  -Process Agile `
  -GroupByPriority `
  -DryRun
```

A dry run prints the priority group counts (for example `P0=30, P1=46, P2=22, P3=14`) and the would-be parent title without making any API calls.

If a real run partially fails:

* Inspect the per-row log CSV (`...-import-log.csv` for ADO, `...-jira-import-log.csv` for Jira) and filter `Status = FAIL`.
* Fix the underlying issue (process mismatch, missing field, permissions) and re-run only the failed rows by trimming the CSV.
* Re-running the same CSV will create duplicates; the scripts are not idempotent. Use `-ParentId` / `-ParentKey` to re-attach to the existing parent if you need to re-import a subset.

## Troubleshooting quick reference

ADO:

* `TF401320: Rule Error for field` — a field value is rejected by the target process. Confirm `-Process` matches the project's process template and that `Priority` is `1`-`4`.
* `VS402625: The work item type does not exist` — `-Process` does not match the project. Verify on the project's `_settings/process` page.
* `401 Unauthorized` — re-run `az login --scope 499b84ac-1321-427f-aa17-267ca6975798/.default`.

Jira:

* `401 Unauthorized` — the API token is invalid or doesn't match the email. Regenerate the token.
* `403 Forbidden` — the account lacks Create Issue or Add Attachment permission.
* `400 issuetype: 'Story' is not valid` — pass `-GroupType <type>` matching a type that exists in your project.
* `400 parent: Field 'parent' cannot be set` — company-managed project; use `-NoParent` or set `-EpicNameField` and link via Epic Link manually.
* `400 Epic Name is required` — legacy company-managed project; pass `-EpicNameField customfield_10011` (or your project's field id).

Full troubleshooting tables live in each SKILL.md.

## Where to look next

* [Work item export SKILL.md](../.github/skills/hve-resiliency-workitem-export/SKILL.md) — full parameter reference and destination column mapping.
* [Work item import (ADO) SKILL.md](../.github/skills/hve-resiliency-workitem-import/SKILL.md) — full parameter reference, field mapping by process, and outputs.
* [Work item import (Jira) SKILL.md](../.github/skills/hve-resiliency-workitem-jira-import/SKILL.md) — full parameter reference, ADF rendering details, and outputs.
* [Resiliency Researcher Workflow](resiliency-researcher-workflow.md) — the upstream Phase 1-5 workflow that produces the assessment.
