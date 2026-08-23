# agent-memory-hub setup script (Windows)
# Usage:
#   .\setup.ps1              # install in-place (use this repo's folder as the hub)
#   .\setup.ps1 -Force       # overwrite existing pointer files
#   .\setup.ps1 -Fresh       # wipe accumulated memories (keep skeleton)

param(
    [switch]$Force,
    [switch]$Fresh
)

$ErrorActionPreference = "Stop"
$SharedDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== agent-memory-hub setup ===" -ForegroundColor Cyan
Write-Host "Hub directory: $SharedDir"
Write-Host ""

# ---------- helpers ----------

function Expand-Template {
    param([string]$Path)
    (Get-Content $Path -Raw -Encoding UTF8) -replace '\{\{SHARED\}\}', $SharedDir.Replace('$', '$$')
}

function Install-Pointer {
    param([string]$Template, [string]$Dest, [string]$AgentName)
    $content = Expand-Template $Template
    if (Test-Path -LiteralPath $Dest) {
        if ($Force) {
            Set-Content -LiteralPath $Dest -Value $content -Encoding UTF8
            Write-Host "  [$AgentName] updated: $Dest" -ForegroundColor Yellow
        } else {
            Write-Host "  [$AgentName] skipped (exists, use -Force to overwrite): $Dest"
        }
        return
    }
    Set-Content -LiteralPath $Dest -Value $content -Encoding UTF8
    Write-Host "  [$AgentName] installed: $Dest" -ForegroundColor Green
}

# ---------- optional: fresh start ----------

if ($Fresh) {
    $confirm = Read-Host "This deletes all accumulated memories under memory\. Continue? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Get-ChildItem "$SharedDir\memory" -Directory | Where-Object { $_.Name -ne 'consolidated' } | Remove-Item -Recurse -Force
        if (Test-Path "$SharedDir\scripts\sync_state.json") { Remove-Item "$SharedDir\scripts\sync_state.json" -Force }
        Write-Host "Memories wiped. Skeleton kept." -ForegroundColor Yellow
    } else {
        Write-Host "Aborted."; exit 1
    }
}

# ---------- detect agents & install pointers ----------

Write-Host "Detecting installed agents..."

# OpenCode — global instructions file
if (Test-Path "$HOME\.config\opencode" -ErrorAction SilentlyContinue) {
    Install-Pointer "$SharedDir\agents\opencode\AGENTS.md" "$HOME\AGENTS.md" "OpenCode"
} else {
    # OpenCode reads ~/AGENTS.md from the workspace root; install anyway if opencode.json exists anywhere
    $oc = Get-Command opencode -ErrorAction SilentlyContinue
    if ($oc) { Install-Pointer "$SharedDir\agents\opencode\AGENTS.md" "$HOME\AGENTS.md" "OpenCode" }
    else { Write-Host "  [OpenCode] not detected, skipped" -ForegroundColor DarkGray }
}

# Claude Code — global memory file
if (Test-Path "$HOME\.claude") {
    Install-Pointer "$SharedDir\agents\claude\CLAUDE.md" "$HOME\.claude\CLAUDE.md" "Claude"
} else {
    Write-Host "  [Claude] not detected, skipped" -ForegroundColor DarkGray
}

# Hermes — root memory files (auto-detect common paths)
$HermesDir = $null
foreach ($candidate in @(
    "$HOME\.hermes",
    "$HOME\.config\hermes",
    "$env:LOCALAPPDATA\hermes",
    "$env:APPDATA\hermes"
)) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -ErrorAction SilentlyContinue)) {
        $HermesDir = $candidate
        break
    }
}
if ($HermesDir) {
    Install-Pointer "$SharedDir\agents\hermes\MEMORY.md" "$HermesDir\MEMORY.md" "Hermes"
    Install-Pointer "$SharedDir\agents\hermes\USER.md" "$HermesDir\USER.md" "Hermes"
} else {
    Write-Host "  [Hermes] not detected, skipped" -ForegroundColor DarkGray
}

# QClaw
if (Test-Path "$HOME\.qclaw") {
    $dest = "$HOME\.qclaw\workspace"
    if (Test-Path $dest) {
        Install-Pointer "$SharedDir\agents\qclaw\MEMORY.md" "$dest\MEMORY.md" "QClaw"
    } else { Write-Host "  [QClaw] workspace not found, skipped" -ForegroundColor DarkGray }
} else {
    Write-Host "  [QClaw] not detected, skipped" -ForegroundColor DarkGray
}

# OpenClaw
if (Test-Path "$HOME\.openclaw") {
    $dest = "$HOME\.openclaw\workspace"
    if (Test-Path $dest) {
        Install-Pointer "$SharedDir\agents\openclaw\MEMORY.md" "$dest\MEMORY.md" "OpenClaw"
    } else { Write-Host "  [OpenClaw] workspace not found, skipped" -ForegroundColor DarkGray }
} else {
    Write-Host "  [OpenClaw] not detected, skipped" -ForegroundColor DarkGray
}

# ---------- first sync ----------

Write-Host ""
Write-Host "Running first sync..."
$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
    & python "$SharedDir\scripts\sync_memory.py"
} else {
    Write-Host "Python not found. Install Python 3.8+ and run: python scripts\sync_memory.py" -ForegroundColor Red
}

# ---------- git check ----------

Write-Host ""
$insideRepo = git -C $SharedDir rev-parse --is-inside-work-tree 2>$null
if ($insideRepo -eq "true") {
    $remote = git -C $SharedDir remote
    if (-not $remote) {
        Write-Host "No git remote configured." -ForegroundColor Yellow
        Write-Host "To sync memories across devices, create a PRIVATE repo and run:"
        Write-Host "  git remote add origin <your-private-repo-url>"
        Write-Host "  git push -u origin main"
    }
}

Write-Host ""
Write-Host "Setup done." -ForegroundColor Green
