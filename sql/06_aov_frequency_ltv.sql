-- 06. Average order value, purchase frequency and a simple 60-day LTV by channel.
-- LTV here = revenue per signed-up user in their first 60 days (only users with 60 days
-- of history). A proxy, not a forecast: it says which channels bring valuable customers.
WITH last_day AS (SELECT MAX(CAST(order_time AS DATE)) AS d FROM orders),
eligible AS (
    SELECT u.* FROM users u CROSS JOIN last_day l WHERE CAST(u.signup_date AS DATE) + 60 <= l.d
),
o60 AS (
    SELECT e.user_id, e.channel, o.order_id, o.amount
    FROM eligible e LEFT JOIN orders o
      ON o.user_id = e.user_id AND CAST(o.order_time AS DATE) < CAST(e.signup_date AS DATE) + 60
)
SELECT
    channel,
    COUNT(DISTINCT user_id)                                              AS users,
    ROUND(COUNT(DISTINCT user_id) FILTER (WHERE order_id IS NOT NULL) * 1.0 / COUNT(DISTINCT user_id), 3) AS buyer_rate,
    ROUND(AVG(amount), 0)                                                AS aov,
    ROUND(COUNT(order_id) * 1.0 / NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE order_id IS NOT NULL), 0), 2) AS orders_per_buyer,
    ROUND(COALESCE(SUM(amount), 0) / COUNT(DISTINCT user_id), 0)         AS ltv_60d_revenue
FROM o60
GROUP BY channel
ORDER BY ltv_60d_revenue DESC;
