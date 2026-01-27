-- Most common titles in your network
SELECT
  title,
  COUNT(*) AS people
FROM connections_clean
WHERE title IS NOT NULL
GROUP BY title
ORDER BY people DESC
LIMIT 30;

-- Most recent connections (warm intros)
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
LIMIT 30;

-- GTM leadership connections
SELECT
  first_name,
  last_name,
  company,
  title,
  linkedin_url
FROM connections_clean
WHERE
  title ILIKE '%chief%' OR
  title ILIKE '%cro%' OR
  title ILIKE '%cso%' OR
  title ILIKE '%vp sales%' OR
  title ILIKE '%head of sales%' OR
  title ILIKE '%vp%' OR
  title ILIKE '%head of%' OR
  title ILIKE '%director%'
ORDER BY company, last_name
LIMIT 100;

-- Data quality overview
SELECT
  SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END)       AS missing_company,
  SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END)         AS missing_title,
  SUM(CASE WHEN connected_on IS NULL THEN 1 ELSE 0 END) AS missing_date
FROM connections_clean;
