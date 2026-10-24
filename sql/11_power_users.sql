-- 11. Power-user curve (L28): how many days in the last 28 was each user active?
-- A healthy habit product has a "smile": a hump of heavy users at the right end.
WITH last_day AS (SELECT MAX(CAST(event_time AS DATE)) AS d FROM events),
days_active AS (
    SELECT e.user_id, COUNT(DISTINCT CAST(e.event_time AS DATE)) AS active_days
    FROM events e CROSS JOIN last_day l
    WHERE e.event_name = 'app_open' AND CAST(e.event_time AS DATE) > l.d - 28
    GROUP BY e.user_id
)
SELECT active_days, COUNT(*) AS users,
       ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (), 3) AS share
FROM days_active
GROUP BY active_days
ORDER BY active_days;
