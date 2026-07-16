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
$SkillsSource = Join-Path $PSScriptRoot "skills"

Write-Host "Installing skills from $SkillsSource into $TargetDir"

# .agents\skills\<name> is the canonical, tool-agnostic install location.
# Every tool-specific directory below is just a shim pointing into it, so
# nothing but this one layer ever points back at the source repo.
$canonicalRoot = Join-Path $TargetDir ".agents\skills"
New-Item -ItemType Directory -Force -Path $canonicalRoot | Out-Null

if ($Claude) {
    $claudeRoot = Join-Path $TargetDir ".claude\skills"
    New-Item -ItemType Directory -Force -Path $claudeRoot | Out-Null
}

if ($Devin) {
    $devinRoot = Join-Path $TargetDir ".devin\skills"
    New-Item -ItemType Directory -Force -Path $devinRoot | Out-Null
}

if ($Cursor) {
    # Cursor commands are single markdown files, e.g. .cursor\commands\<name>.md
    $cursorRoot = Join-Path $TargetDir ".cursor\commands"
    New-Item -ItemType Directory -Force -Path $cursorRoot | Out-Null
}

if ($Windsurf) {
    # Windsurf workflows are single markdown files, e.g. .windsurf\workflows\<name>.md
    $windsurfRoot = Join-Path $TargetDir ".windsurf\workflows"
    New-Item -ItemType Directory -Force -Path $windsurfRoot | Out-Null
}

Get-ChildItem -Path $SkillsSource -Directory | ForEach-Object {
    $skillDir = $_.FullName
    $skillName = $_.Name
    $skillFile = Join-Path $skillDir "SKILL.md"

    if (-not (Test-Path $skillFile)) {
        Write-Host "SKIP $skillName — no SKILL.md at $skillFile" -ForegroundColor Yellow
        return
    }

    # Canonical: whole-folder symlink into .agents\skills\<name>
    $canonicalLink = Join-Path $canonicalRoot $skillName
    if (Test-Path $canonicalLink) { Remove-Item $canonicalLink -Recurse -Force }
    New-Item -ItemType SymbolicLink -Path $canonicalLink -Target $skillDir | Out-Null
    Write-Host "Linked canonical: $canonicalLink -> $skillDir"

    if ($Claude) {
        # Claude: whole-folder symlink
        $claudeLink = Join-Path $claudeRoot $skillName
        if (Test-Path $claudeLink) { Remove-Item $claudeLink -Recurse -Force }
        New-Item -ItemType SymbolicLink -Path $claudeLink -Target $canonicalLink | Out-Null
        Write-Host "Linked Claude: $claudeLink -> $canonicalLink"
    }

    if ($Devin) {
        # Devin: whole-folder symlink
        $devinLink = Join-Path $devinRoot $skillName
        if (Test-Path $devinLink) { Remove-Item $devinLink -Recurse -Force }
        New-Item -ItemType SymbolicLink -Path $devinLink -Target $canonicalLink | Out-Null
        Write-Host "Linked Devin: $devinLink -> $canonicalLink"
    }

    if ($Cursor) {
        # Cursor: flat file symlink, SKILL.md doubles as the command body
        $cursorLink = Join-Path $cursorRoot "$skillName.md"
        if (Test-Path $cursorLink) { Remove-Item $cursorLink -Force }
        New-Item -ItemType SymbolicLink -Path $cursorLink -Target (Join-Path $canonicalLink "SKILL.md") | Out-Null
        Write-Host "Linked Cursor: $cursorLink -> $canonicalLink\SKILL.md"
    }

    if ($Windsurf) {
        # Windsurf: flat file symlink, SKILL.md doubles as the workflow body
        $windsurfLink = Join-Path $windsurfRoot "$skillName.md"
        if (Test-Path $windsurfLink) { Remove-Item $windsurfLink -Force }
        New-Item -ItemType SymbolicLink -Path $windsurfLink -Target (Join-Path $canonicalLink "SKILL.md") | Out-Null
        Write-Host "Linked Windsurf: $windsurfLink -> $canonicalLink\SKILL.md"
    }
}

Write-Host "Done."
