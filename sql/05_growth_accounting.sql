-- 05. Growth accounting: each month's active buyers split into new, retained and
-- resurrected, plus churned buyers from the previous month.
-- Read it: growth = new + resurrected - churned. If churned outpaces new, acquisition is
-- filling a leaky bucket.
WITH monthly AS (
    SELECT DISTINCT user_id, DATE_TRUNC('month', CAST(order_time AS TIMESTAMP)) AS m FROM orders
),
first_m AS (SELECT user_id, MIN(m) AS first_month FROM monthly GROUP BY 1),
months AS (SELECT DISTINCT m FROM monthly),
status AS (
    SELECT cur.m, cur.user_id,
           CASE WHEN f.first_month = cur.m THEN 'new'
                WHEN prev.user_id IS NOT NULL THEN 'retained'
                ELSE 'resurrected' END AS state
    FROM monthly cur
    JOIN first_m f USING (user_id)
    LEFT JOIN monthly prev ON prev.user_id = cur.user_id AND prev.m = cur.m - INTERVAL 1 MONTH
),
churned AS (
    SELECT mo.m, COUNT(*) AS churned
    FROM months mo
    JOIN monthly prev ON prev.m = mo.m - INTERVAL 1 MONTH
    LEFT JOIN monthly cur ON cur.user_id = prev.user_id AND cur.m = mo.m
    WHERE cur.user_id IS NULL
    GROUP BY mo.m
)
SELECT s.m AS month,
       COUNT(*) FILTER (WHERE state = 'new')          AS new_buyers,
       COUNT(*) FILTER (WHERE state = 'retained')     AS retained,
       COUNT(*) FILTER (WHERE state = 'resurrected')  AS resurrected,
       COALESCE(MAX(c.churned), 0)                    AS churned,
       COUNT(*)                                       AS active_buyers
FROM status s LEFT JOIN churned c ON c.m = s.m
GROUP BY s.m
ORDER BY s.m;
