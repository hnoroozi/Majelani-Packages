<#
.SYNOPSIS
  Majelani AI Supervisor - Daily Push Script (PowerShell)
  - Auto-detect supervisor report
  - Copy to dated folder
  - Commit & push to GitHub
  - Structured logging

#>

param(
  [string]$VerifiedEmail = "YOUR_VERIFIED_EMAIL@example.com"
)

$ErrorActionPreference = "Stop"

# --- Repo root = current script directory
$RepoDir = Split-Path -Parent $PSCommandPath
$LogDir  = Join-Path $RepoDir "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# --- Candidate paths for the latest report
$candidates = @(
  "C:\Users\hazot\Downloads\Majelani_Supervisor_RealReady\supervisor_core\output\supervisor_report_latest.json",
  "C:\Majelani\Supervisor\supervisor_core\output\supervisor_report_latest.json",
  (Join-Path (Split-Path $RepoDir -Parent) "Majelani_Supervisor_RealReady\supervisor_core\output\supervisor_report_latest.json")
)

$src = $null
foreach ($p in $candidates) {
  if (Test-Path $p) { $src = $p; break }
}

if (-not $src) {
  Write-Host "[ERROR] Could not locate supervisor_report_latest.json"
  $candidates | ForEach-Object { Write-Host "Tried: $_" }
  exit 2
}

# --- Pacific time
$tz  = [TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time')
$now = [TimeZoneInfo]::ConvertTime([datetime]::UtcNow, $tz)
$ts  = $now.ToString('yyyy-MM-dd_HH-mm-ss')
$day = $now.ToString('yyyy-MM-dd')

$dstDir  = Join-Path $RepoDir ("reports\" + $day)
$dstFile = Join-Path $dstDir ("report_{0}.json" -f $ts)
New-Item -ItemType Directory -Path $dstDir -Force | Out-Null

Copy-Item -Path $src -Destination $dstFile -Force

$logFile = Join-Path $LogDir ("push_{0}.log" -f $day)
Add-Content -Path $logFile -Value ("[{0}] Copied: {1} -> {2}" -f $ts, $src, $dstFile)

# --- Git identity
& git -C $RepoDir config user.name  "H.N. Majelani" | Out-Null
& git -C $RepoDir config user.email $VerifiedEmail | Out-Null

# --- Commit & push
Push-Location $RepoDir
& git add $dstFile | Out-Null
$commitResult = & git commit -m ("daily snapshot: {0} ({1})" -f $day, $ts) 2>&1
if ($LASTEXITCODE -ne 0) {
  Add-Content $logFile ("[{0}] WARN: No changes to commit. Git said: {1}" -f $ts, $commitResult)
} else {
  Add-Content $logFile ("[{0}] Committed {1}" -f $ts, $dstFile)
}

$pushResult = & git push 2>&1
if ($LASTEXITCODE -ne 0) {
  Add-Content $logFile ("[{0}] ERROR: git push failed. {1}" -f $ts, $pushResult)
  Pop-Location
  exit 3
} else {
  Add-Content $logFile ("[{0}] OK: pushed to remote." -f $ts)
  Pop-Location
  exit 0
}