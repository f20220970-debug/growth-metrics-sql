-- 10. First-touch vs last-touch attribution: which channel gets credit for buyers' revenue?
-- Technique: ROW_NUMBER() over each user's touches, ascending and descending.
-- Read it: channels that look weak on last touch but strong on first touch are
-- starting journeys that others finish; cutting them can quietly hurt growth.
WITH ranked AS (
    SELECT user_id, channel,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY touch_time)      AS first_rank,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY touch_time DESC) AS last_rank
    FROM touches
),
revenue AS (SELECT user_id, SUM(amount) AS revenue FROM orders GROUP BY 1),
credit AS (
    SELECT r.channel,
           SUM(CASE WHEN r.first_rank = 1 THEN v.revenue ELSE 0 END) AS first_touch_revenue,
           SUM(CASE WHEN r.last_rank  = 1 THEN v.revenue ELSE 0 END) AS last_touch_revenue
    FROM ranked r JOIN revenue v USING (user_id)
    GROUP BY r.channel
)
SELECT channel,
       ROUND(first_touch_revenue, 0) AS first_touch_revenue,
       ROUND(last_touch_revenue, 0)  AS last_touch_revenue,
       ROUND(first_touch_revenue * 1.0 / SUM(first_touch_revenue) OVER (), 3) AS first_touch_share,
       ROUND(last_touch_revenue  * 1.0 / SUM(last_touch_revenue)  OVER (), 3) AS last_touch_share
FROM credit
ORDER BY channel;
