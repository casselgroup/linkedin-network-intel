-- Companies with the most connections
SELECT
  company,
  COUNT(*) AS connections
FROM connections_clean
WHERE company IS NOT NULL
GROUP BY company
ORDER BY connections DESC
LIMIT 25;

-- Companies where you have multiple connections (multi-threading targets)
SELECT
  company,
  COUNT(*) AS connections
FROM connections_clean
WHERE company IS NOT NULL
GROUP BY company
HAVING COUNT(*) >= 2
ORDER BY connections DESC, company
LIMIT 100;
