-- Cleaned, typed view over LinkedIn connections
CREATE OR REPLACE VIEW connections_clean AS
SELECT
  "First Name"         AS first_name,
  "Last Name"          AS last_name,
  "URL"                AS linkedin_url,
  "Email Address"      AS email,
  NULLIF(TRIM("Company"), '')   AS company,
  NULLIF(TRIM("Position"), '')  AS title,
  try_strptime("Connected On", '%d-%b-%y')::DATE AS connected_on
FROM linkedin_intel.main.connections;
