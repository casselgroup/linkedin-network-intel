param(
  [string]$DatabaseName = "linkedin_intel",
  [string]$SchemaName = "main",
  [string]$TableName = "connections"
)

$ErrorActionPreference = "Stop"

# Verify DuckDB is available
if (-not (Get-Command duckdb -ErrorAction SilentlyContinue)) {
  Write-Error "duckdb not found on PATH. Test with: duckdb --version"
  exit 1
}

# Run from repo root (script lives in scripts/)
Set-Location $PSScriptRoot
Set-Location ..

New-Item -ItemType Directory -Force -Path ".\outputs" | Out-Null


# Resolve SQL paths (DuckDB prefers forward slashes)
$ViewsPath   = (Resolve-Path ".\sql\01_views.sql").Path.Replace('\','/')
$CompanyPath = (Resolve-Path ".\sql\10_company_insights.sql").Path.Replace('\','/')
$PeoplePath  = (Resolve-Path ".\sql\20_people_insights.sql").Path.Replace('\','/')

Write-Host "Running MotherDuck network intel..."
Write-Host "  DB    : $DatabaseName"
Write-Host "  Source: $DatabaseName.$SchemaName.$TableName"
Write-Host "  SQL   : 01_views, 10_company_insights, 20_people_insights"

$duckdbCommands = @"
INSTALL motherduck;
LOAD motherduck;
ATTACH 'md:$DatabaseName';

-- Show available tables to make debugging easy
SHOW TABLES FROM $DatabaseName.$SchemaName;

-- Fail fast if the table doesn't exist
SELECT COUNT(*) AS raw_rows FROM $DatabaseName.$SchemaName.$TableName;

-- Pointer: create a stable source view for the rest of the SQL to use
CREATE OR REPLACE VIEW connections_source AS
SELECT * FROM $DatabaseName.$SchemaName.$TableName;

-- Build semantic layer (should read FROM connections_source)
.read '$ViewsPath'

-- Sanity check semantic layer
SELECT COUNT(*) AS clean_rows FROM connections_clean;

-- Export: Top companies
COPY (
  SELECT
    company,
    COUNT(*) AS connections
  FROM connections_clean
  WHERE company IS NOT NULL
  GROUP BY company
  ORDER BY connections DESC
  LIMIT 100
) TO 'outputs/top_companies.csv' (HEADER, DELIMITER ',');

-- Export: Multi-thread companies (2+ connections)
COPY (
  SELECT
    company,
    COUNT(*) AS connections
  FROM connections_clean
  WHERE company IS NOT NULL
  GROUP BY company
  HAVING COUNT(*) >= 2
  ORDER BY connections DESC, company
  LIMIT 300
) TO 'outputs/multi_thread_companies.csv' (HEADER, DELIMITER ',');

-- Export: Recent connections
COPY (
  SELECT
    first_name,
    last_name,
    company,
    title,
    connected_on,
    linkedin_url
  FROM connections_clean
  WHERE connected_on IS NOT NULL
  ORDER BY connected_on DESC
  LIMIT 200
) TO 'outputs/recent_connections.csv' (HEADER, DELIMITER ',');

-- Export: GTM leadership
COPY (
  SELECT
    first_name,
    last_name,
    company,
    title,
    linkedin_url
  FROM connections_clean
  WHERE title IS NOT NULL AND (
    title ILIKE '%chief%' OR
    title ILIKE '%cro%' OR
    title ILIKE '%cso%' OR
    title ILIKE '%vp sales%' OR
    title ILIKE '%head of sales%' OR
    title ILIKE '%vp%' OR
    title ILIKE '%head of%' OR
    title ILIKE '%director%'
  )
  ORDER BY company, last_name
  LIMIT 500
) TO 'outputs/gtm_leaders.csv' (HEADER, DELIMITER ',');


-- Run your prebuilt query packs (they will print results to console)
.read '$CompanyPath'
.read '$PeoplePath'
"@

$duckdbCommands | duckdb
