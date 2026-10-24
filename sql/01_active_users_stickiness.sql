-- 01. Daily, weekly and monthly active users, and stickiness (DAU / MAU).
-- "Active" = opened the app that day. WAU and MAU are ROLLING windows (last 7 / 28 days),
-- computed with a range join, so every day has a comparable value.
-- Read it: stickiness of 20% means the average monthly user opens the app about 6 days a month.
WITH days AS (
    SELECT DISTINCT CAST(event_time AS DATE) AS day FROM events
),
daily AS (
    SELECT CAST(event_time AS DATE) AS day, user_id FROM events
    WHERE event_name = 'app_open' GROUP BY 1, 2
)
SELECT
    d.day,
    COUNT(DISTINCT u.user_id) FILTER (WHERE u.day = d.day)                         AS dau,
    COUNT(DISTINCT u.user_id) FILTER (WHERE u.day > d.day - INTERVAL 7 DAY)        AS wau,
    COUNT(DISTINCT u.user_id)                                                      AS mau,
    ROUND(COUNT(DISTINCT u.user_id) FILTER (WHERE u.day = d.day) * 1.0
          / NULLIF(COUNT(DISTINCT u.user_id), 0), 3)                               AS stickiness
FROM days d
JOIN daily u ON u.day > d.day - INTERVAL 28 DAY AND u.day <= d.day
GROUP BY d.day
ORDER BY d.day;
