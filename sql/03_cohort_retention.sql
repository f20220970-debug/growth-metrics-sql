-- 03. Weekly cohort retention triangle: of users who signed up in week W, what share
-- was active N weeks later? The classic retention chart, as a table.
-- Read it down a column to see whether newer cohorts retain better than older ones.
WITH cohort AS (
    SELECT user_id, DATE_TRUNC('week', CAST(signup_date AS DATE)) AS cohort_week FROM users
),
activity AS (
    SELECT DISTINCT user_id, DATE_TRUNC('week', CAST(event_time AS DATE)) AS active_week
    FROM events WHERE event_name = 'app_open'
),
joined AS (
    SELECT c.cohort_week, c.user_id,
           DATE_DIFF('week', c.cohort_week, a.active_week) AS week_n
    FROM cohort c JOIN activity a USING (user_id)
    WHERE a.active_week >= c.cohort_week
),
sizes AS (SELECT cohort_week, COUNT(*) AS cohort_size FROM cohort GROUP BY 1)
SELECT
    j.cohort_week, s.cohort_size, j.week_n,
    COUNT(DISTINCT j.user_id)                                   AS active_users,
    ROUND(COUNT(DISTINCT j.user_id) * 1.0 / s.cohort_size, 3)   AS retention
FROM joined j JOIN sizes s USING (cohort_week)
WHERE j.week_n BETWEEN 0 AND 8
GROUP BY 1, 2, 3
ORDER BY 1, 3;
