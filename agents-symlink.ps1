param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,
    [switch]$Claude,
    [switch]$Devin,
    [switch]$Cursor,
    [switch]$Windsurf,
    [switch]$All
)

# Default to installing for every supported tool so the target project
# is compatible with whichever agentic tool the user happens to run.
if (-not ($Claude -or $Devin -or $Cursor -or $Windsurf -or $All)) {
    $All = $true
}
if ($All) {
    $Claude = $true
    $Devin = $true
    $Cursor = $true
    $Windsurf = $true
}

$TargetDir = (Resolve-Path $TargetDir).Path
$AgentsSource = Join-Path $PSScriptRoot "agents"

Write-Host "Installing agents from $AgentsSource into $TargetDir"

# .agents\agents\<name> is the canonical, tool-agnostic install location.
# Every tool-specific directory below is just a shim pointing into it, so
# nothing but this one layer ever points back at the source repo.
$canonicalRoot = Join-Path $TargetDir ".agents\agents"
New-Item -ItemType Directory -Force -Path $canonicalRoot | Out-Null

if ($Claude) {
    $claudeRoot = Join-Path $TargetDir ".claude\agents"
    New-Item -ItemType Directory -Force -Path $claudeRoot | Out-Null
}

if ($Devin) {
    $devinRoot = Join-Path $TargetDir ".devin\agents"
    New-Item -ItemType Directory -Force -Path $devinRoot | Out-Null
}

if ($Cursor -or $Windsurf) {
    Write-Host "NOTE: Cursor and Windsurf have no file-based subagent/persona convention today, so agents are not installed for them (skills/commands still are)." -ForegroundColor Yellow
}

Get-ChildItem -Path $AgentsSource -Directory | ForEach-Object {
    $agentDir = $_.FullName
    $agentName = $_.Name
    $agentFile = Join-Path $agentDir "AGENT.md"

    if (-not (Test-Path $agentFile)) {
        Write-Host "SKIP $agentName — no AGENT.md at $agentFile" -ForegroundColor Yellow
        return
    }

    # Canonical: whole-folder symlink into .agents\agents\<name>
    $canonicalLink = Join-Path $canonicalRoot $agentName
    if (Test-Path $canonicalLink) { Remove-Item $canonicalLink -Recurse -Force }
    New-Item -ItemType SymbolicLink -Path $canonicalLink -Target $agentDir | Out-Null
    Write-Host "Linked canonical: $canonicalLink -> $agentDir"

    if ($Claude) {
        # Claude: flat file symlink pointing at the canonical AGENT.md
        $claudeFile = Join-Path $claudeRoot "$agentName.md"
        if (Test-Path $claudeFile) { Remove-Item $claudeFile -Force }
        New-Item -ItemType SymbolicLink -Path $claudeFile -Target (Join-Path $canonicalLink "AGENT.md") | Out-Null
        Write-Host "Linked Claude: $claudeFile -> $canonicalLink\AGENT.md"
    }

    if ($Devin) {
        # Devin: whole-folder symlink, same shape as canonical already
        $devinFolder = Join-Path $devinRoot $agentName
        if (Test-Path $devinFolder) { Remove-Item $devinFolder -Recurse -Force }
        New-Item -ItemType SymbolicLink -Path $devinFolder -Target $canonicalLink | Out-Null
        Write-Host "Linked Devin: $devinFolder -> $canonicalLink"
    }
}

Write-Host "Done."
