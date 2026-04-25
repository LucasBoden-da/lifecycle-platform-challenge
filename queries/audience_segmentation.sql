--users with at least 3 searches in the last 90 days
DECLARE run_date DATE DEFAULT CURRENT_DATE();

with search_activity as (
  select renter_id, count(*) as searches_count
  from renter_activity
  where event_timestamp >= TIMESTAMP_SUB(TIMESTAMP(run_date), INTERVAL 90 DAY)
  and event_type = 'search'
  group by renter_id
  having count(*) >= 3
)
--select all churned users who have not logged in for 30 days, have a phone number, have opted in for SMS, are not on the suppression list, and have at least 3 searches in the last 90 days
SELECT
  rp.renter_id,
  rp.email,
  rp.phone,
  rp.last_login,
  sa.searches_count AS search_count,
  DATE_DIFF(run_date, DATE(rp.last_login), DAY) AS days_since_login
FROM renter_profiles rp
JOIN search_activity sa
  ON rp.renter_id = sa.renter_id
WHERE 1=1
  AND rp.last_login < TIMESTAMP_SUB(TIMESTAMP(run_date), INTERVAL 30 DAY)
  AND rp.subscription_status = 'churned'
  AND rp.phone IS NOT NULL
  AND rp.sms_consent = TRUE
  AND NOT EXISTS (
    SELECT 1
    FROM suppression_list sl
    WHERE sl.renter_id = rp.renter_id
  )
  AND (rp.dnd_until IS NULL OR rp.dnd_until < TIMESTAMP(run_date))