<#
.SYNOPSIS
    Installs the HVE Resiliency Copilot skills, prompts, and instructions into the current repository.

.DESCRIPTION
    Downloads the requested ref of christopherromero/HVE-Resiliency from GitHub and copies the
    .github/skills, .github/prompts, and .github/instructions folders into the
    current working directory's .github/ folder so GitHub Copilot Chat auto-discovers them.

    Requires no git client. Works on Windows PowerShell 5.1+ and PowerShell 7+ (cross-platform).

.PARAMETER Ref
    Git ref (branch, tag, or commit SHA) to install from. Defaults to 'main'.

.PARAMETER Destination
    Target repository root. Defaults to the current directory.

.PARAMETER Include
    Subfolders of .github to install. Defaults to skills, prompts, instructions.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER Repo
    Override the source repository in the form owner/name. Defaults to christopherromero/HVE-Resiliency.

.EXAMPLE
    # Recommended one-liner (run from your target repo's root)
    irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1 | iex

.EXAMPLE
    # Parameterized form (pin to a tag, force overwrite)
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/christopherromero/HVE-Resiliency/main/install.ps1))) -Ref v1.0 -Force

.EXAMPLE
    # Local script form
    pwsh ./install.ps1 -Ref main -Force
#>
[CmdletBinding()]
param(
    [string]$Ref = 'main',
    [string]$Destination = (Get-Location).Path,
    [string[]]$Include = @('skills', 'prompts', 'instructions'),
    [switch]$Force,
    [string]$Repo = 'christopherromero/HVE-Resiliency'
)

$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host ('HVE Resiliency installer  ({0}@{1})' -f $Repo, $Ref) -ForegroundColor Cyan
Write-Host ('Destination: {0}' -f $Destination)
Write-Host ('Sections   : {0}' -f ($Include -join ', '))
Write-Host ''

$repoName = ($Repo -split '/')[-1]
$zipUrl = 'https://codeload.github.com/{0}/zip/refs/heads/{1}' -f $Repo, $Ref
$tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('hve-resiliency-install-' + [Guid]::NewGuid().ToString('N'))
$zipPath = Join-Path -Path $tempRoot -ChildPath 'archive.zip'

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
    Write-Host ('Downloading {0} ...' -f $zipUrl)
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    }
    catch {
        # Fallback: tags don't live under refs/heads
        $zipUrl = 'https://codeload.github.com/{0}/zip/refs/tags/{1}' -f $Repo, $Ref
        Write-Host ('  refs/heads not found, trying refs/tags: {0}' -f $zipUrl)
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    }

    Write-Host 'Extracting ...'
    Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

    $extractedRoot = Get-ChildItem -Path $tempRoot -Directory | Select-Object -First 1
    if (-not $extractedRoot) { throw 'Failed to locate extracted archive contents.' }
    $sourceGithub = Join-Path -Path $extractedRoot.FullName -ChildPath '.github'
    if (-not (Test-Path -LiteralPath $sourceGithub)) {
        throw ('No .github folder found in the downloaded archive: {0}' -f $sourceGithub)
    }

    $destGithub = Join-Path -Path $Destination -ChildPath '.github'
    if (-not (Test-Path -LiteralPath $destGithub)) {
        New-Item -ItemType Directory -Path $destGithub -Force | Out-Null
    }

    $copied = 0
    $skipped = 0
    foreach ($section in $Include) {
        $srcSection = Join-Path -Path $sourceGithub -ChildPath $section
        if (-not (Test-Path -LiteralPath $srcSection)) {
            Write-Host ('  Skipping {0}: not present in source.' -f $section) -ForegroundColor Yellow
            continue
        }
        $dstSection = Join-Path -Path $destGithub -ChildPath $section

        Write-Host ('Installing .github/{0} ...' -f $section)
        $srcFiles = Get-ChildItem -Path $srcSection -Recurse -File
        foreach ($file in $srcFiles) {
            $rel = $file.FullName.Substring($srcSection.Length).TrimStart([char]'\', [char]'/')
            $targetFile = Join-Path -Path $dstSection -ChildPath $rel
            $targetDir = Split-Path -Path $targetFile -Parent
            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            if ((Test-Path -LiteralPath $targetFile) -and -not $Force) {
                $existing = Get-FileHash -LiteralPath $targetFile -Algorithm SHA256
                $incoming = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
                if ($existing.Hash -eq $incoming.Hash) {
                    $skipped++
                    continue
                }
                $answer = Read-Host ('Overwrite {0}? [y/N/a(ll)]' -f $targetFile)
                switch ($answer.ToLower()) {
                    'a' { $Force = $true }
                    'y' { }
                    default { $skipped++; continue }
                }
            }
            Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
            $copied++
        }
    }

    Write-Host ''
    Write-Host ('Installed: {0} file(s) copied, {1} skipped.' -f $copied, $skipped) -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor Cyan
    Write-Host '  1. Reload VS Code (Developer: Reload Window) so Copilot Chat re-indexes the new files.'
    Write-Host '  2. Install the HVE Core VS Code extension if you have not already:'
    Write-Host '     https://marketplace.visualstudio.com/items?itemName=ise-hve-essentials.hve-core'
    Write-Host '  3. In Copilot Chat type "/" to see the new commands:'
    Write-Host '     /hve-resiliency-research'
    Write-Host '     /hve-resiliency-workitem-export'
    Write-Host '     /hve-resiliency-workitem-import'
    Write-Host '     /hve-resiliency-workitem-jira-import'
    Write-Host '  4. Commit the new .github/ files so your team gets the same workflow.'
    Write-Host ''
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
