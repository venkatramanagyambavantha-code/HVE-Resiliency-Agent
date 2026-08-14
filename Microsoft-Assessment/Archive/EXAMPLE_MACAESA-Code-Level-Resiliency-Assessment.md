# Code-Level Resiliency Assessment

**Multi-Agent-Custom-Automation-Engine-Solution-Accelerator**

**Assessment Date:** 2026-05-07

**Repo Scope:** Multi-Agent-Custom-Automation-Engine-Solution-Accelerator

**Current Deployment:** Single-region with passive DR target

**Target Deployment:** Active/Active

**Version:** 1.0.0

---

<a id="top"></a>

## Table of Contents

1. [Assessment Overview](#1-assessment-overview)
2. [Resilient Focused Recommendations](#2-resilient-focused-recommendations)
3. [Non-Resilient Focused Recommendations](#3-non-resilient-focused-recommendations)
4. [IaC Gap Analysis](#4-iac-gap-analysis)
5. [Full Finding Matrix](#5-full-finding-matrix)
6. [Microsoft Standards Alignment](#6-microsoft-standards-alignment)

---

# 1. Assessment Overview

The Multi-Agent-Custom-Automation-Engine-Solution-Accelerator is a multi-agent orchestration accelerator that lets end users author, approve, and execute long-running plans produced by AI agents. It ships three deployable workloads: a React SPA served by a small FastAPI proxy on Azure App Service, a FastAPI backend with WebSocket streaming on Azure Container Apps, and a FastMCP tools server also on Azure Container Apps. The orchestration layer drives a Magentic group-chat workflow against an Azure AI Foundry account and Project, with Azure OpenAI deployments projected through Foundry, Azure AI Search for RAG, Cosmos DB NoSQL (serverless) for plan and step persistence, Azure Storage Blob for documents, and Application Insights and Log Analytics for telemetry. Identity uses one User-Assigned Managed Identity across data planes plus a System-Assigned Managed Identity on App Service. In WAF mode the topology adds a VNet, NSGs, Private Endpoints, Private DNS zones, Bastion, and a Windows jumpbox VM. The codebase is Python 3.11 plus Bicep, with no durable workflow runtime, no message bus, no Key Vault, no global load balancer, and no Front Door, Application Gateway, or Traffic Manager today.

This assessment was produced under an evidence-only methodology: every finding cites a single primary source line in the repository (Bicep, Python, PowerShell, or workflow YAML), and every priority assignment is grounded in code or IaC behavior rather than in inferred intent. The scope is the customer's transition from the current single-region deployment with a passive DR target to an active/active topology fronted by a Global Load Balancer (GLB), with both regions serving traffic and the GLB making informed health-based routing decisions. Each finding was re-evaluated under that frame: items that block GLB-driven failover, prevent symmetric serving, or cause data loss or orphaned work during cutover are escalated; items whose behavior is identical between single-region and active/active are tracked as code quality.

## Assessment Themes

1. **No global load balancer and no truthful health signal.** The IaC contains no Front Door, Application Gateway, or Traffic Manager profile, so there is no failover decision-maker, and the backend `/healthz` endpoint is registered with `checks={}` so it returns healthy regardless of dependency state. The GLB layer must be added and the health endpoint must be wired to real dependency probes before active/active traffic is admissible. **Findings:** P0-021, P0-024, P0-025, P1-046.

2. **Stateful orchestration paths live in process memory.** Magentic checkpoints use `InMemoryCheckpointStorage`, the human-approval pause uses an `asyncio.Event` keyed by an in-process dict, the WebSocket connection map is a process-local `{user_id: WebSocket}` dictionary, and plan execution is handed to FastAPI `BackgroundTasks` that die with the worker. Any pod restart, replica scale event, or GLB cutover loses in-flight plans, drops live streams, and returns 404 on legitimate approval calls. Durable persistence and a pub/sub backplane are required before either region can serve traffic safely. **Findings:** P0-008, P0-009, P0-010, P0-011, P0-018, P0-019, P0-020.

3. **Every backing service is single-region by default.** Cosmos is provisioned as serverless (which cannot be promoted in place to multi-region writes), Foundry account and Project, AI Search (1×1), Storage, App Service, Container Apps Environment, and the VNet plus PE plus Private DNS stack are all single-region. The IaC exposes one `location` parameter and bakes single-region FQDNs into Container Apps env vars. The active/active topology requires symmetric infrastructure in both regions plus client-side region preference and per-region endpoint resolution. **Findings:** P0-001 through P0-007, P0-013, P0-014, P0-030, P1-001 through P1-006, P1-017.

4. **Identity and authentication gaps amplify when a second region is added.** The backend Container App enforces no auth at ingress, an all-zeros `sample_user` principal is returned when the auth header is absent, the MCP server runs unauthenticated when JWKS env vars are unset, and the WebSocket endpoint accepts a `user_id` query parameter and uses it as the session key without validating the principal. Adding a second region without fixing these doubles the public attack surface and breaks per-tenant isolation. **Findings:** P0-026, P0-027, P0-028, P0-029, P1-010, P1-011, P1-042, P1-043, P1-044, P1-045.

5. **External coupling and IaC hardcoding break region symmetry.** Container Apps and the Web App pull a base image from `biabcontainerreg.azurecr.io` (a Microsoft-owned shared registry not under customer control), the Bicep includes hard-coded paired-region tables for Cosmos and Log Analytics, the jumpbox admin password has a literal fallback, and image references use the mutable `latest_v4` tag. Customer-owned mirroring, parameterized region inputs, secret-store-sourced credentials, and digest-pinned images are required before the deployment can be reproduced symmetrically across two regions. **Findings:** P0-005, P0-022, P0-023, P1-012, P1-013, P1-014, P3-009.

## Summary Findings Table

| Section            | Priority  | Count  | Description                                                                                  |
|--------------------|-----------|--------|----------------------------------------------------------------------------------------------|
| **Resiliency**     | **P0**    | 30     | Blocks failover from functioning or renders multi-region deployment meaningless              |
| **Resiliency**     | **P1**    | 46     | Materially increases risk during failure; procedural workarounds or limited blast radius    |
| **Resiliency**     | **P2**    | 0      | Weakens resilience posture; best-practice improvements for zone/region survivability        |
| **Resiliency**     | **P3**    | 0      | Referential entries or compound interaction descriptions                                     |
| **Non-Resiliency** | **P2**    | 22     | Code quality, security hygiene, observability, and configuration improvements                |
| **Non-Resiliency** | **P3**    | 14     | Security-only observations and configuration hygiene items                                   |
|                    | **Total** | **112** |                                                                                              |

All 22 P2 and 14 P3 findings in this repository were classified by the Master Report as "behaves the same in single-region and active/active" or "identical regardless of region count." Under the active/active litmus test defined in the engagement context, every P2 and P3 finding therefore lands in the Non-Resiliency section. All 30 P0 and all 46 P1 findings change behavior between single-region and active/active and are therefore Resiliency.

> **IMPORTANT:** Throughout this guidance, hard numbers used for retry counts, timeout settings, interval timings, thread pool sizes, and circuit breaker thresholds are provided as examples. In code, these should be configurable variables sourced from environment-specific configmaps. Treat all code snippets as illustrative patterns, not prescriptive implementations.

[Back to Top](#top)

---


# 2. Resilient Focused Recommendations

## P0 — Critical Resiliency Risks (30)

#### P0-001: Foundry / AI Services account is single-region

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The AI Foundry / AI Services account is provisioned only in `{primaryRegion}` with no twin in `{secondaryRegion}`. During a regional failure or GLB-driven cutover, replicas in the secondary region have no Foundry control plane to call: every agent invocation, model call, and Bing-grounding tool fails with DNS or 5xx errors. The active/active deployment delivers zero AI continuity because the upstream dependency is gone.

**What does this solve:** Provides a regional Foundry endpoint in each region with runtime endpoint resolution that prefers local and falls back to peer.

**Resiliency Impact:** A peer Foundry account in `{secondaryRegion}`, plus an `app_config.resolve_foundry_endpoint()` resolver that probes local health and falls back to the peer, keeps agent invocations working when one region is unreachable.

**Recommended Fix:** Provision a peer `Microsoft.CognitiveServices/accounts` (kind `AIServices`) in `{secondaryRegion}` with the same UAMI and connection name; replace the single `AZURE_AI_PROJECT_ENDPOINT` env var with `_PRIMARY` / `_SECONDARY` plus an `APP_REGION` per regional Container App revision; add a `resolve_foundry_endpoint()` method that prefers the local-region endpoint and falls back to the peer; surface Foundry health in `/healthz/ready`.

**File:** infra/main.bicep:856-870

```bicep
// before — single Foundry account in one region; backend env points to the single endpoint
module aiFoundry 'modules/ai-services.bicep' = {
  name: 'foundry-${location}'
  params: {
    name: 'aif-${solutionPrefix}-${location}'
    location: location
    userAssignedIdentityResourceId: uami.outputs.resourceId
  }
}
// Container App env: AZURE_AI_PROJECT_ENDPOINT = aiFoundry.outputs.endpoint
```

**Fix:**

```bicep
module aiFoundryPrimary 'modules/ai-services.bicep' = {
  name: 'foundry-${primaryLocation}'
  params: {
    name: 'aif-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    userAssignedIdentityResourceId: uami.outputs.resourceId
  }
}
module aiFoundrySecondary 'modules/ai-services.bicep' = {
  name: 'foundry-${secondaryLocation}'
  params: {
    name: 'aif-${solutionPrefix}-${secondaryLocation}'
    location: secondaryLocation
    userAssignedIdentityResourceId: uami.outputs.resourceId
  }
}
```

```python
# path: src/backend/common/config/app_config.py
class AppConfig:
    def __init__(self) -> None:
        self.app_region = os.environ["APP_REGION"]  # "{primaryRegion}" or "{secondaryRegion}"
        self._foundry_endpoints = {
            "{primaryRegion}":   os.environ["AZURE_AI_PROJECT_ENDPOINT_PRIMARY"],
            "{secondaryRegion}": os.environ["AZURE_AI_PROJECT_ENDPOINT_SECONDARY"],
        }
        self._foundry_health: dict[str, bool] = {r: True for r in self._foundry_endpoints}

    def resolve_foundry_endpoint(self) -> str:
        local = self._foundry_endpoints[self.app_region]
        peer  = next(v for k, v in self._foundry_endpoints.items() if k != self.app_region)
        return local if self._foundry_health[self.app_region] else peer

    async def mark_foundry_unhealthy(self, region: str) -> None:
        self._foundry_health[region] = False
```

**Notes:** Cross-ref P0-002 (Project + Agent Service replication), P0-006 (OpenAI deployments), P0-016 (5xx-aware retry path), P0-017 (Foundry health probe). The `binggrnd` connection name stays identical across regions; only the underlying API key / managed-identity binding is re-issued to the peer Project.

<span style="font-size: 14px;">**MSFT Reference:** [OpenAI business continuity multi-region](https://learn.microsoft.com/azure/ai-services/openai/how-to/business-continuity-multivariate)</span>

---

#### P0-002: Foundry Project + Agent Service single-instance

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The Foundry Project and Agent Service exist only inside the primary-region Foundry account; agent definitions, thread metadata, and the Bing-grounding connection live there. During regional failover the GLB cannot land any plan-execution traffic in `{secondaryRegion}` — even with a healthy peer Foundry account (P0-001), there is no Project or agent metadata for it to use.

**What does this solve:** Replicates the Project and seeded agent catalog into the peer Foundry account so the secondary region can serve plan execution.

**Resiliency Impact:** A peer Project in `{secondaryRegion}` with identical agent definitions and connection names lets the failover region run the full agent flow without any user-visible reconfiguration.

**Recommended Fix:** Promote agent definitions to a versioned JSON catalog under `data/agent_teams/`; provision a peer `Microsoft.CognitiveServices/accounts/projects` under the secondary Foundry account with identical project name and connection name; add a post-deploy `deploymentScript` (or `azd hook`) that idempotently POSTs the catalog into both Projects via the Foundry SDK; ensure `AGENT_PROJECT_NAME` is identical in both regions and resolves through the regional Foundry endpoint from P0-001.

**File:** infra/main.bicep:937-960

```bicep
// before — single Project under the single Foundry account; one connection scope only
module aiFoundryProject 'modules/ai-project.bicep' = {
  name: 'aif-project-${location}'
  params: {
    parentName: aiFoundry.outputs.name
    location: location
    projectName: aiProjectName
    connections: [ { name: 'binggrnd', target: bingConnectionTarget } ]
  }
}
```

**Fix:**

```bicep
module aiFoundryProjectPrimary 'modules/ai-project.bicep' = {
  name: 'aif-project-${primaryLocation}'
  params: {
    parentName: aiFoundryPrimary.outputs.name
    location: primaryLocation
    projectName: aiProjectName
    connections: [ { name: 'binggrnd', target: bingConnectionTarget } ]
  }
}
module aiFoundryProjectSecondary 'modules/ai-project.bicep' = {
  name: 'aif-project-${secondaryLocation}'
  params: {
    parentName: aiFoundrySecondary.outputs.name
    location: secondaryLocation
    projectName: aiProjectName       // identical logical name in both regions
    connections: [ { name: 'binggrnd', target: bingConnectionTarget } ]
  }
}
```

```python
# path: src/backend/common/config/app_config.py
def resolve_agent_project(self) -> tuple[str, str]:
    endpoint = self.resolve_foundry_endpoint()
    project  = os.environ["AGENT_PROJECT_NAME"]   # identical in both regions
    return endpoint, project
```

**Notes:** Treat `data/agent_teams/*.json` as the seed catalog. Validation: replay the seed against both Projects and assert `count(agents)` matches; chaos-stop the primary Foundry account and submit a plan via `{secondaryRegion}`. Readiness: agent-count drift surfaces as `agents.drift=true` and the probe returns 503.

<span style="font-size: 14px;">**MSFT Reference:** [OpenAI business continuity multi-region](https://learn.microsoft.com/azure/ai-services/openai/how-to/business-continuity-multivariate)</span>

---

#### P0-003: Cosmos DB NoSQL is serverless single-region

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** Cosmos is provisioned with `EnableServerless` and a single `locations[]` entry, with `enableAutomaticFailover=false` and `enableMultipleWriteLocations=false`. During zone loss in `{primaryRegion}` or a regional outage, every read/write fails: backend replicas in `{secondaryRegion}` cannot fetch plans, persist approvals, or write checkpoints. Active/active for the data plane is not possible without migration.

**What does this solve:** Establishes a provisioned, geo-replicated, zone-redundant Cosmos account that the SDK can fail over across.

**Resiliency Impact:** With `locations[]` covering both regions, `enableMultipleWriteLocations=true`, and `automaticFailover=true`, the SDK's `preferred_locations` keeps reads pinned local and steps to the peer on connection error, so a regional outage does not stop plan reads/writes.

**Recommended Fix:** Per P0-013, provision a new `Microsoft.DocumentDB/databaseAccounts` *without* serverless, with both regions in `locations[]`, multi-region writes, automatic failover, and `isZoneRedundant=true`; migrate plan/step containers via change-feed; in `cosmosdb.CosmosDBClient.__init__` pass `preferred_locations=[app_region, peer_region]`; register a Cosmos dependency probe in `HealthCheckMiddleware`.

**File:** infra/main.bicep:1043-1130

```bicep
// before — serverless, single region, no automatic failover, no multi-region writes
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}'
  params: {
    name: 'cosmos-${solutionPrefix}'
    locations: [ { locationName: location, failoverPriority: 0 } ]
    capabilities: [ { name: 'EnableServerless' } ]
    automaticFailover: false
    enableMultipleWriteLocations: false
  }
}
```

**Fix:**

```bicep
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}'
  params: {
    name: 'cosmos-${solutionPrefix}'
    locations: [
      { locationName: primaryLocation,   failoverPriority: 0, isZoneRedundant: enableRedundancy }
      { locationName: secondaryLocation, failoverPriority: 1, isZoneRedundant: enableRedundancy }
    ]
    automaticFailover: true
    enableMultipleWriteLocations: true
    // capabilities: []  // intentionally empty — DO NOT include 'EnableServerless'
  }
}
```

```python
# path: src/backend/common/database/cosmosdb.py
from azure.cosmos.aio import CosmosClient
from azure.identity.aio import DefaultAzureCredential

class CosmosDBClient:
    def __init__(self, endpoint: str, app_region: str, peer_region: str) -> None:
        self._client = CosmosClient(
            url=endpoint,
            credential=DefaultAzureCredential(),
            preferred_locations=[app_region, peer_region],   # local-first, then peer
            consistency_level="Session",
        )
```

**Notes:** Cross-ref P0-013 (serverless cannot be promoted in place — migration is the prerequisite), P0-014 (client-side retry / failover), P0-015 (429 handling), P0-030 (PE in the secondary VNet). Readiness: if only the *peer* is reachable, return 200 with `cosmos.local=false, cosmos.peer=true` (degraded-but-serving) so GLB keeps the region in rotation.

<span style="font-size: 14px;">**MSFT Reference:** [Distribute data globally](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)</span>

---

#### P0-004: VNet / NSG / Private DNS / PE single-region

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The VNet, NSGs, Private DNS zones, and Private Endpoints are deployed only in `{primaryRegion}`. There is no network fabric in `{secondaryRegion}` to host PEs for Cosmos, Foundry, Search, or Storage. In an active/active topology this means the secondary region's Container Apps replicas cannot resolve or reach any private dependency, so symmetric failover is structurally impossible.

**What does this solve:** Establishes a symmetric per-region private network fabric so workloads in either region can reach private dependencies locally.

**Resiliency Impact:** During a `{primaryRegion}` outage, replicas in `{secondaryRegion}` have no PE wiring or DNS resolution path to private dependencies, so even healthy compute cannot serve traffic. A symmetric fabric with shared global Private DNS zones linked to both VNets is the prerequisite for any regional failover.

**Recommended Fix:** Refactor the VNet / NSG / PE module to take `location` and instantiate it twice from `main.bicep`; keep Private DNS zones as global resources and add `virtualNetworkLinks` for both regional VNets; provision per-region Private Endpoints for Cosmos, Foundry, Search, and Storage; validate `nslookup` from each region resolves to its local PE IP.

**File:** infra/main.bicep:736-754

```bicep
// Single regional network stack — only {primaryRegion} VNet, NSGs, PEs, DNS
module network 'modules/network.bicep' = {
  name: 'net-${location}'
  params: {
    location: location
    addressPrefix: '10.10.0.0/16'
  }
}
// Cosmos PE only in the primary VNet; Private DNS zone linked to one VNet only.
```

**Fix:**

```bicep
module networkPrimary   'modules/network.bicep' = { name: 'net-${primaryLocation}',   params: { location: primaryLocation,   addressPrefix: '10.10.0.0/16' } }
module networkSecondary 'modules/network.bicep' = { name: 'net-${secondaryLocation}', params: { location: secondaryLocation, addressPrefix: '10.20.0.0/16' } }

resource cosmosDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
}
resource cosmosDnsLinkPrimary 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: cosmosDnsZone
  name: 'link-${primaryLocation}'
  location: 'global'
  properties: { registrationEnabled: false, virtualNetwork: { id: networkPrimary.outputs.vnetId } }
}
resource cosmosDnsLinkSecondary 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: cosmosDnsZone
  name: 'link-${secondaryLocation}'
  location: 'global'
  properties: { registrationEnabled: false, virtualNetwork: { id: networkSecondary.outputs.vnetId } }
}

module cosmosPePrimary 'modules/private-endpoint.bicep' = {
  name: 'pe-cosmos-${primaryLocation}'
  params: {
    location: primaryLocation
    subnetId: networkPrimary.outputs.peSubnetId
    privateLinkServiceId: cosmos.outputs.resourceId
    groupIds: [ 'Sql' ]
    privateDnsZoneId: cosmosDnsZone.id
  }
}
// cosmosPeSecondary mirrors the same pattern for {secondaryRegion}.
```

**Notes:** Cross-ref P0-005 (per-region location parameters) and P0-030 (Cosmos PE in the secondary VNet specifically). Validate from each region: `nslookup` must resolve to the *local* PE private IP, not the peer region's range.

<span style="font-size: 14px;">**MSFT Reference:** [Reliability redundancy](https://learn.microsoft.com/azure/well-architected/reliability/redundancy)</span>

---

#### P0-005: Single Bicep `location` parameter

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `infra/main.bicep` exposes a single `location` parameter consumed by every module. The IaC has no concept of primary + secondary location, so it cannot describe an active/active topology at all. This blocks every other regional symmetry remediation (P0-001, P0-003, P0-004, P0-006, P0-007).

**What does this solve:** Allows the IaC to express two regional stacks the GLB can route across.

**Resiliency Impact:** Without explicit primary/secondary location parameters, symmetric infrastructure cannot be deployed, so a regional outage in `{primaryRegion}` has no peer in `{secondaryRegion}` to fail over to.

**Recommended Fix:** Add `primaryLocation` (default to RG location) and `secondaryLocation` (no default — force explicit) parameters; convert each regional module into a parameterized module instantiated twice; keep global resources (Private DNS, GLB, geo-replicated ACR, RBAC) at non-regional scope; wire `secondaryLocation` into `main.parameters.json` and `main.waf.parameters.json`.

**File:** infra/main.bicep:60

```bicep
// before — single region parameter, every module receives the same location
param location string = resourceGroup().location
```

**Fix:**

```bicep
@description('Primary region for this active/active deployment.')
param primaryLocation string = resourceGroup().location

@description('Secondary (peer) region — must differ from primaryLocation.')
param secondaryLocation string

var regions = [ primaryLocation, secondaryLocation ]

@batchSize(1)
module appStack 'modules/region-stack.bicep' = [for region in regions: {
  name: 'stack-${region}'
  params: {
    location: region
    solutionPrefix: solutionPrefix
    cosmosResourceId: cosmos.outputs.resourceId   // cross-region account from P0-003
  }
}]
```

**Notes:** Replace static `cosmosRegionPair` / `logAnalyticsRegionPair` lookup tables (P1-013, P1-014) with the explicit `secondaryLocation`. Surface the new parameter in `azure.yaml` / `azure_custom.yaml`. This refactor is a prerequisite for P0-001, P0-003, P0-004, P0-006, P0-007.

<span style="font-size: 14px;">**MSFT Reference:** [Bicep parameters](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameters)</span>

---

#### P0-006: `azureAiServiceLocation` pins single Foundry account

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The `azureAiServiceLocation` parameter feeds a single Foundry account; all OpenAI deployments inherit that location. During regional failover, OpenAI chat/embedding calls from `{secondaryRegion}` resolve to the dead primary, so plan generation and approval flows fail end-to-end. No model means no agent — the active/active deployment delivers no AI value.

**What does this solve:** Provisions identical OpenAI deployments in both Foundry accounts so the secondary region can serve model traffic.

**Resiliency Impact:** Per-region Foundry-location parameters with `GlobalStandard` SKU (where allowed) make quota portable across regions; identical deployment names mean only the endpoint changes per region, and the resolver from P0-001 does the rest.

**Recommended Fix:** Replace `azureAiServiceLocation` with `azureAiServicePrimaryLocation` and `azureAiServiceSecondaryLocation`; pre-validate model + capacity quota in both regions (`az cognitiveservices usage list`); deploy identical model deployments (same name, version, capacity) into both Foundry accounts; route OpenAI calls through `app_config.resolve_foundry_endpoint()` from P0-001.

**File:** infra/main.bicep:937-960

```bicep
// before — single location parameter pins all model deployments to one region
param azureAiServiceLocation string

module openAi 'modules/ai-services-deployments.bicep' = {
  name: 'oai-${azureAiServiceLocation}'
  params: { parentName: aiFoundry.outputs.name, deployments: openAiDeployments, location: azureAiServiceLocation }
}
```

**Fix:**

```bicep
param azureAiServicePrimaryLocation   string
param azureAiServiceSecondaryLocation string

var openAiDeployments = [
  { name: 'gpt-4.1-mini', model: 'gpt-4.1-mini', version: '2025-04-14', capacity: 50 }
  { name: 'gpt-4.1',      model: 'gpt-4.1',      version: '2025-04-14', capacity: 30 }
  { name: 'o4-mini',      model: 'o4-mini',      version: '2025-04-16', capacity: 30 }
]

module openAiPrimary 'modules/ai-services-deployments.bicep' = {
  name: 'oai-${azureAiServicePrimaryLocation}'
  params: { parentName: aiFoundryPrimary.outputs.name,   deployments: openAiDeployments, location: azureAiServicePrimaryLocation }
}
module openAiSecondary 'modules/ai-services-deployments.bicep' = {
  name: 'oai-${azureAiServiceSecondaryLocation}'
  params: { parentName: aiFoundrySecondary.outputs.name, deployments: openAiDeployments, location: azureAiServiceSecondaryLocation }
}
```

**Notes:** From each region's backend replica, issue a `chat.completions` call and assert the response telemetry `azure.region` matches the local region. Cross-ref P0-001 (resolver) and P0-016 (5xx + failover at the call site).

<span style="font-size: 14px;">**MSFT Reference:** [OpenAI business continuity multi-region](https://learn.microsoft.com/azure/ai-services/openai/how-to/business-continuity-multivariate)</span>

---

#### P0-007: `enableRedundancy=false` default

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `enableRedundancy` defaults to `false` and is not threaded through every AVM module. With the flag off, a single-zone failure inside either `{primaryRegion}` or `{secondaryRegion}` knocks out App Service Plan, Container Apps Env, Storage, and Cosmos in that region. Active/active only delivers value if each region also survives a zone loss; without zone-redundant defaults, a single zonal incident defeats the GLB's ability to keep the region in rotation.

**What does this solve:** Makes zone redundancy the production default and threads it consistently across every regional AVM module.

**Resiliency Impact:** Zone-redundant App Service Plans, Container Apps Envs, Storage (GZRS), and Cosmos `locations[].isZoneRedundant` ensure each region survives a single-zone loss without flipping the GLB unhealthy.

**Recommended Fix:** Flip the default to `true`; thread `enableRedundancy` into App Service Plan (`zoneRedundant`), Container Apps Env, Storage (`Standard_GZRS`), and Cosmos per-`locations[]`; validate at deploy time that each chosen region has at least 3 availability zones and fail the deployment otherwise.

**File:** infra/main.bicep:80

```bicep
// before — redundancy off by default; flag never reaches storage / Cosmos / plans
param enableRedundancy bool = false
```

**Fix:**

```bicep
param enableRedundancy bool = true

module appServicePlan 'br/public:avm/res/web/serverfarm:0.x.y' = {
  name: 'plan-${primaryLocation}'
  params: {
    name: 'plan-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    skuName: enableRedundancy ? 'P1v3' : 'B1'
    zoneRedundant: enableRedundancy
  }
}

module containerAppsEnv 'br/public:avm/res/app/managed-environment:0.x.y' = {
  name: 'cae-${primaryLocation}'
  params: {
    location: primaryLocation
    zoneRedundant: enableRedundancy
    workloadProfiles: [ { name: 'Consumption', workloadProfileType: 'Consumption' } ]
  }
}

module storage 'br/public:avm/res/storage/storage-account:0.x.y' = {
  params: {
    skuName: enableRedundancy ? 'Standard_GZRS' : 'Standard_LRS'
    location: primaryLocation
  }
}
```

**Notes:** Drop the proximity placement group requirement on the jumpbox so it isn't pinned to a single zone (cross-ref P1-009). Ready-probe contract (P0-021): a region is ready when at least 2 of 3 zones report healthy replicas; single-zone loss must not flip the region unhealthy.

<span style="font-size: 14px;">**MSFT Reference:** [Reliability redundancy](https://learn.microsoft.com/azure/well-architected/reliability/redundancy)</span>

---

#### P0-008: Orchestration uses InMemoryCheckpointStorage

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `OrchestrationConfig` constructs an `InMemoryCheckpointStorage` per process, so plan checkpoints live only in the replica that started them. Under a single-region topology a pod restart already loses in-flight checkpoints; once the deployment is active/active across `{primaryRegion}` and `{secondaryRegion}`, GLB cutover or replica failover deterministically destroys every in-flight checkpoint because the peer replicas have no shared store to read from.

**What does this solve:** Plan execution survives replica restarts and regional cutover by persisting checkpoints to a durable, geo-replicated store.

**Resiliency Impact:** During zone loss or `{primaryRegion}` → `{secondaryRegion}` failover the secondary replicas can resume orchestration from the latest checkpoint instead of restarting the plan. Without it, every active plan is abandoned the moment GLB shifts traffic.

**Recommended Fix:** Replace `InMemoryCheckpointStorage` with a Cosmos-backed `CheckpointStorage` keyed by `plan_id`, partitioned on `/plan_id`, with `_etag` optimistic concurrency, and run a startup recovery scan that re-drives `in_progress` plans owned by a dead replica.

**File:** src/backend/v4/orchestration/orchestration_config.py:1-50

```python
# before
class OrchestrationConfig:
    def __init__(self) -> None:
        self.checkpoint_storage = InMemoryCheckpointStorage()
```

**Fix:**

```python
# src/backend/v4/orchestration/checkpoint_storage.py (new)
from typing import Protocol, Any
from azure.cosmos.aio import ContainerProxy

class CheckpointStorage(Protocol):
    async def get(self, plan_id: str) -> dict[str, Any] | None: ...
    async def put(self, plan_id: str, state: dict[str, Any], etag: str | None) -> str: ...
    async def list_in_progress(self) -> list[str]: ...

class CosmosCheckpointStorage:
    def __init__(self, container: ContainerProxy) -> None:
        self._container = container

    async def put(self, plan_id: str, state: dict[str, Any], etag: str | None) -> str:
        state["id"] = plan_id
        state["plan_id"] = plan_id
        headers = {"If-Match": etag} if etag else None
        resp = await self._container.upsert_item(state, headers=headers)
        return resp["_etag"]

    async def list_in_progress(self) -> list[str]:
        q = "SELECT c.plan_id FROM c WHERE c.status = 'in_progress'"
        return [row["plan_id"] async for row in self._container.query_items(query=q, enable_cross_partition_query=True)]

# src/backend/v4/orchestration/orchestration_config.py
from v4.orchestration.checkpoint_storage import CosmosCheckpointStorage
self.checkpoint_storage = CosmosCheckpointStorage(cosmos.get_container("checkpoints"))
```

**Notes:** Add a `checkpoints` container to `infra/main.bicep` partitioned on `/plan_id`. Gate `/healthz/ready` on `recovery.complete=true` so GLB does not route fresh plan starts into a replica that has not finished sweeping orphans. Cross-ref P0-011 (durable runner) and P0-019 (startup recovery scan).

<span style="font-size: 14px;">**MSFT Reference:** [Leader Election pattern](https://learn.microsoft.com/azure/architecture/patterns/leader-election)</span>

---

#### P0-009: Pre-approval MPlan held in `asyncio.Event`

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `HumanApprovalMagenticManager` keeps the pending `MPlan` in a process-local dict and waits on an `asyncio.Event` for approval. In a single-region deployment a pod restart already strands the awaiting coroutine; in active/active across `{primaryRegion}` and `{secondaryRegion}` the GLB routinely routes the approval call to a different replica or region than the one that generated the plan, so the awaiting coroutine never resumes and the user sees 404.

**What does this solve:** Approvals can complete on any replica or region that receives the user action, regardless of where the plan was generated.

**Resiliency Impact:** During regional failover or replica churn, plans waiting on human approval continue to advance because the pending `MPlan` and decision are persisted in geo-replicated Cosmos rather than process memory.

**Recommended Fix:** Persist the pending plan and its approval state in a Cosmos `approvals` container partitioned by `/plan_id`; replace `event.wait()` with a bounded poll (or change-feed subscription) and apply approvals via `_etag` compare-and-set with an idempotency key.

**File:** src/backend/v4/orchestration/human_approval_manager.py:1-90

```python
# before
class HumanApprovalMagenticManager:
    def __init__(self) -> None:
        self._pending: dict[str, MPlan] = {}
        self._events: dict[str, asyncio.Event] = {}

    async def request_approval(self, plan: MPlan) -> bool:
        self._pending[plan.plan_id] = plan
        ev = self._events.setdefault(plan.plan_id, asyncio.Event())
        await ev.wait()                       # never resumes on a different replica
        return self._decisions[plan.plan_id]
```

**Fix:**

```python
# src/backend/v4/orchestration/human_approval_manager.py
async def request_approval(self, plan: MPlan) -> bool:
    record = {
        "id": plan.plan_id,
        "plan_id": plan.plan_id,
        "status": "awaiting",
        "mplan": plan.model_dump(),
        "user_id": self.current_user_id,
    }
    await self._approvals.upsert_item(record)
    decision = await self._poll_until_decided(plan.plan_id, timeout_s=3600)
    return decision == "approved"

async def _poll_until_decided(self, plan_id: str, timeout_s: int) -> str:
    deadline = asyncio.get_event_loop().time() + timeout_s
    delay = 0.5
    while asyncio.get_event_loop().time() < deadline:
        rec = await self._approvals.read_item(plan_id, partition_key=plan_id)
        if rec["status"] in ("approved", "rejected"):
            return rec["status"]
        await asyncio.sleep(min(delay, 5.0))
        delay = min(delay * 1.5, 5.0)
    raise TimeoutError(f"approval timeout for {plan_id}")
```

**Notes:** Pair with P0-012 (idempotency keys) and P0-020 (stateless approval routes). Change-feed-driven notification removes polling cost once P0-010's backplane is in place.

<span style="font-size: 14px;">**MSFT Reference:** [Idempotency pattern](https://learn.microsoft.com/azure/architecture/patterns/idempotency)</span>

---

#### P0-010: WebSocket connection map is in-memory

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `ConnectionConfig` keeps `{user_id: WebSocket}` in a process-local dict. Tokens emitted by the orchestrator running on replica A only reach sockets attached to replica A. In single-region this is hidden by sticky load balancing; under active/active across `{primaryRegion}` and `{secondaryRegion}` the orchestrator and the WebSocket land on different replicas (or different regions) on most requests, so live agent output is silently lost.

**What does this solve:** Live WebSocket streaming works regardless of which replica or region terminates the socket.

**Resiliency Impact:** During replica scale events, GLB cutover, or zone failure, users keep receiving agent tokens because every replica subscribes to a shared backplane that fans messages out by `user_id`.

**Recommended Fix:** Introduce a pub/sub backplane (Service Bus topic with geo-DR pair, or Web PubSub) authenticated via Managed Identity. Each replica subscribes per-user (or with a `user_id` correlation filter) and forwards events to its locally connected sockets; never emit directly to the in-memory dict.

**File:** src/backend/v4/api/connection_config.py:1-60

```python
# before
class ConnectionConfig:
    def __init__(self) -> None:
        self._sockets: dict[str, WebSocket] = {}

    async def emit(self, user_id: str, event: dict) -> None:
        ws = self._sockets.get(user_id)       # only finds sockets on this replica
        if ws is not None:
            await ws.send_json(event)
```

**Fix:**

```python
# src/backend/v4/api/backplane.py (new) — Service Bus, Managed Identity, no SAS keys
from azure.identity.aio import DefaultAzureCredential
from azure.servicebus.aio import ServiceBusClient
from azure.servicebus import ServiceBusMessage

class ServiceBusBackplane:
    def __init__(self, fqns: str, topic: str) -> None:
        self._client = ServiceBusClient(fully_qualified_namespace=fqns, credential=DefaultAzureCredential())
        self._topic = topic

    async def publish(self, user_id: str, event: dict) -> None:
        async with self._client.get_topic_sender(self._topic) as sender:
            await sender.send_messages(ServiceBusMessage(json.dumps(event), application_properties={"user_id": user_id}))

# src/backend/v4/api/connection_config.py
class ConnectionConfig:
    def __init__(self, backplane: Backplane) -> None:
        self._sockets: dict[str, WebSocket] = {}
        self._backplane = backplane

    async def attach(self, user_id: str, ws: WebSocket) -> None:
        self._sockets[user_id] = ws
        await self._backplane.subscribe(user_id, lambda evt: self._send_local(user_id, evt))

    async def emit(self, user_id: str, event: dict) -> None:
        await self._backplane.publish(user_id, event)
```

**Notes:** Provision Service Bus Premium per region with geo-DR pairing; grant the workload UAMI `Azure Service Bus Data Sender` and `Receiver`. CI must grep Bicep for `Endpoint=sb://`, `SharedAccessKey=`, `AccessKey=` and fail on match. Cross-ref P0-018 (replay-on-reconnect) and P0-029 (token-derived `user_id`).

<span style="font-size: 14px;">**MSFT Reference:** [Service Bus messaging overview](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview)</span>

---

#### P0-011: BackgroundTasks orphans `in_progress` plans

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The plan-execution route hands orchestration to FastAPI `BackgroundTasks`, which runs in the same process as the request handler. Single-region pod restarts already orphan in-flight plans; with active/active across `{primaryRegion}` and `{secondaryRegion}`, scale-in events, revision rollouts, and GLB drains routinely kill the loop, leaving plans stuck at `status='in_progress'` with no driver in either region.

**What does this solve:** Plan execution survives replica restarts because the work is queued to a durable runner that any healthy replica can pick up.

**Resiliency Impact:** During GLB cutover or zone loss, queued jobs are leased by replicas in the surviving region; checkpoints from P0-008 let the new owner resume from the latest step rather than restarting the plan.

**Recommended Fix:** Replace `BackgroundTasks.add_task(...)` with an enqueue to a Service Bus queue (sessions enabled, partitioned by `plan_id`). Run an `OrchestrationWorker` per replica that consumes with peek-lock and completes only on terminal status. Add a startup recovery scan that re-enqueues orphaned `in_progress` plans whose lease is expired.

**File:** src/backend/v4/api/router.py:368-371

```python
# before
@router.post("/api/v4/plans")
async def create_plan(req: CreatePlanRequest, background_tasks: BackgroundTasks):
    plan = await plans.create(req)
    background_tasks.add_task(run_plan, plan.plan_id)   # dies with the worker
    return plan
```

**Fix:**

```python
# src/backend/v4/api/router.py
@router.post("/api/v4/plans")
async def create_plan(req: CreatePlanRequest, runner: DurableRunner = Depends(get_runner)):
    plan = await plans.create(req)
    await runner.enqueue(PlanExecutionJob(plan_id=plan.plan_id, user_id=req.user_id))
    return plan

# src/backend/v4/orchestration/durable_runner.py (new)
class OrchestrationWorker:
    async def run_forever(self) -> None:
        async with self._runner._client.get_queue_receiver(self._runner._queue, max_wait_time=30) as rx:
            async for msg in rx:
                job = PlanExecutionJob.model_validate_json(str(msg))
                try:
                    await self._cfg.execute(job.plan_id)     # checkpoints to Cosmos (P0-008)
                    await rx.complete_message(msg)
                except TransientError:
                    await rx.abandon_message(msg)            # redeliver
                except Exception:
                    await rx.dead_letter_message(msg)
```

**Notes:** Use `DefaultAzureCredential` to authenticate to Service Bus; CI must reject any `SharedAccessKey=` literal in Bicep or Container Apps `secrets[]`. Gate `/healthz/ready` on `app.state.recovery_complete=true`. Cross-ref P0-008, P0-019.

<span style="font-size: 14px;">**MSFT Reference:** [Queue-Based Load Leveling pattern](https://learn.microsoft.com/azure/architecture/patterns/queue-based-load-leveling)</span>

---

#### P0-012: Approval / clarification routes lack idempotency keys

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** Approval and clarification endpoints mutate plan state without an `Idempotency-Key` header or `_etag` precondition. Single-region 5xx retries can already produce double-applied approvals; in active/active across `{primaryRegion}` and `{secondaryRegion}`, GLB probe-driven re-routing and cross-region client retries multiply the duplicate-write surface, so the same approval can be applied twice or race against a rejection from a peer replica.

**What does this solve:** Mutating routes are safe to retry: identical keys return the cached decision; conflicting concurrent decisions return 409 instead of corrupting plan state.

**Resiliency Impact:** During failover-driven retries plan state stays consistent because optimistic concurrency rejects stale writes and the per-key cache yields a deterministic replay response.

**Recommended Fix:** Require an `Idempotency-Key` header on every mutating route; atomically write `{idem_key, decision_response}` to the `approvals` Cosmos record on first call; on replay, return the cached response without mutation. Apply changes via `MatchConditions.IfNotModified` against the document `_etag`.

**File:** src/backend/v4/api/router.py:450-528

```python
# before — no idempotency key, no etag CAS
@router.post("/api/v4/plans/{plan_id}/approve")
async def approve(plan_id: str, body: ApproveRequest):
    rec = await approvals.read_item(item=plan_id, partition_key=plan_id)
    rec["status"] = "approved"
    await approvals.replace_item(item=plan_id, body=rec)   # last-write-wins
    return {"status": "approved"}
```

**Fix:**

```python
# src/backend/v4/api/idempotency.py (new)
async def require_idempotency_key(idempotency_key: str = Header(..., alias="Idempotency-Key")) -> str:
    if len(idempotency_key) < 16 or len(idempotency_key) > 128:
        raise HTTPException(status_code=400, detail="invalid Idempotency-Key")
    return idempotency_key

# src/backend/v4/api/router.py
@router.post("/api/v4/plans/{plan_id}/approve")
async def approve(plan_id: str, body: ApproveRequest,
                  idem_key: str = Depends(require_idempotency_key),
                  approvals = Depends(get_approvals_container)):
    rec = await approvals.read_item(item=plan_id, partition_key=plan_id)
    if rec.get("idem_key") == idem_key:
        return rec["decision_response"]                       # safe replay
    if rec["status"] != "awaiting":
        raise HTTPException(status_code=409, detail=f"plan already {rec['status']}")
    rec.update(status="approved", idem_key=idem_key, decided_by=body.user_id,
               decision_response={"status": "approved", "plan_id": plan_id})
    try:
        await approvals.replace_item(item=plan_id, body=rec, etag=rec["_etag"],
                                     match_condition=MatchConditions.IfNotModified)
    except ResourceModifiedError:
        raise HTTPException(status_code=409, detail="approval state changed; retry with fresh state")
    return rec["decision_response"]
```

**Notes:** Frontend must generate a stable UUID per user action and resend the same key on retry. Centralize the dependency so future mutating routes inherit the discipline. Do not log the idempotency key alongside user identifiers.

<span style="font-size: 14px;">**MSFT Reference:** [Idempotency pattern](https://learn.microsoft.com/azure/architecture/patterns/idempotency)</span>

---

#### P0-013: Cosmos serverless cannot be promoted in place

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The Cosmos account is created with `capabilities: [{ name: 'EnableServerless' }]`. Serverless accounts cannot be converted to provisioned, cannot enable multi-region writes, and cannot add additional regions — every path to active/active requires a one-way migration to a *new* provisioned account. Until this migration happens, P0-003 / P0-014 / P0-015 cannot be remediated and `{secondaryRegion}` Container Apps replicas have no Cosmos peer.

**What does this solve:** Provides the side-by-side migration plan and provisioned, geo-replicated target account that unblocks every other Cosmos finding.

**Resiliency Impact:** A new provisioned account with multi-region writes, container-level autoscale, and zone-redundant `locations[]` is the only path to a functioning active/active Cosmos plane.

**Recommended Fix:** Provision a new `Microsoft.DocumentDB/databaseAccounts` (`cosmos-${solutionPrefix}-mr`) without serverless, with multi-region writes, automatic failover, and `isZoneRedundant=true` per location; configure throughput at the *container* level (`autoscaleMaxThroughput`); use the change feed (or Data Factory) to copy data; cut readers over first, then writers; decommission the serverless account only after a 7-day soak; ensure `disableLocalAuth=true` so no key-based auth surface is reintroduced.

**File:** infra/main.bicep:1043-1130

```bicep
// before — serverless capability blocks geo-replication; no autoscale; no zone redundancy
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}'
  params: {
    name: 'cosmos-${solutionPrefix}'
    locations: [ { locationName: location, failoverPriority: 0 } ]
    capabilities: [ { name: 'EnableServerless' } ]
  }
}
```

**Fix:**

```bicep
// after — provisioned, geo-replicated, zone-redundant. NO connection strings emitted.
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}-mr'
  params: {
    name: 'cosmos-${solutionPrefix}-mr'
    locations: [
      { locationName: primaryLocation,   failoverPriority: 0, isZoneRedundant: enableRedundancy }
      { locationName: secondaryLocation, failoverPriority: 1, isZoneRedundant: enableRedundancy }
    ]
    automaticFailover: true
    enableMultipleWriteLocations: true
    capabilities: []                              // intentionally empty — no 'EnableServerless'
    disableLocalAuth: true                        // forbid key-based auth
    sqlDatabases: [
      {
        name: 'macae'
        containers: [
          { name: 'plans',       paths: [ '/user_id' ], autoscaleMaxThroughput: 4000 }
          { name: 'steps',       paths: [ '/plan_id' ], autoscaleMaxThroughput: 4000 }
          { name: 'approvals',   paths: [ '/plan_id' ], autoscaleMaxThroughput: 1000 }
          { name: 'checkpoints', paths: [ '/plan_id' ], autoscaleMaxThroughput: 4000 }
        ]
      }
    ]
    roleAssignments: [
      { principalId: uami.outputs.principalId, roleDefinitionIdOrName: 'Cosmos DB Built-in Data Contributor', principalType: 'ServicePrincipal' }
    ]
  }
}
```

**Notes:** CI guard: pipeline fails if `listKeys(cosmos` appears in any deployed Bicep output. End-to-end smoke: write to `{primaryRegion}` and read from `{secondaryRegion}` within 5s under session consistency. Cross-ref P0-003, P0-014, P0-015, P0-030.

<span style="font-size: 14px;">**MSFT Reference:** [Distribute data globally](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)</span>

---

#### P0-014: Cosmos unavailable / regional outage unhandled (F1)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `CosmosDBClient.__init__` constructs a `CosmosClient` with no `preferred_locations`, no retry policy, and no circuit-breaker. When `{primaryRegion}` Cosmos goes down, every request raises `ServiceRequestError` / `ServiceResponseError` and bubbles to callers as 500. Even with the multi-region account from P0-003 in place, the client never *uses* `{secondaryRegion}` because it is not in the preferred list — active/active does not engage.

**What does this solve:** Wires the SDK's region-aware behavior into the client and exposes regional health to `/healthz/ready`.

**Resiliency Impact:** Local-first `preferred_locations` plus bounded retries (3 attempts, 250 ms base, full jitter) keep reads serving from `{secondaryRegion}` within the SDK timeout window when `{primaryRegion}` is unreachable; `/healthz/ready` flips to 503 only when *both* regions fail.

**Recommended Fix:** Pass `preferred_locations=[app_region, peer_region]`; configure `retry_total=3` and `retry_backoff_factor=0.25`; wrap each operation in `_with_retry` that distinguishes 503 (retry) from 429 (cross-ref P0-015) from 4xx (no retry); register a Cosmos probe in `HealthCheckMiddleware` issuing a 1-RU read against a known partition; never introduce an `account_key` overload as a "fallback".

**File:** src/backend/common/database/cosmosdb.py:71-73

```python
# before — no preferred_locations, no retry, generic exceptions, no health flag
class CosmosDBClient:
    def __init__(self, endpoint: str) -> None:
        self._client = CosmosClient(url=endpoint, credential=DefaultAzureCredential())

    async def read_item(self, container: str, item: str, pk: str):
        return await self._container(container).read_item(item=item, partition_key=pk)
```

**Fix:**

```python
from azure.cosmos.aio import CosmosClient
from azure.cosmos.exceptions import CosmosHttpResponseError, CosmosClientTimeoutError
from azure.identity.aio import DefaultAzureCredential

class CosmosDBClient:
    def __init__(self, endpoint: str, app_region: str, peer_region: str) -> None:
        self._endpoint = endpoint
        self._app_region = app_region
        self._client = CosmosClient(
            url=endpoint,
            credential=DefaultAzureCredential(),
            preferred_locations=[app_region, peer_region],
            consistency_level="Session",
            retry_total=3,
            retry_backoff_factor=0.25,
            connection_timeout=5,
        )
        self._healthy: dict[str, bool] = {app_region: True, peer_region: True}

    async def read_item(self, container: str, item: str, pk: str):
        try:
            return await self._container(container).read_item(item=item, partition_key=pk)
        except CosmosHttpResponseError as ex:
            if ex.status_code == 503:
                self._healthy[self._app_region] = False
                raise CosmosRegionUnavailable(self._app_region) from ex
            raise
        except CosmosClientTimeoutError:
            self._healthy[self._app_region] = False
            raise

    def is_healthy(self, region: str) -> bool:
        return self._healthy.get(region, False)
```

**Notes:** Cross-ref P0-003 (multi-region account is the prerequisite), P0-015 (429 handling lives in a sibling helper), P0-021/P0-025 (Cosmos probe registration). Chaos test: block egress to the primary Cosmos FQDN and assert reads succeed against `{secondaryRegion}` within the SDK timeout window.

<span style="font-size: 14px;">**MSFT Reference:** [Cosmos DB preferred locations (Python)](https://learn.microsoft.com/azure/cosmos-db/nosql/quickstart-python)</span>

---

#### P0-015: Cosmos 429 RU throttling unhandled (F2)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The Cosmos wrapper catches a generic `Exception` and logs it; HTTP 429 (`x-ms-retry-after-ms`) is not differentiated from 503 or transport errors. During a GLB cutover, the surviving region absorbs both regions' workload; RU consumption spikes, Cosmos sheds load with 429, and every shed request becomes a user-visible 500. Without honoring `x-ms-retry-after-ms`, the wrapper retries immediately (cascading the throttle) or not at all.

**What does this solve:** Adds a retry-after-honoring 429 handler with bounded total budget, separate from the 5xx retry path.

**Resiliency Impact:** During failover absorption, throttled requests sleep for the server-advised interval (with jitter) up to a 10s wall-clock cap, preventing throttle cascades while keeping users out of the 5xx path; sustained throttling surfaces as `cosmos.throttled=true` in `/healthz` for ops, but does not flip readiness.

**Recommended Fix:** Replace `except Exception` with `except CosmosHttpResponseError` and branch on `ex.status_code`; on 429, parse `ex.headers["x-ms-retry-after-ms"]` (fallback 100ms), sleep, and retry up to 5 attempts within a 10s budget; emit `cosmos.throttled` and `cosmos.ru_charge` metrics; do not flip readiness on throttling — backpressure is not an outage.

**File:** src/backend/common/database/cosmosdb.py:110-176

```python
# before — generic exception swallow; 429 retried immediately or not at all
async def read_item(self, container: str, item: str, pk: str):
    try:
        return await self._container(container).read_item(item=item, partition_key=pk)
    except Exception as ex:
        log.error("cosmos read_item failed: %s", ex)
        raise
```

**Fix:**

```python
import asyncio, random
from azure.cosmos.exceptions import CosmosHttpResponseError

async def _with_429_retry(self, op_name: str, op):
    deadline = asyncio.get_event_loop().time() + 10.0
    attempt = 0
    while True:
        try:
            result = await op()
            ru = float(result.headers.get("x-ms-request-charge", "0")) if hasattr(result, "headers") else 0.0
            metrics.histogram("cosmos.ru_charge", ru, tags={"op": op_name})
            return result
        except CosmosHttpResponseError as ex:
            if ex.status_code == 429 and attempt < 5 and asyncio.get_event_loop().time() < deadline:
                delay_ms = int(ex.headers.get("x-ms-retry-after-ms", "100"))
                jitter   = random.uniform(0, delay_ms * 0.25)
                metrics.counter("cosmos.throttled", tags={"op": op_name})
                await asyncio.sleep((delay_ms + jitter) / 1000.0)
                attempt += 1
                continue
            raise

async def read_item(self, container: str, item: str, pk: str):
    return await self._with_429_retry(
        f"read_item:{container}",
        lambda: self._container(container).read_item(item=item, partition_key=pk),
    )
```

**Notes:** Load test: ramp to 2× provisioned RU; assert API stays under 1% 5xx and `cosmos.throttled` rises while end-user requests still succeed. Budget test: unbounded 429 mocks must raise after the 10s deadline (no infinite retry). Cross-ref P0-014 (sibling 5xx path), P1-022 (separation of 429 from generic exceptions).

<span style="font-size: 14px;">**MSFT Reference:** [Retry pattern](https://learn.microsoft.com/azure/architecture/patterns/retry)</span>

---

#### P0-016: OpenAI 5xx / regional outage unhandled (F5)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `HumanApprovalMagenticManager` calls Azure OpenAI through the Foundry Project with no 5xx-aware retry and no fallback endpoint. During an OpenAI regional outage in `{primaryRegion}` (503s, capacity exhaustion, model rollover), every plan-generation call fails. Even with the peer Foundry account from P0-001 deployed, this code path never tries it, so active/active delivers no AI continuity at runtime.

**What does this solve:** Adds 5xx-aware retry with bounded jitter and a peer-endpoint fallback at the call site.

**Resiliency Impact:** Bounded retry (3 attempts, exponential jitter) absorbs transient 5xx; on exhaustion, the manager marks the local Foundry endpoint unhealthy and reconstructs the client against the peer endpoint, emitting `openai.failover` exactly once per cutover.

**Recommended Fix:** Wrap OpenAI calls in `tenacity` with `stop_after_attempt(3)` and `wait_exponential_jitter(initial=0.5, max=4)`, retrying only on 5xx and connection errors; on exhaustion, call `app_config.mark_foundry_unhealthy(local_region)`, build a client against the peer endpoint, and retry once; emit `openai.failover from=… to=… reason=…` per cutover; never introduce an `AZURE_OPENAI_API_KEY` env var as a "fallback" — token auth via `DefaultAzureCredential` only.

**File:** src/backend/v4/orchestration/human_approval_manager.py:114-141

```python
# before — single endpoint, no retry, no fallback
class HumanApprovalMagenticManager:
    def __init__(self, app_config: AppConfig) -> None:
        self._client = AsyncAzureOpenAI(
            azure_endpoint=app_config.openai_endpoint,
            api_key=app_config.openai_api_key,
            api_version="2025-04-01-preview",
        )

    async def generate_plan(self, prompt: str) -> MPlan:
        resp = await self._client.chat.completions.create(
            model="gpt-4.1-mini",
            messages=[{"role": "user", "content": prompt}],
        )
        return MPlan.from_response(resp)
```

**Fix:**

```python
from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential_jitter, retry_if_exception_type
from openai import AsyncAzureOpenAI, APIStatusError, APIConnectionError

class HumanApprovalMagenticManager:
    def __init__(self, app_config: AppConfig) -> None:
        self._cfg = app_config

    async def _client_for(self, endpoint: str) -> AsyncAzureOpenAI:
        token = await self._cfg.credential.get_token("https://cognitiveservices.azure.com/.default")
        return AsyncAzureOpenAI(azure_endpoint=endpoint, api_key=token.token, api_version="2025-04-01-preview")

    async def generate_plan(self, prompt: str) -> MPlan:
        local = self._cfg.resolve_foundry_endpoint()
        try:
            return await self._call_with_retry(local, prompt)
        except (APIStatusError, APIConnectionError) as ex:
            if self._is_5xx(ex):
                await self._cfg.mark_foundry_unhealthy(self._cfg.app_region)
                peer = self._cfg.peer_foundry_endpoint()
                log.warning("openai.failover from=%s to=%s reason=%s", local, peer, ex)
                return await self._call_with_retry(peer, prompt)
            raise

    async def _call_with_retry(self, endpoint: str, prompt: str) -> MPlan:
        async for attempt in AsyncRetrying(
            stop=stop_after_attempt(3),
            wait=wait_exponential_jitter(initial=0.5, max=4),
            retry=retry_if_exception_type((APIStatusError, APIConnectionError)),
            reraise=True,
        ):
            with attempt:
                client = await self._client_for(endpoint)
                resp = await client.chat.completions.create(model="gpt-4.1-mini", messages=[{"role": "user", "content": prompt}])
                return MPlan.from_response(resp)

    @staticmethod
    def _is_5xx(ex: Exception) -> bool:
        return isinstance(ex, APIStatusError) and 500 <= ex.status_code < 600
```

**Notes:** Cross-ref P0-001 (`resolve_foundry_endpoint`, `peer_foundry_endpoint`, `mark_foundry_unhealthy`), P0-017 (Foundry probe feeds health). Build gate: fail if `AZURE_OPENAI_API_KEY` appears in any `secrets[]`. Readiness contract: a region stays ready when *either* local or peer Foundry is reachable; only dual-failure flips it 503.

<span style="font-size: 14px;">**MSFT Reference:** [Retry pattern](https://learn.microsoft.com/azure/architecture/patterns/retry)</span>

---

#### P0-017: Foundry / AI Project unavailable unhandled (F6)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `app_config` resolves the Foundry / AI Project endpoint once at process startup and caches it for the life of the replica. There is no health probe and no re-resolution on transient failure. If Foundry in `{primaryRegion}` becomes unavailable after startup, every agent invocation continues to dial the dead endpoint until the replica is restarted, the peer endpoint (P0-001) is never consulted, and `/healthz/ready` keeps returning 200 because nothing observes Foundry's state. Active/active never engages.

**What does this solve:** Replaces the cached client with a lazy factory and adds a periodic Foundry probe that drives the regional health flag and `/healthz/ready`.

**Resiliency Impact:** A 15-second probe loop with a 60-second cool-down on recovery prevents flap; the resolver from P0-001 picks the peer endpoint within one tick when local goes unhealthy; readiness flips to 503 only when both regions are unhealthy.

**Recommended Fix:** Replace the cached `Project` instance with an `AzureAIClient` factory that calls `app_config.resolve_foundry_endpoint()` per call; add a `_FoundryProbe` background task (15s interval) that hits `GET /openai/models` against the local endpoint and calls `mark_foundry_unhealthy(local_region)` on 5xx/timeout; mark the region healthy again after 4 consecutive successes (60s); start the task in the FastAPI lifespan hook; surface `foundry.local` / `foundry.peer` flags in the readiness payload.

**File:** src/backend/common/config/app_config.py:244-269

```python
# before — endpoint resolved once at startup; no probe, no re-resolution
class AppConfig:
    def __init__(self) -> None:
        self.credential = DefaultAzureCredential()
        self._project = AIProjectClient(
            endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
            credential=self.credential,
        )

    def get_ai_project_client(self) -> AIProjectClient:
        return self._project   # cached for life of process
```

**Fix:**

```python
from azure.ai.projects.aio import AIProjectClient
from azure.identity.aio import DefaultAzureCredential

class AppConfig:
    def get_ai_project_client(self) -> AIProjectClient:
        endpoint = self.resolve_foundry_endpoint()         # P0-001 resolver, called every time
        return AIProjectClient(endpoint=endpoint, credential=self.credential)

    async def start_foundry_probe(self) -> None:
        self._probe_task = asyncio.create_task(self._foundry_probe_loop())

    async def _foundry_probe_loop(self) -> None:
        consecutive_ok = 0
        while True:
            try:
                client = self.get_ai_project_client()
                async with client:
                    _ = [m async for m in client.inference.list_models()]   # cheap probe
                consecutive_ok += 1
                if consecutive_ok >= 4:                     # 4 × 15s = 60s
                    await self.mark_foundry_healthy(self.app_region)
            except Exception as ex:
                consecutive_ok = 0
                await self.mark_foundry_unhealthy(self.app_region)
                log.warning("foundry.probe.failed region=%s err=%s", self.app_region, ex)
            await asyncio.sleep(15)
```

```python
# path: src/backend/middleware/health_check.py
async def readiness(self) -> JSONResponse:
    payload = {
        "foundry.local": app_config.is_foundry_healthy(app_config.app_region),
        "foundry.peer":  app_config.is_foundry_healthy(app_config.peer_region),
        # ... cosmos, backplane, runner ...
    }
    ok = payload["foundry.local"] or payload["foundry.peer"]
    return JSONResponse(status_code=200 if ok else 503, content=payload)
```

**Notes:** Cross-ref P0-001 (resolver + health flags), P0-016 (call-site retry that consults the same flag), P0-021/P0-025 (probe registry that publishes the readiness payload). Recovery test: bring the endpoint back and assert `foundry.local=true` flips after 60s of consecutive successes (no flap).

<span style="font-size: 14px;">**MSFT Reference:** [Health endpoint monitoring](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P0-018: WebSocket disconnect / replica failover (F12)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** WebSocket disconnects from replica scaling, GLB cutover, or transient network blips drop the user's session with no reconnect protocol and no message replay. In single-region this manifests as occasional UI staleness; in active/active across `{primaryRegion}` and `{secondaryRegion}` the cutover deterministically severs every WebSocket, and the reconnecting client lands on a different replica with no offset tracking — so the new replica either replays everything (duplicates) or nothing (gaps).

**What does this solve:** Reconnecting clients receive exactly the messages they missed, with no duplicates and no gaps, regardless of which replica or region terminates the new socket.

**Resiliency Impact:** During regional failover users keep monitoring running plans through the cutover because per-user offsets and a 24-hour backplane TTL let any replica replay the missed window.

**Recommended Fix:** Tag every outbound event with a monotonic per-user `seq`; persist `last_acked_seq` per `user_id` in a Cosmos `connections` container; on reconnect, accept `?since=<seq>` and replay from the backplane subscription starting at `since+1`. Pair with P0-010 backplane.

**File:** src/backend/v4/api/connection_config.py:1-60

```python
# before — emits to local socket only, no seq, no replay
async def emit(self, user_id: str, event: dict) -> None:
    ws = self._sockets.get(user_id)
    if ws is not None:
        await ws.send_json(event)
```

**Fix:**

```python
# src/backend/v4/api/router.py
@router.websocket("/api/v4/ws")
async def stream(ws: WebSocket, since: int = Query(default=0), connections: ConnectionConfig = Depends(get_connections)):
    user_id = await authenticate_ws(ws)        # cross-ref P0-029
    await ws.accept()
    await connections.attach(user_id, ws)
    async for evt in connections.replay(user_id, after_seq=since):
        await ws.send_json(evt)
    while True:
        msg = await ws.receive_json()
        if "ack" in msg:
            await connections.record_ack(user_id, int(msg["ack"]))

# src/backend/v4/api/connection_config.py
class ConnectionConfig:
    async def emit(self, user_id: str, event: dict) -> None:
        seq = await self._next_seq(user_id)
        event["seq"] = seq
        await self._backplane.publish(user_id, event)

    async def record_ack(self, user_id: str, seq: int) -> None:
        await self._container.upsert_item({"id": user_id, "user_id": user_id, "last_acked_seq": seq})
```

**Notes:** Backplane subscription TTL ≥ 24h so reconnects within the window do not drop messages. Cross-ref P0-010 (backplane) and P0-029 (WS auth).

<span style="font-size: 14px;">**MSFT Reference:** [Azure Web PubSub overview](https://learn.microsoft.com/azure/azure-web-pubsub/overview)</span>

---

#### P0-019: Pod restart mid-orchestration (F13)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** Replicas restart for routine deploys, revision rollouts, scale-in, zone loss, and GLB drains. Because plan execution lives in `BackgroundTasks` (P0-011) and checkpoints live in process memory (P0-008), a restart kills the loop and leaves the plan at `in_progress` with no driver. Active/active across `{primaryRegion}` and `{secondaryRegion}` makes replica churn the common case rather than the edge case.

**What does this solve:** Plans abandoned by a dead replica are detected and re-enqueued the moment a fresh replica starts, before the replica advertises ready.

**Resiliency Impact:** Routine deploys and regional cutover do not strand plans because the surviving region's replicas sweep orphans on startup and resume them via the durable runner.

**Recommended Fix:** In the FastAPI lifespan hook, call `checkpoint_storage.list_in_progress()`, evaluate each plan's lease (via `heartbeat_ts`), and re-enqueue stale ones onto the durable runner from P0-011. Set `app.state.recovery_complete=True` only after the scan finishes; gate `/healthz/ready` on the flag.

**File:** src/backend/app.py:108

```python
# before — no recovery scan; restarts strand plans permanently
app = FastAPI()
app.add_middleware(HealthCheckMiddleware, checks={}, password="")
```

**Fix:**

```python
# src/backend/app.py
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.recovery_complete = False
    log.info("startup.recovery.begin")
    orphans = await app_config.orchestration.checkpoint_storage.list_in_progress()
    now = time.time()
    recovered = 0
    for plan_id in orphans:
        ckpt = await app_config.orchestration.checkpoint_storage.get(plan_id)
        if not ckpt:
            continue
        owner_age = now - ckpt.get("heartbeat_ts", 0)
        if owner_age > 60:
            await runner.enqueue(PlanExecutionJob(plan_id=plan_id, user_id=ckpt.get("user_id", "recovery")))
            log.info("plan.recovered plan_id=%s owner_was=%s age_s=%.1f", plan_id, ckpt.get("owner"), owner_age)
            recovered += 1
    metrics.gauge("plans.recovered_total", recovered)
    app.state.recovery_complete = True
    yield
```

**Notes:** Stale-lease threshold (60s) must exceed the worker heartbeat interval to avoid double-leases. Cross-ref P0-008 (checkpoint store), P0-011 (durable runner), P0-021 (readiness gate).

<span style="font-size: 14px;">**MSFT Reference:** [Reliability checklist](https://learn.microsoft.com/azure/well-architected/reliability/checklist)</span>

---

#### P0-020: Approval / clarification 404 after restart (F14)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** After a replica restart, the in-memory pending approval entry held by `HumanApprovalMagenticManager` is gone, so approval routes return 404 even though the plan exists in Cosmos. Single-region deploys already exhibit this on rollout; in active/active across `{primaryRegion}` and `{secondaryRegion}`, the GLB routinely routes the approval to a replica or region that never held the dict entry, so legitimate approvals fail with 404.

**What does this solve:** Approval and clarification routes are stateless, idempotent, and survive restarts and cross-region routing because they read from Cosmos as the source of truth.

**Resiliency Impact:** During regional failover users can advance plans through HITL gates from the surviving region; 404 is returned only when the plan genuinely does not exist, never as an artifact of where the request landed.

**Recommended Fix:** Persist the awaiting state in the Cosmos `approvals` container (P0-009) and reconstruct on lookup. Combine with idempotency from P0-012 — duplicate `Idempotency-Key` returns the prior decision response; conflicting CAS returns 409, never 404.

**File:** src/backend/v4/api/router.py:450-528

```python
# before — relies on in-memory dict that vanishes on restart
@router.get("/api/v4/plans/{plan_id}/approval")
async def get_approval(plan_id: str):
    if plan_id not in approval_manager.pending:
        raise HTTPException(404)              # 404 even if the plan is in Cosmos
    return approval_manager.pending[plan_id]
```

**Fix:**

```python
# src/backend/v4/api/router.py — Cosmos is the source of truth
@router.get("/api/v4/plans/{plan_id}/approval")
async def get_approval(plan_id: str, approvals = Depends(get_approvals_container)):
    try:
        rec = await approvals.read_item(item=plan_id, partition_key=plan_id)
    except CosmosResourceNotFoundError:
        raise HTTPException(status_code=404, detail="plan not found")
    return {"plan_id": plan_id, "status": rec["status"], "mplan": rec.get("mplan"),
            "decided_by": rec.get("decided_by")}

@router.post("/api/v4/plans/{plan_id}/approve")
async def approve(plan_id: str, body: ApproveRequest,
                  idem_key: str = Depends(require_idempotency_key),
                  approvals = Depends(get_approvals_container)):
    rec = await approvals.read_item(item=plan_id, partition_key=plan_id)
    if rec.get("idem_key") == idem_key:
        return rec["decision_response"]
    if rec["status"] != "awaiting":
        raise HTTPException(status_code=409, detail=f"plan already {rec['status']}")
    rec.update(status="approved", idem_key=idem_key, decided_by=body.user_id,
               decision_response={"status": "approved", "plan_id": plan_id})
    try:
        await approvals.replace_item(item=plan_id, body=rec, etag=rec["_etag"],
                                     match_condition=MatchConditions.IfNotModified)
    except ResourceModifiedError:
        raise HTTPException(status_code=409, detail="approval state changed; retry")
    return rec["decision_response"]
```

**Notes:** Orchestration loop wakes via the approvals change feed (or next poll) and resumes the plan from the latest checkpoint. Cross-ref P0-009, P0-011, P0-012.

<span style="font-size: 14px;">**MSFT Reference:** [Idempotency pattern](https://learn.microsoft.com/azure/architecture/patterns/idempotency)</span>

---

#### P0-021: `/healthz` returns healthy regardless of dependency state

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `HealthCheckMiddleware` is registered with an empty `checks={}` dict, so `/healthz` returns 200 regardless of Cosmos, Foundry, OpenAI, Search, Storage, MCP, or Service Bus state. In single-region this is misleading; once `{primaryRegion}` and `{secondaryRegion}` run active/active behind a GLB, the probe cannot tell a poisoned region from a healthy one — a dead `{primaryRegion}` keeps advertising success and the GLB keeps splitting traffic into a black hole.

**What does this solve:** The GLB receives a truthful per-region readiness signal that reflects the actual state of all critical dependencies.

**Resiliency Impact:** During zone or regional failure the GLB drains the unhealthy region within a few probe intervals, so live traffic shifts to the surviving region instead of returning 500s from the impacted one.

**Recommended Fix:** Build a `DependencyProbe` registry; split `/healthz/live` (process liveness) from `/healthz/ready` (dependency readiness); register Cosmos, Foundry, OpenAI, Service Bus, MCP, and JWKS as `critical=True`; cache probe results ~2s and run them concurrently with a 2s per-probe timeout. Wire the GLB origin probe to `/healthz/ready` only.

**File:** src/backend/middleware/health_check.py:24-30

```python
# before — empty registry returns 200 for everything
class HealthCheckMiddleware:
    def __init__(self, app, checks: dict = None, password: str = "") -> None:
        self.app = app
        self._checks = checks or {}             # always empty in app.py:108

    async def healthz(self) -> tuple[int, dict]:
        return 200, {"status": "ok"}            # synthetic OK regardless of state
```

**Fix:**

```python
# src/backend/middleware/health_check.py
@dataclass
class ProbeResult:
    ok: bool
    latency_ms: float
    detail: str = ""

class HealthCheckMiddleware:
    def __init__(self, app, probes: dict[str, DependencyProbe], app_region: str) -> None:
        self.app, self._probes, self._region = app, probes, app_region
        self._cache: dict[str, tuple[float, ProbeResult]] = {}

    async def _run(self, probe: DependencyProbe) -> ProbeResult:
        now = time.monotonic()
        cached = self._cache.get(probe.name)
        if cached and now - cached[0] < 2.0:
            return cached[1]
        start = time.perf_counter()
        try:
            result = await asyncio.wait_for(probe.check(), timeout=2.0)
        except Exception as exc:
            result = ProbeResult(ok=False, latency_ms=(time.perf_counter() - start) * 1000, detail=str(exc))
        self._cache[probe.name] = (now, result)
        return result

    async def ready(self) -> tuple[int, dict]:
        results = await asyncio.gather(*(self._run(p) for p in self._probes.values()))
        payload = {p.name: {"ok": r.ok, "latency_ms": r.latency_ms, "detail": r.detail, "critical": p.critical}
                   for p, r in zip(self._probes.values(), results)}
        critical_failed = any((not r.ok) and p.critical for p, r in zip(self._probes.values(), results))
        return (503 if critical_failed else 200), {"region": self._region, "checks": payload}
```

**Notes:** Foundational finding — every dependency-bearing P0/P1 (Cosmos, Foundry, ACR, Service Bus, MCP, auth) registers a probe in this registry. GLB probe contract: `GET /healthz/ready`, HTTPS, 5s interval, 2s timeout, 3 successes = healthy, 2 failures = unhealthy. Probe path is exempt from auth (cross-ref P0-026). Cross-region degradation: when local dependency is down but peer is reachable, return 200 with `<probe>.local=false, <probe>.peer=true`.

<span style="font-size: 14px;">**MSFT Reference:** [Health Endpoint Monitoring pattern](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P0-022: External ACR `biabcontainerreg.azurecr.io`

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** Container Apps and the App Service pull the runtime image from `biabcontainerreg.azurecr.io` — a Microsoft-owned shared registry not under customer control. During an outage of that single-region registry (or a network partition between either customer region and that hostname), cold-start of new replicas fails in `{primaryRegion}` and `{secondaryRegion}` simultaneously. An active/active topology that depends on a single shared external registry is not actually active/active.

**What does this solve:** Removes a third-party single-region supply-chain dependency from both regions' cold-start path.

**Resiliency Impact:** A customer-owned, geo-replicated ACR with Managed-Identity pull keeps cold-start working in both regions during failover, even if the upstream Microsoft-owned registry is unavailable or partitioned away.

**Recommended Fix:** Provision a Premium ACR with `replications` for both regions and `adminUserEnabled=false`; grant the workload UAMI `AcrPull` on the registry; mirror the upstream image as part of the `azd` pre-provision hook; replace every `biabcontainerreg.azurecr.io/...` literal with `${containerRegistryHostname}/...` sourced from the new ACR's `loginServer`; add a CI grep gate that fails the build if the external hostname reappears.

**File:** infra/main.bicep:140-160

```bicep
// before — image pinned to an external Microsoft-owned registry
var backendImage = 'biabcontainerreg.azurecr.io/macae/backend:latest'
// ...
properties: {
  template: {
    containers: [ { name: 'backend', image: backendImage } ]
  }
}
```

**Fix:**

```bicep
param acrName string = 'acr${solutionPrefix}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: primaryLocation
  sku: { name: 'Premium' }
  properties: {
    adminUserEnabled: false
    zoneRedundancy: enableRedundancy ? 'Enabled' : 'Disabled'
    publicNetworkAccess: 'Disabled'
  }
}

resource acrReplicaPrimary 'Microsoft.ContainerRegistry/registries/replications@2023-11-01-preview' = {
  parent: acr
  name: primaryLocation
  location: primaryLocation
  properties: { zoneRedundancy: enableRedundancy ? 'Enabled' : 'Disabled' }
}
resource acrReplicaSecondary 'Microsoft.ContainerRegistry/registries/replications@2023-11-01-preview' = {
  parent: acr
  name: secondaryLocation
  location: secondaryLocation
  properties: { zoneRedundancy: enableRedundancy ? 'Enabled' : 'Disabled' }
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, uami.outputs.principalId, 'acrpull')
  scope: acr
  properties: {
    principalId: uami.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

var containerRegistryHostname = acr.properties.loginServer
var backendImage = '${containerRegistryHostname}/macae/backend:${imageTag}'
```

**Notes:** Pin to immutable digests (not floating tags) once mirrored. ACR is non-critical for live requests (image is cached on running replicas), so it surfaces in `/healthz` as `acr.local_replica=ok|fail` but does not flip readiness. CI guard: grep `infra/**` and `src/**` for `biabcontainerreg.azurecr.io` and fail on any match.

<span style="font-size: 14px;">**MSFT Reference:** [ACR geo-replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication)</span>

---

#### P0-023: Jumpbox admin password fallback literal

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The jumpbox VM's admin password has a hard-coded literal default (`JumpboxAdminP@ssw0rd1234!`) baked into `infra/main.bicep` and the compiled `infra/main.json`. Any deployer who runs `azd provision` without overriding the parameter creates a privileged VM with a known credential. When the WAF layout is symmetrically deployed to `{secondaryRegion}` (P0-004, P0-005), the same literal is replicated — doubling the blast radius — and many tenants' regional policy rejects plaintext passwords outright, so the secondary region cannot stand up cleanly for active/active.

**What does this solve:** Eliminates a known weak credential from source control and lets the symmetric `{secondaryRegion}` deployment pass tenant policy.

**Resiliency Impact:** Without this fix, the secondary region's deployment is blocked by policy; with it, both regions deploy cleanly and the credential is rotated through Key Vault.

**Recommended Fix:** Delete the literal default; decorate the parameter with `@secure()` and remove any default value; source the value from Key Vault via `keyVault.id` + `secretName` syntax in `main.parameters.json`; rotate the compromised credential for every environment where this template was deployed; rebuild `infra/main.json` from the cleaned Bicep; add a CI gitleaks gate that fails on the literal substring `JumpboxAdminP@ssw0rd`.

**File:** infra/main.bicep:619-620

```bicep
// before — hard-coded password literal in source control
param vmAdminPassword string = 'JumpboxAdminP@ssw0rd1234!'
```

**Fix:**

```bicep
@secure()
@description('Jumpbox admin password sourced from Key Vault; no inline default permitted.')
param vmAdminPassword string

module jumpbox 'modules/jumpbox.bicep' = {
  name: 'jumpbox-${primaryLocation}'
  params: {
    location: primaryLocation
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
  }
}
```

```json
// path: infra/main.parameters.json — Key Vault secret reference
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vmAdminPassword": {
      "reference": {
        "keyVault": { "id": "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv>" },
        "secretName": "jumpbox-admin-password"
      }
    }
  }
}
```

**Notes:** Never grant the workload UAMI access to this secret — only the deployer principal needs `Key Vault Secret User`. Validation: `bicep build` produces a JSON artifact with no literal; `git grep` returns no matches; `azd provision` without override fails with a clear "parameter required" error.

<span style="font-size: 14px;">**MSFT Reference:** [Key Vault best practices](https://learn.microsoft.com/azure/key-vault/general/best-practices)</span>

---

#### P0-024: No GLB / Front Door / App Gateway / Traffic Manager

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The IaC contains no Front Door, Traffic Manager, Application Gateway, or CDN profile. Even after `{primaryRegion}` and `{secondaryRegion}` are stood up symmetrically (P0-001 through P0-007), there is no global routing layer in front to fail traffic over. Clients resolve a single regional FQDN, so a region outage is a full outage and the active/active control plane built by every other P0 finding has no decision-maker to act on the readiness signal from P0-021.

**What does this solve:** Adds the global decision-maker that consumes per-region readiness and routes users to a healthy region.

**Resiliency Impact:** Front Door Premium with two regional origins, priority-based failover, and a `/healthz/ready` probe automatically pulls a region out of rotation within ~15s of probe failures and restores it on recovery — turning the symmetric deployment into a true active/active topology.

**Recommended Fix:** Add a `Microsoft.Cdn/profiles` (Front Door Premium) at global scope with one `afdEndpoints` child per surface; create `originGroups` with `healthProbeSettings` pointing at `GET /healthz/ready` (HTTPS, 5s interval, 2s timeout); add two `origins` per group (`priority: 1` primary, `priority: 2` secondary); attach a WAF policy in Prevention mode; bind a custom domain via `afdCustomDomains` with a managed certificate; lock origin ingress to Front Door only (Private Link origin or `X-Azure-FDID` header validation).

**File:** infra/modules/global-load-balancer.bicep (absent)

```bicep
// before — no Front Door, Traffic Manager, App Gateway, or CDN profile in infra/.
// Clients resolve a single regional Container App FQDN. No failover layer exists.
```

**Fix:**

```bicep
// path: infra/modules/global-load-balancer.bicep (new)
param solutionPrefix string
param backendPrimaryHostname   string
param backendSecondaryHostname string

resource fd 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'fd-${solutionPrefix}'
  location: 'global'
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: { originResponseTimeoutSeconds: 60 }
}

resource fdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: fd
  name: 'api'
  location: 'global'
  properties: { enabledState: 'Enabled' }
}

resource fdOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: fd
  name: 'backend'
  properties: {
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3, additionalLatencyInMilliseconds: 50 }
    healthProbeSettings: {
      probePath: '/healthz/ready'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 5
    }
    sessionAffinityState: 'Disabled'
  }
}

resource fdOriginPrimary 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: fdOriginGroup
  name: 'origin-primary'
  properties: {
    hostName: backendPrimaryHostname
    originHostHeader: backendPrimaryHostname
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}
resource fdOriginSecondary 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: fdOriginGroup
  name: 'origin-secondary'
  properties: {
    hostName: backendSecondaryHostname
    originHostHeader: backendSecondaryHostname
    httpsPort: 443
    priority: 2
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

resource fdRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: fdEndpoint
  name: 'backend-route'
  properties: {
    originGroup: { id: fdOriginGroup.id }
    supportedProtocols: [ 'Https' ]
    patternsToMatch: [ '/*' ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}
```

**Notes:** Probe path must bypass auth at the backend (cross-ref P0-026): `/healthz/ready` is allow-listed in Easy Auth `excludedPaths` so anonymous probes are not rejected. Origin lock-down: backend rejects requests whose `X-Azure-FDID` header does not match the configured Front Door instance ID. This finding is the GLB layer that consumes the readiness contract defined in P0-021.

<span style="font-size: 14px;">**MSFT Reference:** [Azure Front Door overview](https://learn.microsoft.com/azure/frontdoor/front-door-overview)</span>

---

#### P0-025: `/healthz` registered with `checks={}` (implementation evidence; cross-ref P0-021)

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** `app.add_middleware(HealthCheckMiddleware, checks={}, password="")` registers the middleware with an empty probe dict and an empty-string password literal. The dict short-circuits to 200 and the password literal is a dead artifact. Active/active across `{primaryRegion}` and `{secondaryRegion}` makes this fatal: the GLB has no truthful per-region signal to drive failover, so an unhealthy region continues to receive 50% of traffic indefinitely.

**What does this solve:** The call site supplies a real probe dict so the middleware actually evaluates Cosmos, Foundry, OpenAI, Service Bus, MCP, and Search/Storage on every readiness call.

**Resiliency Impact:** With a populated registry, regional dependency outages flip `/healthz/ready` to 503 within one probe cycle and the GLB drains the impacted region.

**Recommended Fix:** Delete the `checks={}` and `password=""` arguments. Build a `probes` dict from the live dependency clients (no fresh client construction), mark Cosmos/Foundry/OpenAI/Service Bus/MCP as `critical=True`, mark Search/Storage as `critical=False`, and pass it to `HealthCheckMiddleware`.

**File:** src/backend/app.py:108

```python
# before — synthetic OK with empty-string password literal
app.add_middleware(HealthCheckMiddleware, checks={}, password="")
```

**Fix:**

```python
# src/backend/common/health/probes.py (new)
@dataclass
class CosmosProbe:
    client: object
    container_name: str
    critical: bool = True
    name: str = "cosmos"

    async def check(self):
        start = time.perf_counter()
        try:
            container = self.client.get_container(self.container_name)
            await container.read_item(item="__healthz__", partition_key="__healthz__")
            return ProbeResult(ok=True, latency_ms=(time.perf_counter() - start) * 1000)
        except Exception as exc:
            if "NotFound" in type(exc).__name__:
                return ProbeResult(ok=True, latency_ms=(time.perf_counter() - start) * 1000, detail="sentinel-missing")
            return ProbeResult(ok=False, latency_ms=(time.perf_counter() - start) * 1000, detail=str(exc))

# src/backend/app.py
probes = {
    "cosmos":     CosmosProbe(cosmos_client, container_name="checkpoints", critical=True),
    "foundry":    FoundryProbe(app_config.resolve_foundry_endpoint(), critical=True),
    "openai":     OpenAIProbe(app_config.resolve_openai_endpoint(),  critical=True),
    "search":     SearchProbe(app_config.search_endpoint,            critical=False),
    "storage":    StorageProbe(app_config.storage_account,           critical=False),
    "servicebus": ServiceBusProbe(app_config.servicebus_fqns,        critical=True),
    "mcp":        McpProbe(app_config.mcp_endpoint,                  critical=True),
}
app.add_middleware(HealthCheckMiddleware, probes=probes, app_region=app_config.app_region)
```

**Notes:** Inherits the GLB readiness contract from P0-021. Build-time grep must reject any reintroduction of `checks={}` or `password=""`. Cross-ref P3-010.

<span style="font-size: 14px;">**MSFT Reference:** [Health Endpoint Monitoring pattern](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P0-026: Backend has no auth enforcement at Container App ingress

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The backend Container App exposes `ingressExternal=true` with no `authConfigs` resource and no JWT validation in FastAPI. The app trusts whatever Easy Auth headers it receives, but Easy Auth is not configured, so unauthenticated traffic reaches route handlers directly and the principal is whatever the request claims. Once the GLB exposes the backend from both `{primaryRegion}` and `{secondaryRegion}`, the public attack surface doubles, and the Front Door origin can be bypassed if attackers find either Container App FQDN.

**What does this solve:** Every request to the backend ingress is authenticated against Entra ID and rejected at the platform level when the token is missing or invalid, in both regions.

**Resiliency Impact:** Adding `{secondaryRegion}` does not multiply the unauthenticated attack surface because each regional ingress enforces auth identically; failover between regions does not bypass identity controls.

**Recommended Fix:** Add a `Microsoft.App/containerApps/authConfigs` (Easy Auth v2) child to each regional backend with `unauthenticatedClientAction='Return401'`, configure Entra ID issuer/audience from Bicep params, allow-list `/healthz/live` and `/healthz/ready`, and add a FastAPI `AuthMiddleware` that re-validates the bearer token against JWKS and rejects when no principal resolves (no fallback).

**File:** src/backend/app.py:99-109

```python
# before — no auth middleware; ingress accepts anonymous requests
app = FastAPI()
app.add_middleware(HealthCheckMiddleware, checks={}, password="")
# (no AuthMiddleware; sample_user fallback fills request.state.principal)
```

**Fix:**

```bicep
// infra/main.bicep — Container App authConfigs (Easy Auth v2)
resource backendAuth 'Microsoft.App/containerApps/authConfigs@2024-03-01' = {
  parent: backendContainerApp
  name: 'current'
  properties: {
    platform: { enabled: true }
    globalValidation: {
      unauthenticatedClientAction: 'Return401'
      excludedPaths: [ '/healthz/live', '/healthz/ready' ]
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: backendApiClientId
          openIdIssuer: 'https://sts.windows.net/${entraTenantId}/'
        }
        validation: { allowedAudiences: [ backendApiAudience ] }
      }
    }
  }
}
```

```python
# src/backend/middleware/auth_middleware.py (new)
EXCLUDED = {"/healthz/live", "/healthz/ready"}

class AuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in EXCLUDED:
            return await call_next(request)
        token = request.headers.get("authorization", "").removeprefix("Bearer ").strip()
        if not token:
            return JSONResponse(status_code=401, content={"error": "missing_token"})
        try:
            principal = await validate_bearer_token(token)
        except AuthError as exc:
            return JSONResponse(status_code=401, content={"error": str(exc)})
        request.state.principal = principal
        return await call_next(request)
```

**Notes:** Audience and issuer are sourced from Bicep params; no client IDs or secrets in code. Register `AuthMiddleware` after `HealthCheckMiddleware` so probes are reached first. Apply same validator on WebSocket upgrade (P0-029). Cross-ref P0-027 (delete `sample_user` fallback in same change), P1-045.

<span style="font-size: 14px;">**MSFT Reference:** [Protected web API scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P0-027: `sample_user` all-zeros principal fallback

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** When `X-Ms-Client-Principal` is missing, `auth_utils` returns a `sample_user` whose `oid` and `tid` are `00000000-0000-0000-0000-000000000000`. That synthetic id is used as the Cosmos partition key for plans, approvals, and connections. In a single-region deployment this already silently authorizes anonymous callers; in active/active across `{primaryRegion}` and `{secondaryRegion}`, every region exposes the same fallback, so the synthetic principal is uniformly privileged in both regions and cross-tenant data isolation collapses across the failover topology.

**What does this solve:** Authentication fails closed: no synthetic principal can reach a route handler in production, in either region.

**Resiliency Impact:** Adding a second region does not extend an authentication-bypass surface; the failover topology preserves per-tenant isolation because both regions reject anonymous requests identically.

**Recommended Fix:** Delete the `sample_user` fallback from `get_authenticated_user_details()`; raise `AuthError("missing_principal")` instead. Move the `sample_user` literal into a test-only fixture under `src/tests/`. Audit Cosmos for documents whose `user_id` is the all-zeros oid and quarantine them. Add a regression grep that fails the build if `00000000-0000-0000-0000-000000000000` appears in `src/backend/`.

**File:** src/backend/auth/sample_user.py:32

```python
# before — anonymous request becomes a privileged synthetic user
def get_authenticated_user_details(request_headers):
    header = request_headers.get("X-Ms-Client-Principal")
    if header is None:
        return sample_user.sample_user        # all-zeros oid/tid fallback
    return _decode_easy_auth_header(header)

# src/backend/auth/sample_user.py:32
sample_user = {
    "oid": "00000000-0000-0000-0000-000000000000",
    "tid": "00000000-0000-0000-0000-000000000000",
}
```

**Fix:**

```python
# src/backend/common/auth/auth_utils.py
from common.auth.errors import AuthError

def get_authenticated_user_details(request_headers) -> dict:
    header = request_headers.get("X-Ms-Client-Principal")
    if header is None:
        raise AuthError("missing_principal")
    details = _decode_easy_auth_header(header)
    if not details.get("oid") or details["oid"] == "00000000-0000-0000-0000-000000000000":
        raise AuthError("invalid_principal")
    return details

# src/tests/backend/fixtures/sample_user.py (test-only; not imported from src/backend/)
sample_user_for_tests = {
    "oid": "11111111-2222-3333-4444-555555555555",
    "tid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    "name": "Test User",
}
```

**Notes:** `AuthMiddleware` from P0-026 returns 401 on missing principal rather than calling the deleted fallback. Quarantine query: `SELECT VALUE COUNT(1) FROM c WHERE c.user_id = '00000000-...'` should return 0 in production. Cross-ref P0-029 (WebSocket auth uses validated `oid`).

<span style="font-size: 14px;">**MSFT Reference:** [Managed identities for Azure resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)</span>

---

#### P0-028: MCP server runs unauthenticated when `enable_auth=True` but JWKS/issuer/audience env vars are unset

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The MCP server reads `MCP_ENABLE_AUTH` and JWKS settings from env; when `enable_auth=True` but `JWKS_URI`, `MCP_ISSUER`, or `MCP_AUDIENCE` is unset, the current code logs a warning and starts anyway with auth effectively disabled. Active/active across `{primaryRegion}` and `{secondaryRegion}` makes env drift between regional Container Apps inevitable — if one region is missing an env var, the GLB happily routes MCP traffic into the open instance because nothing detects the misconfiguration.

**What does this solve:** A misconfigured MCP region fails closed at startup so its Container Apps revision never reaches `Running` and the GLB does not route to it.

**Resiliency Impact:** Cross-region env-var drift cannot silently leave an unauthenticated MCP serving traffic; the failover topology only routes to regions that have validated their auth configuration on boot.

**Recommended Fix:** Replace the warn-and-continue branch with `sys.exit(1)` when `MCP_ENABLE_AUTH=true` and any required env var is missing. Default `MCP_ENABLE_AUTH=true` in IaC for both regional MCP Container Apps. Add a startup self-test that fetches JWKS once and emits `mcp.auth.startup.ok`; failure exits non-zero.

**File:** src/mcp_server/mcp_server.py:31-52

```python
# before — warns and continues with auth effectively off
def _validate_auth_config() -> None:
    enabled = os.environ.get("MCP_ENABLE_AUTH", "false").lower() == "true"
    if not enabled:
        return
    missing = [k for k in ("JWKS_URI", "MCP_ISSUER", "MCP_AUDIENCE") if not os.environ.get(k)]
    if missing:
        log.warning("mcp.auth.misconfigured missing=%s — starting unauthenticated", missing)
        return                                         # fails open
```

**Fix:**

```python
# src/mcp_server/mcp_server.py
import os, sys, logging

log = logging.getLogger("mcp")
REQUIRED_AUTH_ENV = ("JWKS_URI", "MCP_ISSUER", "MCP_AUDIENCE")

def _validate_auth_config() -> None:
    enabled = os.environ.get("MCP_ENABLE_AUTH", "true").lower() == "true"
    if not enabled:
        log.warning("mcp.auth.disabled — running unauthenticated; non-prod only")
        return
    missing = [k for k in REQUIRED_AUTH_ENV if not os.environ.get(k)]
    if missing:
        log.error("mcp.auth.misconfigured missing=%s", missing)
        sys.exit(1)                                    # fail closed
    log.info("mcp.auth.startup.ok issuer=%s audience=%s",
             os.environ["MCP_ISSUER"], os.environ["MCP_AUDIENCE"])

if __name__ == "__main__":
    _validate_auth_config()
    run_mcp_server()
```

**Notes:** Wire `JWKS_URI`, `MCP_ISSUER`, `MCP_AUDIENCE` from Bicep params/Key Vault into both regional MCP Container Apps. CI test must boot the image with missing env and assert non-zero exit. The MCP probe in P0-021's registry depends on an authenticated `GET /healthz` — a misconfigured region's revision never reaches `Running`, so the backend's MCP probe in that region returns failure and `/healthz/ready` returns 503. Cross-ref P1-011, P3-014.

<span style="font-size: 14px;">**MSFT Reference:** [Protected web API scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P0-029: WebSocket `user_id` accepted from query param without token validation

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The WebSocket endpoint takes `user_id` from the query string and uses it directly as the connection key, with no token validation on upgrade. After P0-010 introduces the pub/sub backplane, every region subscribes to `user_id`-keyed topics — meaning any client can claim any user's stream simply by passing that user's id in the URL. Active/active across `{primaryRegion}` and `{secondaryRegion}` exposes the same flaw on both sides of the GLB, doubling the attack surface.

**What does this solve:** WebSocket connections are bound to a token-validated `oid`, so a client cannot impersonate another user's stream from either region.

**Resiliency Impact:** Adding `{secondaryRegion}` does not introduce a new identity-spoofing vector; the failover topology preserves per-user stream isolation because both regions derive `user_id` from the same validated token claim.

**Recommended Fix:** On WebSocket upgrade, read the bearer token from the `Authorization` header (or `?access_token=` for browser WS over `wss://`), call the same `validate_bearer_token` validator as `AuthMiddleware`, derive `user_id` from `principal["oid"]`, close with code `1008` on missing/invalid token. Never trust the query-string `user_id`.

**File:** src/backend/v4/api/router.py:54-63

```python
# before — user_id from query param, no token check
@router.websocket("/api/v4/ws")
async def ws_handler(websocket: WebSocket, user_id: str = Query(...)):
    await websocket.accept()
    await connection_config.attach(user_id, websocket)   # any client can claim any user
    while True:
        msg = await websocket.receive_json()
```

**Fix:**

```python
# src/backend/v4/api/router.py
from fastapi import WebSocket
from common.auth.auth_utils import validate_bearer_token, AuthError

@router.websocket("/api/v4/ws")
async def ws_handler(websocket: WebSocket):
    await websocket.accept()
    auth_header = websocket.headers.get("authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    if not token and websocket.url.scheme == "wss":
        token = websocket.query_params.get("access_token", "")
    if not token:
        await websocket.close(code=1008)               # policy violation
        return
    try:
        principal = await validate_bearer_token(token)
    except AuthError:
        await websocket.close(code=1008)
        return

    user_id = principal["oid"]                         # canonical, never from query
    await connection_config.attach(user_id, websocket)
    try:
        while True:
            msg = await websocket.receive_json()
    finally:
        await connection_config.detach(user_id, websocket)
```

**Notes:** Shares the JWKS dependency with P0-026/P0-028 — JWKS unreachable flips `/healthz/ready` to 503 and the GLB drains the region for both HTTP and WebSocket traffic. JWKS URI must be sourced from `app_config.jwks_uri`, never hard-coded. Regression grep must fail the build on `user_id = websocket.query_params`.

<span style="font-size: 14px;">**MSFT Reference:** [Protected web API scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P0-030: Cosmos PE only in primary while Cosmos fails over

**Priority: P0 — Failover-Blocking Risk**

**Resiliency Related:** Yes

**Issue:** The Cosmos Private Endpoint exists only in the primary VNet; once Cosmos is given a secondary region (P0-003), the PE wiring is missing in `{secondaryRegion}`. With `publicNetworkAccess=Disabled`, secondary-region Container Apps either resolve the public Cosmos FQDN (blocked) or fail DNS entirely. After regional failover, Cosmos hands out the secondary write region, but the secondary region has no PE/DNS path to it — reads and writes time out, defeating active/active.

**What does this solve:** Provides a symmetric per-region Cosmos PE with shared global Private DNS so each region resolves Cosmos to its *local* PE private IP.

**Resiliency Impact:** Symmetric PEs plus `virtualNetworkLinks` from a single global `privatelink.documents.azure.com` zone to both VNets keep traffic on private endpoints during failover, with no public network exposure.

**Recommended Fix:** Add a `Microsoft.Network/privateEndpoints` in `{secondaryRegion}` targeting the same Cosmos account (`groupIds: ['Sql']`) in the secondary PE subnet; ensure the global Private DNS zone exists exactly once; add `virtualNetworkLinks` for both VNets with `registrationEnabled=false`; add a `privateDnsZoneGroups` child to *each* PE; validate `nslookup` from each region resolves to the local PE IP.

**File:** infra/main.bicep:1088-1101

```bicep
// before — Cosmos PE only in {primaryRegion}; secondary VNet has no PE or DNS link
resource cosmosPe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-cosmos-${primaryLocation}'
  location: primaryLocation
  properties: {
    subnet: { id: networkPrimary.outputs.peSubnetId }
    privateLinkServiceConnections: [
      { name: 'cosmos', properties: { privateLinkServiceId: cosmos.outputs.resourceId, groupIds: [ 'Sql' ] } }
    ]
  }
}
```

**Fix:**

```bicep
resource cosmosDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.documents.azure.com'
}

resource cosmosPeSecondary 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-cosmos-${secondaryLocation}'
  location: secondaryLocation
  properties: {
    subnet: { id: networkSecondary.outputs.peSubnetId }
    privateLinkServiceConnections: [
      {
        name: 'cosmos'
        properties: {
          privateLinkServiceId: cosmos.outputs.resourceId
          groupIds: [ 'Sql' ]
        }
      }
    ]
  }
}

resource cosmosPeDnsSecondary 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: cosmosPeSecondary
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-documents-azure-com'
        properties: { privateDnsZoneId: cosmosDnsZone.id }
      }
    ]
  }
}

resource cosmosDnsLinkSecondary 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: cosmosDnsZone
  name: 'link-${secondaryLocation}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: { id: networkSecondary.outputs.vnetId }
  }
}
```

**Notes:** Cosmos `publicNetworkAccess` must remain `Disabled` — no IP allow-list workarounds. Validation: trigger a Cosmos manual failover and confirm the SDK in `{secondaryRegion}` continues reads/writes via the local PE. Cross-ref P0-003 (multi-region Cosmos), P0-004 (per-region VNet fabric).

<span style="font-size: 14px;">**MSFT Reference:** [Distribute data globally](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)</span>

---

## P1 — High Priority Resiliency (46)

#### P1-001: Azure OpenAI deployments single-region

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** OpenAI model deployments (`gpt-4o`, embeddings, etc.) are projected only through the primary-region Foundry account, with no peer deployments in `{secondaryRegion}`. The single-region topology means that on regional failover the secondary-region backend has no deployment to call: the SDK returns 404 / DNS errors for every chat-completions or embeddings request. Even a healthy peer Foundry account (P0-001) is useless until matching deployments and capacity exist there.

**What does this solve:** Establishes a symmetric model-deployment catalog projected through both Foundry accounts so active/active backend replicas can resolve a local model endpoint.

**Resiliency Impact:** Without peer deployments the secondary region cannot run any agent or embedding call during failover, defeating the entire multi-region design.

**Recommended Fix:** Promote the deployment list to a parameterized array consumed by `infra/modules/ai-services-deployments.bicep`, instantiate the module against both `aiFoundryPrimary` and `aiFoundrySecondary` with identical names + versions, and switch SKUs to `GlobalStandard` (or `DataZoneStandard` where allowed) so quota is portable.

**File:** infra/modules/ai-services-deployments.bicep

```bicep
// Single-region projection — deployments only against primary Foundry
module openAiDeployments 'modules/ai-services-deployments.bicep' = {
  name: 'oai-deploys'
  params: {
    parentAccountName: aiFoundry.outputs.name
    deployments: openAiDeployments
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module openAiDeploymentsPrimary 'modules/ai-services-deployments.bicep' = {
  name: 'oai-deploys-${primaryLocation}'
  params: {
    parentAccountName: aiFoundryPrimary.outputs.name
    deployments: openAiDeployments  // shared catalog
  }
}
module openAiDeploymentsSecondary 'modules/ai-services-deployments.bicep' = {
  name: 'oai-deploys-${secondaryLocation}'
  params: {
    parentAccountName: aiFoundrySecondary.outputs.name
    deployments: openAiDeployments  // identical names + versions
  }
}
```

```python
# path: src/backend/common/config/app_config.py
from openai import AsyncAzureOpenAI

def get_openai_client(self) -> AsyncAzureOpenAI:
    endpoint = self.resolve_foundry_endpoint()  # P0-001
    return AsyncAzureOpenAI(
        azure_endpoint=endpoint,
        azure_ad_token_provider=self._token_provider,
        api_version=os.environ["AZURE_OPENAI_API_VERSION"],
    )
```

**Notes:** Cross-ref P0-001 (peer Foundry account) and P1-017 (env-driven endpoint resolution). Pre-validate quota with `az cognitiveservices usage list` per region before flipping deployments.

<span style="font-size: 14px;">**MSFT Reference:** [Azure AI services disaster recovery](https://learn.microsoft.com/azure/ai-services/disaster-recovery)</span>

---

#### P1-002: Azure AI Search 1×1 + public network, single-region

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** AI Search is provisioned at `replicaCount=1, partitionCount=1` with public network access in `{primaryRegion}` only. The single-region → active/active migration requires a peer Search service in `{secondaryRegion}`; today a single replica failure or zone incident takes RAG offline, and there is no peer service to satisfy grounded retrieval after cutover. Public network access also widens attack surface relative to the rest of the stack which is on Private Endpoints.

**What does this solve:** Provisions a symmetric Search service per region with replicas ≥ 3, partitions ≥ 2, Private Endpoint only, so RAG queries land on a local zone-redundant service in either region.

**Resiliency Impact:** A single replica failure or zonal incident takes grounded retrieval offline today, and cross-region failover cannot serve grounded results until a peer service and replicated indexes exist.

**Recommended Fix:** Provision a peer `Microsoft.Search/searchServices` in `{secondaryRegion}` via the same module with `replicaCount: 3` and `partitionCount: 2`, set `publicNetworkAccess: 'Disabled'`, add Private Endpoints with `privatelink.search.windows.net`, and drive index parity from a JSON catalog applied to both services post-deploy.

**File:** infra/main.bicep:1697-1751

```bicep
module search 'br/public:avm/res/search/search-service:0.x.y' = {
  name: 'srch'
  params: {
    name: 'srch-${solutionPrefix}'
    location: location
    sku: 'standard'
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module searchPrimary 'br/public:avm/res/search/search-service:0.x.y' = {
  name: 'srch-${primaryLocation}'
  params: {
    name: 'srch-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    sku: 'standard'
    replicaCount: 3
    partitionCount: 2
    publicNetworkAccess: 'Disabled'
    semanticSearch: 'standard'
  }
}
module searchSecondary 'br/public:avm/res/search/search-service:0.x.y' = {
  name: 'srch-${secondaryLocation}'
  params: {
    name: 'srch-${solutionPrefix}-${secondaryLocation}'
    location: secondaryLocation
    sku: 'standard'
    replicaCount: 3
    partitionCount: 2
    publicNetworkAccess: 'Disabled'
    semanticSearch: 'standard'
  }
}
```

**Notes:** Cross-ref P1-016 (replicas/partitions/public-access angle), P1-017 (endpoint resolution), and P0-021 (readiness contract). Run an index parity check after deploy: `count(documents)` matches between regions within tolerance.

<span style="font-size: 14px;">**MSFT Reference:** [AI Search reliability](https://learn.microsoft.com/azure/search/search-reliability)</span>

---

#### P1-003: Container Apps + Environment zone redundancy gated

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Container Apps Environment hosting `backend` and `mcp_server` is provisioned in `{primaryRegion}` with `zoneRedundant` left at the AVM default (false) and Container Apps in `revisionsMode='Single'`. The single-region → active/active topology requires a peer Environment in `{secondaryRegion}`; today a zone incident takes all replicas down at once and during regional failover there is no environment to host workloads at all.

**What does this solve:** Stands up zone-redundant Container Apps Environments in both regions with `revisionsMode=Multiple` for graceful drain, so each region can survive zonal events and the GLB can shift traffic between regions.

**Resiliency Impact:** Without `zoneRedundant=true` a single zone outage drops every replica simultaneously; without a peer Environment in `{secondaryRegion}` the active/active design has nowhere to run workloads on regional failover.

**Recommended Fix:** Set `zoneRedundant: true` on both Environments, ensure the delegated subnet meets `/27` minimum, set `revisionsMode: 'Multiple'` plus `minReplicas: 3` on every Container App, and provision a peer Environment bound to the `{secondaryRegion}` VNet.

**File:** infra/main.bicep:1143-1170

```bicep
module acaEnv 'br/public:avm/res/app/managed-environment:0.x.y' = {
  name: 'aca-env'
  params: {
    name: 'cae-${solutionPrefix}'
    location: location
    // zoneRedundant defaults to false
  }
}

resource backendApp 'Microsoft.App/containerApps@2024-03-01' = {
  properties: {
    configuration: { activeRevisionsMode: 'Single' }
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module acaEnvPrimary 'br/public:avm/res/app/managed-environment:0.x.y' = {
  name: 'aca-env-${primaryLocation}'
  params: {
    name: 'cae-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    zoneRedundant: true
    infrastructureSubnetResourceId: vnetPrimary.outputs.acaSubnetResourceId
  }
}

module backendApp 'br/public:avm/res/app/container-app:0.x.y' = {
  name: 'aca-backend-${primaryLocation}'
  params: {
    name: 'ca-backend-${solutionPrefix}'
    environmentResourceId: acaEnvPrimary.outputs.resourceId
    revisionsMode: 'Multiple'
    scaleSettings: { minReplicas: 3, maxReplicas: 10 }
  }
}
```

**Notes:** Cross-ref P0-004 (regional VNets) and P0-021 (readiness contract). Drain test: deploy a new revision at `weight=0`, ramp to 100 over 60s, confirm zero failed in-flight plans via Application Insights `requests`.

<span style="font-size: 14px;">**MSFT Reference:** [Container Apps availability zones](https://learn.microsoft.com/azure/container-apps/availability-zones)</span>

---

#### P1-004: App Service + Plan zone redundancy gated

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The frontend App Service plan uses `P1v3`-class without `zoneRedundant=true` and there is no peer plan in `{secondaryRegion}`. The single-region → active/active design needs a UI origin behind the GLB in both regions; today a zone outage takes the SPA origin offline and regional failover has no UI origin until a peer is provisioned. `healthCheckPath` is also unset, so App Service intra-plan load balancing does not exclude unhealthy instances.

**What does this solve:** Deploys a Premium V3 zone-redundant plan and Web App in each region with `healthCheckPath` wired to the SPA origin, eliminating zonal blast radius and enabling GLB-based regional failover.

**Resiliency Impact:** Without zone redundancy and a peer origin a routine zonal event takes the entire UI offline; without `healthCheckPath` the in-plan LB keeps routing to dead instances.

**Recommended Fix:** Set `sku: { name: 'P1v3', tier: 'PremiumV3' }`, `zoneRedundant: true`, and `skuCapacity: 3` on both regional plans; set `healthCheckPath: '/healthz/ready'` on each Web App; place both behind the GLB.

**File:** infra/main.bicep:1539-1573

```bicep
module webPlan 'br/public:avm/res/web/serverfarm:0.x.y' = {
  name: 'plan'
  params: {
    name: 'asp-${solutionPrefix}'
    location: location
    skuName: 'P1v3'
    // zoneRedundant defaults to false; capacity not pinned
  }
}

module webApp 'br/public:avm/res/web/site:0.x.y' = {
  params: {
    siteConfig: { minTlsVersion: '1.2' } // healthCheckPath unset
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module webPlanPrimary 'br/public:avm/res/web/serverfarm:0.x.y' = {
  name: 'plan-${primaryLocation}'
  params: {
    name: 'asp-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    skuName: 'P1v3'
    skuCapacity: 3
    zoneRedundant: true
  }
}
module webAppPrimary 'br/public:avm/res/web/site:0.x.y' = {
  name: 'web-${primaryLocation}'
  params: {
    name: 'app-${solutionPrefix}-${primaryLocation}'
    serverFarmResourceId: webPlanPrimary.outputs.resourceId
    siteConfig: {
      healthCheckPath: '/healthz/ready'
      minTlsVersion: '1.2'
    }
  }
}
```

**Notes:** Cross-ref P0-024 (GLB / Front Door fronting both origins), P0-021 (readiness contract), and P1-010 (Easy Auth symmetry). Mirror the plan + Web App for `{secondaryRegion}`.

<span style="font-size: 14px;">**MSFT Reference:** [Configure App Service reliability](https://learn.microsoft.com/azure/app-service/configure-reliability)</span>

---

#### P1-005: Container Registry no geo-replication

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The customer-owned ACR is single-region with no `replications` block. The single-region → active/active topology means that on a regional outage of the ACR home region, image pulls in `{secondaryRegion}` fail (DNS or 5xx) and Container Apps cannot scale or roll new revisions. Cross-region pulls from the surviving region also breach data-locality intent and add latency to cold-starts.

**What does this solve:** Promotes the registry to Premium with replications in both `{primaryRegion}` and `{secondaryRegion}`, regional login servers, and AcrPull RBAC for both regions' workload identities.

**Resiliency Impact:** A single ACR regional incident blocks pulls for every workload across both regions and prevents Container Apps from scaling or recovering during the very failover the design is meant to handle.

**Recommended Fix:** Set `acrSku: 'Premium'`, add `replications: [{ location: secondaryLocation }]` (the base account is the primary), enable `zoneRedundancy: 'Enabled'`, and grant `AcrPull` to both regions' UAMIs at the registry scope.

**File:** infra/main.bicep:140-160

```bicep
module acr 'br/public:avm/res/container-registry/registry:0.x.y' = {
  name: 'acr-${solutionPrefix}'
  params: {
    name: 'acr${solutionPrefix}'
    location: location
    acrSku: 'Standard' // no replications, no zone redundancy
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module acr 'br/public:avm/res/container-registry/registry:0.x.y' = {
  name: 'acr-${solutionPrefix}'
  params: {
    name: 'acr${solutionPrefix}'
    location: primaryLocation
    acrSku: 'Premium'
    zoneRedundancy: 'Enabled'
    replications: [
      { location: secondaryLocation, zoneRedundancy: 'Enabled' }
    ]
    roleAssignments: [
      { principalId: backendUami.outputs.principalId, roleDefinitionIdOrName: 'AcrPull' }
      { principalId: webUami.outputs.principalId,     roleDefinitionIdOrName: 'AcrPull' }
    ]
  }
}
```

**Notes:** Cross-ref P1-019 (regional login servers in image references) and P0-022 (mirror upstream registry into customer-owned ACR). Verify `az acr replication list -r <acr>` shows both replications in `Succeeded`.

<span style="font-size: 14px;">**MSFT Reference:** [ACR geo-replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication)</span>

---

#### P1-006: Storage Blob default replication (LRS)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Storage account hosting documents and indexed sources is created without an explicit `skuName`, and `enableRedundancy` is not threaded into the AVM call, so the account defaults to `Standard_LRS`. The single-region → active/active migration requires zone- and region-redundant storage; today a zone incident loses durability and a regional outage loses availability of every blob the RAG pipeline depends on.

**What does this solve:** Pins Storage to `Standard_GZRS` (or `Standard_RAGZRS` for RA reads), threads `enableRedundancy` through the AVM, disables public access, and adds Private Endpoints per region.

**Resiliency Impact:** LRS-class durability cannot survive a zonal or regional event; without RA-GZRS the secondary endpoint is unreadable during failover and RAG read paths break.

**Recommended Fix:** Add a `storageSkuName` parameter (default `Standard_GZRS`, allowed `[Standard_GZRS, Standard_RAGZRS, Standard_ZRS]`), pass it plus `enableRedundancy` into the AVM, and configure the SDK with `secondary_hostname` so reads can fall back to `<acct>-secondary.blob.core.windows.net`.

**File:** infra/main.bicep:1597-1612

```bicep
module storage 'br/public:avm/res/storage/storage-account:0.x.y' = {
  name: 'st-${solutionPrefix}'
  params: {
    name: 'st${solutionPrefix}'
    location: location
    // skuName omitted => defaults to Standard_LRS
    // enableRedundancy not threaded
    publicNetworkAccess: 'Enabled'
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module storage 'br/public:avm/res/storage/storage-account:0.x.y' = {
  name: 'st-${solutionPrefix}'
  params: {
    name: 'st${solutionPrefix}'
    location: primaryLocation
    skuName: storageSkuName            // 'Standard_GZRS' or 'Standard_RAGZRS'
    enableRedundancy: enableRedundancy
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
  }
}
```

```python
# path: src/backend/common/storage/blob_client.py
from azure.storage.blob.aio import BlobServiceClient
from azure.storage.blob import LocationMode

client = BlobServiceClient(
    account_url=app_config.storage_primary_url,
    credential=app_config.credential,
    secondary_hostname=app_config.storage_secondary_url,
)
container = client.get_container_client(name)
container._config.location_mode = LocationMode.SECONDARY
```

**Notes:** Cross-ref P1-020 (the threading bug itself) and P1-017 (env-driven endpoint resolution). Validate `az storage account show` returns `sku.name=Standard_GZRS` (or RAGZRS) post-deploy.

<span style="font-size: 14px;">**MSFT Reference:** [Storage redundancy](https://learn.microsoft.com/azure/storage/common/storage-redundancy)</span>

---

#### P1-007: Entra ID + UAMI cross-region readiness

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** A single `Microsoft.ManagedIdentity/userAssignedIdentities` is created in `{primaryRegion}` and attached to every workload and data plane (Cosmos, Foundry, OpenAI, Search, Storage, ACR), with RBAC granted on resources that live only in the primary region. Moving from single-region to active/active means data-plane RBAC will not be propagated for the same UAMI on peer resources in `{secondaryRegion}` unless mirrored, and a primary-region IMDS metadata propagation issue can stall token issuance from secondary replicas.

**What does this solve:** Establishes per-region UAMIs with mirrored RBAC on every regional resource so token issuance and authorization succeed independently in both regions.

**Resiliency Impact:** Without per-region UAMI + mirrored RBAC, secondary-region replicas may fail `DefaultAzureCredential` token acquisition or be denied at the data plane during failover. With it, each region authenticates using a local identity bound to local resources.

**Recommended Fix:** Create `uamiPrimary` and `uamiSecondary`, attach the local UAMI to each region's workloads, and grant both UAMIs the required role on every regional data-plane resource using deterministic role-assignment GUIDs. Read `tenant_id` and `client_id` from env only.

**File:** infra/main.bicep:384-388

```bicep
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${solutionPrefix}'
  location: location
}
// RBAC granted only to primary-region resources
```

**Fix:**

```bicep
module uamiPrimary 'br/public:avm/res/managed-identity/user-assigned-identity:0.x.y' = {
  name: 'uami-${primaryLocation}'
  params: { name: 'id-${solutionPrefix}-${primaryLocation}', location: primaryLocation }
}
module uamiSecondary 'br/public:avm/res/managed-identity/user-assigned-identity:0.x.y' = {
  name: 'uami-${secondaryLocation}'
  params: { name: 'id-${solutionPrefix}-${secondaryLocation}', location: secondaryLocation }
}
resource cosmosRoleBoth 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in [
  uamiPrimary.outputs.principalId, uamiSecondary.outputs.principalId
]: {
  name: guid(cosmos.outputs.resourceId, principalId, 'CosmosDataContributor')
  scope: cosmosScope
  properties: {
    principalId: principalId
    roleDefinitionId: cosmosDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
}]
```

**Notes:** Build `DefaultAzureCredential(managed_identity_client_id=os.environ["AZURE_CLIENT_ID"])` in `app_config` so each replica binds deterministically to its local UAMI's client id. Cross-ref P1-042, P1-044.

<span style="font-size: 14px;">**MSFT Reference:** [Managed Identities for Azure Resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)</span>

---

#### P1-008: Bastion zone-redundancy not configured

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Bastion is provisioned without `availabilityZones`, so a single-zone fault in `{primaryRegion}` removes the only operator entry path. The single-region → active/active design needs a peer Bastion in `{secondaryRegion}` plus zone redundancy in each region; during a zonal incident or regional failover triage today the team has no jumpbox path until a peer Bastion is built.

**What does this solve:** Deploys a zone-redundant Bastion Standard SKU in each region so operator triage survives a single-zone fault and a peer path exists for regional failover.

**Resiliency Impact:** Loss of operator access during a zonal event blocks the very break-glass procedures needed to drive regional failover.

**Recommended Fix:** Use `skuName: 'Standard'` with `availabilityZones: ['1','2','3']` and provision a peer Bastion in `{secondaryRegion}` with the same configuration; document the operator runbook for cross-region access via `<bastion-secondary>.bastion.azure.com`.

**File:** infra/main.bicep:421-433

```bicep
resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: 'bas-${solutionPrefix}'
  location: location
  sku: { name: 'Basic' }
  // no availabilityZones property
}
```

**Fix:**

```bicep
// path: infra/main.bicep
module bastionPrimary 'br/public:avm/res/network/bastion-host:0.x.y' = {
  name: 'bas-${primaryLocation}'
  params: {
    name: 'bas-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    skuName: 'Standard'
    availabilityZones: [ '1', '2', '3' ]
    virtualNetworkResourceId: vnetPrimary.outputs.resourceId
  }
}
```

**Notes:** Cross-ref P1-009 (jumpbox VMSS) and P1-015 (combined operator-path zone gap). Bastion Basic SKU does not support zones — Standard is required.

<span style="font-size: 14px;">**MSFT Reference:** [Bastion configuration settings](https://learn.microsoft.com/azure/bastion/configuration-settings)</span>

---

#### P1-009: Windows Jumpbox VM zone-1 pinned + PPG

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Windows jumpbox VM is pinned to `zones: [1]` inside a proximity placement group (PPG). The single-region → active/active design needs zone-spanning operator hosts in each region; today a zone-1 incident in `{primaryRegion}` removes the only operator host, the PPG forbids relocating the VM across zones without redeploy, and there is no peer jumpbox in `{secondaryRegion}`.

**What does this solve:** Replaces the single-VM + PPG construct with a VM Scale Set (uniform orchestration) spanning zones 1, 2, and 3 in each region, eliminating the single-zone operator host.

**Resiliency Impact:** Zonal events take the only operator host down with no automatic recovery, blocking failover triage; regional events leave the team with no jumpbox at all.

**Recommended Fix:** Replace `Microsoft.Compute/virtualMachines` with `Microsoft.Compute/virtualMachineScaleSets` (`zones: ['1','2','3']`, `capacity: 1`), drop the PPG resource and any `proximityPlacementGroup` reference, and provision a peer VMSS in `{secondaryRegion}` with `adminPassword` from Key Vault.

**File:** infra/main.bicep:609-660

```bicep
resource jumpboxVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-jump-${solutionPrefix}'
  location: location
  zones: [ '1' ]
  properties: {
    proximityPlacementGroup: { id: ppg.id }
    osProfile: {
      adminUsername: 'azureuser'
      adminPassword: 'literalPassword'  // P0-023
    }
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep
resource jumpboxVmssPrimary 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'vmss-jump-${primaryLocation}'
  location: primaryLocation
  zones: [ '1', '2', '3' ]
  sku: { name: 'Standard_D2s_v5', capacity: 1, tier: 'Standard' }
  properties: {
    orchestrationMode: 'Uniform'
    virtualMachineProfile: {
      osProfile: {
        adminUsername: 'azureuser'
        adminPassword: kv.getSecret('jumpboxAdminPassword')   // P0-023
      }
    }
  }
}
```

**Notes:** Cross-ref P1-008 (Bastion zones), P1-015 (combined operator path), and P0-023 (`adminPassword` from Key Vault). Validate with Chaos Studio: stop one zone, VMSS keeps `capacity=1` by reallocating into a healthy zone within minutes.

<span style="font-size: 14px;">**MSFT Reference:** [Reliability redundancy guidance](https://learn.microsoft.com/azure/well-architected/reliability/redundancy)</span>

---

#### P1-010: App Service Easy Auth single-tenant config

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** App Service Easy Auth is configured for a single-tenant app registration tied to the primary deployment, and the platform settings do not set `requireAuthentication: true` or `unauthenticatedClientAction: RedirectToLoginPage`. Moving from single-region to active/active means deploying the SPA in `{secondaryRegion}` without symmetric Easy Auth config breaks login from the failover region, and the platform-level guard may remain in audit mode in either region.

**What does this solve:** Enforces symmetric Easy Auth across both regional Web Apps using one app registration with two redirect URIs and the GLB hostname.

**Resiliency Impact:** Without symmetric platform-enforced Easy Auth, unauthenticated requests can hit the SPA origin after failover. With enforcement plus a single app registration, login behavior is identical in both regions and via the GLB.

**Recommended Fix:** Set `globalValidation.requireAuthentication: true` and `unauthenticatedClientAction: 'RedirectToLoginPage'`, use one app registration with redirect URIs for both Web Apps and the GLB hostname, parameterize `tenantId`, and reference the client secret only via `clientSecretSettingName` backed by Key Vault (or use federated credentials).

**File:** infra/modules/web-sites.config.bicep:10-11

```bicep
resource authConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  name: '${siteName}/authsettingsV2'
  properties: {
    platform: { enabled: true }
    // requireAuthentication not set; single-tenant registration
    identityProviders: { azureActiveDirectory: { enabled: true } }
  }
}
```

**Fix:**

```bicep
resource authConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  name: '${siteName}/authsettingsV2'
  properties: {
    platform: { enabled: true }
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: aadClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          openIdIssuer: 'https://login.microsoftonline.com/${tenantId}/v2.0'
        }
        validation: { allowedAudiences: [ 'api://${aadClientId}' ] }
      }
    }
  }
}
```

**Notes:** Configure `excludedPaths: ['/healthz/*']` so GLB probes bypass auth. Cross-ref P0-026, P1-046.

<span style="font-size: 14px;">**MSFT Reference:** [OpenID Connect on the Microsoft Identity Platform](https://learn.microsoft.com/azure/active-directory/develop/v2-protocols-oidc)</span>

---

#### P1-011: MCP JWT/JWKS single-region issuer config

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** MCP JWT/JWKS validation is wired to a single issuer / single JWKS endpoint resolved from env, and on JWKS fetch failure the validator falls back to a permissive mode or caches stale keys indefinitely. Moving from single-region to active/active means the MCP in `{secondaryRegion}` cannot validate tokens during a primary-region issuer outage if the URL is a regional alias, and the fail-open path silently accepts unsigned tokens. Cross-ref P0-028.

**What does this solve:** Pins MCP to the global Entra ID issuer / JWKS URL, caches keys with a refresh path, and fails closed on JWKS failure.

**Resiliency Impact:** Both regional MCPs validate tokens identically using the global Entra ID endpoint. Without it, a regional issuer hiccup either rejects all tokens or accepts forged ones.

**Recommended Fix:** Pin `JWT_ISSUER='https://login.microsoftonline.com/{tenantId}/v2.0'` and the corresponding JWKS URI, cache JWKS for 1 hour with a force-refresh on `kid` miss, validate `aud`/`iss`/`exp`/`nbf`, reject `none`/symmetric algorithms, and fail closed on JWKS unavailability.

**File:** src/mcp_server/mcp_server.py:31-52

```python
def validate_token(token: str) -> dict:
    try:
        keys = httpx.get(os.environ["JWKS_URI"]).json()
        return decode(token, keys, algorithms=["RS256"])
    except Exception:
        return {}   # fail-open — accept on JWKS failure
```

**Fix:**

```python
from jwt import PyJWKClient, decode

_jwks = PyJWKClient(os.environ["JWKS_URI"], cache_keys=True, lifespan=3600)

def validate_token(token: str) -> dict:
    try:
        signing_key = _jwks.get_signing_key_from_jwt(token).key
    except Exception as e:
        raise PermissionError("jwks_unavailable") from e   # fail closed
    return decode(
        token,
        signing_key,
        algorithms=["RS256"],
        audience=os.environ["JWT_AUDIENCE"],
        issuer=os.environ["JWT_ISSUER"],
        options={"require": ["exp", "iat", "iss", "aud"]},
    )
```

**Notes:** Surface validator state in MCP `/healthz/ready` (cross-ref P1-040). Cross-ref P0-028, P1-038.

<span style="font-size: 14px;">**MSFT Reference:** [Microsoft Identity Platform Access Tokens](https://learn.microsoft.com/entra/identity-platform/access-tokens)</span>

---

#### P1-012: External `biabcontainerreg.azurecr.io` shared registry

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Customer-deployed images are pulled from an external Microsoft-owned registry the customer does not own. Moving from single-region to active/active does not fix this: both `{primaryRegion}` and `{secondaryRegion}` remain coupled to a single registry the customer cannot guarantee for tag immutability, signing, or replication, so an upstream ACR incident blocks pulls in both regions simultaneously. Cross-ref P0-022 for the full mitigation.

**What does this solve:** Removes the cross-region single point of failure introduced by an externally-owned registry by mirroring to a customer-owned geo-replicated ACR with immutable, signed, digest-pinned images.

**Resiliency Impact:** During an ACR or registry incident in either region, the customer-owned mirror still serves pulls from the local replica. Without the mirror, both regions cold-start fail the same way at the same time, defeating the active/active design.

**Recommended Fix:** Mirror the upstream images into the customer-owned geo-replicated ACR (cross-ref P0-022), enable tag immutability, sign with Notary v2 / Cosign, and pin Container App images to `{loginServer}/<repo>@sha256:<digest>`.

**File:** infra/main.bicep:140-160

```bicep
var backendImage = 'biabcontainerreg.azurecr.io/backend:latest'
// ... Container App image set to external Microsoft-owned ACR with floating tag
```

**Fix:**

```bicep
// pin to digest in customer-owned geo-replicated ACR (cross-ref P0-022)
var backendImage = '${acr.outputs.loginServer}/backend@sha256:${backendDigest}'
```

**Notes:** Set `tagImmutability: 'Enabled'` on the customer ACR. Verify Notation signatures at admission via Container Apps registry image verification or Defender for Containers policy. Cross-ref P0-022, P1-005, P1-019, P1-038.

<span style="font-size: 14px;">**MSFT Reference:** [Container Registry Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)</span>

---

#### P1-013: Hard-coded Cosmos region-pair map

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** A literal `region → pair` table inside `infra/main.bicep` selects the Cosmos secondary region instead of accepting an explicit operator parameter. The current single-region → active/active migration relies on this map to derive the peer location, so any deployment to a region outside the encoded set silently degrades to a single-region account or selects an incorrect pair without raising an error. This couples the IaC to a specific Azure pairing snapshot that changes over time and blocks symmetric two-region topology.

**What does this solve:** Lets operators choose `{primaryRegion}` and `{secondaryRegion}` explicitly, removing the silent map-based fallback that breaks active/active topology.

**Resiliency Impact:** Without explicit parameters the secondary region resolved by the map can drift from compliance-approved geography or fall back to a single-region account, eliminating the multi-region writes that every downstream P0/P1 fix depends on.

**Recommended Fix:** Replace the `regionPairMap` with `param primaryLocation string` and `param secondaryLocation string`, both `@allowed[]`-validated to an operator-curated list of paired regions, and pass `secondaryLocation` directly into the Cosmos `locations[]` array.

**File:** infra/main.bicep:191-204

```bicep
// Hard-coded pair map drives Cosmos secondary region selection
var regionPairMap = {
  eastus: 'westus'
  eastus2: 'centralus'
  westeurope: 'northeurope'
  // ... limited encoded set
}
var cosmosSecondary = regionPairMap[location]
```

**Fix:**

```bicep
// path: infra/main.bicep
@allowed([
  'eastus', 'eastus2', 'westus2', 'westus3'
  'westeurope', 'northeurope'
  // ... operator-curated list
])
param primaryLocation string

@allowed([
  'eastus', 'eastus2', 'westus2', 'westus3'
  'westeurope', 'northeurope'
])
param secondaryLocation string

// No pair map. Locations are explicit inputs.
var cosmosLocations = [
  { locationName: primaryLocation,   failoverPriority: 0, isZoneRedundant: enableRedundancy }
  { locationName: secondaryLocation, failoverPriority: 1, isZoneRedundant: enableRedundancy }
]
```

**Notes:** Cross-ref P0-005 for the parameter shape and P0-003 / P0-013 for Cosmos consumption. Add a Bicep `assert` that `primaryLocation != secondaryLocation` and same-geography enforcement where data residency requires it. Update `infra/main.parameters.json` to surface `secondaryLocation`.

<span style="font-size: 14px;">**MSFT Reference:** [Bicep parameters](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameters)</span>

---

#### P1-014: Hard-coded Log Analytics replica region pairs

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Log Analytics workspace replication is wired through a hard-coded paired-region table identical in shape to the Cosmos map (P1-013). The single-region → active/active topology requires the LA replica to land in the same operator-chosen `{secondaryRegion}` that hosts every other peer; outside the encoded pair set the replica points to the wrong region or silently no-ops. This breaks the cross-region observability that the failover itself depends on for triage.

**What does this solve:** Lets operators steer the LA replica to the same `{secondaryRegion}` chosen for the data plane, removing data-residency drift and silent observability gaps.

**Resiliency Impact:** During a regional incident telemetry from the surviving region may not be ingested or queryable, blinding the on-call team during the very failover the workspace is meant to instrument.

**Recommended Fix:** Add `param logAnalyticsReplicaLocation string = secondaryLocation` (constrained by `@allowed[]`) and pass it into the workspace replica resource so LA replication aligns with the explicit secondary parameter from P0-005 / P1-013.

**File:** infra/main.bicep

```bicep
// Replica region resolved via the same hard-coded pair table
var laReplicaLocation = regionPairMap[location]

resource laReplica 'Microsoft.OperationalInsights/workspaces/replicas@2025-02-01' = {
  parent: logAnalytics
  name: laReplicaLocation
  location: laReplicaLocation
}
```

**Fix:**

```bicep
// path: infra/main.bicep
param logAnalyticsReplicaLocation string = secondaryLocation

resource laReplica 'Microsoft.OperationalInsights/workspaces/replicas@2025-02-01' = {
  parent: logAnalytics
  name: logAnalyticsReplicaLocation
  location: logAnalyticsReplicaLocation
}
```

**Notes:** Cross-ref P0-005 and P1-013 for the shared parameter. Validate ingestion from both regions via `Heartbeat | summarize count() by _ResourceId, ResourceLocation` after deploy.

<span style="font-size: 14px;">**MSFT Reference:** [Log Analytics availability zones and replication](https://learn.microsoft.com/azure/azure-monitor/logs/availability-zones)</span>

---

#### P1-015: Jumpbox + PPG zone-1 / Bastion no zones

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The operator path combines a jumpbox pinned to `zones: [1]` inside a proximity placement group (P1-009) with a Bastion provisioned without `availabilityZones` (P1-008). In the single-region topology a single zone-1 incident in `{primaryRegion}` removes the entire operator entry path simultaneously, and the active/active design has no peer Bastion or jumpbox in `{secondaryRegion}` to fall back to during regional failover triage.

**What does this solve:** Eliminates the single-zone operator dependency and provides a peer operator path in `{secondaryRegion}` so triage continues during zonal or regional incidents.

**Resiliency Impact:** With both Bastion and jumpbox zone-bound to the same fault domain, a routine zonal event removes all operator access at once, blocking the very break-glass procedures the failover requires.

**Recommended Fix:** Apply P1-008 (Bastion Standard SKU with `availabilityZones: ['1','2','3']` per region) and P1-009 (replace the VM + PPG with a zone-spanning VMSS per region) together as a single operator-readiness change.

**File:** infra/main.bicep:424

```bicep
// Bastion: no zones, single SKU; Jumpbox VM pinned zone-1 in PPG
resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  // no availabilityZones property
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  zones: [ '1' ]
  properties: {
    proximityPlacementGroup: { id: ppg.id }
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep — apply P1-008 and P1-009 as one change, both regions
module bastionPrimary 'br/public:avm/res/network/bastion-host:0.x.y' = {
  name: 'bas-${primaryLocation}'
  params: {
    name: 'bas-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    skuName: 'Standard'
    availabilityZones: [ '1', '2', '3' ]
    virtualNetworkResourceId: vnetPrimary.outputs.resourceId
  }
}

resource jumpboxVmssPrimary 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'vmss-jump-${primaryLocation}'
  location: primaryLocation
  zones: [ '1', '2', '3' ]
  sku: { name: 'Standard_D2s_v5', capacity: 1, tier: 'Standard' }
  properties: { orchestrationMode: 'Uniform' }
}
```

**Notes:** Cross-ref P1-008, P1-009, and P0-023 (jumpbox `adminPassword` from Key Vault). Validate with combined zone-1 chaos: operator must still RDP through Bastion to a jumpbox instance in zone 2 or 3.

<span style="font-size: 14px;">**MSFT Reference:** [Bastion configuration settings](https://learn.microsoft.com/azure/bastion/configuration-settings)</span>

---

#### P1-016: AI Search 1×1 + public network

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Same root cause as P1-002 expressed from the redundancy + exposure angle: AI Search is sized at `replicaCount=1, partitionCount=1` with public network access enabled in `{primaryRegion}` only. The single-region → active/active topology cannot rely on a single replica or public exposure; today a single replica failure or zone incident takes RAG offline, and public access broadens attack surface.

**What does this solve:** Resizes Search to replicas ≥ 3 / partitions ≥ 2, disables public network access, adds a Private Endpoint per region, and gates `semanticSearch` behind a flag enabled only after redundancy is in place.

**Resiliency Impact:** A single replica or zonal failure today removes grounded retrieval entirely, and the public surface adds an exposure axis the rest of the stack avoided.

**Recommended Fix:** Apply the P1-002 implementation in full; specifically gate `semanticSearch: 'standard'` behind a deploy parameter so it is enabled only after replica/partition resize completes.

**File:** infra/main.bicep:1697-1751

```bicep
module search 'br/public:avm/res/search/search-service:0.x.y' = {
  params: {
    sku: 'standard'
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'Enabled'
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep — same module as P1-002, both regions
module searchPrimary 'br/public:avm/res/search/search-service:0.x.y' = {
  name: 'srch-${primaryLocation}'
  params: {
    name: 'srch-${solutionPrefix}-${primaryLocation}'
    location: primaryLocation
    sku: 'standard'
    replicaCount: 3
    partitionCount: 2
    publicNetworkAccess: 'Disabled'
    semanticSearch: enableSemanticRanker ? 'standard' : 'disabled'
  }
}
```

**Notes:** Cross-ref P1-002 (multi-region provisioning), P1-017 (endpoint resolution), and P0-021 (readiness contract). Verify public-internet `curl` to the Search FQDN returns DNS NXDOMAIN or 403 post-deploy.

<span style="font-size: 14px;">**MSFT Reference:** [AI Search reliability](https://learn.microsoft.com/azure/search/search-reliability)</span>

---

#### P1-017: Backend env hardcodes single-region URLs

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Container Apps env vars on the backend bake in single-region FQDNs for Cosmos, Foundry, Search, and Storage. In the single-region → active/active migration these literals defeat regional locality: a backend replica running in `{secondaryRegion}` calls primary-region endpoints over the internet (or fails entirely if those endpoints are down), so every other peer-resource fix is undone by the env wiring.

**What does this solve:** Replaces per-region FQDN literals with primary/secondary endpoint pairs plus an `APP_REGION` selector resolved at runtime, so each replica binds to its local dependencies.

**Resiliency Impact:** Without runtime resolution every cross-region request inflates latency and re-introduces the primary region as a hard dependency, breaking active/active even after Foundry, Search, and Storage peers exist.

**Recommended Fix:** Emit `*_PRIMARY` / `*_SECONDARY` env pairs plus `APP_REGION` from Bicep, and refactor `app_config.AppConfig` to expose `resolve_*_endpoint()` methods that every client builder calls.

**File:** infra/main.bicep:1359-1387

```bicep
// Single-region FQDNs baked into backend env
env: [
  { name: 'AZURE_AI_PROJECT_ENDPOINT', value: aiFoundry.outputs.endpoint }
  { name: 'AZURE_SEARCH_ENDPOINT',     value: search.outputs.endpoint }
  { name: 'COSMOS_ENDPOINT',           value: cosmos.outputs.primaryEndpoint }
  { name: 'STORAGE_ACCOUNT_URL',       value: storage.outputs.primaryBlobEndpoint }
]
```

**Fix:**

```bicep
// path: infra/main.bicep
resource backendApp '...' = {
  properties: {
    template: {
      containers: [{
        env: [
          { name: 'APP_REGION',                          value: primaryLocation }
          { name: 'AZURE_AI_PROJECT_ENDPOINT_PRIMARY',   value: aiFoundryPrimary.outputs.endpoint }
          { name: 'AZURE_AI_PROJECT_ENDPOINT_SECONDARY', value: aiFoundrySecondary.outputs.endpoint }
          { name: 'AZURE_SEARCH_ENDPOINT_PRIMARY',       value: searchPrimary.outputs.endpoint }
          { name: 'AZURE_SEARCH_ENDPOINT_SECONDARY',     value: searchSecondary.outputs.endpoint }
          { name: 'COSMOS_ACCOUNT_ENDPOINT',             value: cosmos.outputs.endpoint }
          { name: 'STORAGE_ACCOUNT_NAME',                value: storage.outputs.name }
        ]
      }]
    }
  }
}
```

**Notes:** Mirror the env block for `mcp_server`. Cross-ref P0-001 (Foundry pair), P1-002 / P1-016 (Search pair), P1-006 (Storage redundancy), and P1-018 (Cosmos `preferred_locations`). Add `resolve_search_endpoint()` and peers in `src/backend/common/config/app_config.py` keyed on `APP_REGION`.

<span style="font-size: 14px;">**MSFT Reference:** [Reliability redundancy guidance](https://learn.microsoft.com/azure/well-architected/reliability/redundancy)</span>

---

#### P1-018: CosmosClient has no `preferred_locations`

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `CosmosClient` is constructed in `app_config` without `preferred_locations`, so the SDK selects a region from account metadata in arbitrary order. In an active/active topology, reads from a `{secondaryRegion}` replica may be routed to the `{primaryRegion}` write endpoint over the internet, inflating latency under steady state and breaking clean failover when the local endpoint degrades.

**What does this solve:** Pins each replica to read from its local region first and roll over deterministically to the peer.

**Resiliency Impact:** Without local-first preferences the SDK cannot exploit the multi-region account; cross-region traffic during normal operation hides the failover signal and produces tail latency that the GLB cannot detect.

**Recommended Fix:** Resolve `app_region` and `peer_region` from environment in `app_config`, pass them as `preferred_locations`, set `consistency_level='Session'`, and keep `enable_endpoint_discovery=True` so the SDK reacts to Cosmos auto-failover events.

**File:** src/backend/common/config/app_config.py:222-242

```python
self._cosmos = CosmosClient(
    url=os.environ["COSMOS_ACCOUNT_ENDPOINT"],
    credential=self.credential,
)
```

**Fix:**

```python
from azure.cosmos.aio import CosmosClient

self._cosmos = CosmosClient(
    url=os.environ["COSMOS_ACCOUNT_ENDPOINT"],
    credential=self.credential,
    preferred_locations=[self.app_region, self.peer_region],  # local-first
    consistency_level="Session",
    enable_endpoint_discovery=True,
)
```

**Notes:** Cross-ref P0-014 (retry policy), P1-024 (singleton wrapper), P2-010 (Session consistency). Validate via `client.client_connection.ReadEndpoints` showing the local region first from each replica.

<span style="font-size: 14px;">**MSFT Reference:** [Distribute data globally with Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)</span>

---

#### P1-019: Single ACR hostname for all workloads

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Backend, MCP, and Web App image references all point at the same single-region ACR hostname, so any ACR regional incident blocks pulls across all workloads in both `{primaryRegion}` and `{secondaryRegion}`. The single-region → active/active migration requires a parameterized registry hostname sourced from the geo-replicated ACR (P1-005) so each region pulls from its local replica.

**What does this solve:** Promotes the registry hostname to a Bicep variable bound to `acr.outputs.loginServer` and pins every workload `image` to a digest, so cutovers can rotate the registry without source edits.

**Resiliency Impact:** A single registry hostname concentrates failure modes — one ACR regional incident blocks every workload pull in every region, defeating the geo-replication.

**Recommended Fix:** Promote `registryLoginServer` to a Bicep variable from the geo-replicated ACR, pin every workload `image` to `'${registryLoginServer}/<repo>@sha256:<digest>'`, and surface the digest as a deployment parameter for reproducibility.

**File:** infra/main.bicep:140-160

```bicep
// All workloads reference one literal hostname
var backendImage = 'acr${solutionPrefix}.azurecr.io/backend:latest'
var mcpImage     = 'acr${solutionPrefix}.azurecr.io/mcp:latest'
var webImage     = 'acr${solutionPrefix}.azurecr.io/web:latest'
```

**Fix:**

```bicep
// path: infra/main.bicep
var registryLoginServer = acr.outputs.loginServer  // geo-replicated, P1-005
param backendDigest string
param mcpDigest string
param webDigest string

var backendImage = '${registryLoginServer}/backend@sha256:${backendDigest}'
var mcpImage     = '${registryLoginServer}/mcp@sha256:${mcpDigest}'
var webImage     = '${registryLoginServer}/web@sha256:${webDigest}'
```

**Notes:** Cross-ref P1-005 (ACR geo-replication), P0-022 (mirror upstream registry), and P0-021 (readiness depends on successful pull). Validate `az containerapp show --query 'properties.template.containers[].image'` returns digests, not floating tags, in both regions.

<span style="font-size: 14px;">**MSFT Reference:** [ACR geo-replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication)</span>

---

#### P1-020: Storage AVM no `skuName` / `enableRedundancy` not threaded

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Storage AVM call omits `skuName` (defaults to LRS) and never receives the `enableRedundancy` flag from `main.bicep`. This is the threading bug behind P1-006: even after the `storageSkuName` parameter exists in `main.bicep`, the AVM call still hardcodes / defaults the SKU, so the single-region → active/active migration cannot get zone- or region-redundant storage without fixing the wiring.

**What does this solve:** Threads `skuName` and `enableRedundancy` from `main.bicep` parameters into the storage AVM call so the deploy actually applies the redundancy choice.

**Resiliency Impact:** Without the threading the Storage AVM silently keeps LRS-class durability regardless of operator intent, leaving the data plane unable to survive a zonal or regional incident.

**Recommended Fix:** Apply P1-006 (parameter + threading) and verify the AVM module call binds both `skuName: storageSkuName` and `enableRedundancy: enableRedundancy` to `main.bicep` parameters rather than AVM defaults.

**File:** infra/main.bicep:1597-1612

```bicep
module storage 'br/public:avm/res/storage/storage-account:0.x.y' = {
  name: 'st-${solutionPrefix}'
  params: {
    name: 'st${solutionPrefix}'
    location: location
    // skuName not set; enableRedundancy not threaded
  }
}
```

**Fix:**

```bicep
// path: infra/main.bicep — same site as P1-006
module storage 'br/public:avm/res/storage/storage-account:0.x.y' = {
  name: 'st-${solutionPrefix}'
  params: {
    name: 'st${solutionPrefix}'
    location: primaryLocation
    skuName: storageSkuName
    enableRedundancy: enableRedundancy
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
  }
}
```

**Notes:** Cross-ref P1-006 (full SKU + redundancy guidance) and P0-021 (readiness contract). Verify with Bicep `what-if` that the SKU is pinned by the deploy, not inherited from AVM defaults.

<span style="font-size: 14px;">**MSFT Reference:** [Storage redundancy](https://learn.microsoft.com/azure/storage/common/storage-redundancy)</span>

---

#### P1-021: `upsert_item` no `_etag` / optimistic concurrency

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Cosmos wrapper calls `upsert_item` without `_etag` checks. The current single-region account masks this, but once the active/active topology enables multi-region writes (P1-023), concurrent updates from `{primaryRegion}` and `{secondaryRegion}` silently overwrite each other under last-writer-wins, corrupting plan and step state across the regional boundary.

**What does this solve:** Establishes deterministic conflict detection for concurrent writes from both regions.

**Resiliency Impact:** Without etag discipline, a multi-region write account (P1-023) is unsafe to enable; lost updates become invisible data corruption rather than actionable errors.

**Recommended Fix:** Read with `read_item` to capture `_etag`, mutate, then `replace_item(if_match_etag=...)`. On 412 Precondition Failed, re-read and retry with bounded attempts; on exhaustion raise a typed `ConcurrentUpdateError` and emit a `cosmos.etag.conflict` metric.

**File:** src/backend/common/database/cosmosdb.py:110-176

```python
async def update_plan(self, plan_id: str, partition_key: str, doc: dict) -> dict:
    return await self._container.upsert_item(body=doc)
```

**Fix:**

```python
from azure.cosmos.exceptions import CosmosAccessConditionFailedError

async def update_plan(self, plan_id: str, partition_key: str, mutate) -> dict:
    for attempt in range(3):
        doc = await self._container.read_item(item=plan_id, partition_key=partition_key)
        mutate(doc)
        try:
            return await self._container.replace_item(
                item=plan_id,
                body=doc,
                if_match_etag=doc["_etag"],
            )
        except CosmosAccessConditionFailedError:
            # 412 — someone else won the race; re-read and retry
            continue
    raise ConcurrentUpdateError(plan_id)
```

**Notes:** Pre-condition for safely enabling P1-023. Sustained `ConcurrentUpdateError` rate above threshold should mark the region degraded so GLB de-weights writes.

<span style="font-size: 14px;">**MSFT Reference:** [Optimistic concurrency control in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/optimistic-concurrency-control)</span>

---

#### P1-022: `except Exception` swallows 429 / 503

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Cosmos wrapper catches bare `Exception` and logs, so throttling (429) and service unavailability (503) are indistinguishable from genuine bugs. In a single-region setup this hides degradation; in active/active the retry policy from P0-014/P0-015 cannot fire because the typed exception is consumed at the wrong layer, and `/healthz/ready` cannot reflect dependency health to the GLB.

**What does this solve:** Surfaces typed Cosmos errors so retry, dead-letter, and readiness machinery can act on them.

**Resiliency Impact:** Swallowed 429/503 prevents region-aware retries and prevents the GLB from de-weighting a degraded region; users see hard failures while the platform thinks everything is healthy.

**Recommended Fix:** Replace `except Exception` with `except CosmosHttpResponseError`, switch on `status_code` (429 honors `x-ms-retry-after-ms`; 503/408 backoff; 412 raises `ConcurrentUpdateError`; default re-raises), and emit per-status metrics.

**File:** src/backend/common/database/cosmosdb.py:110-176

```python
try:
    return await fn(*args, **kwargs)
except Exception as e:
    logger.exception("cosmos call failed: %s", e)
    return None
```

**Fix:**

```python
from azure.cosmos.exceptions import CosmosHttpResponseError
import asyncio, random

async def safe_call(self, fn, *args, **kwargs):
    for attempt in range(5):
        try:
            return await fn(*args, **kwargs)
        except CosmosHttpResponseError as e:
            if e.status_code == 429:
                retry_ms = int(e.headers.get("x-ms-retry-after-ms", "100"))
                await asyncio.sleep(retry_ms / 1000)
                continue
            if e.status_code in (503, 408):
                await asyncio.sleep(min(2 ** attempt, 8) + random.random())
                continue
            raise            # 4xx other than 429 — propagate, do not swallow
    raise CosmosDependencyDegraded()
```

**Notes:** Cross-ref P0-014, P0-015, P0-021. Sustained `CosmosDependencyDegraded` for >10s on the local region must surface in `/healthz/ready` so GLB de-weights the region.

<span style="font-size: 14px;">**MSFT Reference:** [Troubleshoot Azure Cosmos DB request rate too large (429)](https://learn.microsoft.com/azure/cosmos-db/nosql/troubleshoot-request-rate-too-large)</span>

---

#### P1-023: Multi-region writes never enabled

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Cosmos resource in IaC never sets `enableMultipleWriteLocations: true` or `enableAutomaticFailover: true`. Even after migrating off serverless (P0-013) and adding `{secondaryRegion}` to `locations[]` (P0-003), the secondary cannot accept writes — active/active collapses to active/passive for Cosmos, forcing every write to round-trip back to `{primaryRegion}`.

**What does this solve:** Makes Cosmos a true active/active data tier so each region writes locally.

**Resiliency Impact:** Without multi-region writes, regional cutover requires a manual failover-priority swap and writes fail in `{secondaryRegion}` until that completes; the data tier becomes the bottleneck of the entire active/active topology.

**Recommended Fix:** Set `automaticFailoverEnabled: true` and `enableMultipleWriteLocations: true` on the account, define an explicit `conflictResolutionPolicy` per container, and gate the change behind P0-013, P0-003, P1-021 (etag), and P1-018 (preferred_locations).

**File:** infra/main.bicep:1110-1136

```bicep
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}'
  params: {
    name: 'cosmos-${solutionPrefix}'
    locations: [
      { locationName: primaryLocation, failoverPriority: 0 }
    ]
  }
}
```

**Fix:**

```bicep
module cosmos 'br/public:avm/res/document-db/database-account:0.x.y' = {
  name: 'cosmos-${solutionPrefix}'
  params: {
    name: 'cosmos-${solutionPrefix}'
    locations: [
      { locationName: primaryLocation,   failoverPriority: 0, isZoneRedundant: enableRedundancy }
      { locationName: secondaryLocation, failoverPriority: 1, isZoneRedundant: enableRedundancy }
    ]
    automaticFailoverEnabled: true
    enableMultipleWriteLocations: true
    sqlDatabases: [
      {
        name: 'macae'
        containers: [
          {
            name: 'plans'
            partitionKeyPaths: [ '/sessionId' ]
            conflictResolutionPolicy: {
              mode: 'LastWriterWins'
              conflictResolutionPath: '/_ts'
            }
          }
        ]
      }
    ]
  }
}
```

**Notes:** Pre-conditions: P0-013 (off serverless), P0-003 (locations), P1-021 (etag), P1-018 (preferred_locations). Validate dual-write convergence and run a `failover-priority-change` drill.

<span style="font-size: 14px;">**MSFT Reference:** [Conflict resolution policies in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/conflict-resolution-policies)</span>

---

#### P1-024: Singleton CosmosClient no preferred regions

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `app_config` constructs a single sync + async `CosmosClient` pair at startup with no `preferred_locations` and caches them for the process lifetime. In active/active, every read from a `{secondaryRegion}` replica may be routed by the SDK to the `{primaryRegion}` write endpoint, breaking locality during normal operation and producing slow cross-region calls during failover.

**What does this solve:** Wraps P1-018 in a region-aware singleton so there is exactly one constructor path and the cached clients honor regional preferences.

**Resiliency Impact:** Without a single region-aware factory, ad-hoc `CosmosClient(...)` calls elsewhere bypass the preferences and recreate the locality gap; failover behavior becomes inconsistent across modules.

**Recommended Fix:** Add `app_region`/`peer_region` properties on `AppConfig` from env, pass `preferred_locations` to both sync and async clients in `_build_cosmos_clients()`, and route every consumer through `app_config.get_cosmos_client()`.

**File:** src/backend/common/config/app_config.py:222-242

```python
def _build_cosmos_clients(self) -> None:
    self._cosmos_async = AsyncCosmosClient(
        url=os.environ["COSMOS_ACCOUNT_ENDPOINT"],
        credential=self.credential,
    )
    self._cosmos_sync = SyncCosmosClient(
        url=os.environ["COSMOS_ACCOUNT_ENDPOINT"],
        credential=self.credential,
    )
```

**Fix:**

```python
from azure.cosmos.aio import CosmosClient as AsyncCosmosClient
from azure.cosmos import CosmosClient as SyncCosmosClient

def _build_cosmos_clients(self) -> None:
    preferred = [self.app_region, self.peer_region]
    common = dict(
        url=os.environ["COSMOS_ACCOUNT_ENDPOINT"],
        credential=self.credential,
        preferred_locations=preferred,
        consistency_level="Session",
        enable_endpoint_discovery=True,
    )
    self._cosmos_async = AsyncCosmosClient(**common)
    self._cosmos_sync  = SyncCosmosClient(**common)
```

**Notes:** Cross-ref P1-018 (SDK flag), P1-026 (health-driven invalidation), P1-017 (region env). Pair with P1-026 so the singleton is replaced — not patched — when the resolved endpoint becomes unhealthy.

<span style="font-size: 14px;">**MSFT Reference:** [Distribute data globally with Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)</span>

---

#### P1-025: Container Apps revisionsMode Single, no graceful drain

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Each Container App is deployed with `activeRevisionsMode: 'Single'` and no termination grace or SIGTERM drain hook. As the application moves from single-region to active/active, every revision swap (deploy, scale-in, image bump) hard-cuts in-flight WebSocket sessions and HTTP requests in either region, surfacing as user-visible 502s and lost agent stream output during cutovers.

**What does this solve:** Enables blue/green ramp and graceful drain so deploys and scale events do not drop in-flight traffic in either region.

**Resiliency Impact:** Without a drain path, GLB sees momentary 5xx blips on every deploy in either region and may de-weight a healthy region. Multi-revision mode plus a SIGTERM handler that flips `/healthz/ready` to 503 lets GLB shift traffic before old revisions disappear.

**Recommended Fix:** Switch to `revisionsMode: 'Multiple'` with weighted traffic during deploys, set `terminationGracePeriodSeconds: 60`, and add a FastAPI SIGTERM handler that flips readiness to 503 and closes WebSockets cleanly.

**File:** infra/main.bicep:1143-1170

```bicep
resource backendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-backend-${solutionPrefix}'
  properties: {
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: { external: true, targetPort: 8000 }
    }
    template: {
      containers: [ /* ... */ ]
    }
  }
}
```

**Fix:**

```bicep
module backendApp 'br/public:avm/res/app/container-app:0.x.y' = {
  name: 'aca-backend-${primaryLocation}'
  params: {
    name: 'ca-backend-${solutionPrefix}'
    environmentResourceId: acaEnvPrimary.outputs.resourceId
    revisionsMode: 'Multiple'
    template: {
      terminationGracePeriodSeconds: 60
      containers: [ /* ... */ ]
    }
  }
}
```

**Notes:** Pair with a SIGTERM handler in `src/backend/v4/api/lifespan.py` that sets `app.state.ready = False` and a revision-ramp script that uses `az containerapp ingress traffic set` to ramp 0→100. Cross-ref P1-027 (WebSocket retry) and P0-018 (reconnection) so drained sockets reconnect to the new revision or peer region.

<span style="font-size: 14px;">**MSFT Reference:** [Container Apps Revisions](https://learn.microsoft.com/azure/container-apps/revisions)</span>

---

#### P1-026: DatabaseFactory / app_config no health-driven invalidation

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `DatabaseFactory` and `app_config` cache Cosmos, Foundry, and Search clients indefinitely. In a single-region world this is fine; in active/active, after a transient regional incident the cached clients keep pointing at a degraded endpoint (stale endpoint discovery, expired DNS, broken PE) and never recover until the replica restarts — so post-failover the region looks "up" while every dependency call fails.

**What does this solve:** Lets the process recover without a restart by invalidating dependency clients after sustained probe failures.

**Resiliency Impact:** Without invalidation, recovery from a partial-region incident depends on revision restarts; the GLB sees healthy origins that silently serve errors.

**Recommended Fix:** Wrap each cached client in a `HealthGatedClient` with N-consecutive-failure invalidation and a 5s background probe (cheap per-dependency call with 2s timeout); the next caller rebuilds the client. Surface state in `/healthz`.

**File:** src/backend/common/database/database_factory.py

```python
class DatabaseFactory:
    def __init__(self, config):
        self._cosmos = config.get_cosmos_client()  # cached forever

    def get(self):
        return self._cosmos
```

**Fix:**

```python
from dataclasses import dataclass
from typing import Awaitable, Callable, Generic, TypeVar
T = TypeVar("T")

@dataclass
class HealthGatedClient(Generic[T]):
    build: Callable[[], T]
    probe: Callable[[T], Awaitable[bool]]
    threshold: int = 3
    _client: T | None = None
    _failures: int = 0

    async def get(self) -> T:
        if self._client is None:
            self._client = self.build()
        return self._client

    async def probe_once(self) -> None:
        try:
            client = await self.get()
            ok = await self.probe(client)
            self._failures = 0 if ok else self._failures + 1
        except Exception:
            self._failures += 1
        if self._failures >= self.threshold:
            self.invalidate()

    def invalidate(self) -> None:
        self._client = None
        self._failures = 0
```

**Notes:** Cross-ref P0-021. `/healthz` exposes `cosmos.consecutive_failures` and `cosmos.last_invalidated_at`; sustained `cosmos.healthy=false` for >10s flips `/healthz/ready` to 503.

<span style="font-size: 14px;">**MSFT Reference:** [Transient fault handling](https://learn.microsoft.com/azure/well-architected/reliability/transient-faults)</span>

---

#### P1-027: WebSocket emit best-effort no retry / ack

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Outbound WebSocket `send_text` / `send_json` calls are wrapped in a bare `try/except` that logs and continues. As the platform moves from single-region to active/active, a transient socket blip or a revision-drain (P1-025) silently drops live agent output, and the client UI has no way to know a token batch was lost. There is no acknowledgement protocol, no dead-letter, and no metric.

**What does this solve:** Guarantees that streaming agent output survives transient socket blips, replica swaps, and GLB-driven region cutovers.

**Resiliency Impact:** During GLB or replica events the user-visible blast radius is reduced from "lost tokens" to "brief pause then replay." Without it, every cutover during failover testing is observable to end users.

**Recommended Fix:** Wrap `send_json` in a bounded retry helper with jittered backoff, dead-letter unsent payloads to a Storage Queue keyed by `(plan_id, session_id, sequence)`, and require client `ack` for state-changing notifications.

**File:** src/backend/v4/api/connection_config.py

```python
async def send_event(ws: WebSocket, payload: dict) -> None:
    try:
        await ws.send_json(payload)
    except Exception as e:
        logger.warning("ws send failed: %s", e)
        # best-effort — payload is dropped
```

**Fix:**

```python
import asyncio, random
from fastapi import WebSocket, WebSocketDisconnect

async def safe_send_json(ws: WebSocket, payload: dict, *, attempts: int = 3) -> bool:
    for attempt in range(attempts):
        try:
            await ws.send_json(payload)
            return True
        except (WebSocketDisconnect, RuntimeError):
            await asyncio.sleep(min(0.1 * 2 ** attempt, 1.0) + random.random() * 0.1)
    await deadletter_queue.send_message(payload)   # replay on reconnect
    return False
```

**Notes:** Emit `ws.send.retry`, `ws.send.deadletter`, `ws.ack.timeout` metrics. Sustained `ws.send.deadletter` rate above threshold should mark the region degraded so GLB de-weights it. Cross-ref P0-018, P1-025, P1-028.

<span style="font-size: 14px;">**MSFT Reference:** [Azure Web PubSub](https://learn.microsoft.com/azure/azure-web-pubsub/overview)</span>

---

#### P1-028: Partial agent_stream_buffers dropped

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Streaming agent output is held in process-local `agent_stream_buffers` and only persisted to Cosmos at terminal events. Moving from single-region to active/active makes this worse: a replica swap, SIGTERM (P1-025), socket disconnect (P1-027), or cross-region cutover loses every partial token already shown to the user, and the conversation cannot be reconstructed from durable storage in `{secondaryRegion}` on reconnect.

**What does this solve:** Persists streaming agent tokens incrementally so reconnects in either region replay missed chunks instead of dropping them.

**Resiliency Impact:** Without incremental persistence, any drain or cross-region failover is user-visible as truncated agent output. With per-chunk Cosmos writes keyed by `(plan_id, step_id, seq)`, a reconnect resumes from the last seen sequence in either region.

**Recommended Fix:** Append every streamed chunk to a Cosmos container `agent_stream_events` with a monotonic `seq` per `(plan_id, step_id)`, partition key `/plan_id`, TTL 24h. On reconnect, replay `WHERE seq > @lastSeen ORDER BY seq` then resume the live stream.

**File:** src/backend/v4/callbacks/response_handlers.py

```python
async def on_agent_chunk(plan_id: str, step_id: str, chunk: str) -> None:
    # process-local buffer only; persisted on terminal event
    agent_stream_buffers[(plan_id, step_id)].append(chunk)
    await ws.send_json({"plan_id": plan_id, "step_id": step_id, "chunk": chunk})
```

**Fix:**

```python
async def on_agent_chunk(plan_id: str, step_id: str, chunk: str) -> None:
    seq = next_sequence(plan_id, step_id)
    await stream_container.create_item({
        "id": f"{plan_id}:{step_id}:{seq:08d}",
        "plan_id": plan_id,
        "step_id": step_id,
        "seq": seq,
        "chunk": chunk,
        "ts": time.time(),
        "ttl": 86400,
    })
    await safe_send_json(ws, {"plan_id": plan_id, "step_id": step_id, "seq": seq, "chunk": chunk})
```

**Notes:** Pair with the pub/sub backplane (cross-ref P0-018) so a peer region can replay the buffer. `/healthz/ready` should include a write probe to `agent_stream_events` (cross-ref P0-021).

<span style="font-size: 14px;">**MSFT Reference:** [Health Endpoint Monitoring](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P1-029: Cosmos DNS / Private Endpoint failure (F3)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Cosmos Private Endpoint and Private DNS zone live only in `{primaryRegion}`. In active/active, a PE outage, Private DNS misconfiguration, or recursive resolver failure pins traffic on the broken path and never lets the SDK roll over to `{secondaryRegion}`. The SDK's default retries do not cover DNS-resolution exceptions, so the client surfaces `ServiceRequestError` immediately.

**What does this solve:** Provides a regional PE for each replica so name resolution and the SDK both have a local path.

**Resiliency Impact:** Without a peer PE, the data tier cannot follow application traffic to `{secondaryRegion}` even when Cosmos itself is healthy there; DNS becomes the single point of failure.

**Recommended Fix:** Add a peer PE in `{secondaryRegion}` linked to the same Cosmos account, link both VNets to `privatelink.documents.azure.com`, retry on `ServiceRequestError`/`gaierror` with bounded backoff, and assert PE-backed resolution from `/healthz/ready`.

**File:** src/backend/common/database/cosmosdb.py

```python
async def call(fn, *args, **kwargs):
    return await fn(*args, **kwargs)
```

**Fix:**

```python
import socket, ipaddress, asyncio, random
from azure.core.exceptions import ServiceRequestError

async def resilient_call(fn, *args, **kwargs):
    for attempt in range(3):
        try:
            return await fn(*args, **kwargs)
        except (ServiceRequestError, socket.gaierror):
            await asyncio.sleep(min(2 ** attempt, 8) + random.random())
    raise CosmosNetworkDegraded()

def assert_pe_resolution(host: str, allowed_cidrs: list[str]) -> bool:
    ip = socket.gethostbyname(host)
    return any(ipaddress.ip_address(ip) in ipaddress.ip_network(c) for c in allowed_cidrs)
```

**Notes:** Cross-ref P0-030 (Private DNS), P0-021. Mirror the PE in IaC at `infra/main.bicep:1088-1101`. Validate by NSG-blocking the primary PE NIC and observing `/healthz/ready` flip to 503 within 10s.

<span style="font-size: 14px;">**MSFT Reference:** [Retry pattern](https://learn.microsoft.com/azure/architecture/patterns/retry)</span>

---

#### P1-030: OpenAI 429 retry exhausted (F4)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** OpenAI 429s are retried in a tight loop with limited backoff and without honoring the server-side `Retry-After` header. In a single-region deployment this surfaces as a 5xx; in active/active, sustained throttling in `{primaryRegion}` exhausts the retry budget within seconds and never rolls over to a peer deployment in `{secondaryRegion}` (P1-001).

**What does this solve:** Honors the throttling contract and enables peer-region fallback so transient TPM bursts do not become user-visible failures.

**Resiliency Impact:** Without peer fallback, a regional model quota incident kills plan generation globally even though the peer region has headroom.

**Recommended Fix:** Catch `openai.RateLimitError` explicitly, sleep `max(retry_after, jittered_backoff)` capped at 60s, fall back to the peer-region deployment via `app_config.get_openai_client(peer=True)`, and on peer exhaustion return a structured deferred response.

**File:** src/backend/v4/orchestration/human_approval_manager.py:114-141

```python
for _ in range(3):
    try:
        return await client.chat.completions.create(**kwargs)
    except RateLimitError:
        await asyncio.sleep(1)
raise
```

**Fix:**

```python
import asyncio, random
from openai import RateLimitError

async def chat_with_throttle_handling(client_local, client_peer, **kwargs):
    for attempt in range(5):
        try:
            return await client_local.chat.completions.create(**kwargs)
        except RateLimitError as e:
            retry_after = float(e.response.headers.get("retry-after", "1"))
            await asyncio.sleep(max(retry_after, min(2 ** attempt, 60)) + random.random())
    try:
        return await client_peer.chat.completions.create(**kwargs)
    except RateLimitError:
        raise DeferredModelResponse()
```

**Notes:** Cross-ref P1-001 (peer Foundry deployment), P0-021. Sustained `openai.429.deferred` above threshold for 60s marks the region degraded.

<span style="font-size: 14px;">**MSFT Reference:** [Business continuity with Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/how-to/business-continuity-multivariate)</span>

---

#### P1-031: AI Search unavailable / index missing (F7)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** AI Search outages and missing-index errors propagate as unhandled `HttpResponseError` from `azure.search.documents`, which the orchestrator translates to user-facing 5xx. In a single-region setup any Search incident blocks every grounded answer; in active/active the RAG path has no graceful degradation even though the model could still respond with reduced quality.

**What does this solve:** Lets the orchestrator continue with a model-only answer when Search is unavailable instead of failing the whole request.

**Resiliency Impact:** Without graceful degradation, Search becomes a hard dependency for every answer and prevents `{secondaryRegion}` from serving while a regional Search index rebuilds.

**Recommended Fix:** Convert `ResourceNotFoundError` and `HttpResponseError(503/504)` to a typed `SearchUnavailable`, return `documents=[], degraded=True`, and have the orchestrator add a "no document context" system message instead of aborting. Add a Search readiness probe.

**File:** src/backend/v4/rag/search_client.py

```python
async def search(self, query: str):
    docs = await self._client.search(query, top=5)
    return [d async for d in docs]
```

**Fix:**

```python
from azure.core.exceptions import ResourceNotFoundError, HttpResponseError

async def search_with_fallback(self, query: str) -> SearchResult:
    try:
        docs = await self._client.search(query, top=5)
        return SearchResult(documents=[d async for d in docs], degraded=False)
    except ResourceNotFoundError:
        metrics.increment("search.missing_index")
        return SearchResult(documents=[], degraded=True, reason="index_missing")
    except HttpResponseError as e:
        if e.status_code in (503, 504):
            metrics.increment("search.degraded")
            return SearchResult(documents=[], degraded=True, reason="service_unavailable")
        raise
```

**Notes:** Cross-ref P1-002 (peer Search), P0-021. `/healthz/ready` returns 503 only when both local and peer Search are unavailable.

<span style="font-size: 14px;">**MSFT Reference:** [Bulkhead pattern](https://learn.microsoft.com/azure/architecture/patterns/bulkhead)</span>

---

#### P1-032: Storage Blob unavailable (F8)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** A Storage Blob outage cascades into the RAG ingestion pipeline and any backend path that streams attachments. Today an upload fails with `ServiceRequestError` and the user sees a 5xx; there is no deferral, so work is lost rather than retried when Storage recovers — a fragile posture inside a single region and unworkable in active/active.

**What does this solve:** Defers failed uploads to a durable queue so transient Storage incidents become bounded delays, not lost work.

**Resiliency Impact:** Without deferred ingestion, regional Storage incidents propagate into immediate user errors and break the active/active premise that either region can absorb traffic.

**Recommended Fix:** On `ServiceRequestError` or `HttpResponseError(503)` from blob upload, push a deferred-ingest envelope to a Storage Queue; a worker drains with bounded retry and dead-letters poisoned messages. Add a canary-blob HEAD readiness probe.

**File:** src/backend/common/storage/blob_client.py

```python
async def upload(blob_name: str, data: bytes) -> None:
    await container.upload_blob(name=blob_name, data=data, overwrite=True)
```

**Fix:**

```python
from azure.core.exceptions import ServiceRequestError, HttpResponseError
from azure.storage.queue.aio import QueueClient

async def upload_with_defer(blob_name: str, data: bytes, queue: QueueClient) -> None:
    try:
        await container.upload_blob(name=blob_name, data=data, overwrite=True)
    except (ServiceRequestError, HttpResponseError) as e:
        if isinstance(e, HttpResponseError) and e.status_code not in (503, 504):
            raise
        await queue.send_message({"blob_name": blob_name, "len": len(data)})
        metrics.increment("storage.upload.deferred")
```

**Notes:** Cross-ref P1-006 (GZRS), P0-021. `/healthz/ready` returns 503 only when both local and `-secondary` blob HEADs fail.

<span style="font-size: 14px;">**MSFT Reference:** [Throttling pattern](https://learn.microsoft.com/azure/architecture/patterns/throttling)</span>

---

#### P1-033: ACR pull failure blocks cold-start (F9)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Backend, MCP, and Web App Container App revisions all pull from a single-region ACR. A regional ACR incident or transient registry 5xx during cold-start blocks every replica from coming up in either region — the GLB sees no healthy origin, and there is no pre-pulled fallback image. Active/active requires both regions to have an independent path to images.

**What does this solve:** Provides a passive backup ACR per region and orders multiple `registries[]` entries so cold-start has a deterministic fallback.

**Resiliency Impact:** Without a backup registry, image pull becomes a regional single point of failure that defeats the entire active/active investment.

**Recommended Fix:** Apply P1-005 (geo-replicated Premium ACR) as primary, provision a passive `Premium` ACR in `{secondaryRegion}` filled by `az acr import` per release, list both `server` entries on each Container App, and pre-pull digests on cold-start.

**File:** infra/main.bicep:140-160

```bicep
resource backendApp '...' = {
  properties: {
    configuration: {
      registries: [
        { server: acr.outputs.loginServer, identity: uami.outputs.resourceId }
      ]
    }
  }
}
```

**Fix:**

```bicep
module acrSecondary 'br/public:avm/res/container-registry/registry:0.x.y' = {
  name: 'acr-backup-${secondaryLocation}'
  params: {
    name: 'acrbackup${solutionPrefix}'
    location: secondaryLocation
    acrSku: 'Premium'
    adminUserEnabled: false
    roleAssignments: [
      { principalId: uamiPrimary.outputs.principalId,   roleDefinitionIdOrName: 'AcrPull' }
      { principalId: uamiSecondary.outputs.principalId, roleDefinitionIdOrName: 'AcrPull' }
    ]
  }
}

resource backendApp '...' = {
  properties: {
    configuration: {
      registries: [
        { server: acr.outputs.loginServer,          identity: uamiPrimary.outputs.resourceId }
        { server: acrSecondary.outputs.loginServer, identity: uamiPrimary.outputs.resourceId }
      ]
    }
  }
}
```

**Notes:** Cross-ref P1-005, P1-019, P0-022. Validate by blocking egress to the primary ACR and confirming new revisions still pull within 60s.

<span style="font-size: 14px;">**MSFT Reference:** [Circuit breaker pattern](https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker)</span>

---

#### P1-034: Entra ID token failure (F11)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `app_config.get_access_token` calls `DefaultAzureCredential.get_token` directly with no retry, no caching, and no surfacing in `/healthz`. A transient Entra ID glitch (`ClientAuthenticationError`, network blip to `login.microsoftonline.com`) becomes a hard 5xx for users, and `/healthz/ready` cannot distinguish auth-broken regions from data-broken ones in the active/active topology.

**What does this solve:** Adds a token cache and bounded retry so transient auth blips do not become user-visible 5xx.

**Resiliency Impact:** Without token caching and retry, every region is one Entra ID hiccup away from a global outage; the GLB cannot route around an auth incident because both regions look equally degraded.

**Recommended Fix:** Wrap `credential.get_token(scope)` with bounded `tenacity` retry on transient `ClientAuthenticationError`, cache `AccessToken` per scope, refresh at `expires_on - 300s`, open a circuit breaker after 3 consecutive failures, and surface state in `/healthz`.

**File:** src/backend/common/config/app_config.py:170-176

```python
def get_access_token(self, scope: str) -> str:
    return self.credential.get_token(scope).token
```

**Fix:**

```python
import time, asyncio
from azure.core.exceptions import ClientAuthenticationError
from azure.core.credentials import AccessToken
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type

class TokenManager:
    def __init__(self, credential):
        self.credential = credential
        self._cache: dict[str, AccessToken] = {}
        self._lock = asyncio.Lock()

    @retry(
        stop=stop_after_attempt(4),
        wait=wait_random_exponential(min=0.5, max=8),
        retry=retry_if_exception_type(ClientAuthenticationError),
    )
    async def _fetch(self, scope: str) -> AccessToken:
        return await self.credential.get_token(scope)

    async def get(self, scope: str) -> str:
        tok = self._cache.get(scope)
        if tok and tok.expires_on - time.time() > 300:
            return tok.token
        async with self._lock:
            tok = await self._fetch(scope)
            self._cache[scope] = tok
            return tok.token
```

**Notes:** Cross-ref P1-042 (explicit `tenant_id`), P0-021. Token cache must be in-memory only (no disk persistence).

<span style="font-size: 14px;">**MSFT Reference:** [Transient fault handling](https://learn.microsoft.com/azure/well-architected/reliability/transient-faults)</span>

---

#### P1-035: Web App proxy timeout (F17)

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The Python frontend proxies API calls to the backend Container App with a fixed-low `httpx` default timeout (~5s) and no retry on transient 5xx. In a single-region deployment this clips long requests; during active/active regional cutover or a peer-region cold-start, normal warm-up exceeds 5s and produces user-visible 504s at the SPA even though the backend recovers within the GLB probe window.

**What does this solve:** Tunes the proxy timeout budget and adds idempotent retries so cutover warm-up does not surface as user-visible failures.

**Resiliency Impact:** Without a tuned client, the SPA undermines the GLB's recovery window and the user perceives every failover as a hard outage.

**Recommended Fix:** Configure a shared `httpx.AsyncClient` with explicit `connect/read/write/pool` timeouts, retry only `GET`/`HEAD` on `502/503/504`/`ConnectError` with bounded attempts, and return a structured 503 body with the region and correlation id on exhaustion.

**File:** src/App/frontend_server.py

```python
import httpx
_client = httpx.AsyncClient()  # default timeout ~5s, no retry

async def _proxy_get(url: str, headers: dict) -> httpx.Response:
    return await _client.get(url, headers=headers)
```

**Fix:**

```python
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

_client = httpx.AsyncClient(
    timeout=httpx.Timeout(connect=5.0, read=30.0, write=10.0, pool=5.0),
    limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
)

@retry(
    stop=stop_after_attempt(2),
    wait=wait_exponential(multiplier=0.2, max=2.0),
    retry=retry_if_exception_type((httpx.ConnectError, httpx.ReadTimeout)),
)
async def _proxy_get(url: str, headers: dict) -> httpx.Response:
    r = await _client.get(url, headers=headers)
    if r.status_code in (502, 503, 504):
        raise httpx.ReadTimeout("upstream_5xx", request=r.request)
    return r
```

**Notes:** Cross-ref P0-021. The Web App's `/healthz/ready` should probe the local backend `/healthz/ready` over the same client with a 2s timeout.

<span style="font-size: 14px;">**MSFT Reference:** [Retry pattern](https://learn.microsoft.com/azure/architecture/patterns/retry)</span>

---

#### P1-036: AVM Bicep modules cross-repo dependency

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `infra/main.bicep` consumes Azure Verified Modules from `br/public:` without strict version pinning in several places. In the single-region → active/active rollout the two regions are typically deployed at different times; an upstream module change between deployments drifts the secondary region from the primary, breaking the symmetric topology that every other P1 fix depends on.

**What does this solve:** Pins every AVM reference to an exact released version and mirrors critical modules to a private Bicep registry so both regions resolve identical IaC.

**Resiliency Impact:** Asymmetric IaC between regions silently invalidates failover assumptions (different SKUs, missing properties, divergent network rules) and can leave the secondary region unable to serve traffic that worked in the primary.

**Recommended Fix:** Replace floating `0.x.y` versions with exact pins, mirror critical AVMs to `br:<acr>.azurecr.io/bicep/modules/...`, and switch consumers to the private alias defined in `bicepconfig.json`.

**File:** infra/main.bicep

```bicep
// Floating / unpinned AVM references
module cosmos 'br/public:avm/res/document-db/database-account:0.9.2' = { /* ... */ }
module aca    'br/public:avm/res/app/managed-environment:0.x.y'      = { /* ... */ }
module web    'br/public:avm/res/web/site:0.x.y'                     = { /* ... */ }
```

**Fix:**

```bicep
// path: infra/main.bicep — exact pins, mirrored to private registry
module cosmos 'br/private:avm/res/document-db/database-account:0.9.2' = {
  // upgraded 2026-04-15 — bump quarterly
}
module aca    'br/private:avm/res/app/managed-environment:0.11.0' = { /* ... */ }
module web    'br/private:avm/res/web/site:0.13.1'                = { /* ... */ }
```

```yaml
# path: bicepconfig.json (excerpt)
moduleAliases:
  br:
    private:
      registry: acr${solutionPrefix}.azurecr.io
      modulePath: bicep/modules
```

**Notes:** Stand up the private registry inside the customer-owned ACR (cross-ref P1-005 / P1-019). Add a CI gate that runs `az deployment sub what-if` against both `{primaryRegion}` and `{secondaryRegion}` and fails on drift before any AVM bump.

<span style="font-size: 14px;">**MSFT Reference:** [Reliability principles](https://learn.microsoft.com/azure/well-architected/reliability/principles)</span>

---

#### P1-037: `agent_framework` SDK pre-release pins

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `pyproject.toml` pins `agent_framework` (and related Azure AI packages) to pre-release versions. Pre-release wheels can be republished or yanked, so two image builds days apart can ship different runtime semantics. As the application moves from single-region to active/active, the `{secondaryRegion}` image rebuilt later may behave subtly differently from `{primaryRegion}`, defeating "build once, deploy both regions."

**What does this solve:** Locks runtime semantics so identical image artifacts deploy to both regions with reproducible behavior.

**Resiliency Impact:** Identical pinned, hash-locked images in both regions remove a class of "looks-up-but-misbehaves" failures from cross-region cutover. Without it, post-failover bug reports cannot be traced to a deterministic build.

**Recommended Fix:** Switch every pre-release pin to an exact version, generate `requirements.lock` with `pip-compile --generate-hashes`, install with `--require-hashes`, mirror locked wheels to a private feed, and build the image once.

**File:** src/backend/pyproject.toml

```text
[project]
dependencies = [
    "agent_framework>=1.0.0rc1",
    "azure-cosmos>=4.7.0",
    "azure-identity>=1.17.0",
]
```

**Fix:**

```text
[project]
dependencies = [
    "agent_framework==1.0.0rc3",
    "azure-cosmos==4.7.0",
    "azure-identity==1.17.1",
    "azure-search-documents==11.5.1",
]
```

**Notes:** Pair with a Dockerfile that sets `PIP_INDEX_URL` to the private feed and runs `pip install --require-hashes -r requirements.lock`. Track upstream stable through a controlled bump PR. Cross-ref P1-019.

<span style="font-size: 14px;">**MSFT Reference:** [Container Registry Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)</span>

---

#### P1-038: MCP shared image single-FQDN

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The MCP Container App image and endpoint resolve through a single FQDN tied to one region (cross-ref P0-022 / P1-019). During the move from single-region to active/active, MCP cannot cold-start in `{secondaryRegion}` if the upstream ACR is impaired, and the backend cannot fail over to a peer MCP because `app_config` does not know there is one.

**What does this solve:** Deploys MCP per region with an `app_config` resolver that picks the local MCP endpoint, and a peer fallback when local fails.

**Resiliency Impact:** With a regional MCP per region, an ACR or networking incident is bounded to the affected region. Without it, both regions go dark on a single registry FQDN failure.

**Recommended Fix:** Mirror the MCP image into the geo-replicated customer ACR, deploy MCP in both regions with the same digest, expose `MCP_ENDPOINT_PRIMARY` / `MCP_ENDPOINT_SECONDARY` env, and resolve the local URL with a `mcp.fallback` metric on peer use.

**File:** infra/main.bicep:140-160

```bicep
// single MCP Container App in primary region pulling from external ACR
resource mcp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-mcp-${solutionPrefix}'
  properties: {
    template: {
      containers: [ { image: 'biabcontainerreg.azurecr.io/mcp:latest' } ]
    }
  }
}
```

**Fix:**

```bicep
module mcpPrimary 'br/public:avm/res/app/container-app:0.x.y' = {
  name: 'aca-mcp-${primaryLocation}'
  params: {
    name: 'ca-mcp-${solutionPrefix}-${primaryLocation}'
    environmentResourceId: acaEnvPrimary.outputs.resourceId
    template: { containers: [ { image: mcpImage } ] }
  }
}
module mcpSecondary 'br/public:avm/res/app/container-app:0.x.y' = {
  name: 'aca-mcp-${secondaryLocation}'
  params: {
    name: 'ca-mcp-${solutionPrefix}-${secondaryLocation}'
    environmentResourceId: acaEnvSecondary.outputs.resourceId
    template: { containers: [ { image: mcpImage } ] }
  }
}
```

**Notes:** Add `app_config.resolve_mcp_endpoint(peer=False)` returning the local URL based on `APP_REGION`; on local failure, return the peer URL with `mcp.fallback` metric. Front both origins with the GLB. Cross-ref P0-022, P1-011, P1-017, P1-040.

<span style="font-size: 14px;">**MSFT Reference:** [Container Apps Revisions](https://learn.microsoft.com/azure/container-apps/revisions)</span>

---

#### P1-039: Foundry agent metadata seed coupling

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Agent definitions in `data/agent_teams/*.json` are seeded into the Foundry Project at deploy time by an operator-run script. Moving from single-region to active/active introduces drift risk: if the seed step is skipped during the secondary-region deploy, or customer-authored teams are added via the UI to one region only, agent metadata diverges across regions and the same plan produces different agents in `{primaryRegion}` vs `{secondaryRegion}`.

**What does this solve:** Guarantees that both regional Foundry Projects converge on the same seeded and customer-authored agent metadata.

**Resiliency Impact:** Without convergent metadata, post-failover plans behave differently from primary-region plans. With idempotent reseed plus a Cosmos-backed snapshot of customer teams, both regions stay in lockstep.

**Recommended Fix:** Convert seeding to idempotent upserts keyed by `team_id`, run reseed against both regional Foundry Projects in the same CI job, snapshot customer-authored teams to Cosmos + blob, and add a daily drift check.

**File:** data/agent_teams/

```python
# scripts/reseed_agent_teams.py — current
async def reseed():
    proj = AIProjectClient(endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"], credential=cred)
    for path in glob.glob("data/agent_teams/*.json"):
        team = json.loads(open(path).read())
        await proj.agents.create(body=team)   # not idempotent; single endpoint
```

**Fix:**

```python
import json, os, glob
from azure.ai.projects.aio import AIProjectClient
from azure.identity.aio import DefaultAzureCredential

async def reseed(endpoint: str) -> None:
    cred = DefaultAzureCredential()
    async with AIProjectClient(endpoint=endpoint, credential=cred) as proj:
        for path in glob.glob("data/agent_teams/*.json"):
            team = json.loads(open(path, encoding="utf-8").read())
            await proj.agents.create_or_update(agent_id=team["team_id"], body=team)

if __name__ == "__main__":
    import asyncio
    asyncio.run(reseed(os.environ["AZURE_AI_PROJECT_ENDPOINT_PRIMARY"]))
    asyncio.run(reseed(os.environ["AZURE_AI_PROJECT_ENDPOINT_SECONDARY"]))
```

**Notes:** Add a CI drift check that diffs `team_ids` between regions daily. Snapshot customer-authored teams nightly to blob with UAMI auth (no SAS). Cross-ref P1-007, P1-044.

<span style="font-size: 14px;">**MSFT Reference:** [Health Endpoint Monitoring](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P1-040: Web App `/health` static literal; MCP HEALTHCHECK unregistered

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The frontend `/health` returns the literal string `"OK"` regardless of dependency state, and the MCP container has no Docker `HEALTHCHECK` and no `/healthz` route registered in `mcp_server.py`. Moving from single-region to active/active depends on the GLB choosing a healthy region per request, but the GLB cannot distinguish a serving origin from a hung process when both reply 200 to a static literal.

**What does this solve:** Gives the GLB and Container Apps a real liveness/readiness contract so unhealthy regions are de-weighted instead of masking failures behind a static literal.

**Resiliency Impact:** Without a real readiness probe in either region, the GLB cannot route around an unhealthy region — every other P1 readiness contract collapses. Real `/healthz/ready` enables the health-then-GLB pattern that the rest of the active/active design depends on.

**Recommended Fix:** Replace the static literal with a real liveness route, add `/healthz/ready` that probes downstream dependencies, register both routes in `mcp_server.py`, add a Docker `HEALTHCHECK`, and wire Container App probes plus GLB origin probes to `/healthz/ready`.

**File:** src/App/frontend_server.py

```python
@app.get("/health")
async def health():
    return "OK"   # static literal — always 200
```

**Fix:**

```python
from fastapi import APIRouter, Response
router = APIRouter()

@router.get("/health")
async def liveness() -> Response:
    return Response(status_code=200)

@router.get("/healthz/ready")
async def readiness() -> dict:
    backend_ok = await _probe(_proxy_target() + "/healthz/ready")
    auth_ok    = await _probe_auth_cache()
    ready      = backend_ok and auth_ok
    return {"ready": ready, "backend": backend_ok, "auth": auth_ok}
```

**Notes:** Mirror in MCP: register `@app.get("/healthz")` and `/healthz/ready` (probes JWKS cache), and add `HEALTHCHECK CMD curl -f http://localhost:8000/healthz || exit 1` to the MCP Dockerfile. Configure GLB probes against `/healthz/ready` at `interval=5s, timeout=2s`. Cross-ref P0-021, P0-024.

<span style="font-size: 14px;">**MSFT Reference:** [Health Endpoint Monitoring](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring)</span>

---

#### P1-041: Retry coverage limited to OpenAI 429

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** Retry logic exists only around the OpenAI 429 path. Cosmos 503, Search 503, Foundry transient errors, and Storage `ServiceRequestError` all surface immediately as user-visible 5xx. In a single-region setup the inconsistency hurts UX; in active/active there is no shared retry budget, so a single transient blip in any non-OpenAI dependency aborts plans that could have ridden out a sub-second disturbance.

**What does this solve:** Provides a shared retry contract with per-dependency budgets so every Azure SDK call benefits from the same jittered backoff and observability.

**Resiliency Impact:** Without uniform retry, regional cutover surfaces dozens of distinct error shapes to the user instead of a few seconds of additional latency; observability and remediation become fragmented per dependency.

**Recommended Fix:** Create a shared `azure_retry` module exposing a `with_retry(dependency, attempts, ceiling)` decorator built on `tenacity`, define per-dependency budgets (Cosmos 5×8s, Search 3×4s, Foundry 3×8s, Storage 4×8s, OpenAI 5×60s), and apply at every SDK call site.

**File:** src/backend/common/resilience/azure_retry.py

```python
# (file does not exist; retries scattered across modules,
# only OpenAI 429 path has a tight loop)
```

**Fix:**

```python
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type
from azure.cosmos.exceptions import CosmosHttpResponseError
from azure.core.exceptions import HttpResponseError, ServiceRequestError

def with_retry(dependency: str, *, attempts: int, ceiling: float):
    def deco(fn):
        @retry(
            stop=stop_after_attempt(attempts),
            wait=wait_random_exponential(min=0.2, max=ceiling),
            retry=retry_if_exception_type((CosmosHttpResponseError, HttpResponseError, ServiceRequestError)),
            before_sleep=lambda rs: metrics.increment(f"{dependency}.retry.attempt"),
        )
        async def wrapper(*a, **kw):
            try:
                return await fn(*a, **kw)
            except Exception:
                metrics.increment(f"{dependency}.retry.exhausted")
                raise
        return wrapper
    return deco
```

**Notes:** Cross-ref P1-030 (OpenAI), P0-021. Sustained `<dependency>.retry.exhausted > threshold` for 60s flips `/healthz/ready` to 503.

<span style="font-size: 14px;">**MSFT Reference:** [Retry pattern](https://learn.microsoft.com/azure/architecture/patterns/retry)</span>

---

#### P1-042: DefaultAzureCredential / MIC without `tenant_id`

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `DefaultAzureCredential` and `ManagedIdentityCredential` are constructed without an explicit `tenant_id`. As the application moves from single-region to active/active, multi-tenant or guest scenarios can resolve to the wrong tenant in either region, producing intermittent `AADSTS50020`/`AADSTS500011` failures that look transient but are deterministic per user — and behave inconsistently across `{primaryRegion}` and `{secondaryRegion}`.

**What does this solve:** Pins credential construction to a known tenant in both regions and validates the Easy-Auth `tid` claim to keep identity behavior consistent.

**Resiliency Impact:** Identical credential resolution in both regions removes a class of "works in primary, fails in secondary" auth bugs during failover. Without it, tenant-confusion errors are observable post-cutover.

**Recommended Fix:** Read `tenant_id = os.environ["AZURE_TENANT_ID"]` at `AppConfig` init (fail fast if missing), pass `tenant_id` / `additionally_allowed_tenants` to credential constructors, and add middleware that asserts the Easy-Auth `tid` claim matches `AZURE_TENANT_ID`.

**File:** src/backend/common/config/app_config.py:131,133,150,152

```python
from azure.identity.aio import DefaultAzureCredential, ManagedIdentityCredential

self.credential = DefaultAzureCredential()                  # no tenant_id
self._mic = ManagedIdentityCredential(client_id=os.environ.get("AZURE_CLIENT_ID"))
```

**Fix:**

```python
from azure.identity.aio import DefaultAzureCredential, ManagedIdentityCredential

self.tenant_id = os.environ["AZURE_TENANT_ID"]            # required, never defaulted
self.credential = DefaultAzureCredential(
    managed_identity_client_id=os.environ["AZURE_CLIENT_ID"],
    additionally_allowed_tenants=[self.tenant_id],
    exclude_environment_credential=True,
    exclude_shared_token_cache_credential=True,
)
self._mic = ManagedIdentityCredential(
    client_id=os.environ["AZURE_CLIENT_ID"],
)
```

**Notes:** Add a FastAPI middleware that decodes `X-MS-CLIENT-PRINCIPAL` and rejects 401 on `tid` mismatch. Surface `auth.tenant_validated` in `/healthz`. Cross-ref P1-007, P1-043.

<span style="font-size: 14px;">**MSFT Reference:** [Managed Identities for Azure Resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)</span>

---

#### P1-043: No retry / backoff / fallback on `get_access_token`

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** `get_access_token` calls the credential directly with no retry, no jitter, and no fallback credential source. Moving from single-region to active/active makes a transient Entra ID token-endpoint glitch a hard 5xx for the user request that triggered it in either region, with no in-memory cache to ride out the blip — every request re-hits Entra ID.

**What does this solve:** Adds bounded retry with jitter, an in-memory token cache, and a UAMI-based fallback credential path so transient token failures do not propagate to user requests.

**Resiliency Impact:** Brief Entra ID hiccups become invisible to users in both regions during cutover. Without retry, every transient is a hard failure during failover.

**Recommended Fix:** Wrap `get_token` with `tenacity` (4 attempts, jittered exponential up to 8s) on `ClientAuthenticationError`, cache tokens until close to expiry, and on permanent MIC failure attempt `DefaultAzureCredential` once before giving up.

**File:** src/backend/common/config/app_config.py:170-176

```python
async def get_access_token(self, scope: str) -> str:
    tok = await self._mic.get_token(scope)   # no retry, no fallback, no cache
    return tok.token
```

**Fix:**

```python
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type
from azure.core.exceptions import ClientAuthenticationError

@retry(
    stop=stop_after_attempt(4),
    wait=wait_random_exponential(min=0.5, max=8),
    retry=retry_if_exception_type(ClientAuthenticationError),
)
async def _fetch_token(credential, scope: str):
    return await credential.get_token(scope)

async def get_access_token(self, scope: str) -> str:
    try:
        tok = await _fetch_token(self._mic, scope)
    except ClientAuthenticationError:
        metrics.increment("auth.fallback_used")
        tok = await _fetch_token(self.credential, scope)
    return tok.token
```

**Notes:** Surface `auth.last_retry_count`, `auth.fallback_used`. Token cache must be in-memory only; never on disk. Cross-ref P1-034, P1-042.

<span style="font-size: 14px;">**MSFT Reference:** [Microsoft Identity Platform Access Tokens](https://learn.microsoft.com/entra/identity-platform/access-tokens)</span>

---

#### P1-044: Single UAMI sole RBAC subject across data planes

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** A single UAMI is the RBAC principal on Cosmos, Foundry, OpenAI, Search, Storage, and ACR. Moving from single-region to active/active does not isolate blast radius: a misconfigured role assignment, an accidental delete, or a rotation issue takes down access to every data plane in both regions simultaneously, and `{primaryRegion}` and `{secondaryRegion}` share the same single point of identity failure.

**What does this solve:** Splits UAMIs by data-plane scope (or at minimum per region) and assigns least-privilege roles per plane so a single misconfiguration cannot disable every dependency.

**Resiliency Impact:** Per-plane UAMIs contain identity faults to a single dependency in both regions. Without separation, a UAMI mishap is a whole-platform outage.

**Recommended Fix:** Split UAMIs by data-plane responsibility (`uami-data`, `uami-ai`, `uami-runtime`), assign only the narrowest role per plane (Cosmos `Cosmos DB Built-in Data Contributor`, Search `Search Index Data Reader` + `Search Service Contributor`, Storage `Storage Blob Data Contributor`, Foundry `Cognitive Services User`, ACR `AcrPull`), and add a startup self-test against each plane.

**File:** infra/main.bicep:384-388

```bicep
resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${solutionPrefix}'
  location: location
}
// same UAMI used as RBAC principal on every data plane
```

**Fix:**

```bicep
module uamiData 'br/public:avm/res/managed-identity/user-assigned-identity:0.x.y' = {
  name: 'uami-data'
  params: { name: 'id-data-${solutionPrefix}', location: primaryLocation }
}
module uamiAi 'br/public:avm/res/managed-identity/user-assigned-identity:0.x.y' = {
  name: 'uami-ai'
  params: { name: 'id-ai-${solutionPrefix}', location: primaryLocation }
}

resource cosmosRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmos.outputs.resourceId, uamiData.outputs.principalId, 'CosmosDataContributor')
  scope: cosmosScope
  properties: {
    principalId: uamiData.outputs.principalId
    roleDefinitionId: cosmosDataContributorRoleId
    principalType: 'ServicePrincipal'
  }
}
```

**Notes:** Add `data_plane_self_test` in `/healthz` so per-plane health is visible. Mirror per-region (cross-ref P1-007). No subscription-scope `Contributor` assignments.

<span style="font-size: 14px;">**MSFT Reference:** [Protected Web API Scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P1-045: Container Apps `ingressExternal: true`

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The backend Container App is configured with `ingressExternal: true` unconditionally and is publicly reachable. Moving from single-region to active/active means both regions expose the backend publicly once GLB routes traffic, bypassing the GLB / App Gateway and inflating attack surface across both regions during cutover.

**What does this solve:** Gates `ingress.external` on `enablePrivateNetworking` so private-mode deployments are reachable only via the GLB / App Gateway path in both regions.

**Resiliency Impact:** Constraining ingress to the GLB-controlled path in both regions reduces blast radius during failover. Without the gate, direct-to-origin requests bypass auth, WAF, and rate limits regardless of region.

**Recommended Fix:** Replace `ingressExternal: true` with `external: !enablePrivateNetworking`; in private mode front the Container App with an internal App Gateway / GLB origin via Private Link; in public mode keep external true but enforce CORS allow-list (cross-ref P2-017) and Easy Auth (cross-ref P0-026).

**File:** infra/main.bicep:1217

```bicep
module backend 'br/public:avm/res/app/container-app:0.x.y' = {
  params: {
    ingressExternal: true
    ingressTargetPort: 8000
  }
}
```

**Fix:**

```bicep
param enablePrivateNetworking bool = false

resource backendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-backend-${solutionPrefix}'
  properties: {
    configuration: {
      ingress: {
        external: !enablePrivateNetworking
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
    }
  }
}
```

**Notes:** Mirror the gate for the MCP Container App. Cross-ref P0-026, P2-017, P1-046.

<span style="font-size: 14px;">**MSFT Reference:** [Container Apps Ingress Overview](https://learn.microsoft.com/azure/container-apps/ingress-overview)</span>

---

#### P1-046: App Service publicNetworkAccess Enabled

**Priority: P1 — Multi-Region Resiliency Gap**

**Resiliency Related:** Yes

**Issue:** The App Service is created with `publicNetworkAccess: 'Enabled'` regardless of `enablePrivateNetworking`. Moving from single-region to active/active means the SPA origin is publicly reachable in both regions outside the GLB / Front Door path, so direct-to-origin requests bypass GLB-controlled routing, WAF, and rate limits — the active/active topology no longer enforces a single ingress contract.

**What does this solve:** Gates `publicNetworkAccess` on `enablePrivateNetworking` and pins access restrictions to the GLB / Front Door service tag so all user traffic stays on the GLB-controlled path in both regions.

**Resiliency Impact:** Constrains both regional Web App origins to the GLB path during failover. Without it, the GLB cannot enforce traffic shaping across regions.

**Recommended Fix:** Set `publicNetworkAccess: enablePrivateNetworking ? 'Disabled' : 'Enabled'`, in public mode allow only `AzureFrontDoor.Backend` with `x-azure-fdid` header, and in private mode provision a Private Endpoint and bind the GLB to the PE-fronted FQDN. Mirror across both regions.

**File:** infra/main.bicep:1572

```bicep
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-${solutionPrefix}'
  properties: {
    serverFarmId: webPlan.id
    publicNetworkAccess: 'Enabled' // Always enabling the public network access for Web App
  }
}
```

**Fix:**

```bicep
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-${solutionPrefix}-${primaryLocation}'
  properties: {
    serverFarmId: webPlanPrimary.outputs.resourceId
    publicNetworkAccess: enablePrivateNetworking ? 'Disabled' : 'Enabled'
    siteConfig: {
      ipSecurityRestrictionsDefaultAction: 'Deny'
      ipSecurityRestrictions: enablePrivateNetworking ? [] : [
        {
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          action: 'Allow'
          priority: 100
          headers: { 'x-azure-fdid': [ frontDoorId ] }
        }
      ]
    }
  }
}
```

**Notes:** Mirror for `{secondaryRegion}` Web App. Pair with Easy Auth enforcement (cross-ref P1-010). Cross-ref P0-024, P1-004, P1-045.

<span style="font-size: 14px;">**MSFT Reference:** [App Service Private Endpoint](https://learn.microsoft.com/azure/app-service/networking/private-endpoint)</span>

---

[Back to Top](#top)

---

# 3. Non-Resilient Focused Recommendations

## P2 — Improvement / Best Practice (Non-Resiliency) (22)

#### P2-001: Application Insights single regional component

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Application Insights is provisioned as a single regional component gated on `enableMonitoring`, and the connection string is treated as a required environment variable. Telemetry topology behaves identically in single-region and active/active deployments, but a missed `enableMonitoring=true` toggle silently disables monitoring across the entire surface. The gap is observability coverage hygiene, not failover.

**What does this solve:** Ensures telemetry is provisioned alongside every regional workload and that a missing connection string degrades gracefully instead of blocking startup.

**Impact:** Without explicit defaults and degraded-mode handling, operators can deploy a workload that boots cleanly yet emits no telemetry, leaving incident triage blind. The gap shows up as missing dashboards and alerts, not as runtime errors, so it can persist undetected through release cycles.

**Recommended Fix:** Default `enableMonitoring=true` for non-dev environments, provision an Application Insights component per region bound to the local Log Analytics workspace, and treat `APPLICATIONINSIGHTS_CONNECTION_STRING` as optional in `app_config` with a degraded-mode startup banner. Surface the resolved telemetry region in `/healthz` output so operators can verify wiring.

**File:** infra/main.bicep:366-379

```bicep
module appInsights 'br/public:avm/res/insights/component:0.x.y' = if (enableMonitoring) {
  name: 'appi-${location}'
  params: {
    name: 'appi-${solutionPrefix}-${location}'
    workspaceResourceId: logAnalytics.outputs.resourceId
    location: location
  }
}
```

**Fix:**

```bicep
module appInsights 'br/public:avm/res/insights/component:0.x.y' = if (enableMonitoring) {
  name: 'appi-${location}'
  params: {
    name: 'appi-${solutionPrefix}-${location}'
    workspaceResourceId: logAnalytics.outputs.resourceId
    location: location
  }
}
```

**Notes:** Pair with P2-011 so the runtime treats a missing or invalid connection string as a degraded-mode warning rather than an unhandled silent drop.

<span style="font-size: 14px;">**MSFT Reference:** [Application Insights availability overview](https://learn.microsoft.com/azure/azure-monitor/app/availability-overview)</span>

---

#### P2-002: Log Analytics workspace single-region by default

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Log Analytics workspace is single-region by default; cross-region replication is gated on `enableRedundancy` with the replica region fixed by a hard-coded paired-region map. Workspace topology is a deploy-time IaC choice that behaves identically at runtime in single-region and active/active. The gap is best-practice coverage of the workspace contract, not failover behaviour.

**What does this solve:** Makes the replicated workspace the default for production and lets operators choose the replica region explicitly instead of inheriting a hard-coded pairing.

**Impact:** Off-by-default replication leaves production deployments under-protected for log retention and cross-region investigation. The hard-coded pairing also blocks operators in regulated environments who need to keep telemetry inside a specific geography.

**Recommended Fix:** Default `enableRedundancy=true` in production parameter files, expose a `logAnalyticsReplicaLocation` parameter that overrides the paired-region map, and document the BYO workspace pattern in `docs/re-use-log-analytics.md`.

**File:** infra/main.bicep:290-340

```bicep
param logAnalyticsReplicaLocation string = paired[location]
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.x.y' = {
  params: {
    replication: enableRedundancy ? { location: logAnalyticsReplicaLocation } : null
  }
}
```

**Fix:**

```bicep
param logAnalyticsReplicaLocation string = paired[location]
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.x.y' = {
  params: {
    replication: enableRedundancy ? { location: logAnalyticsReplicaLocation } : null
  }
}
```

**Notes:** Operator override unblocks deployments outside the canonical paired-region table and removes a silent IaC dependency on the hard-coded map.

<span style="font-size: 14px;">**MSFT Reference:** [Log Analytics workspace overview](https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview)</span>

---

#### P2-003: Cosmos paired-region table covers only 10 regions

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The `cosmosDbZoneRedundantHaRegionPairs` lookup table in `infra/main.bicep` enumerates only 10 regions, and the variable `cosmosDbHaLocation = cosmosDbZoneRedundantHaRegionPairs[location]` returns `null` if the deploy `location` is not a key. This is an IaC-completeness gap whose behavior is identical in single-region and active/active deployments — once a supported region is chosen, runtime is unaffected. The risk is a silent deploy-time disablement of HA wiring rather than a regional failover concern.

**What does this solve:** Surfaces unsupported deploy regions as an explicit deploy-time error and lets operators override the paired region when needed.

**Impact:** Operators selecting any region outside the hardcoded 10-entry table see HA-related fields silently resolve to `null`, with no clear failure signal in the deployment log. This is a code-quality / IaC hygiene concern that complicates onboarding new regions, not a runtime resiliency one.

**Recommended Fix:** Replace the silent `null` fallback with a Bicep `assert` that fails the deployment when `location` is not in the table, and add a `cosmosDbHaLocationOverride` parameter so operators can explicitly opt in for unlisted regions. Cite the canonical Microsoft paired-regions documentation in a Bicep comment so future maintainers can refresh the table.

**File:** infra/main.bicep:191-203

```bicep
var cosmosDbZoneRedundantHaRegionPairs = {
  australiaeast: 'uksouth'
  centralus: 'eastus2'
  eastasia: 'southeastasia'
  eastus: 'centralus'
  eastus2: 'centralus'
  japaneast: 'australiaeast'
  northeurope: 'westeurope'
  southeastasia: 'eastasia'
  uksouth: 'westeurope'
  westeurope: 'northeurope'
}
var cosmosDbHaLocation = cosmosDbZoneRedundantHaRegionPairs[location]
```

**Fix:**

```bicep
// Source: https://learn.microsoft.com/azure/reliability/cross-region-replication-azure
var cosmosDbZoneRedundantHaRegionPairs = {
  australiaeast: 'uksouth'
  centralus: 'eastus2'
  eastasia: 'southeastasia'
  eastus: 'centralus'
  eastus2: 'centralus'
  japaneast: 'australiaeast'
  northeurope: 'westeurope'
  southeastasia: 'eastasia'
  uksouth: 'westeurope'
  westeurope: 'northeurope'
}

@description('Optional override for the Cosmos HA paired region when {primaryRegion} is not in the supported table.')
param cosmosDbHaLocationOverride string = ''

var pair = cosmosDbZoneRedundantHaRegionPairs[?location]
var cosmosDbHaLocation = !empty(cosmosDbHaLocationOverride) ? cosmosDbHaLocationOverride : pair
// assert: cosmosDbHaLocation must not be null
```

**Notes:** Pairs the deploy-time validation with an operator escape hatch. Aligns with the parameter-validation pattern used elsewhere in the template. Cross-references the Cosmos consistency / backup hygiene findings (P2-004, P2-007).

<span style="font-size: 14px;">**MSFT Reference:** [Bicep parameters and conditional wiring](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameters)</span>

---

#### P2-004: Cosmos `defaultConsistencyLevel` not set

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Cosmos AVM module call does not pin `defaultConsistencyLevel`, so the account inherits the AVM default (`Session`) implicitly. Runtime behaviour is identical in single-region and active/active because the level is the same in both, but the contract is unverifiable from IaC and can drift under module upgrades. The gap is contract-clarity hygiene.

**What does this solve:** Makes the consistency contract explicit in IaC and verifiable through `az cosmosdb show`, removing the dependency on AVM module defaults.

**Impact:** Implicit consistency is fragile during module version bumps and complicates compliance reviews that require explicit data-tier guarantees. Pinning the value also makes regression review trivial during AVM upgrades.

**Recommended Fix:** Pin `defaultConsistencyLevel: 'Session'` (or the chosen level) on the Cosmos AVM call, document the chosen level in `docs/`, and emit a startup log line recording the resolved account-level consistency.

**File:** infra/main.bicep:1043-1128

```bicep
consistencyPolicy: {
  defaultConsistencyLevel: 'Session'
}
```

**Fix:**

```bicep
consistencyPolicy: {
  defaultConsistencyLevel: 'Session'
}
```

**Notes:** Cross-references P2-010, which pins the same level on the application `CosmosClient`.

<span style="font-size: 14px;">**MSFT Reference:** [Cosmos DB consistency levels](https://learn.microsoft.com/azure/cosmos-db/consistency-levels)</span>

---

#### P2-005: Hot-path queries miss `/session_id` partition key

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Multiple hot-path Cosmos queries (`get_plan_by_plan_id`, `get_all_plans`, `get_team*`, `delete_plan_by_plan_id`) omit `session_id`, forcing cross-partition fan-out on every call. Query shape is inefficient regardless of region count, and behaves identically in single-region and active/active. The gap is query-shape performance hygiene.

**What does this solve:** Restricts hot-path queries to a single partition, cutting RU consumption and tail latency without changing data model.

**Impact:** Cross-partition queries silently inflate cost and p99 latency under load and become the first bottleneck during traffic spikes. Partition-scoped reads keep RU charges predictable as traffic grows.

**Recommended Fix:** Thread `session_id` (or the model's partition key) through callers and pass `partition_key=` on `query_items` and `read_item`. For lookups that genuinely span sessions, add a secondary index strategy (materialized view container) and add an integration test asserting an RU charge ceiling per query.

**File:** src/backend/common/database/cosmosdb.py:189-200

```python
async def get_plan_by_plan_id(self, plan_id: str, session_id: str) -> Plan | None:
    query = "SELECT * FROM c WHERE c.id = @id AND c.data_type = 'plan'"
    params = [{"name": "@id", "value": plan_id}]
    async for item in self._container.query_items(
        query=query, parameters=params, partition_key=session_id
    ):
        return Plan(**item)
    return None
```

**Fix:**

```python
async def get_plan_by_plan_id(self, plan_id: str, session_id: str) -> Plan | None:
    query = "SELECT * FROM c WHERE c.id = @id AND c.data_type = 'plan'"
    params = [{"name": "@id", "value": plan_id}]
    async for item in self._container.query_items(
        query=query, parameters=params, partition_key=session_id
    ):
        return Plan(**item)
    return None
```

**Notes:** Record `x-ms-request-charge` per call in tests and assert below an agreed RU threshold to prevent regressions.

<span style="font-size: 14px;">**MSFT Reference:** [Query a Cosmos DB container](https://learn.microsoft.com/azure/cosmos-db/nosql/how-to-query-container)</span>

---

#### P2-006: `DatabaseFactory` not closed on lifespan shutdown

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** `DatabaseFactory.close_all()` exists but is never invoked from the FastAPI `lifespan` shutdown hook, leaving the cached `CosmosClient` open until process exit. Resource leak only manifests at shutdown, identically in single-region and active/active deployments. The gap is lifecycle hygiene around SDK client cleanup.

**What does this solve:** Ensures cached SDK clients are closed cleanly during graceful shutdown, releasing sockets and stopping background tasks deterministically.

**Impact:** Process-exit-only cleanup yields noisy shutdown logs, leaked sockets in test runs, and warnings from the asyncio runtime. Closing the factory in lifespan keeps shutdown deterministic and unit-testable.

**Recommended Fix:** Await `DatabaseFactory.close_all()` after `yield` in the FastAPI `lifespan` context manager, audit other singletons (Search, Storage, OpenAI) for matching `aclose` hooks, and add a unit test that exercises lifespan shutdown.

**File:** src/backend/common/database/database_factory.py:39-58

```python
from contextlib import asynccontextmanager
from common.database.database_factory import DatabaseFactory

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await DatabaseFactory.close_all()
```

**Fix:**

```python
from contextlib import asynccontextmanager
from common.database.database_factory import DatabaseFactory

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await DatabaseFactory.close_all()
```

**Notes:** Run `pytest` with `asyncio_mode=auto`, trigger lifespan shutdown, and assert `close_all` was awaited.

<span style="font-size: 14px;">**MSFT Reference:** [Observability in Well-Architected operational excellence](https://learn.microsoft.com/azure/well-architected/operational-excellence/observability)</span>

---

#### P2-007: Cosmos backup policy not set in IaC

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Cosmos AVM module call does not pass `backupPolicyType` or related fields, so the account inherits the default 4-hour periodic policy. Backup posture is identical regardless of region count, and serverless mode also blocks continuous backup (PITR). The gap is data-protection best practice, not regional failover.

**What does this solve:** Makes the backup posture explicit in IaC and unlocks PITR for accounts that move off the serverless tier.

**Impact:** An implicit 4-hour periodic policy is unsuitable for many production RPO targets and is invisible during code review. Pinning the policy makes the recovery contract explicit and reviewable.

**Recommended Fix:** Pin `backupPolicyType` and retention on the Cosmos AVM module, evaluate moving off serverless to enable `Continuous` (PITR) where the SKU allows, and document the chosen RPO in `docs/`.

**File:** infra/main.bicep:1043-1128

```bicep
backupPolicy: {
  type: 'Continuous'
  continuousModeProperties: { tier: 'Continuous30Days' }
}
```

**Fix:**

```bicep
backupPolicy: {
  type: 'Continuous'
  continuousModeProperties: { tier: 'Continuous30Days' }
}
```

**Notes:** Validate with `az cosmosdb show --query backupPolicy` after deploy.

<span style="font-size: 14px;">**MSFT Reference:** [Cosmos DB online backup and restore](https://learn.microsoft.com/azure/cosmos-db/online-backup-and-restore)</span>

---

#### P2-008: Storage blob versioning / PITR / change feed disabled

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Storage `blobServices` block sets only soft-delete and access tracking; `isVersioningEnabled`, `restorePolicy`, and `changeFeed` are not configured. Blob protection posture is identical in single-region and active/active. The gap is data-protection hygiene, not regional failover behaviour.

**What does this solve:** Enables versioning, point-in-time restore, and change feed so accidental overwrites and deletes are recoverable and audit replay is available.

**Impact:** Without versioning and PITR, an operator overwrite during a deploy script can be unrecoverable, and audit/replay scenarios have no source of truth. Enabling change feed also unlocks downstream eventing patterns.

**Recommended Fix:** Enable `isVersioningEnabled: true` with a `restorePolicy` window of at least 7 days, enable `changeFeed.enabled: true` for audit and replay, and document blob retention in the operator guide.

**File:** infra/main.bicep:1642-1684

```bicep
blobServices: {
  isVersioningEnabled: true
  restorePolicy: { enabled: true, days: 7 }
  changeFeed: { enabled: true, retentionInDays: 7 }
  deleteRetentionPolicy: { enabled: true, days: 7 }
}
```

**Fix:**

```bicep
blobServices: {
  isVersioningEnabled: true
  restorePolicy: { enabled: true, days: 7 }
  changeFeed: { enabled: true, retentionInDays: 7 }
  deleteRetentionPolicy: { enabled: true, days: 7 }
}
```

**Notes:** Confirm with `az storage account blob-service-properties show` after deploy.

<span style="font-size: 14px;">**MSFT Reference:** [Blob versioning overview](https://learn.microsoft.com/azure/storage/blobs/versioning-overview)</span>

---

#### P2-009: `upload-batch --overwrite` without concurrency control

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** All `az storage blob upload-batch` calls use `--overwrite` with no ETag or `If-None-Match` guard, so a second operator running the same script clobbers the first one's uploads. Bulk-upload script behaviour is identical regardless of region count. The gap is operator-script idempotency hygiene, not regional failover.

**What does this solve:** Adds a concurrency model to operator upload scripts so concurrent runs detect each other and fail fast instead of overwriting silently.

**Impact:** Today, two operators running the dataset upload concurrently will silently produce a non-deterministic blob set. Lease-based concurrency turns the second run into a clean lease error.

**Recommended Fix:** Maintain a manifest blob recording the last-good upload and operator id, acquire a lease on a `lock` blob before running the batch, and stamp uploaded blobs with a run id metadata header.

**File:** infra/scripts/Selecting-Team-Config-And-Data.ps1:702

```powershell
az storage blob lease acquire --container-name $container --blob-name "upload.lock" --lease-duration 60
$runId = [guid]::NewGuid().ToString()
az storage blob upload-batch --overwrite --metadata "runId=$runId"
az storage blob lease release --container-name $container --blob-name "upload.lock"
```

**Fix:**

```powershell
az storage blob lease acquire --container-name $container --blob-name "upload.lock" --lease-duration 60
$runId = [guid]::NewGuid().ToString()
az storage blob upload-batch --overwrite --metadata "runId=$runId"
az storage blob lease release --container-name $container --blob-name "upload.lock"
```

**Notes:** Validate by running two operator scripts concurrently and confirming the second exits cleanly with a lease error.

<span style="font-size: 14px;">**MSFT Reference:** [Blob change feed support](https://learn.microsoft.com/azure/storage/blobs/storage-blob-change-feed)</span>

---

#### P2-010: Cosmos `Session` consistency not pinned

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Cosmos `Session` consistency is inherited from AVM defaults, and per-replica `CosmosClient` instances scope session tokens locally. Runtime behaviour is identical in single-region and active/active because the level is the same in both, but the contract is unverifiable from code. The gap is contract-clarity hygiene parallel to P2-004.

**What does this solve:** Makes the application-level consistency contract explicit and creates a hook for propagating session tokens when read-your-writes matters.

**Impact:** Implicit consistency leaves session continuity unverifiable in tests and code review, and a future SDK or AVM upgrade can change defaults silently. Pinning the level removes that drift risk.

**Recommended Fix:** Pin `consistency_level="Session"` on `CosmosClient` construction. If session continuity matters across requests, propagate the response session token through cookies or headers to the next request, and add tests for read-your-writes within a session.

**File:** src/backend/common/database/cosmosdb.py:62-64

```python
CosmosClient(
    url=endpoint,
    credential=credential,
    consistency_level="Session",
)
```

**Fix:**

```python
CosmosClient(
    url=endpoint,
    credential=credential,
    consistency_level="Session",
)
```

**Notes:** Cross-references P2-004 (IaC pin) and the integration test for read-your-writes within the same session.

<span style="font-size: 14px;">**MSFT Reference:** [Cosmos DB consistency levels](https://learn.microsoft.com/azure/cosmos-db/consistency-levels)</span>

---

#### P2-011: Telemetry exporter drops events silently

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** `azure-monitor-opentelemetry` configuration and `track_event` calls return without raising on exporter failure, so live metrics blackouts during incidents look identical to a healthy boot. Silent-drop behaviour is the same in single-region and active/active topologies. The gap is observability hygiene around exporter health, not regional failover.

**What does this solve:** Surfaces exporter initialisation failures and connection-string gaps so operators see them immediately instead of inferring them from missing telemetry.

**Impact:** A failing exporter today disappears into the logs, masking outages and giving false confidence during incident response. Fixing it shortens triage time and prevents misleading green health probes.

**Recommended Fix:** Wrap `configure_azure_monitor` in a try/except block that logs an ERROR with the exception, treat `APPLICATIONINSIGHTS_CONNECTION_STRING` as optional with a clear degraded-mode startup banner, and add a periodic exporter heartbeat task whose state is reflected in `/healthz`.

**File:** src/backend/app.py:80-99

```python
import logging
from azure.monitor.opentelemetry import configure_azure_monitor

log = logging.getLogger(__name__)
cs = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if cs:
    try:
        configure_azure_monitor(connection_string=cs)
    except Exception as ex:
        log.error("telemetry.exporter.init_failed", exc_info=ex)
else:
    log.warning("telemetry.degraded=true reason=missing_connection_string")
```

**Fix:**

```python
import logging
from azure.monitor.opentelemetry import configure_azure_monitor

log = logging.getLogger(__name__)
cs = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if cs:
    try:
        configure_azure_monitor(connection_string=cs)
    except Exception as ex:
        log.error("telemetry.exporter.init_failed", exc_info=ex)
else:
    log.warning("telemetry.degraded=true reason=missing_connection_string")
```

**Notes:** Cross-references P2-001 (component provisioning) and P2-022 (structured logging depth).

<span style="font-size: 14px;">**MSFT Reference:** [Observability in Well-Architected operational excellence](https://learn.microsoft.com/azure/well-architected/operational-excellence/observability)</span>

---

#### P2-012: Pinned Microsoft Python SDKs and version drift

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** `src/backend/requirements.txt`, `src/mcp_server/requirements.txt`, and operator scripts under `infra/scripts/` pin different versions of `azure-identity` and related Microsoft SDKs (for example `azure-identity==1.24.0` in the backend versus `1.19.0` in MCP), and some entries are beta releases such as `azure-ai-inference==1.0.0b9`. This behaves identically in single-region and active/active deployments — version drift and yank risk affect rebuilds, not runtime in either region. Drift also leaves failover semantics inconsistent across components.

**What does this solve:** Centralizes SDK pins in one constraints file so every Python component resolves to the same versions, and pushes beta pins toward GA to reduce yank risk.

**Impact:** Two components calling the same SDK with different versions can exhibit subtly different retry, token-refresh, or failover behavior, complicating diagnosis. Beta pins also expose the build to deletion / yank by upstream maintainers. This is a dependency hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Introduce a top-level `constraints.txt` referenced by every `requirements.txt`, move beta pins to GA where available, and mirror critical wheels to a private feed (cross-ref P3-007) so rebuilds do not depend on PyPI availability.

**File:** src/backend/requirements.txt:3-6

```text
fastapi==0.116.1
uvicorn==0.35.0
azure-cosmos==4.9.0
azure-monitor-opentelemetry==1.8.5
azure-monitor-events-extension==0.1.0
azure-identity==1.24.0
python-dotenv==1.1.1
```

**Fix:**

```text
# path: constraints.txt
azure-identity==1.19.0
azure-cosmos==4.9.0
azure-monitor-opentelemetry==1.8.5
azure-core==1.30.2
```

```text
# path: src/backend/requirements.txt
-c ../../constraints.txt
fastapi==0.116.1
uvicorn==0.35.0
azure-cosmos
azure-monitor-opentelemetry
azure-monitor-events-extension==0.1.0
azure-identity
python-dotenv==1.1.1
```

**Notes:** Apply the same `-c ../../constraints.txt` reference in `src/mcp_server/requirements.txt` and operator scripts under `infra/scripts/`. Cross-references P3-007 (private wheel mirror) and P2-013 (CI/CD supply-chain hygiene).

<span style="font-size: 14px;">**MSFT Reference:** [WAF supply-chain security](https://learn.microsoft.com/azure/well-architected/security/supply-chain-security)</span>

---

#### P2-013: GitHub Actions tag-pinned, not SHA-pinned

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Every reusable GitHub Action in `.github/workflows/` is referenced by a moving tag (for example `actions/checkout@v4`, `Azure/setup-azd@v2`, `azure/login@v2`) rather than by an immutable commit SHA. This behaves identically in single-region and active/active deployments — tag mutability is a CI/CD concern, not a runtime resiliency one. A compromised or retagged action could ship arbitrary code into the next build without any code change in this repository.

**What does this solve:** Pins every action to an immutable commit SHA so a build run today is byte-identical to a re-run tomorrow, and a tag rewrite cannot silently introduce new behavior.

**Impact:** A tag-rewrite or upstream compromise of any pinned action propagates immediately into the next workflow run, including DR re-deploys. This is a supply-chain hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Replace every `uses: org/action@vN` reference with `uses: org/action@<full-40-char-sha> # vN`, document the bump policy in `CONTRIBUTING.md`, and add a CI check (for example `zgosalvez/github-actions-ensure-sha-pinned-actions`) that fails on non-SHA pins. Track Microsoft-owned actions on a separate (faster) cadence than third-party.

**File:** .github/workflows/azure-dev.yml:26

```yaml
steps:
  - name: Checkout Code
    uses: actions/checkout@v4

  - name: Install azd
    uses: Azure/setup-azd@v2

  - name: Login to Azure
    uses: azure/login@v2
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
```

**Fix:**

```yaml
steps:
  - name: Checkout Code
    uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

  - name: Install azd
    uses: Azure/setup-azd@1ea4c33dc0d22b08e1c6ff2c8e4e06058a78e6f1 # v2.1.0

  - name: Login to Azure
    uses: azure/login@a65d910e8af852a8061c627c456678ba9eddff1f # v2.2.0
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
```

**Notes:** Apply across every file under `.github/workflows/`. Cross-references P2-012 (Python SDK pins) and P3-007 (private wheel mirror) — both contribute to a reproducible-build supply chain.

<span style="font-size: 14px;">**MSFT Reference:** [Security hardening for GitHub Actions](https://docs.github.com/actions/security-guides/security-hardening-for-github-actions)</span>

---

#### P2-014: VNet `10.0.0.0/8` and subnets hardcoded

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The VNet module is invoked with a fixed `addressPrefixes: ['10.0.0.0/8']`, and every subnet CIDR inside `infra/modules/virtualNetwork.bicep` is hardcoded. This behaves identically in single-region and active/active deployments — address space is a deploy-time choice and does not change with region count. The default `/8` collides with most enterprise hub-and-spoke ranges and prevents BYO-VNet peering without code edits.

**What does this solve:** Makes VNet and subnet CIDRs configurable at deploy time so the template fits typical enterprise IP plans and supports peering scenarios.

**Impact:** Operators integrating with an existing hub network must edit the template to avoid CIDR collisions. The oversized `/8` default also wastes a top-level RFC1918 block. This is an IaC parameterization / hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Promote the VNet address prefix and per-subnet prefixes to parameters in `infra/main.bicep`, default to a typical hub-and-spoke `/22`, and document peering and BYO-VNet guidance alongside the parameter declarations.

**File:** infra/main.bicep:398-407

```bicep
module virtualNetwork 'modules/virtualNetwork.bicep' = if (enablePrivateNetworking) {
  name: take('module.virtualNetwork.${solutionSuffix}', 64)
  params: {
    name: 'vnet-${solutionSuffix}'
    location: location
    tags: tags
    enableTelemetry: enableTelemetry
    addressPrefixes: ['10.0.0.0/8']
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    resourceSuffix: solutionSuffix
  }
}
```

**Fix:**

```bicep
@description('CIDR for the workload VNet in {primaryRegion} (and the matching peer VNet in {secondaryRegion}).')
param vnetAddressPrefix string = '10.10.0.0/22'

@description('Per-subnet CIDR plan. Each value must fit inside vnetAddressPrefix.')
param subnetPrefixes object = {
  backend: '10.10.0.0/27'
  containers: '10.10.2.0/23'
  privateEndpoints: '10.10.1.0/27'
}

module virtualNetwork 'modules/virtualNetwork.bicep' = if (enablePrivateNetworking) {
  name: take('module.virtualNetwork.${solutionSuffix}', 64)
  params: {
    name: 'vnet-${solutionSuffix}'
    location: location
    tags: tags
    enableTelemetry: enableTelemetry
    addressPrefixes: [vnetAddressPrefix]
    subnetPrefixes: subnetPrefixes
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    resourceSuffix: solutionSuffix
  }
}
```

**Notes:** Threads the same `subnetPrefixes` object into `infra/modules/virtualNetwork.bicep` so the module references the parameter rather than its own hardcoded array. Cross-references P2-021 (route tables / NAT / DDoS) where the same subnet plan is consumed.

<span style="font-size: 14px;">**MSFT Reference:** [Virtual networks overview](https://learn.microsoft.com/azure/virtual-network/virtual-networks-overview)</span>

---

#### P2-015: SAMI on Web/Storage while RBAC uses UAMI

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Web Site module is configured with `managedIdentities: { systemAssigned: true }`, and the Storage account similarly enables a system-assigned identity, but every data-plane RBAC binding in `infra/main.bicep` references the shared User-Assigned Managed Identity. This behaves identically in single-region and active/active deployments — no code path resolves the SAMI today. The hazard is a latent footgun for future changes that pick the wrong identity.

**What does this solve:** Standardizes on a single identity model so any future data-plane code path automatically inherits the role assignments already granted to the UAMI.

**Impact:** A future contributor wiring a new SDK client through `ManagedIdentityCredential` may pick up the SAMI principal id and silently get 403s, with no obvious link back to the IaC identity-model split. This is an identity-model consistency / hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Drop the SAMIs that have no role bindings, attach the shared UAMI to the Web Site and Storage account where data-plane access is required, and document the chosen identity model in the deployment guide.

**File:** infra/main.bicep:1539-1541

```bicep
managedIdentities: {
  systemAssigned: true
}
```

**Fix:**

```bicep
managedIdentities: {
  userAssignedResourceIds: [userAssignedIdentity.outputs.resourceId]
}
```

**Notes:** Same UAMI is already used by the AI Foundry, Cosmos, Search, and OpenAI role assignments, so this aligns Web Site and Storage with the rest of the stack. Cross-references P2-016 (RBAC propagation gating) — a single principal id makes the propagation probe trivial.

<span style="font-size: 14px;">**MSFT Reference:** [Managed identity best-practice recommendations](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations)</span>

---

#### P2-016: No readiness gate for Entra RBAC propagation

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Role assignments for the UAMI on AI Foundry, Cosmos, Storage, and Search are emitted at deploy time with no post-deploy probe and no `dependsOn` chain that waits for propagation. This behaves identically in single-region and active/active deployments — the runtime steady state is the same once propagation completes. The hazard is a deploy-time window where the application can return 403 for several minutes immediately after a cold deployment.

**What does this solve:** Adds a deploy-time gate that withholds traffic admission until the UAMI's data-plane role assignments are observable from the workload.

**Impact:** Cold deployments and `azd up` runs can mark the deployment "succeeded" while the workload's first requests fail with `AuthorizationFailed`, complicating triage and CI smoke checks. This is a deploy-time hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Add an `azd hook postdeploy` script that polls a representative data-plane call (Cosmos is typically slowest to propagate) until it returns 200, with a bounded retry budget. Block the deployment exit on the probe and repeat for Storage and Search.

**File:** infra/main.bicep:856-870

```bicep
roleAssignments: [
  {
    roleDefinitionIdOrName: '53ca6127-db72-4b80-b1b0-d745d6d5456d' // Azure AI User
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  {
    roleDefinitionIdOrName: '64702f94-c441-49e6-a78b-ef80e0188fee' // Azure AI Developer
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  {
    roleDefinitionIdOrName: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
]
```

**Fix:**

```powershell
# path: infra/scripts/postdeploy-rbac-probe.ps1
# Wired via azure.yaml hooks.postdeploy; runs against {primaryRegion} (and {secondaryRegion} when active/active).
$ErrorActionPreference = 'Stop'
for ($i = 1; $i -le 30; $i++) {
    $result = az cosmosdb sql container show `
        --account-name $env:COSMOS_ACCOUNT `
        --resource-group $env:RG `
        --database-name $env:COSMOS_DB `
        --name $env:COSMOS_CONTAINER 2>$null
    if ($LASTEXITCODE -eq 0) { exit 0 }
    Start-Sleep -Seconds 10
}
Write-Error 'rbac.propagation.timeout'
exit 1
```

**Notes:** Probe runs from the deployment principal's context, which is sufficient to validate that the assignment is materialized. Also cited from OQ-10 in the master plan. Cross-references P2-015 (UAMI standardization).

<span style="font-size: 14px;">**MSFT Reference:** [Azure RBAC role assignments](https://learn.microsoft.com/azure/role-based-access-control/role-assignments)</span>

---

#### P2-017: FastAPI `CORSMiddleware` `allow_origins=["*"]`

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** `src/backend/app.py` registers `CORSMiddleware` with `allow_origins=["*"]`, `allow_credentials=True`, and wildcard methods/headers, overriding the more restrictive Container App `corsPolicy` set in IaC. This behaves identically in single-region and active/active deployments — CORS is a code-defined concern that does not change with region count. Combining `*` origins with `allow_credentials=True` is also rejected by browsers under the CORS spec.

**What does this solve:** Aligns the FastAPI middleware with an explicit allow-list and the Container App `corsPolicy`, so the SPA origin is the only one able to issue credentialed cross-origin requests.

**Impact:** Any browser that sends credentials cross-origin will see the response rejected, while non-credentialed requests from arbitrary origins are accepted. This is a security-posture hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Restrict `allow_origins` to the configured SPA origin from `app_config`, narrow `allow_methods` to the verbs actually used, and align the values with the Container App `corsPolicy` so both layers agree.

**File:** src/backend/app.py:101-105

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Fix:**

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[config.FRONTEND_SITE_NAME],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
```

**Notes:** Cross-references P1-045 (external ingress) — both layers need the same allow-list to be effective. The Container App `corsPolicy` in `infra/main.bicep` should mirror this list.

<span style="font-size: 14px;">**MSFT Reference:** [FastAPI CORS configuration](https://fastapi.tiangolo.com/tutorial/cors/)</span>

---

#### P2-018: Startup identity-coupled with no degraded-mode

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** `src/backend/app.py` constructs its Application Insights client and downstream SDK clients eagerly at startup, all of which depend on Entra token issuance succeeding before the FastAPI process can serve traffic. This behaves identically in single-region and active/active deployments — cold-start failure mode is independent of region count. There is no degraded-mode path that allows the process to start when token acquisition is briefly unavailable.

**What does this solve:** Lets the process boot, expose `/healthz`, and surface a clear degraded indicator instead of crash-looping when token acquisition is briefly unavailable at startup.

**Impact:** Transient identity outages or RBAC-propagation lag (cross-ref P2-016) cause container-app replicas to crash-loop on first start, generating noisy alerts and delaying recovery. This is a startup-robustness hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Defer non-essential client construction to first-use behind a cached factory, add a startup readiness probe that retries on `get_token` errors with exponential backoff, and surface degraded mode in `/healthz` so operators can distinguish "not yet authenticated" from "broken".

**File:** src/backend/app.py:80-96

```python
app = FastAPI(lifespan=lifespan)

frontend_url = config.FRONTEND_SITE_NAME
# Configure Azure Monitor and instrument FastAPI for OpenTelemetry
if config.APPLICATIONINSIGHTS_CONNECTION_STRING:
    configure_azure_monitor(
        connection_string=config.APPLICATIONINSIGHTS_CONNECTION_STRING,
        enable_live_metrics=True
    )
    FastAPIInstrumentor.instrument_app(app, excluded_urls="socket,ws")
    logging.info("Application Insights configured with live metrics and WebSocket filtering")
else:
    logging.warning(
        "No Application Insights connection string found. Telemetry disabled."
    )
```

**Fix:**

```python
from functools import lru_cache
from azure.identity.aio import DefaultAzureCredential

app = FastAPI(lifespan=lifespan)

@lru_cache(maxsize=1)
def credential() -> DefaultAzureCredential:
    return DefaultAzureCredential()

if config.APPLICATIONINSIGHTS_CONNECTION_STRING:
    try:
        configure_azure_monitor(
            connection_string=config.APPLICATIONINSIGHTS_CONNECTION_STRING,
            enable_live_metrics=True,
        )
        FastAPIInstrumentor.instrument_app(app, excluded_urls="socket,ws")
    except Exception as ex:
        logging.error("telemetry.exporter.init_failed", exc_info=ex)
        app.state.identity_degraded = True
else:
    logging.warning("telemetry.degraded=true reason=missing_connection_string")
```

**Notes:** Pairs with a `/healthz` extension that reports `identity=degraded` until the first `get_token` call succeeds. Cross-references P2-011 (telemetry exporter silent drop) and P2-016 (RBAC propagation gate).

<span style="font-size: 14px;">**MSFT Reference:** [Identity and access management design principles](https://learn.microsoft.com/azure/architecture/framework/security/design-identity)</span>

---

#### P2-019: AI Foundry `networkAcls.defaultAction: Allow`

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** AI Foundry is provisioned with `networkAcls.defaultAction: 'Allow'` and empty `virtualNetworkRules` / `ipRules`, regardless of the `enablePrivateNetworking` toggle. This behaves identically in single-region and active/active deployments — ACL configuration is a deploy-time choice unchanged across regions. The result is that the private-networking flag does not actually tighten AI Foundry's ingress posture.

**What does this solve:** Ties the AI Foundry network ACL to the `enablePrivateNetworking` switch so production deployments default to deny and explicit allow rules.

**Impact:** Operators enabling private networking still get a publicly reachable AI Foundry data plane unless they manually edit the resource post-deploy. This is a network-posture hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Set `networkAcls.defaultAction: 'Deny'` whenever `enablePrivateNetworking` is true, populate `virtualNetworkRules` with the workload subnet, and document the chosen posture.

**File:** infra/main.bicep:928-933

```bicep
networkAcls: {
  defaultAction: 'Allow'
  virtualNetworkRules: []
  ipRules: []
}
```

**Fix:**

```bicep
networkAcls: {
  defaultAction: enablePrivateNetworking ? 'Deny' : 'Allow'
  virtualNetworkRules: enablePrivateNetworking ? [
    {
      id: '${virtualNetwork.outputs.resourceId}/subnets/containers'
      ignoreMissingVnetServiceEndpoint: false
    }
  ] : []
  ipRules: []
}
```

**Notes:** Same pattern should be propagated to other Cognitive Services accounts in the template. Cross-references P2-020 (Storage `bypass`) for stack-wide consistency.

<span style="font-size: 14px;">**MSFT Reference:** [WAF networking guidance](https://learn.microsoft.com/azure/well-architected/security/networking)</span>

---

#### P2-020: Storage `networkAcls.bypass: AzureServices`

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The Storage account is provisioned with `networkAcls.bypass: 'AzureServices'` while public network access is otherwise disabled, allowing any first-party Azure service principal to reach the data plane. This behaves identically in single-region and active/active deployments — the bypass setting is a deploy-time posture choice. The configuration is inconsistent with the rest of the stack, which assumes private endpoints are the only ingress path.

**What does this solve:** Forces all Storage data-plane access to flow through the explicit private-endpoint and VNet-rule path, eliminating the implicit Azure-service trust shortcut.

**Impact:** A misconfigured first-party Azure service in the same tenant could reach the Storage account unintentionally, despite public access being disabled. This is a posture-mismatch hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Set `bypass: 'None'`, enumerate any genuinely required Azure-service exceptions explicitly, and pair the change with `defaultAction: 'Deny'` plus VNet rules covering the workload subnets.

**File:** infra/main.bicep:1642-1684

```bicep
blobServices: {
  automaticSnapshotPolicyEnabled: true
  containerDeleteRetentionPolicyDays: 10
  containerDeleteRetentionPolicyEnabled: true
  containers: [
    // ...containers omitted for brevity...
  ]
  deleteRetentionPolicyDays: 9
  deleteRetentionPolicyEnabled: true
  lastAccessTimeTrackingPolicyEnabled: true
}
// networkAcls block (current):
// networkAcls: {
//   bypass: 'AzureServices'
//   defaultAction: 'Deny'
// }
```

**Fix:**

```bicep
networkAcls: {
  bypass: 'None'
  defaultAction: 'Deny'
  virtualNetworkRules: enablePrivateNetworking ? [
    {
      id: '${virtualNetwork.outputs.resourceId}/subnets/containers'
      action: 'Allow'
    }
  ] : []
  ipRules: []
}
```

**Notes:** Audit which Azure services genuinely need access and add named exceptions only for those (typically none in this workload). Cross-references P2-019 for stack-wide ACL consistency.

<span style="font-size: 14px;">**MSFT Reference:** [Storage network security](https://learn.microsoft.com/azure/storage/common/storage-network-security)</span>

---

#### P2-021: No route tables, NAT Gateway, or DDoS plan

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** The VNet is created without route tables, without a NAT Gateway, and without a DDoS Protection plan attached. This behaves identically in single-region and active/active deployments — traffic-shaping controls are a network-design choice unchanged with region count. Outbound flows from Container Apps default to platform SNAT, which is exhaustion-prone under bursty workloads.

**What does this solve:** Adds deterministic outbound egress (NAT Gateway), explicit forced-tunneling support (route tables), and an optional production-grade DDoS posture for the public ingress path.

**Impact:** Bursty outbound traffic can hit SNAT exhaustion under load, surfacing as random `ConnectionResetError` against external dependencies, and the workload has no DDoS Protection Standard for production. This is a network-controls hygiene concern, not a runtime resiliency one.

**Recommended Fix:** Attach a NAT Gateway with a dedicated public IP to the workload subnets, add route tables for forced-tunneling scenarios, and gate DDoS Protection Standard behind a parameter for production parameter files.

**File:** infra/main.bicep:398-407

```bicep
module virtualNetwork 'modules/virtualNetwork.bicep' = if (enablePrivateNetworking) {
  name: take('module.virtualNetwork.${solutionSuffix}', 64)
  params: {
    name: 'vnet-${solutionSuffix}'
    location: location
    tags: tags
    enableTelemetry: enableTelemetry
    addressPrefixes: ['10.0.0.0/8']
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    resourceSuffix: solutionSuffix
  }
}
```

**Fix:**

```bicep
@description('Enable DDoS Protection Standard on the VNet (production parameter files only).')
param enableDdosProtection bool = false

resource natPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (enablePrivateNetworking) {
  name: 'pip-nat-${solutionSuffix}'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource natGw 'Microsoft.Network/natGateways@2023-11-01' = if (enablePrivateNetworking) {
  name: 'nat-${solutionSuffix}-${location}'
  location: location
  sku: { name: 'Standard' }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [{ id: natPip.id }]
  }
}

module virtualNetwork 'modules/virtualNetwork.bicep' = if (enablePrivateNetworking) {
  name: take('module.virtualNetwork.${solutionSuffix}', 64)
  params: {
    name: 'vnet-${solutionSuffix}'
    location: location
    tags: tags
    enableTelemetry: enableTelemetry
    addressPrefixes: [vnetAddressPrefix]
    natGatewayResourceId: natGw.id
    enableDdosProtection: enableDdosProtection
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    resourceSuffix: solutionSuffix
  }
}
```

**Notes:** Cross-references P2-014 (parameterized CIDRs) — the same `vnetAddressPrefix` parameter is reused. NAT Gateway should be deployed per region in active/active so {primaryRegion} and {secondaryRegion} each have their own egress IP.

<span style="font-size: 14px;">**MSFT Reference:** [NAT Gateway overview](https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview)</span>

---

#### P2-022: Insufficient observability for silent-failure triage

**Priority: P2 — Code Quality / Best Practice**

**Resiliency Related:** No

**Issue:** Health probes, correlation IDs, structured logging, dependency-call telemetry, and business metrics are minimal or absent, and some transaction-critical paths still use `print(...)`. Telemetry depth does not change with region count, so silent failures stay silent in both single-region and active/active. The gap is observability hygiene, not failover signalling.

**What does this solve:** Gives operators the trace context, dependency telemetry, and structured fields needed to diagnose silent failures without pulling local logs.

**Impact:** Today, a Cosmos or OpenAI dependency failure can produce a generic 500 with no correlation id or trace context, forcing reproduction in non-production. Adding structured logging and dependency telemetry collapses the triage loop to minutes.

**Recommended Fix:** Add structured JSON logging with `traceId`, `spanId`, `userId`, and `correlationId` propagated via OTel context, replace `print(...)` calls on transaction-critical paths with structured loggers, emit dependency-call telemetry for Cosmos / Search / OpenAI, and add a `correlationId` middleware that surfaces `x-correlation-id` on every response.

**File:** src/backend/app.py:108

```python
import logging, json
class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {"level": record.levelname, "msg": record.getMessage(), "logger": record.name}
        for k in ("traceId", "spanId", "userId", "correlationId"):
            if hasattr(record, k):
                payload[k] = getattr(record, k)
        return json.dumps(payload)
```

**Fix:**

```python
import logging, json
class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {"level": record.levelname, "msg": record.getMessage(), "logger": record.name}
        for k in ("traceId", "spanId", "userId", "correlationId"):
            if hasattr(record, k):
                payload[k] = getattr(record, k)
        return json.dumps(payload)
```

**Notes:** Pair with P2-011 so exporter failures and structured log records arrive at the same backend. See also Application Insights `requests` table for dependency `operation_Id` propagation.

<span style="font-size: 14px;">**MSFT Reference:** [Best practices for Azure Monitor Logs](https://learn.microsoft.com/azure/azure-monitor/best-practices-logs)</span>

---

## P3 — Code Consistency (Non-Resiliency) (14)

#### P3-001: DCR for jumpbox tied to single workspace

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** The jumpbox Data Collection Rule routes operator-only performance and security event telemetry to a single regional Log Analytics workspace, conditional on `enablePrivateNetworking && enableMonitoring`. This is operator-only telemetry; application behavior is unchanged regardless of topology.

**What does this solve:** Ensures jumpbox operator telemetry has parity across regions when DR replication is enabled.

**Impact:** Cosmetic completeness gap when a `{secondaryRegion}` workspace is added later. No application impact today; operator forensics in a `{secondaryRegion}` jumpbox would be missing without a mirrored DCR.

**Recommended Fix:** Mirror the DCR resource into the `{secondaryRegion}` workspace when DR replication is enabled, document the operator-only telemetry scope in module headers, and confirm retention parity across regions.

**File:** infra/main.bicep:481-577

```bicep
module windowsVmDataCollectionRules 'br/public:avm/res/insights/data-collection-rule:0.11.0' = if (enablePrivateNetworking && enableMonitoring) {
  name: take('avm.res.insights.data-collection-rule.${dataCollectionRulesResourceName}', 64)
  params: {
    name: dataCollectionRulesResourceName
    tags: tags
    enableTelemetry: enableTelemetry
    location: dataCollectionRulesLocation
    dataCollectionRuleProperties: {
      kind: 'Windows'
      destinations: {
        logAnalytics: [
          {
            workspaceResourceId: logAnalyticsWorkspaceResourceId
            name: 'la--1264800308'
          }
        ]
      }
      // ...dataSources / dataFlows omitted...
    }
  }
}
```

**Fix:**

```bicep
// Per-region operator telemetry mirroring: emit one DCR per workspace when DR replication is enabled.
module windowsVmDataCollectionRulesPrimary 'br/public:avm/res/insights/data-collection-rule:0.11.0' = if (enablePrivateNetworking && enableMonitoring) {
  name: take('avm.res.insights.dcr.primary.${dataCollectionRulesResourceName}', 64)
  params: {
    name: '${dataCollectionRulesResourceName}-primary'
    location: primaryLogAnalyticsLocation
    dataCollectionRuleProperties: {
      destinations: {
        logAnalytics: [
          { workspaceResourceId: primaryLogAnalyticsWorkspaceResourceId, name: 'la-primary' }
        ]
      }
    }
  }
}

module windowsVmDataCollectionRulesSecondary 'br/public:avm/res/insights/data-collection-rule:0.11.0' = if (enablePrivateNetworking && enableMonitoring && enableDrReplication) {
  name: take('avm.res.insights.dcr.secondary.${dataCollectionRulesResourceName}', 64)
  params: {
    name: '${dataCollectionRulesResourceName}-secondary'
    location: secondaryLogAnalyticsLocation
    dataCollectionRuleProperties: {
      destinations: {
        logAnalytics: [
          { workspaceResourceId: secondaryLogAnalyticsWorkspaceResourceId, name: 'la-secondary' }
        ]
      }
    }
  }
}
```

**Notes:** Operator-only telemetry path. Validate with `az monitor data-collection rule show` in both regions and confirm jumpbox heartbeat ingestion in each workspace.

<span style="font-size: 14px;">**MSFT Reference:** [Data Collection Rule Overview](https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-rule-overview)</span>

---

#### P3-002: Sync and async `CosmosClient` coexist

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** A synchronous `CosmosClient` is constructed in `app_config.get_cosmos_database_client` while the request path uses an async client through `DatabaseFactory`. The sync path is dead code with no production caller; behavior unchanged regardless of topology.

**What does this solve:** Eliminates a duplicated, blocking SDK surface that misleads readers and risks accidental use in async paths.

**Impact:** Maintainability defect. Future contributors may import the wrong client and introduce blocking calls inside the FastAPI event loop.

**Recommended Fix:** Remove the unused synchronous client from `app_config`, standardize on the async client through `DatabaseFactory`, and add a lint rule against `azure.cosmos.CosmosClient` (sync) imports.

**File:** src/backend/common/config/app_config.py:219-237

```python
from azure.cosmos import CosmosClient

class AppConfig:
    def get_cosmos_database_client(self):
        """Get a Cosmos DB client for the configured database."""
        try:
            if self._cosmos_client is None:
                self._cosmos_client = CosmosClient(
                    self.COSMOSDB_ENDPOINT,
                    credential=self.get_azure_credential(self.AZURE_CLIENT_ID),
                )
            if self._cosmos_database is None:
                self._cosmos_database = self._cosmos_client.get_database_client(
                    self.COSMOSDB_DATABASE
                )
            return self._cosmos_database
        except Exception as exc:
            logging.error("Failed to create CosmosDB client: %s", exc)
            raise
```

**Fix:**

```python
# Remove the synchronous import and the get_cosmos_database_client helper.
# All Cosmos access must flow through the async DatabaseFactory.

# (deleted) from azure.cosmos import CosmosClient
# (deleted) AppConfig.get_cosmos_database_client(...)

# Async surface used by the request path (unchanged):
#   from common.database.database_factory import DatabaseFactory
#   db = await DatabaseFactory.get_database()
```

**Notes:** Confirm grep for `azure.cosmos.CosmosClient` returns zero hits after the change. Existing Cosmos integration tests should pass without modification.

<span style="font-size: 14px;">**MSFT Reference:** [Cosmos DB Python Best Practices](https://learn.microsoft.com/azure/cosmos-db/nosql/best-practice-python)</span>

---

#### P3-003: `delete_*` returns `True` regardless of outcome

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** `delete_team` returns `True` even when no document was found, and sibling delete helpers rely on a truthy `AsyncItemPaged`. The caller cannot distinguish "deleted N", "not found", or "transient failure"; behavior unchanged regardless of topology.

**What does this solve:** Restores a meaningful API contract for delete operations so callers can branch on real outcomes.

**Impact:** API-contract gap. UI and reconciliation flows treat missing rows as successes, masking data drift.

**Recommended Fix:** Return a structured `DeleteResult` (count or status enum) distinguishing `deleted`, `not_found`, and `error`; update callers to handle the new contract; add unit tests for each branch.

**File:** src/backend/common/database/cosmosdb.py:317-336

```python
async def delete_team(self, team_id: str) -> bool:
    """Delete a team configuration by team_id."""
    await self._ensure_initialized()
    try:
        team = await self.get_team(team_id)
        print(team)
        if team:
            await self.delete_item(item_id=team.id, partition_key=team.session_id)
        return True
    except Exception as e:
        logging.exception(f"Failed to delete team from Cosmos DB: {e}")
        return False
```

**Fix:**

```python
from enum import Enum

class DeleteStatus(str, Enum):
    DELETED = "deleted"
    NOT_FOUND = "not_found"
    ERROR = "error"

async def delete_team(self, team_id: str) -> DeleteStatus:
    """Delete a team configuration by team_id and report the outcome."""
    await self._ensure_initialized()
    try:
        team = await self.get_team(team_id)
        if team is None:
            return DeleteStatus.NOT_FOUND
        await self.delete_item(item_id=team.id, partition_key=team.session_id)
        return DeleteStatus.DELETED
    except Exception as e:
        logging.exception("Failed to delete team from Cosmos DB: %s", e)
        return DeleteStatus.ERROR
```

**Notes:** Update sibling delete helpers (`delete_data`, etc.) to the same contract. Callers should explicitly handle `NOT_FOUND` without raising.

<span style="font-size: 14px;">**MSFT Reference:** [API Design Best Practices](https://learn.microsoft.com/azure/architecture/best-practices/api-design)</span>

---

#### P3-004: Easy Auth fallback to `sample_user` principal

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** When `x-ms-client-principal-id` is absent, the backend falls back to a `sample_user` principal embedded in source. Latent today because `AUTH_ENABLED=false` by default; behavior unchanged regardless of topology, but the fallback is a hygiene defect.

**What does this solve:** Eliminates a hard-coded development principal so production traffic cannot silently inherit a sample identity.

**Impact:** If Easy Auth is mis-provisioned in either region, requests anonymously map to `sample_user` rather than failing closed. Cross-ref P0-026 / P0-027.

**Recommended Fix:** Fail closed (`401`) when the header is absent in non-dev environments; gate the `sample_user` fallback behind an explicit `DEV_MODE` flag; provision Easy Auth via IaC if production relies on it.

**File:** src/backend/auth/auth_utils.py:5-32

```python
def get_authenticated_user_details(request_headers):
    user_object = {}
    if "x-ms-client-principal-id" not in request_headers:
        logging.info("No user principal found in headers")
        # if it's not, assume we're in development mode and return a default user
        from . import sample_user
        raw_user_object = sample_user.sample_user
    else:
        raw_user_object = {k: v for k, v in request_headers.items()}
    # ...normalize headers and populate user_object...
    return user_object
```

**Fix:**

```python
import os
from fastapi import HTTPException, status

def get_authenticated_user_details(request_headers):
    user_object = {}
    if "x-ms-client-principal-id" not in request_headers:
        if os.getenv("DEV_MODE", "false").lower() != "true":
            logging.warning("Missing x-ms-client-principal-id header; failing closed")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required",
            )
        from . import sample_user
        raw_user_object = sample_user.sample_user
    else:
        raw_user_object = {k: v for k, v in request_headers.items()}
    # ...normalize headers and populate user_object...
    return user_object
```

**Notes:** Cross-ref P0-026 (Easy Auth not provisioned) and P0-027 (auth disabled by default). The `sample_user` module should be excluded from production images or guarded by `DEV_MODE`.

<span style="font-size: 14px;">**MSFT Reference:** [Configure App Service Auth (AAD)](https://learn.microsoft.com/azure/app-service/configure-authentication-provider-aad)</span>

---

#### P3-005: MCP `JWTVerifier` JWKS unreachable when auth enabled

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** When `ENABLE_AUTH=true`, FastMCP `JWTVerifier` rejects requests if it cannot fetch JWKS from Entra. Latent today because auth is disabled by default; behavior unchanged regardless of topology, but a JWKS outage with no cache fallback is a completeness gap.

**What does this solve:** Adds a cached-JWKS reachability probe so JWKS unavailability surfaces in `/health` rather than as opaque 401s.

**Impact:** Once auth is enabled, transient JWKS fetch failures translate directly to broad `401` responses with no operator signal. Cross-ref P0-028.

**Recommended Fix:** Cache JWKS aggressively with TTL and refresh-on-failure semantics, add a JWKS reachability probe to `/health`, and document the auth-on rollout path.

**File:** src/mcp_server/mcp_server.py:33-50

```python
def create_fastmcp_server():
    """Create and configure FastMCP server."""
    auth = None
    if config.enable_auth:
        auth_config = {
            "jwks_uri": config.jwks_uri,
            "issuer": config.issuer,
            "audience": config.audience,
        }
        if all(auth_config.values()):
            auth = JWTVerifier(
                jwks_uri=auth_config["jwks_uri"],
                issuer=auth_config["issuer"],
                algorithm="RS256",
                audience=auth_config["audience"],
            )
    mcp_server = factory.create_mcp_server(name=config.server_name, auth=auth)
    return mcp_server
```

**Fix:**

```python
import time, httpx

_JWKS_CACHE = {"keys": None, "fetched_at": 0.0}
_JWKS_TTL_SECONDS = 3600

async def _refresh_jwks(jwks_uri: str) -> bool:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(jwks_uri)
            r.raise_for_status()
            _JWKS_CACHE["keys"] = r.json()
            _JWKS_CACHE["fetched_at"] = time.time()
            return True
    except Exception as exc:
        logger.warning("JWKS refresh failed: %s", exc)
        return False

def create_fastmcp_server():
    auth = None
    if config.enable_auth:
        if not all([config.jwks_uri, config.issuer, config.audience]):
            raise RuntimeError("ENABLE_AUTH=true but JWKS/issuer/audience are unset; failing closed")
        auth = JWTVerifier(
            jwks_uri=config.jwks_uri,
            issuer=config.issuer,
            algorithm="RS256",
            audience=config.audience,
        )
    return factory.create_mcp_server(name=config.server_name, auth=auth)

# /health probe should return 503 if (time.time() - _JWKS_CACHE["fetched_at"]) > _JWKS_TTL_SECONDS
# and a fresh _refresh_jwks() call also fails.
```

**Notes:** Cross-ref P0-028 (MCP unauthenticated when JWKS env unset). Pair with P3-014 to flip the default-false flag for production.

<span style="font-size: 14px;">**MSFT Reference:** [Protected Web API Scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P3-006: External base-image registries used at build time

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Image builds depend on Docker Hub (`python:3.11-slim-bullseye`), MCR, and `ghcr.io` (`astral-sh/uv:0.6.3`) for base images. Rebuild-time concern only; live runtime is unaffected once images are in ACR, so behavior is unchanged regardless of topology.

**What does this solve:** Internalizes the supply chain so a from-source rebuild does not depend on three independent public registries.

**Impact:** A from-source DR rebuild creates three independent supply-chain dependencies. Hygiene gap, not a runtime defect.

**Recommended Fix:** Mirror base images to a private registry (ACR), pin base images by `@sha256:` digest in all Dockerfiles, and track a CVE / refresh cadence.

**File:** src/backend/Dockerfile:2

```dockerfile
FROM python:3.11-slim-bullseye AS base
WORKDIR /app

FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.6.3 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
```

**Fix:**

```dockerfile
# Base images mirrored to the internal ACR and pinned by digest.
ARG INTERNAL_ACR=biabcontainerreg.azurecr.io
FROM ${INTERNAL_ACR}/mirror/python:3.11-slim-bullseye@sha256:<digest> AS base
WORKDIR /app

FROM base AS builder
COPY --from=${INTERNAL_ACR}/mirror/astral-sh/uv:0.6.3@sha256:<digest> /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
```

**Notes:** Apply uniformly across `src/backend/Dockerfile`, `src/mcp_server/Dockerfile`, and `src/App/Dockerfile`. Validate with a build that has public registries blocked.

<span style="font-size: 14px;">**MSFT Reference:** [Container Registry Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)</span>

---

#### P3-007: PyPI / npm reachable at deploy-script time

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Operator post-deploy scripts and frontend packaging run `pip install -r infra/scripts/requirements.txt` and `npm install` against public registries with no `--index-url` / `--registry` overrides. Rebuild- and operator-script concern only; behavior unchanged regardless of topology at runtime.

**What does this solve:** Pins and pre-bakes deploy-time dependencies so a `{secondaryRegion}` operator network outage to PyPI / npm does not block re-running scripts.

**Impact:** Operator-script reproducibility in `{secondaryRegion}` is gated on PyPI / npm reachability. Hygiene gap, not a runtime defect.

**Recommended Fix:** Pin `azure-core` and other deps in `infra/scripts/requirements.txt`, pre-install dependencies into images where feasible, and configure private package mirrors for DR scenarios.

**File:** infra/scripts/Selecting-Team-Config-And-Data.ps1:542

```powershell
# Install the requirements
Write-Host "Installing requirements"
pip install --quiet -r infra/scripts/requirements.txt
Write-Host "Requirements installed"
```

**Fix:**

```powershell
# Install the requirements from the internal mirror, with pinned versions.
Write-Host "Installing requirements"
$indexUrl = $env:INTERNAL_PYPI_INDEX_URL
if ([string]::IsNullOrWhiteSpace($indexUrl)) {
    Write-Warning "INTERNAL_PYPI_INDEX_URL not set; falling back to public PyPI"
    pip install --quiet -r infra/scripts/requirements.txt
} else {
    pip install --quiet --index-url $indexUrl --no-deps -r infra/scripts/requirements.txt
}
Write-Host "Requirements installed"
```

**Notes:** Apply the same pattern to frontend `npm install` (use `--registry $env:INTERNAL_NPM_REGISTRY`). Cross-ref P2-012 for SDK pinning alignment.

<span style="font-size: 14px;">**MSFT Reference:** [Container Registry Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)</span>

---

#### P3-008: Microsoft Entra ID is the global identity plane

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Microsoft Entra ID mediates every Azure data-plane call across all shared dependencies. Restated for completeness; behavior unchanged regardless of topology, with no discrete actionable fix beyond identity-related items already listed.

**What does this solve:** Records the cross-cutting global control plane so reviewers do not infer it is per-region.

**Impact:** Documentation-only completeness item; operational risk is fully covered by the cross-referenced findings.

**Recommended Fix:** No discrete remediation. Cross-ref P1-007 (RBAC), P1-034 (token errors), P1-043 (token retry).

**File:** src/backend/common/config/app_config.py:8

```python
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.identity.aio import (
    DefaultAzureCredential as DefaultAzureCredentialAsync,
    ManagedIdentityCredential as ManagedIdentityCredentialAsync,
)
# All Azure data-plane access flows through Entra-issued tokens via these credentials.
```

**Fix:**

```python
# No code change for this finding. See:
#   P1-007 — RBAC role assignments per region
#   P1-034 — token acquisition error handling
#   P1-043 — token retry / refresh discipline
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.identity.aio import (
    DefaultAzureCredential as DefaultAzureCredentialAsync,
    ManagedIdentityCredential as ManagedIdentityCredentialAsync,
)
```

**Notes:** Cross-ref P3-013 for the related tenant-id duplication. No source change; this finding is recorded so the global control plane is explicit in the report.

<span style="font-size: 14px;">**MSFT Reference:** [Protected Web API Scenario](https://learn.microsoft.com/azure/active-directory/develop/scenario-protected-web-api-overview)</span>

---

#### P3-009: Container images use mutable `latest_v4` tag

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Backend, MCP, and frontend image references use the mutable `latest_v4` tag rather than an immutable `@sha256:` digest. Image-identity drift across cold-starts is a deploy-time concern; behavior unchanged regardless of topology once images are pinned.

**What does this solve:** Pins deployments to immutable image digests so `{primaryRegion}` and `{secondaryRegion}` revisions are byte-identical.

**Impact:** A cold-start in `{secondaryRegion}` may pull a different layer set than `{primaryRegion}` if the tag is moved between deploys. Image-integrity hygiene defect.

**Recommended Fix:** Reference images by `@sha256:` digest in `main.bicep` and `main_custom.bicep`; have the build pipeline emit digests as Bicep outputs / parameter overrides; recommend digest-pinning as the deployment contract.

**File:** infra/main.bicep:141

```bicep
@description('Optional. The Container Image Tag to deploy on the backend.')
param backendContainerImageTag string = 'latest_v4'

@description('Optional. The Container Registry hostname where the docker images for the frontend are located.')
param frontendContainerRegistryHostname string = 'biabcontainerreg.azurecr.io'

@description('Optional. The Container Image Name to deploy on the frontend.')
param frontendContainerImageName string = 'macaefrontend'
```

**Fix:**

```bicep
@description('Required. The immutable digest (sha256:...) of the backend container image. Emitted by the build pipeline.')
param backendContainerImageDigest string

@description('Required. The immutable digest (sha256:...) of the frontend container image. Emitted by the build pipeline.')
param frontendContainerImageDigest string

// Compose the full reference at use-site:
//   '${backendContainerRegistryHostname}/${backendContainerImageName}@${backendContainerImageDigest}'
//   '${frontendContainerRegistryHostname}/${frontendContainerImageName}@${frontendContainerImageDigest}'
// Apply the same pattern in main_custom.bicep for backend, MCP, and frontend.
```

**Notes:** Digest-pinning is the recommended remediation for image integrity. Validate with `az containerapp show` confirming a digest-pinned image, and that re-deploy with the same digest yields identical revision content.

<span style="font-size: 14px;">**MSFT Reference:** [Container Registry Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)</span>

---

#### P3-010: `HealthCheckMiddleware` registered with empty password

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** The middleware is constructed with `password=""` and `checks={}`. Inert today, but an empty-string credential literal embedded in middleware construction is a hygiene defect; behavior unchanged regardless of topology.

**What does this solve:** Removes a literal credential parameter from source so no constant credential ever appears at the middleware call site.

**Impact:** Even though inert, the empty-string literal is misleading and risks being replaced with a non-empty hardcoded value during a future edit.

**Recommended Fix:** Remove the `password` argument from the call site explicitly — even though it is currently inert. Drop the parameter from the middleware signature, or resolve it from `app_config` / Key Vault and never from a literal. Pair with real dependency probes (cross-ref P0-025).

**File:** src/backend/app.py:108

```python
# Configure health check
app.add_middleware(HealthCheckMiddleware, password="", checks={})
# v4 endpoints
app.include_router(app_v4)
logging.info("Added health check middleware")
```

**Fix:**

```python
# Configure health check — no literal credentials at the call site.
app.add_middleware(
    HealthCheckMiddleware,
    checks={
        "cosmos": cosmos_probe,
        "foundry": foundry_probe,
        "openai": openai_probe,
        "search": search_probe,
        "storage": storage_probe,
    },
)
# (removed) password="" literal — middleware signature should drop the parameter,
# or read it from app_config if a real value is ever required.
app.include_router(app_v4)
logging.info("Added health check middleware")
```

**Notes:** Cross-ref P0-025 (synthetic OK on `/healthz`). Confirm grep returns zero hits for empty-string credential literals in middleware constructors.

<span style="font-size: 14px;">**MSFT Reference:** [Secrets Management (Well-Architected)](https://learn.microsoft.com/azure/well-architected/security/secrets)</span>

---

#### P3-011: Uniform single-rule outbound NSGs across subnets

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** All subnets share the same single-rule outbound NSG pattern (`deny-hop-outbound` for 22 / 3389 only) with no per-subnet differentiation between apps, jumpbox, and private endpoints. Segmentation hygiene; behavior unchanged regardless of topology and identical across `{primaryRegion}` and `{secondaryRegion}`.

**What does this solve:** Differentiates egress posture per subnet so each tier has least-privilege rules instead of a uniform pattern.

**Impact:** Lateral-movement and exfiltration surface is broader than necessary. No live runtime defect; segmentation completeness gap.

**Recommended Fix:** Differentiate egress rules per subnet (apps vs jumpbox vs private endpoints), add deny-by-default with explicit allow rules, and document segmentation expectations.

**File:** infra/modules/virtualNetwork.bicep:19

```bicep
param subnets subnetType[] = [
  {
    name: 'backend'
    addressPrefixes: ['10.0.0.0/27']
    networkSecurityGroup: {
      name: 'nsg-backend'
      securityRules: [
        {
          name: 'deny-hop-outbound'
          properties: {
            access: 'Deny'
            destinationAddressPrefix: '*'
            destinationPortRanges: ['22', '3389']
            direction: 'Outbound'
            priority: 200
            protocol: 'Tcp'
            sourceAddressPrefix: 'VirtualNetwork'
            sourcePortRange: '*'
          }
        }
      ]
    }
  }
  // ...containers, webserverfarm subnets repeat the same single rule...
]
```

**Fix:**

```bicep
param subnets subnetType[] = [
  {
    name: 'backend'
    addressPrefixes: ['10.0.0.0/27']
    networkSecurityGroup: {
      name: 'nsg-backend'
      securityRules: [
        { name: 'deny-hop-outbound', properties: { access: 'Deny', direction: 'Outbound', priority: 200, protocol: 'Tcp', sourceAddressPrefix: 'VirtualNetwork', sourcePortRange: '*', destinationAddressPrefix: '*', destinationPortRanges: ['22', '3389'] } }
        { name: 'allow-azure-services-https', properties: { access: 'Allow', direction: 'Outbound', priority: 300, protocol: 'Tcp', sourceAddressPrefix: 'VirtualNetwork', sourcePortRange: '*', destinationAddressPrefix: 'AzureCloud', destinationPortRange: '443' } }
        { name: 'deny-all-outbound', properties: { access: 'Deny', direction: 'Outbound', priority: 4000, protocol: '*', sourceAddressPrefix: '*', sourcePortRange: '*', destinationAddressPrefix: '*', destinationPortRange: '*' } }
      ]
    }
  }
  // jumpbox subnet: allow only RDP from operator bastion + AzureCloud:443; deny-all otherwise.
  // privateEndpoints subnet: deny all outbound by default; ingress only.
]
```

**Notes:** Validate per-subnet differentiation with `az network nsg rule list`. Document the segmentation contract alongside the module.

<span style="font-size: 14px;">**MSFT Reference:** [Network Security Best Practices](https://learn.microsoft.com/azure/security/fundamentals/network-best-practices)</span>

---

#### P3-012: No NSG flow logs or Network Watcher

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Diagnostic settings exist on the VNet only; no `flowLogs` resource or Network Watcher is provisioned. Network forensics depth gap; behavior unchanged regardless of topology.

**What does this solve:** Adds NSG flow logs and Network Watcher so operators can perform post-incident traffic analysis in either region.

**Impact:** Incident response loses 5-tuple visibility for in-region and cross-region traffic. Forensics completeness gap.

**Recommended Fix:** Provision a Network Watcher and NSG flow logs to a Storage account in each region, enable Traffic Analytics if licensed, and document retention.

**File:** infra/modules/virtualNetwork.bicep:19

```bicep
// VNet diagnostic settings exist; no flowLogs resource provisioned.
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: name
}
// (no Microsoft.Network/networkWatchers/flowLogs resource present)
```

**Fix:**

```bicep
@description('Storage account for NSG flow logs (per region).')
param flowLogsStorageAccountId string

@description('Enable NSG flow logs and Traffic Analytics.')
param enableFlowLogs bool = true

resource networkWatcher 'Microsoft.Network/networkWatchers@2023-09-01' = if (enableFlowLogs) {
  name: 'nw-${location}'
  location: location
}

resource nsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-09-01' = [for nsg in nsgs: if (enableFlowLogs) {
  parent: networkWatcher
  name: 'fl-${nsg.name}'
  location: location
  properties: {
    targetResourceId: nsg.id
    storageId: flowLogsStorageAccountId
    enabled: true
    format: { type: 'JSON', version: 2 }
    retentionPolicy: { days: 30, enabled: true }
  }
}]
```

**Notes:** Provision per region. Confirm flow log blobs land in the configured Storage account post-deploy; document retention.

<span style="font-size: 14px;">**MSFT Reference:** [NSG Flow Logging Overview](https://learn.microsoft.com/azure/network-watcher/network-watcher-nsg-flow-logging-overview)</span>

---

#### P3-013: `AZURE_TENANT_ID` and `TENANT_ID` duplicated

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** Two `AppConfig` attributes (`AZURE_TENANT_ID` and `TENANT_ID`) resolve to the same `AZURE_TENANT_ID` env var, and `get_tenantid` exists only as dead code. Maintainability concern; behavior unchanged regardless of topology.

**What does this solve:** Collapses two aliases to a single canonical attribute so reviewers and tooling see one source of truth.

**Impact:** Misleads reviewers and increases the chance of drift between callers that read `AZURE_TENANT_ID` vs `TENANT_ID`. Cross-ref P1-042.

**Recommended Fix:** Drop the duplicate `TENANT_ID` attribute, keep `AZURE_TENANT_ID` as canonical, remove or wire up `get_tenantid`, and add a lint check for unused config helpers.

**File:** src/backend/common/config/app_config.py:27

```python
class AppConfig:
    def __init__(self):
        # Azure authentication settings
        self.AZURE_TENANT_ID = self._get_optional("AZURE_TENANT_ID")
        self.AZURE_CLIENT_ID = self._get_optional("AZURE_CLIENT_ID")
        # ... many lines later ...
        self.TENANT_ID = self._get_optional("AZURE_TENANT_ID")
        self.CLIENT_ID = self._get_optional("AZURE_CLIENT_ID")
```

**Fix:**

```python
class AppConfig:
    def __init__(self):
        # Single canonical attribute for the Entra tenant id.
        self.AZURE_TENANT_ID = self._get_optional("AZURE_TENANT_ID")
        self.AZURE_CLIENT_ID = self._get_optional("AZURE_CLIENT_ID")
        # (removed) self.TENANT_ID alias
        # (removed) self.CLIENT_ID alias
        # All callers must read AZURE_TENANT_ID / AZURE_CLIENT_ID directly.
        # (removed) get_tenantid dead-code helper
```

**Notes:** Cross-ref P1-042. Confirm both attributes are env-sourced (no literal tenant id in source or `.env.example`). Update any caller of `cfg.TENANT_ID` / `cfg.CLIENT_ID` to use the canonical names.

<span style="font-size: 14px;">**MSFT Reference:** [Secrets Management (Well-Architected)](https://learn.microsoft.com/azure/well-architected/security/secrets)</span>

---

#### P3-014: Default `ENABLE_AUTH=false` and `MCP_ENABLE_AUTH=false`

**Priority: P3 — Code Consistency**

**Resiliency Related:** No

**Issue:** IaC and shipped-config defaults disable auth on both the web app and the MCP server. Posture default; behavior unchanged regardless of topology, but a `{secondaryRegion}` cold DR deploy will inherit the insecure default unless operators override it.

**What does this solve:** Makes the production parameter sets secure-by-default so a cold deploy in either region requires explicit opt-out for dev only.

**Impact:** Risk amplifies during DR cold deploy if defaults are not flipped at deploy time. Cross-ref P0-026, P0-028.

**Recommended Fix:** Default `ENABLE_AUTH=true` and `MCP_ENABLE_AUTH=true` in production parameter sets; update `.env.example` and `docker-compose.yml`; keep dev overrides explicit; add a parameter-file lint that asserts `ENABLE_AUTH=true` for prod profiles.

**File:** infra/main.bicep:1466

```bicep
{
  name: 'ENABLE_AUTH'
  value: 'false'
}
{
  name: 'TENANT_ID'
  value: tenant().tenantId
}
{
  name: 'CLIENT_ID'
  value: userAssignedIdentity!.outputs.clientId
}
```

**Fix:**

```bicep
@description('Enable authentication for the web app and MCP server. Defaults to true for production parameter sets.')
param enableAuth bool = true

// MCP container app env:
{
  name: 'ENABLE_AUTH'
  value: string(enableAuth)
}
{
  name: 'TENANT_ID'
  value: tenant().tenantId
}
{
  name: 'CLIENT_ID'
  value: userAssignedIdentity!.outputs.clientId
}
// Web app env mirrors the same default:
//   { name: 'ENABLE_AUTH', value: string(enableAuth) }
// Production parameter files (main.parameters.json, main.waf.parameters.json):
//   "enableAuth": { "value": true }
// Dev overrides remain explicit (.env.example, docker-compose.yml).
```

**Notes:** Cross-ref P0-026 (Easy Auth not provisioned) and P0-028 (MCP unauthenticated when JWKS env unset). Production parameter sets must default `true`; dev overrides should remain explicit.

<span style="font-size: 14px;">**MSFT Reference:** [Configure App Service Auth (AAD)](https://learn.microsoft.com/azure/app-service/configure-authentication-provider-aad)</span>

---

[Back to Top](#top)

---



# 4. IaC Gap Analysis

The Multi-Agent-Custom-Automation-Engine-Solution-Accelerator infrastructure is expressed in Bicep with Azure Verified Modules (AVM) under `infra/main.bicep` and `infra/modules/`, supplemented by operator post-deploy PowerShell scripts under `infra/scripts/`. The repository's IaC is single-region by construction: a single `location` parameter is threaded through every module, AVM module versions and SKUs are pinned, and feature flags (`enableRedundancy`, `enablePrivateNetworking`, `enableMonitoring`, `enableScalability`) gate optional posture rather than per-region replication. Visible in repo: AI Foundry / Project / Agent Service provisioning, Cosmos DB account with serverless capability and a paired-region map for HA, AI Search SKU and replica/partition counts, Storage account AVM call, Container Apps environment and Container App revision config, App Service plan and Web App config, Application Insights and Log Analytics workspace, Container Apps and Web App env-var injection (Cosmos / Foundry / Search / Storage FQDNs and the external `biabcontainerreg.azurecr.io` registry), VNet/subnet CIDRs, NSG rules, Private Endpoints, Bastion + Windows jumpbox + PPG, a single User-Assigned Managed Identity (UAMI) and its RBAC role assignments, App Service Easy Auth toggles, and MCP JWT/JWKS env config. Not visible in repo: any Global Load Balancer / Front Door / Traffic Manager profile, Azure Key Vault, customer-owned ACR mirror, secondary-region DNS records, per-region parameter set (`primaryLocation` / `secondaryLocation`), ACR geo-replication, Cosmos backup-policy override, Storage geo-redundant SKU pin, multi-region read/write topology, conflict-resolution policy, secondary-region Cosmos Private Endpoint, secondary-region Bastion / jumpbox peer, or operator runbooks for cross-region failover, RBAC propagation, and Foundry agent metadata reseeding. The result is that all multi-region resiliency decisions fall outside the repo and onto the operator and platform.

## Available to Review

| Configuration | Current Value | Resiliency Assessment |
| --- | --- | --- |
| `location` parameter | Single string parameter, no `primaryLocation` / `secondaryLocation` split | Threaded through every AVM module; the deployment cannot be projected into a second region without forking the parameter set (P0-005, P1-013, P1-014, P1-017) |
| `enableRedundancy` flag | `bool = false` default | Not threaded through every AVM module call (notably Storage); zone redundancy on Container Apps, App Service, Bastion, Cosmos, AI Search is gated off by default (P0-007, P1-003, P1-004, P1-006, P1-008, P1-020) |
| `enablePrivateNetworking` flag | `bool = false` default | Gates the entire VNet / NSG / Private DNS / Private Endpoint / Bastion / jumpbox stack; when false the platform is fully public; when true the PE/DNS topology is single-region only (P0-004, P0-030) |
| `enableMonitoring` flag | `bool = false` default | Gates Application Insights component and Log Analytics workspace creation; when false the platform has no first-class observability (P2-001, P2-002, P3-001) |
| AI Foundry account (`Microsoft.CognitiveServices/accounts`) | AVM `avm/res/cognitive-services/account` provisioned at `azureAiServiceLocation`; `networkAcls.defaultAction: Allow` | Single-region Foundry control plane; no secondary account in `{secondaryRegion}`; `Allow` default action exposes the data plane to the public Internet (P0-001, P0-002, P0-006, P2-019) |
| AI Foundry Project + Agent Service | Single project, agent metadata seeded once via deployment script | Agent IDs are not portable to a second project; reseeding required during failover (P0-002, P1-039) |
| Azure OpenAI deployments (`gpt-4.1-mini`, `gpt-4.1`, `o4-mini`) | Deployed under the single Foundry account at `azureAiServiceLocation` | All inference traffic projects into one region; no PTU pinning, no secondary deployment (P1-001) |
| Cosmos DB account | AVM `avm/res/document-db/database-account` with `capabilities: [{ name: 'EnableServerless' }]`; `cosmosDbZoneRedundantHaRegionPairs` map for HA | Serverless cannot be promoted to multi-region writes in place; HA region resolved from a hardcoded 10-row pair table; no secondary write region (P0-003, P0-013, P1-013, P1-023, P2-003, P2-004, P2-007) |
| Cosmos Private Endpoint | PE only in primary VNet; Private DNS zone linked to primary VNet only | If Cosmos fails over to its paired region, the PE remains anchored to the primary VNet and DNS resolution breaks for any caller in `{secondaryRegion}` (P0-030, P1-029) |
| AI Search service | AVM `avm/res/search/search-service` with `replicaCount: 1`, `partitionCount: 1`, `publicNetworkAccess: 'Enabled'` (gated by `enablePrivateNetworking`) | Below the SLA-bearing 2×3 minimum; single-region; no replica in `{secondaryRegion}`; index rebuild required during failover (P1-002, P1-016) |
| Storage account | AVM `avm/res/storage/storage-account` invoked without `skuName`; `enableRedundancy` not threaded; `networkAcls.bypass: 'AzureServices'` | Default LRS; no GZRS / RA-GZRS pin; trusted-services bypass leaves a public ingress path even when private networking is on (P1-006, P1-020, P2-008, P2-020) |
| Container Apps Environment | AVM `avm/res/app/managed-environment` with `zoneRedundant: enableRedundancy`; `revisionsMode: 'Single'`; `ingressExternal: true` on Container Apps | Zone redundancy off by default; single-revision mode + external ingress on backend means there is no ingress isolation and no graceful drain on revision swap (P1-003, P1-025, P1-045) |
| App Service Plan + Web App | AVM `avm/res/web/serverfarm` + `avm/res/web/site`; `publicNetworkAccess: 'Enabled'`; single region | Frontend Web App is publicly addressable; no per-region App Service Plan; no GLB-fronted dual-region site (P1-004, P1-046) |
| Application Insights | AVM `avm/res/insights/component` (single component) | One regional component; telemetry from a `{secondaryRegion}` workload would land in the primary-region component (P2-001, P2-011) |
| Log Analytics workspace | AVM `avm/res/operational-insights/workspace`; `replicaRegionPairs` map for cross-region replica | Workspace is created in primary region; replica region is chosen from a hardcoded 10-row pair table; operator cannot override at deploy time (P1-014, P2-002) |
| Container Registry reference | `backendContainerRegistryHostname`, `frontendContainerRegistryHostname`, `MCPContainerRegistryHostname` all default to `biabcontainerreg.azurecr.io` | External Microsoft-operated ACR baked into Container Apps and Web App env vars; no customer-controlled ACR; mutable `latest_v4` tag (P0-022, P1-005, P1-012, P1-019, P1-038, P3-009) |
| Virtual Network + subnets | `infra/modules/virtualNetwork.bicep` creates VNet with `addressPrefixes: ['10.0.0.0/8']` and 5 hardcoded subnet CIDRs | `/8` consumes a private-IP-space block far in excess of need; subnet CIDRs are not parameterized; cannot peer cleanly with another `10/8` deployment (P2-014, P3-011, P3-012) |
| Bastion + Windows jumpbox | AVM bastion-host + virtual-machine; `virtualMachineAvailabilityZone = 1`; PPG attached; jumpbox admin password param marked `string?` with literal fallback in scripts | Bastion zone redundancy not configured; jumpbox pinned to AZ 1 + PPG; single-zone admin path; password literal in script when param empty (P1-008, P1-009, P1-015, P0-023) |
| User-Assigned Managed Identity + role assignments | Single UAMI `id-${solutionSuffix}`; role assignments scoped to the primary resource group only | Same UAMI is the principal across Cosmos / Foundry / Search / Storage data planes; role assignments do not extend to a `{secondaryRegion}` resource group (P1-007, P1-044, P2-015, P2-016) |
| App Service Easy Auth + MCP JWT/JWKS env | `WEBSITE_AUTH_AAD_ALLOWED_TENANTS` single-tenant; `MCP_JWKS_URI` / `MCP_AUTH_ISSUER` / `MCP_AUTH_AUDIENCE` derived from one Easy Auth issuer; `ENABLE_AUTH=false` and `MCP_ENABLE_AUTH=false` defaults | Single-tenant config; MCP JWT validation is wired but disabled by default; no tenant-pinning for the frontend during failover (P0-026, P0-028, P1-010, P1-011, P3-014) |
| `/healthz` middleware config | `HealthCheckMiddleware` registered with `checks={}` and an empty-string `password` literal | Always returns healthy regardless of dependency state; no GLB-grade readiness contract; secret is empty literal in code (P0-021, P0-025, P1-040, P3-010) |
| Container env-var bindings | Backend Container App `env` block hardcodes `COSMOSDB_ENDPOINT`, `AZURE_AI_AGENT_ENDPOINT`, `AZURE_SEARCH_SERVICE_ENDPOINT`, `AZURE_STORAGE_ACCOUNT_NAME`, all derived from primary-region module outputs | Backend cannot reach a secondary-region data plane without a redeploy; no env-var indirection through GLB / runtime config (P0-027, P0-029, P1-017, P1-042) |
| AVM module references | `br/public:avm/...` pinned at minor versions across `main.bicep` | Cross-repo supply-chain dependency on the public AVM registry; module bumps require manual pinning review (P1-036) |
| Operator post-deploy scripts | `infra/scripts/Selecting-Team-Config-And-Data.ps1` runs `az storage blob upload-batch --overwrite` against the deployed Storage account; agent metadata seeding script writes Foundry agent IDs | Cross-region deployment requires the operator to re-run these scripts against the secondary stack; `--overwrite` has no concurrency control and `latest_v4` images are pulled at run time (P2-009, P3-007) |
| GitHub Actions workflows | Workflows under `.github/workflows/` reference third-party actions by tag, not commit SHA | Tag-pinned third-party actions can be re-pointed by their owners; no SHA pinning enforces an immutable supply chain (P2-013) |

## Not Available (External Repos / Platform / Operator)

| Configuration | Needed For |
| --- | --- |
| Global Load Balancer / Front Door / Traffic Manager profile | Failover decision-maker between `{primaryRegion}` and `{secondaryRegion}`; required for the readiness contract that `/healthz` is meant to feed (P0-021, P0-024) |
| Customer-owned Azure Container Registry with geo-replication | Replacement for the external `biabcontainerreg.azurecr.io` so image pulls survive cross-region failover and SHA-pinned cold-starts (P0-022, P1-005, P1-012, P1-019) |
| Azure Key Vault | Source for the jumpbox admin password and any other secret currently inlined in scripts or env defaults; required to remove the empty-string `password` literal in `HealthCheckMiddleware` (P0-023, P3-010) |
| Cosmos DB provisioned-throughput migration target | Serverless Cosmos cannot be promoted to multi-region writes in place; a migration to provisioned RU/s is a prerequisite for any multi-region topology (P0-013, P1-023) |
| Cosmos multi-region read / write topology + conflict-resolution policy | `locations[]` array, `enableMultipleWriteLocations`, and a `conflictResolutionPolicy` are required to enable geo-replication on the Cosmos account (P0-003, P1-018, P1-021, P1-023, P2-004) |
| ACR geo-replication configuration + digest-pinned image references | Required for cold-start in `{secondaryRegion}` and for an immutable supply chain (current refs use mutable `latest_v4`) (P1-005, P3-009) |
| Per-region parameter sets / `primaryLocation` + `secondaryLocation` Bicep parameters | Replacement for the single `location` parameter and the hardcoded `cosmosDbZoneRedundantHaRegionPairs` and `replicaRegionPairs` tables (P0-005, P1-013, P1-014, P1-017) |
| Cross-region DNS records / FQDN aliasing | Required for the GLB to address per-region origins for the Web App, Container App, and MCP server (P0-024, P1-040) |
| Cosmos Private Endpoint in `{secondaryRegion}` and Private DNS zone link to both VNets | Required to keep Cosmos traffic on private endpoints during failover; without it the secondary VNet cannot resolve the Cosmos account privately (P0-030, P1-029) |
| Operator runbooks for failover, RBAC propagation readiness, and Foundry agent metadata reseeding | Required during cutover; the repo has no readiness gate for Entra RBAC propagation and no reseeding flow for agent IDs (P1-007, P1-039, P2-016) |
| Azure Monitor / Log Analytics replica region operator override | Required to align telemetry residency with the chosen secondary region; the replica region is hardcoded in `replicaRegionPairs` (P1-014, P2-002) |
| Continuous backup / PITR posture for Cosmos and blob versioning + restore policy + change feed for Storage | Required for an explicit RPO contract; serverless Cosmos blocks PITR and the Storage account has no versioning / restore policy (P2-007, P2-008) |
| Service Bus / Web PubSub / Redis Pub-Sub backplane | Required as the cross-replica WebSocket and orchestration backplane to replace the in-memory connection map, in-memory checkpoint storage, and `asyncio.Event` pre-approval state (P0-008, P0-009, P0-010, P0-011, P0-018, P0-019, P0-020, P1-027, P1-028) |
| Azure Bastion peer + jumpbox peer in `{secondaryRegion}` | Operator access path during a primary-region outage; current bastion + jumpbox are single-region and AZ-1-pinned (P1-008, P1-009, P1-015) |

[Back to Top](#top)

---

# 5. Full Finding Matrix

| ID | Priority | Category | Finding | Repo(s) |
| --- | --- | --- | --- | --- |
| [P0-001](#p0-001-foundry--ai-services-account-is-single-region) | **P0** | AI Foundry & OpenAI Multi-Region Provisioning | Foundry / AI Services account is single-region | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-002](#p0-002-foundry-project--agent-service-single-instance) | **P0** | AI Foundry & OpenAI Multi-Region Provisioning | Foundry Project + Agent Service single-instance | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-003](#p0-003-cosmos-db-nosql-is-serverless-single-region) | **P0** | Cosmos DB / Data Plane | Cosmos DB NoSQL is serverless single-region | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-004](#p0-004-vnet--nsg--private-dns--pe-single-region) | **P0** | Region Topology / IaC Symmetry | VNet / NSG / Private DNS / PE single-region | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-005](#p0-005-single-bicep-location-parameter) | **P0** | Region Topology / IaC Symmetry | Single Bicep location parameter | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-006](#p0-006-azureaiservicelocation-pins-single-foundry-account) | **P0** | AI Foundry & OpenAI Multi-Region Provisioning | azureAiServiceLocation pins single Foundry account | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-007](#p0-007-enableredundancyfalse-default) | **P0** | Region Topology / IaC Symmetry | enableRedundancy=false default | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-008](#p0-008-orchestration-uses-inmemorycheckpointstorage) | **P0** | Durable State & Orchestration | Orchestration uses InMemoryCheckpointStorage | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-009](#p0-009-pre-approval-mplan-held-in-asyncioevent) | **P0** | Durable State & Orchestration | Pre-approval MPlan held in asyncio.Event | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-010](#p0-010-websocket-connection-map-is-in-memory) | **P0** | Durable State & Orchestration | WebSocket connection map is in-memory | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-011](#p0-011-backgroundtasks-orphans-in_progress-plans) | **P0** | Durable State & Orchestration | BackgroundTasks orphans in_progress plans | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-012](#p0-012-approval--clarification-routes-lack-idempotency-keys) | **P0** | Idempotency & Concurrency | Approval / clarification routes lack idempotency keys | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-013](#p0-013-cosmos-serverless-cannot-be-promoted-in-place) | **P0** | Cosmos DB / Data Plane | Cosmos serverless cannot be promoted in place | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-014](#p0-014-cosmos-unavailable--regional-outage-unhandled-f1) | **P0** | Cosmos DB / Data Plane | Cosmos unavailable / regional outage unhandled (F1) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-015](#p0-015-cosmos-429-ru-throttling-unhandled-f2) | **P0** | Cosmos DB / Data Plane | Cosmos 429 RU throttling unhandled (F2) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-016](#p0-016-openai-5xx--regional-outage-unhandled-f5) | **P0** | AI Foundry & OpenAI Multi-Region Provisioning | OpenAI 5xx / regional outage unhandled (F5) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-017](#p0-017-foundry--ai-project-unavailable-unhandled-f6) | **P0** | AI Foundry & OpenAI Multi-Region Provisioning | Foundry / AI Project unavailable unhandled (F6) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-018](#p0-018-websocket-disconnect--replica-failover-f12) | **P0** | Durable State & Orchestration | WebSocket disconnect / replica failover (F12) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-019](#p0-019-pod-restart-mid-orchestration-f13) | **P0** | Durable State & Orchestration | Pod restart mid-orchestration (F13) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-020](#p0-020-approval--clarification-404-after-restart-f14) | **P0** | Durable State & Orchestration | Approval / clarification 404 after restart (F14) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-021](#p0-021-healthz-returns-healthy-regardless-of-dependency-state) | **P0** | Health Probes & GLB Readiness | /healthz returns healthy regardless of dependency state | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-022](#p0-022-external-acr-biabcontainerregazurecrio) | **P0** | Region Topology / IaC Symmetry | External ACR biabcontainerreg.azurecr.io | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-023](#p0-023-jumpbox-admin-password-fallback-literal) | **P0** | Region Topology / IaC Symmetry | Jumpbox admin password fallback literal | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-024](#p0-024-no-glb--front-door--app-gateway--traffic-manager) | **P0** | Region Topology / IaC Symmetry | No GLB / Front Door / App Gateway / Traffic Manager | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-025](#p0-025-healthz-registered-with-checks-implementation-evidence-cross-ref-p0-021) | **P0** | Health Probes & GLB Readiness | /healthz registered with checks={} (implementation evidence; cross-ref P0-021) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-026](#p0-026-backend-has-no-auth-enforcement-at-container-app-ingress) | **P0** | Identity & Authentication | Backend has no auth enforcement at Container App ingress | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-027](#p0-027-sample_user-all-zeros-principal-fallback) | **P0** | Identity & Authentication | sample_user all-zeros principal fallback | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-028](#p0-028-mcp-server-runs-unauthenticated-when-enable_authtrue-but-jwksissueraudience-env-vars-are-unset) | **P0** | Identity & Authentication | MCP server runs unauthenticated when enable_auth=True but JWKS/issuer/audience env vars are unset | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-029](#p0-029-websocket-user_id-accepted-from-query-param-without-token-validation) | **P0** | Identity & Authentication | WebSocket user_id accepted from query param without token validation | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P0-030](#p0-030-cosmos-pe-only-in-primary-while-cosmos-fails-over) | **P0** | Cosmos DB / Data Plane | Cosmos PE only in primary while Cosmos fails over | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-001](#p1-001-azure-openai-deployments-single-region) | **P1** | Backing Services Multi-Region Provisioning | Azure OpenAI deployments single-region | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-002](#p1-002-azure-ai-search-11--public-network-single-region) | **P1** | Backing Services Multi-Region Provisioning | Azure AI Search 1×1 + public network, single-region | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-003](#p1-003-container-apps--environment-zone-redundancy-gated) | **P1** | Backing Services Multi-Region Provisioning | Container Apps + Environment zone redundancy gated | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-004](#p1-004-app-service--plan-zone-redundancy-gated) | **P1** | Backing Services Multi-Region Provisioning | App Service + Plan zone redundancy gated | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-005](#p1-005-container-registry-no-geo-replication) | **P1** | Backing Services Multi-Region Provisioning | Container Registry no geo-replication | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-006](#p1-006-storage-blob-default-replication-lrs) | **P1** | Backing Services Multi-Region Provisioning | Storage Blob default replication (LRS) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-007](#p1-007-entra-id--uami-cross-region-readiness) | **P1** | Identity & Authentication | Entra ID + UAMI cross-region readiness | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-008](#p1-008-bastion-zone-redundancy-not-configured) | **P1** | Backing Services Multi-Region Provisioning | Bastion zone-redundancy not configured | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-009](#p1-009-windows-jumpbox-vm-zone-1-pinned--ppg) | **P1** | Backing Services Multi-Region Provisioning | Windows Jumpbox VM zone-1 pinned + PPG | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-010](#p1-010-app-service-easy-auth-single-tenant-config) | **P1** | Identity & Authentication | App Service Easy Auth single-tenant config | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-011](#p1-011-mcp-jwtjwks-single-region-issuer-config) | **P1** | Identity & Authentication | MCP JWT/JWKS single-region issuer config | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-012](#p1-012-external-biabcontainerregazurecrio-shared-registry) | **P1** | Shared Dependencies / Supply Chain | External biabcontainerreg.azurecr.io shared registry | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-013](#p1-013-hard-coded-cosmos-region-pair-map) | **P1** | Region Topology / IaC Symmetry | Hard-coded Cosmos region-pair map | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-014](#p1-014-hard-coded-log-analytics-replica-region-pairs) | **P1** | Region Topology / IaC Symmetry | Hard-coded Log Analytics replica region pairs | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-015](#p1-015-jumpbox--ppg-zone-1--bastion-no-zones) | **P1** | Region Topology / IaC Symmetry | Jumpbox + PPG zone-1 / Bastion no zones | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-016](#p1-016-ai-search-11--public-network) | **P1** | Backing Services Multi-Region Provisioning | AI Search 1×1 + public network | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-017](#p1-017-backend-env-hardcodes-single-region-urls) | **P1** | Region Topology / IaC Symmetry | Backend env hardcodes single-region URLs | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-018](#p1-018-cosmosclient-has-no-preferred_locations) | **P1** | Cosmos DB Multi-Region Behavior | CosmosClient has no preferred_locations | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-019](#p1-019-single-acr-hostname-for-all-workloads) | **P1** | Backing Services Multi-Region Provisioning | Single ACR hostname for all workloads | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-020](#p1-020-storage-avm-no-skuname--enableredundancy-not-threaded) | **P1** | Backing Services Multi-Region Provisioning | Storage AVM no skuName / enableRedundancy not threaded | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-021](#p1-021-upsert_item-no-_etag--optimistic-concurrency) | **P1** | Cosmos DB Multi-Region Behavior | upsert_item no _etag / optimistic concurrency | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-022](#p1-022-except-exception-swallows-429--503) | **P1** | Cosmos DB Multi-Region Behavior | except Exception swallows 429 / 503 | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-023](#p1-023-multi-region-writes-never-enabled) | **P1** | Cosmos DB Multi-Region Behavior | Multi-region writes never enabled | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-024](#p1-024-singleton-cosmosclient-no-preferred-regions) | **P1** | Cosmos DB Multi-Region Behavior | Singleton CosmosClient no preferred regions | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-025](#p1-025-container-apps-revisionsmode-single-no-graceful-drain) | **P1** | State / Streaming / Lifecycle | Container Apps revisionsMode Single, no graceful drain | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-026](#p1-026-databasefactory--app_config-no-health-driven-invalidation) | **P1** | Cosmos DB Multi-Region Behavior | DatabaseFactory / app_config no health-driven invalidation | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-027](#p1-027-websocket-emit-best-effort-no-retry--ack) | **P1** | State / Streaming / Lifecycle | WebSocket emit best-effort no retry / ack | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-028](#p1-028-partial-agent_stream_buffers-dropped) | **P1** | State / Streaming / Lifecycle | Partial agent_stream_buffers dropped | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-029](#p1-029-cosmos-dns--private-endpoint-failure-f3) | **P1** | Cosmos DB Multi-Region Behavior | Cosmos DNS / Private Endpoint failure (F3) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-030](#p1-030-openai-429-retry-exhausted-f4) | **P1** | Resilience Patterns / Retry & Failure Modes | OpenAI 429 retry exhausted (F4) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-031](#p1-031-ai-search-unavailable--index-missing-f7) | **P1** | Resilience Patterns / Retry & Failure Modes | AI Search unavailable / index missing (F7) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-032](#p1-032-storage-blob-unavailable-f8) | **P1** | Resilience Patterns / Retry & Failure Modes | Storage Blob unavailable (F8) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-033](#p1-033-acr-pull-failure-blocks-cold-start-f9) | **P1** | Resilience Patterns / Retry & Failure Modes | ACR pull failure blocks cold-start (F9) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-034](#p1-034-entra-id-token-failure-f11) | **P1** | Resilience Patterns / Retry & Failure Modes | Entra ID token failure (F11) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-035](#p1-035-web-app-proxy-timeout-f17) | **P1** | Resilience Patterns / Retry & Failure Modes | Web App proxy timeout (F17) | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-036](#p1-036-avm-bicep-modules-cross-repo-dependency) | **P1** | Region Topology / IaC Symmetry | AVM Bicep modules cross-repo dependency | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-037](#p1-037-agent_framework-sdk-pre-release-pins) | **P1** | Shared Dependencies / Supply Chain | agent_framework SDK pre-release pins | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-038](#p1-038-mcp-shared-image-single-fqdn) | **P1** | Shared Dependencies / Supply Chain | MCP shared image single-FQDN | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-039](#p1-039-foundry-agent-metadata-seed-coupling) | **P1** | Shared Dependencies / Supply Chain | Foundry agent metadata seed coupling | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-040](#p1-040-web-app-health-static-literal-mcp-healthcheck-unregistered) | **P1** | Health Probes & GLB Readiness | Web App /health static literal; MCP HEALTHCHECK unregistered | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-041](#p1-041-retry-coverage-limited-to-openai-429) | **P1** | Resilience Patterns / Retry & Failure Modes | Retry coverage limited to OpenAI 429 | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-042](#p1-042-defaultazurecredential--mic-without-tenant_id) | **P1** | Identity & Authentication | DefaultAzureCredential / MIC without tenant_id | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-043](#p1-043-no-retry--backoff--fallback-on-get_access_token) | **P1** | Identity & Authentication | No retry / backoff / fallback on get_access_token | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-044](#p1-044-single-uami-sole-rbac-subject-across-data-planes) | **P1** | Identity & Authentication | Single UAMI sole RBAC subject across data planes | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-045](#p1-045-container-apps-ingressexternal-true) | **P1** | Network Surface & Ingress | Container Apps ingressExternal: true | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P1-046](#p1-046-app-service-publicnetworkaccess-enabled) | **P1** | Network Surface & Ingress | App Service publicNetworkAccess Enabled | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-001](#p2-001-application-insights-single-regional-component) | **P2** | Observability | Application Insights single regional component | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-002](#p2-002-log-analytics-workspace-single-region-by-default) | **P2** | Observability | Log Analytics workspace single-region by default | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-003](#p2-003-cosmos-paired-region-table-covers-only-10-regions) | **P2** | IaC / Platform | Cosmos paired-region table covers only 10 regions | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-004](#p2-004-cosmos-defaultconsistencylevel-not-set) | **P2** | Data Management | Cosmos defaultConsistencyLevel not set | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-005](#p2-005-hot-path-queries-miss-session_id-partition-key) | **P2** | Data Management | Hot-path queries miss /session_id partition key | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-006](#p2-006-databasefactory-not-closed-on-lifespan-shutdown) | **P2** | Data Management | DatabaseFactory not closed on lifespan shutdown | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-007](#p2-007-cosmos-backup-policy-not-set-in-iac) | **P2** | Data Management | Cosmos backup policy not set in IaC | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-008](#p2-008-storage-blob-versioning--pitr--change-feed-disabled) | **P2** | Data Management | Storage blob versioning / PITR / change feed disabled | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-009](#p2-009-upload-batch---overwrite-without-concurrency-control) | **P2** | Data Management | upload-batch --overwrite without concurrency control | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-010](#p2-010-cosmos-session-consistency-not-pinned) | **P2** | Data Management | Cosmos Session consistency not pinned | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-011](#p2-011-telemetry-exporter-drops-events-silently) | **P2** | Observability | Telemetry exporter drops events silently | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-012](#p2-012-pinned-microsoft-python-sdks-and-version-drift) | **P2** | Build / Dependencies | Pinned Microsoft Python SDKs and version drift | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-013](#p2-013-github-actions-tag-pinned-not-sha-pinned) | **P2** | Build / Dependencies | GitHub Actions tag-pinned, not SHA-pinned | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-014](#p2-014-vnet-10008-and-subnets-hardcoded) | **P2** | IaC / Platform | VNet 10.0.0.0/8 and subnets hardcoded | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-015](#p2-015-sami-on-webstorage-while-rbac-uses-uami) | **P2** | Identity / Configuration | SAMI on Web/Storage while RBAC uses UAMI | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-016](#p2-016-no-readiness-gate-for-entra-rbac-propagation) | **P2** | Identity / Configuration | No readiness gate for Entra RBAC propagation | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-017](#p2-017-fastapi-corsmiddleware-allow_origins) | **P2** | Security & Network Posture | FastAPI CORSMiddleware allow_origins=["*"] | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-018](#p2-018-startup-identity-coupled-with-no-degraded-mode) | **P2** | Identity / Configuration | Startup identity-coupled with no degraded-mode | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-019](#p2-019-ai-foundry-networkaclsdefaultaction-allow) | **P2** | Security & Network Posture | AI Foundry networkAcls.defaultAction: Allow | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-020](#p2-020-storage-networkaclsbypass-azureservices) | **P2** | Security & Network Posture | Storage networkAcls.bypass: AzureServices | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-021](#p2-021-no-route-tables-nat-gateway-or-ddos-plan) | **P2** | Security & Network Posture | No route tables, NAT Gateway, or DDoS plan | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P2-022](#p2-022-insufficient-observability-for-silent-failure-triage) | **P2** | Observability | Insufficient observability for silent-failure triage | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-001](#p3-001-dcr-for-jumpbox-tied-to-single-workspace) | **P3** | Operator Telemetry | DCR for jumpbox tied to single workspace | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-002](#p3-002-sync-and-async-cosmosclient-coexist) | **P3** | Data | Sync and async CosmosClient coexist | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-003](#p3-003-delete_-returns-true-regardless-of-outcome) | **P3** | Data | delete_* returns True regardless of outcome | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-004](#p3-004-easy-auth-fallback-to-sample_user-principal) | **P3** | Identity / Configuration Hygiene | Easy Auth fallback to sample_user principal | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-005](#p3-005-mcp-jwtverifier-jwks-unreachable-when-auth-enabled) | **P3** | Identity / Configuration Hygiene | MCP JWTVerifier JWKS unreachable when auth enabled | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-006](#p3-006-external-base-image-registries-used-at-build-time) | **P3** | Build / Packaging | External base-image registries used at build time | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-007](#p3-007-pypi--npm-reachable-at-deploy-script-time) | **P3** | Build / Packaging | PyPI / npm reachable at deploy-script time | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-008](#p3-008-microsoft-entra-id-is-the-global-identity-plane) | **P3** | Identity / Configuration Hygiene | Microsoft Entra ID is the global identity plane | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-009](#p3-009-container-images-use-mutable-latest_v4-tag) | **P3** | Build / Packaging | Container images use mutable latest_v4 tag | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-010](#p3-010-healthcheckmiddleware-registered-with-empty-password) | **P3** | Backend Hygiene | HealthCheckMiddleware registered with empty password | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-011](#p3-011-uniform-single-rule-outbound-nsgs-across-subnets) | **P3** | Networking Hygiene | Uniform single-rule outbound NSGs across subnets | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-012](#p3-012-no-nsg-flow-logs-or-network-watcher) | **P3** | Networking Hygiene | No NSG flow logs or Network Watcher | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-013](#p3-013-azure_tenant_id-and-tenant_id-duplicated) | **P3** | Identity / Configuration Hygiene | AZURE_TENANT_ID and TENANT_ID duplicated | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |
| [P3-014](#p3-014-default-enable_authfalse-and-mcp_enable_authfalse) | **P3** | Identity / Configuration Hygiene | Default ENABLE_AUTH=false and MCP_ENABLE_AUTH=false | Multi-Agent-Custom-Automation-Engine-Solution-Accelerator |

[Back to Top](#top)

---

# 6. Microsoft Standards Alignment

| Pattern | Status | Findings |
| --- | --- | --- |
| [Health Endpoint Monitoring](https://learn.microsoft.com/azure/architecture/patterns/health-endpoint-monitoring) | Not Implemented | P0-021, P0-025, P1-040, P3-010 |
| [Retry Pattern](https://learn.microsoft.com/azure/architecture/patterns/retry) | Partial (only OpenAI 429 path retried; Cosmos / Foundry / Storage / Search not covered) | P0-014, P0-015, P0-016, P0-017, P1-022, P1-030, P1-031, P1-032, P1-033, P1-034, P1-041, P1-043 |
| [Circuit Breaker](https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker) | Not Implemented | P0-014, P0-016, P0-017, P1-026, P1-031, P1-032 |
| [Throttling](https://learn.microsoft.com/azure/architecture/patterns/throttling) | Not followed (429 not honored, no `x-ms-retry-after-ms`) | P0-015, P1-022, P1-030 |
| [Idempotent Receiver](https://learn.microsoft.com/azure/architecture/patterns/idempotency) | Not Implemented | P0-012, P0-020, P1-021 |
| [Queue-Based Load Leveling](https://learn.microsoft.com/azure/architecture/patterns/queue-based-load-leveling) | Not Implemented | P0-008, P0-011, P0-019 |
| [Publisher / Subscriber](https://learn.microsoft.com/azure/architecture/patterns/publisher-subscriber) | Not Implemented | P0-010, P0-018, P1-027, P1-028 |
| [Geode Pattern](https://learn.microsoft.com/azure/architecture/patterns/geodes) | Not Implemented (no GLB or per-region geode) | P0-024, P1-001, P1-002, P1-003, P1-004 |
| [Deployment Stamps](https://learn.microsoft.com/azure/architecture/patterns/deployment-stamp) | Not Implemented (no `primaryLocation` / `secondaryLocation`) | P0-005, P0-006, P1-013, P1-014, P1-017 |
| [Compensating Transaction](https://learn.microsoft.com/azure/architecture/patterns/compensating-transaction) | Not Implemented | P0-009, P0-019, P0-020 |
| [Bulkhead](https://learn.microsoft.com/azure/architecture/patterns/bulkhead) | Not followed (single UAMI across all data planes; single Cosmos client; no isolation between Foundry / Search / Storage call paths) | P1-026, P1-044, P2-018 |
| [Cosmos DB Multi-Region Distribution](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally) | Not Implemented | P0-003, P0-013, P0-030, P1-018, P1-023, P1-024 |
| [Cosmos DB Optimistic Concurrency](https://learn.microsoft.com/azure/cosmos-db/optimistic-concurrency-control) | Not followed | P1-021 |
| [Cosmos DB Conflict Resolution](https://learn.microsoft.com/azure/cosmos-db/conflict-resolution-policies) | Not Implemented | P1-023 |
| [Azure OpenAI Business Continuity](https://learn.microsoft.com/azure/ai-services/openai/how-to/business-continuity-multivariate) | Not Implemented | P0-006, P0-016, P1-001, P1-030 |
| [Azure Container Registry Geo-Replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication) | Not Implemented | P0-022, P1-005, P1-012, P1-019, P1-038 |
| [Azure Storage Redundancy](https://learn.microsoft.com/azure/storage/common/storage-redundancy) | Misconfigured (default LRS, `enableRedundancy` not threaded) | P1-006, P1-020, P1-032 |
| [Azure AI Search Reliability](https://learn.microsoft.com/azure/search/search-reliability) | Misconfigured (1 replica × 1 partition, public network) | P1-002, P1-016, P1-031 |
| [Azure Container Apps Reliability](https://learn.microsoft.com/azure/container-apps/availability-zones) | Partial (zone redundancy gated by `enableRedundancy=false` default) | P1-003, P1-025 |
| [Azure App Service Reliability](https://learn.microsoft.com/azure/app-service/configure-reliability) | Misconfigured (`publicNetworkAccess: 'Enabled'`, single region) | P1-004, P1-046 |
| [Managed Identity Best Practices](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations) | Not followed (single UAMI sole RBAC subject; tenant_id not pinned) | P1-007, P1-042, P1-044, P2-015 |
| [Protected Web API](https://learn.microsoft.com/entra/identity-platform/scenario-protected-web-api-overview) | Not Implemented (backend Container App has no auth at ingress; sample_user fallback; MCP unauthenticated when JWKS unset; WebSocket query-param spoofable) | P0-026, P0-027, P0-028, P0-029, P3-004, P3-005, P3-014 |
| [Azure Front Door Overview](https://learn.microsoft.com/azure/frontdoor/front-door-overview) | Not Implemented | P0-024, P1-045, P1-046 |
| [Azure Key Vault Best Practices](https://learn.microsoft.com/azure/key-vault/general/best-practices) | Not Implemented (no Key Vault provisioned; jumpbox password literal) | P0-023, P3-010 |
| [Azure Bicep Parameters](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameters) | Not followed (single `location` parameter, hardcoded VNet/subnet CIDRs, paired-region tables) | P0-005, P1-013, P1-014, P2-003, P2-014 |
| [Image Integrity / Pinning](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices) | Not followed (mutable `latest_v4` tag) | P3-009 |
| [GitHub Actions Hardening](https://docs.github.com/actions/security-guides/security-hardening-for-github-actions) | Not followed (tag-pinned, not SHA-pinned) | P2-013 |
| [Azure Monitor Best Practices](https://learn.microsoft.com/azure/azure-monitor/best-practices-logs) | Partial (App Insights present but exporter drops silently; structured logging missing) | P2-001, P2-002, P2-011, P2-022 |
| [Cosmos DB Backup and Restore](https://learn.microsoft.com/azure/cosmos-db/online-backup-and-restore) | Not followed (default 4-hour periodic; serverless blocks PITR) | P2-007 |
| [Azure Storage Versioning and PITR](https://learn.microsoft.com/azure/storage/blobs/versioning-overview) | Not Implemented | P2-008 |
| [Azure Virtual Network NAT Gateway](https://learn.microsoft.com/azure/virtual-network/nat-gateway/nat-overview) | Not Implemented | P2-021, P3-011, P3-012 |

[Back to Top](#top)

---

