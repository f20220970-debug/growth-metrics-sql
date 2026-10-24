-- 08. A/B test readout in SQL: conversion (ordered within 14 days of assignment) by
-- variant, absolute lift, a two-proportion z-score, and a sample-ratio-mismatch check.
-- Read it: |z| > 1.96 is significant at 5%. Check the SRM chi-square FIRST: above 6.63
-- (p < 0.01 for a 50/50 split) means the split itself is broken and results can't be trusted.
WITH conv AS (
    SELECT x.variant, x.user_id,
           MAX(CASE WHEN CAST(o.order_time AS DATE) BETWEEN CAST(x.assigned_date AS DATE)
                                                     AND CAST(x.assigned_date AS DATE) + 13
                    THEN 1 ELSE 0 END) AS converted
    FROM experiment x LEFT JOIN orders o USING (user_id)
    GROUP BY 1, 2
),
agg AS (
    SELECT variant, COUNT(*) AS n, SUM(converted) AS x, AVG(converted) AS p FROM conv GROUP BY 1
),
ab AS (
    SELECT a.n AS n_a, a.p AS p_a, b.n AS n_b, b.p AS p_b,
           (a.x + b.x) * 1.0 / (a.n + b.n) AS pooled
    FROM agg a, agg b WHERE a.variant = 'A' AND b.variant = 'B'
)
SELECT
    n_a, ROUND(p_a, 4) AS conversion_a, n_b, ROUND(p_b, 4) AS conversion_b,
    ROUND(p_b - p_a, 4)                                                         AS abs_lift,
    ROUND((p_b - p_a) / SQRT(pooled * (1 - pooled) * (1.0 / n_a + 1.0 / n_b)), 2) AS z_score,
    ROUND((POWER(n_a - (n_a + n_b) / 2.0, 2) + POWER(n_b - (n_a + n_b) / 2.0, 2)) / ((n_a + n_b) / 2.0), 2) AS srm_chi_square
FROM ab;
