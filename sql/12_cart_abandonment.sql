-- 12. Cart abandonment by hour of day: of sessions with an add-to-cart, what share ended
-- without a purchase within 60 minutes? Pairs each add_to_cart with the next purchase.
-- Read it: hours with high abandonment are candidates for checkout nudges or fixes.
WITH carts AS (
    SELECT user_id, event_time AS cart_time FROM events WHERE event_name = 'add_to_cart'
),
paired AS (
    SELECT c.user_id, c.cart_time,
           MIN(p.event_time) AS purchase_time
    FROM carts c
    LEFT JOIN events p ON p.user_id = c.user_id AND p.event_name = 'purchase'
         AND CAST(p.event_time AS TIMESTAMP) BETWEEN CAST(c.cart_time AS TIMESTAMP)
                                                AND CAST(c.cart_time AS TIMESTAMP) + INTERVAL 60 MINUTE
    GROUP BY 1, 2
)
SELECT HOUR(CAST(cart_time AS TIMESTAMP)) AS hour,
       COUNT(*)                                                   AS carts,
       ROUND(AVG(CASE WHEN purchase_time IS NULL THEN 1.0 ELSE 0 END), 3) AS abandonment_rate
FROM paired
GROUP BY 1
ORDER BY 1;
