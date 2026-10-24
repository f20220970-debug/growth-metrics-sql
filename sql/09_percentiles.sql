-- 09. Distributions, not just averages: median and 90th percentile of order value,
-- and days from signup to first order, by city.
-- Read it: when the mean is far above the median, a few big orders are pulling it up.
WITH first_order AS (
    SELECT o.user_id, MIN(CAST(o.order_time AS DATE)) AS first_day FROM orders o GROUP BY 1
)
SELECT
    u.city,
    ROUND(AVG(o.amount), 0)                                         AS mean_order_value,
    ROUND(QUANTILE_CONT(o.amount, 0.5), 0)                          AS median_order_value,
    ROUND(QUANTILE_CONT(o.amount, 0.9), 0)                          AS p90_order_value,
    ROUND(MEDIAN(DATE_DIFF('day', CAST(u.signup_date AS DATE), f.first_day)), 1) AS median_days_to_first_order
FROM orders o
JOIN users u USING (user_id)
JOIN first_order f USING (user_id)
GROUP BY u.city
ORDER BY u.city;
