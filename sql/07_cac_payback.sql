-- 07. CAC and payback by paid channel.
-- CAC = spend / new users. Payback (months) = CAC / monthly gross margin per user, where
-- monthly margin = 60-day revenue per user / 2 x gross margin ({margin} by default).
-- Read it: a channel with cheap CAC but weak buyers can pay back slower than a pricier one.
WITH last_day AS (SELECT MAX(CAST(order_time AS DATE)) AS d FROM orders),
cac AS (
    SELECT s.channel, SUM(s.amount) AS spend,
           (SELECT COUNT(*) FROM users u WHERE u.channel = s.channel) AS new_users
    FROM spend s GROUP BY s.channel
),
value AS (
    SELECT u.channel, COALESCE(SUM(o.amount), 0) / COUNT(DISTINCT u.user_id) AS rev_60d
    FROM users u CROSS JOIN last_day l
    LEFT JOIN orders o ON o.user_id = u.user_id
         AND CAST(o.order_time AS DATE) < CAST(u.signup_date AS DATE) + 60
    WHERE CAST(u.signup_date AS DATE) + 60 <= l.d
    GROUP BY u.channel
)
SELECT c.channel,
       ROUND(c.spend, 0)                                         AS spend,
       c.new_users,
       ROUND(c.spend / c.new_users, 0)                           AS cac,
       ROUND(v.rev_60d / 2 * {margin}, 0)                        AS monthly_margin_per_user,
       ROUND((c.spend / c.new_users) / NULLIF(v.rev_60d / 2 * {margin}, 0), 1) AS payback_months
FROM cac c JOIN value v USING (channel)
ORDER BY payback_months;
