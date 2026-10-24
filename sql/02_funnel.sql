-- 02. Purchase funnel: how many users reach each step, and where do they drop?
-- Counted per user in their FIRST 7 DAYS after signup, so long-lived users don't inflate it.
-- Read it: the step with the lowest step_conversion is where to focus first.
WITH steps AS (
    SELECT * FROM (VALUES (1, 'app_open'), (2, 'view_product'), (3, 'add_to_cart'),
                          (4, 'checkout'), (5, 'purchase')) t(step_no, step)
),
reached AS (
    SELECT s.step_no, s.step, COUNT(DISTINCT e.user_id) AS users
    FROM steps s
    LEFT JOIN events e ON e.event_name = s.step
    LEFT JOIN users u  ON u.user_id = e.user_id
    WHERE e.user_id IS NULL OR CAST(e.event_time AS DATE) < CAST(u.signup_date AS DATE) + 7
    GROUP BY 1, 2
)
SELECT
    step_no, step, users,
    ROUND(users * 1.0 / LAG(users) OVER (ORDER BY step_no), 3)          AS step_conversion,
    ROUND(users * 1.0 / FIRST_VALUE(users) OVER (ORDER BY step_no), 3)  AS overall_conversion
FROM reached
ORDER BY step_no;
