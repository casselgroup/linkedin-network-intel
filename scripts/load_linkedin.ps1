param(
  [Parameter(Mandatory=$true)]
  [string]$CsvPath,

  [string]$DatabaseName = "linkedin_intel"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command duckdb -ErrorAction SilentlyContinue)) {
  Write-Error "duckdb not found on PATH. Test with: duckdb --version"
  exit 1
}

# Always run relative to repo root (script lives in scripts/)
Set-Location $PSScriptRoot
Set-Location ..

if (-not (Test-Path $CsvPath)) {
  Write-Error "CSV file not found: $CsvPath"
  exit 1
}

$CsvPathNormalized = (Resolve-Path $CsvPath).Path.Replace('\','/')
$ViewsPath = (Resolve-Path ".\sql\00_views.sql").Path.Replace('\','/')

Write-Host "Loading LinkedIn CSV into MotherDuck..."
Write-Host "  CSV : $CsvPathNormalized"
Write-Host "  DB  : $DatabaseName"
Write-Host "  View: $ViewsPath"

$duckdbCommands = @"
INSTALL motherduck;
LOAD motherduck;
ATTACH 'md:$DatabaseName';

-- IMPORTANT: write into the attached MotherDuck database explicitly
CREATE OR REPLACE TABLE "$DatabaseName".main.connections AS
SELECT * FROM read_csv_auto('$CsvPathNormalized', HEADER=true);

-- Run semantic layer build
.read '$ViewsPath'

-- Verify data is in MotherDuck
SELECT COUNT(*) AS row_count FROM "$DatabaseName".main.connections;
SELECT COUNT(*) AS clean_row_count FROM connections_clean;
"@

$duckdbCommands | duckdb
