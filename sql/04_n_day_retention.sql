-- 04. D1 / D7 / D30 retention by acquisition channel: share of users active exactly
-- 1, 7 and 30 days after signing up (only users old enough to have reached that day).
-- Read it: compare channels on quality, not just volume.
WITH last_day AS (SELECT MAX(CAST(event_time AS DATE)) AS d FROM events),
opens AS (SELECT DISTINCT user_id, CAST(event_time AS DATE) AS day FROM events WHERE event_name = 'app_open'),
base AS (
    SELECT u.user_id, u.channel, CAST(u.signup_date AS DATE) AS s FROM users u
)
SELECT
    b.channel,
    COUNT(*)                                                                                   AS users,
    ROUND(AVG(CASE WHEN o1.user_id IS NOT NULL THEN 1.0 ELSE 0 END) FILTER (WHERE b.s + 1  <= l.d), 3) AS d1,
    ROUND(AVG(CASE WHEN o7.user_id IS NOT NULL THEN 1.0 ELSE 0 END) FILTER (WHERE b.s + 7  <= l.d), 3) AS d7,
    ROUND(AVG(CASE WHEN o30.user_id IS NOT NULL THEN 1.0 ELSE 0 END) FILTER (WHERE b.s + 30 <= l.d), 3) AS d30
FROM base b CROSS JOIN last_day l
LEFT JOIN opens o1  ON o1.user_id  = b.user_id AND o1.day  = b.s + 1
LEFT JOIN opens o7  ON o7.user_id  = b.user_id AND o7.day  = b.s + 7
LEFT JOIN opens o30 ON o30.user_id = b.user_id AND o30.day = b.s + 30
GROUP BY b.channel
ORDER BY d30 DESC;
