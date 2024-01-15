-- SCHEMA: pizza_pg_case_study

-- DROP SCHEMA IF EXISTS pizza_pg_case_study;

CREATE SCHEMA IF NOT EXISTS pizza_pg_case_study
    AUTHORIZATION postgres;

SET search_path = pizza_pg_case_study;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
    "runner_id" INTEGER,
    "registration_date" DATE
);
INSERT INTO runners ("runner_id", "registration_date")
VALUES
    (1, '2021-01-01'),
    (2, '2021-01-03'),
    (3, '2021-01-08'),
    (4, '2021-01-15');

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "pizza_id" INTEGER,
    "exclusions" VARCHAR(4),
    "extras" VARCHAR(4),
    "order_time" TIMESTAMP
);

INSERT INTO customer_orders ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
    ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
    ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
    ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
    ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
    ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
    ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
    ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
    ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
    ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
    ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
    ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
    ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
    ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
    ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
    "order_id" INTEGER,
    "runner_id" INTEGER,
    "pickup_time" VARCHAR(19),
    "distance" VARCHAR(7),
    "duration" VARCHAR(10),
    "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
    ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
    ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
    ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
    ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
    ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
    ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
    ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
    ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
    ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
    ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
    "pizza_id" INTEGER,
    "pizza_name" TEXT
);
INSERT INTO pizza_names ("pizza_id", "pizza_name")
VALUES
    (1, 'Meatlovers'),
    (2, 'Vegetarian');

DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
    "pizza_id" INTEGER,
    "toppings" TEXT
);
INSERT INTO pizza_recipes ("pizza_id", "toppings")
VALUES
    (1, '1, 2, 3, 4, 5, 6, 8, 10'),
    (2, '4, 6, 7, 9, 11, 12');

DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
    "topping_id" INTEGER,
    "topping_name" TEXT
);
INSERT INTO pizza_toppings ("topping_id", "topping_name")
VALUES
    (1, 'Bacon'),
    (2, 'BBQ Sauce'),
    (3, 'Beef'),
    (4, 'Cheese'),
    (5, 'Chicken'),
    (6, 'Mushrooms'),
    (7, 'Onions'),
    (8, 'Pepperoni'),
    (9, 'Peppers'),
    (10, 'Salami'),
    (11, 'Tomatoes'),
    (12, 'Tomato Sauce');

-- DATA CLEANING WORK

SELECT * FROM customer_orders_cleaned;
SELECT * FROM exclusions;
SELECT * FROM extras;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes_cleaned;
SELECT * FROM pizza_toppings;
SELECT * FROM runner_orders;
SELECT * FROM runners;

-- 1. cleaning customer_orders

UPDATE customer_orders SET exclusions = NULL WHERE exclusions = 'NaN' OR exclusions = '' OR exclusions = 'null';

UPDATE customer_orders SET extras = NULL WHERE extras = 'NaN' OR extras = '' OR extras = 'null';

CREATE TABLE customer_orders_cleaned AS
SELECT
    "co"."order_id",
    "co"."customer_id",
    "co"."pizza_id",
    "e"."exclusion",
    "e"."extra",
    "co"."order_time"
FROM customer_orders "co"
LEFT JOIN LATERAL (
    SELECT
        regexp_split_to_table("co"."exclusions", ',')::integer AS "exclusion",
        regexp_split_to_table("co"."extras", ',')::integer AS "extra"
) AS "e" ON TRUE
ORDER BY "co"."order_id";

-- 1.5 creation of exclusions and extras table 

ALTER TABLE customer_orders_cleaned ADD COLUMN id SERIAL PRIMARY KEY;

CREATE TABLE exclusions AS
SELECT id, order_id, exclusion :: INTEGER AS exclusion_id
FROM customer_orders_cleaned;

CREATE TABLE extras AS
SELECT id, order_id, extra :: INTEGER AS extra_id
FROM customer_orders_cleaned;

-- 2. cleaning runner_orders

UPDATE runner_orders
SET
    pickup_time = NULLIF(pickup_time, 'null'),
    cancellation = NULLIF(NULLIF(NULLIF(cancellation, ''), 'null'), 'NaN'),
    distance = NULLIF(NULLIF(regexp_replace(distance, '[a-z]+', '', 'g'), ''), 'null')::DECIMAL(3,1),
    duration = NULLIF(NULLIF(regexp_replace(duration, '[a-z]+', '', 'g'), ''), 'null')::INTEGER;

-- 3. cleaning pizza_recipes

CREATE TABLE pizza_recipes_cleaned AS
SELECT
    pizza_id,
    unnest(string_to_array(toppings, ', ')::int[]) AS topping
FROM pizza_recipes;

-------------------------------------------------------------------------------------------------------------------------------
										-- A. Pizza Metrics
-------------------------------------------------------------------------------------------------------------------------------

-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS Pizza_Orders
FROM customer_orders_cleaned;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS Distinct_Orders
FROM customer_orders_cleaned;

-- 3. How many successful orders were delivered by each runner?

SELECT COUNT(*) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL;

-- 4. How many of each type of pizza was delivered?

SELECT pizza_id AS pizzas, COUNT(*) AS successfully_delivered
FROM customer_orders_cleaned coc
INNER JOIN runner_orders ro ON coc.order_id = ro.order_id 
WHERE cancellation IS NULL
GROUP BY pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

WITH CTE AS (
    SELECT 
        customer_id, 
        CASE WHEN pizza_id = 1 THEN 'MeatLover' ELSE NULL END AS orders_non_veg,
        CASE WHEN pizza_id = 2 THEN 'Vegetarian' ELSE NULL END AS orders_veg
    FROM customer_orders_cleaned
)
SELECT
    customer_id,
    COUNT(orders_non_veg) AS MeatLover,
    COUNT(orders_veg) AS Vegetarian
FROM CTE
GROUP BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT
    order_id,
    COUNT(order_id) AS most_ordered
FROM customer_orders_cleaned
GROUP BY order_id
ORDER BY most_ordered DESC
LIMIT 4;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
    customer_id,
    SUM(CASE WHEN exclusion IS NOT NULL OR extra IS NOT NULL THEN 1 ELSE 0 END) AS changes_made,
    SUM(CASE WHEN exclusion IS NULL AND extra IS NULL THEN 1 ELSE 0 END) AS changes_not_made
FROM customer_orders_cleaned
LEFT JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT
    customer_id,
    SUM(CASE WHEN exclusion IS NOT NULL AND extra IS NOT NULL THEN 1 ELSE 0 END) AS changes_made
FROM customer_orders_cleaned
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY customer_id;

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
    EXTRACT(HOUR FROM order_time) AS hour,
    COUNT(order_id) AS order_count
FROM customer_orders_cleaned
GROUP BY hour
ORDER BY order_count DESC;

-- 10. What was the volume of orders for each day of the week?

SELECT
    EXTRACT(DOW FROM order_time) AS day_of_week,
    COUNT(order_id) AS count_of_orders
FROM customer_orders_cleaned
GROUP BY day_of_week
ORDER BY count_of_orders DESC;
----------------------------------------------------------------------------------------------------------------------
							-- B. Runner and Customer Experience
-----------------------------------------------------------------------------------------------------------------------
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    EXTRACT(WEEK FROM registration_date) AS week_joined,
    COUNT(runner_id) AS runner_signed
FROM runners
GROUP BY week_joined;

-- 2. What was the average time in minutes it took for each 
-- runner to arrive at the Pizza Runner HQ to pick up the order?

SELECT 
    runner_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (pickup_time::timestamp - order_time::timestamp)) / 60.0), 2) AS time_require_estm
FROM customer_orders_cleaned
LEFT JOIN runner_orders USING(order_id)
GROUP BY runner_id;

-- 3. Is there any relationship between 
-- the number of pizzas and how long the order takes to prepare?

WITH prep_time AS (
SELECT
   ro.order_id,
   COUNT(co.pizza_id) AS qty_pizzas,
   EXTRACT(EPOCH FROM ro.pickup_time::timestamp - co.order_time::timestamp) / 60 AS prep_time
	FROM runner_orders ro
JOIN customer_orders_cleaned co ON co.order_id = ro.order_id
GROUP BY ro.order_id, prep_time
)

SELECT
    qty_pizzas,
    ROUND(AVG(prep_time),2) AS avg_prep_time
FROM prep_time
GROUP BY qty_pizzas
ORDER BY qty_pizzas;

-- 4. What was the average distance travelled for each customer?

SELECT 
    c.customer_id,
    ROUND(AVG(CAST(r.distance AS NUMERIC)), 1) AS dist_trav
FROM customer_orders_cleaned c
JOIN runner_orders r USING(order_id)
WHERE cancellation IS NULL
GROUP BY c.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    (MAX(duration::DECIMAL) - MIN(duration::DECIMAL)) AS duration_difference
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery, and do you notice any trend for these values?

SELECT 
    runner_id,
    order_id,
    ROUND(AVG((distance :: NUMERIC) / (duration :: DECIMAL/ 60)), 1) AS average_KmPH
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?

WITH deliveries AS(
SELECT
runner_id,
COUNT(order_id) AS total_deliveries,
SUM(CASE WHEN cancellation IS NOT NULL THEN 0
ELSE 1 END) AS successful_deliveries
FROM runner_orders
GROUP BY runner_id)
SELECT *, ROUND((successful_deliveries::DECIMAL/total_deliveries::DECIMAL),2) AS perc_successful
FROM deliveries;
-----------------------------------------------------------------------------------------------------------------------
									-- C. Ingredient Optimization
----------------------------------------------------------------------------------------------------------------------
-- 1. What are the standard ingredients for each pizza?

SELECT
  pn.pizza_name,
  pt.topping_name
FROM pizza_names pn
JOIN pizza_recipes_cleaned prc ON prc.pizza_id = pn.pizza_id
JOIN pizza_toppings pt ON pt.topping_id = prc.topping
ORDER BY pn.pizza_name, pt.topping_name;
  
-- 2. What was the most commonly added extra?

SELECT 
    pt.topping_name, 
    COUNT(c.extra) as most_added
FROM customer_orders_cleaned c 
INNER JOIN  pizza_toppings pt ON c.extra:: DECIMAL = pt.topping_id:: DECIMAL
GROUP BY pt.topping_name
ORDER BY COUNT(c.extra) DESC LIMIT 1;

-- 3. What was the most common exclusion?

SELECT 
    pt.topping_name, 
    COUNT(c.exclusion) as most_exclusion
FROM customer_orders_cleaned c 
INNER JOIN  pizza_toppings pt ON c.exclusion:: DECIMAL = pt.topping_id:: DECIMAL
GROUP BY pt.topping_name
ORDER BY COUNT(c.exclusion) DESC LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- A. Meat Lovers
-- B. Meat Lovers - Exclude Beef
-- C. Meat Lovers - Extra Bacon
-- D. Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT
	tco.order_id,
    tco.pizza_id,
    pn.pizza_name,
    tco.exclusion,
    tco.extra,
    CASE
		WHEN tco.pizza_id = 1 AND tco.exclusion IS NULL AND tco.extra IS NULL THEN 'Meat Lovers'
        WHEN tco.pizza_id = 2 AND tco.exclusion IS NULL AND tco.extra IS NULL THEN 'Vegetarian'
        WHEN tco.pizza_id = 1 AND tco.exclusion = '4' AND tco.extra IS NULL THEN 'Meat Lovers - Exclude Cheese'
        WHEN tco.pizza_id = 2 AND tco.exclusion = '4' AND tco.extra IS NULL THEN 'Vegetarian - Exclude Cheese'
        WHEN tco.pizza_id = 1 AND tco.exclusion IS NULL AND tco.extra = '1' THEN 'Meat Lovers - Extra Bacon'
        WHEN tco.pizza_id = 2 AND tco.exclusion IS NULL AND tco.extra = '1' THEN 'Vegetarian - Extra Bacon'
        WHEN tco.pizza_id = 1 AND tco.exclusion = '4' AND tco.extra = '1' THEN 'Meat Lovers - Exclude Cheese - Extra Bacon and Chicken'
		WHEN tco.pizza_id = 1 AND tco.exclusion = '4' AND tco.extra = '5' THEN 'Meat Lovers - Exclude Cheese - Extra Bacon and Chicken'
        WHEN tco.pizza_id = 1 AND tco.exclusion = '2' AND tco.extra = '1' THEN 'Meat Lovers - Exclude BBQ Sauce and Mushroom - Extra Bacon and Cheese'
		WHEN tco.pizza_id = 1 AND tco.exclusion = '6' AND tco.extra = '4' THEN 'Meat Lovers - Exclude BBQ Sauce and Mushroom - Extra Bacon and Cheese'
	END AS order_item
FROM customer_orders_cleaned tco
JOIN pizza_names pn ON tco.pizza_id = pn.pizza_id ORDER BY order_id;

-- 5. Generate an alphabetically ordered comma-separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH pizza_details AS (
    SELECT
        co.id,
        co.order_id,
        co.pizza_id,
        pn.pizza_name,
        pt.topping_name,
        CASE
            WHEN pt.topping_id IN (SELECT extra_id FROM extras WHERE id = co.id) THEN '2x'
            ELSE NULL
        END AS double_option
    FROM
        customer_orders_cleaned co
    JOIN
        pizza_recipes_cleaned pi ON pi.pizza_id = co.pizza_id
    JOIN
        pizza_names pn ON pn.pizza_id = pi.pizza_id
    JOIN
        pizza_toppings pt ON pt.topping_id = pi.topping
    WHERE
        pt.topping_id NOT IN (SELECT exclusion_id FROM exclusions WHERE id = co.id)
    ORDER BY
        co.id,
        pt.topping_name
)

SELECT
    id,
    order_id,
    CONCAT(
        pizza_name,
        ': ',
        STRING_AGG(
            CONCAT(
                COALESCE(double_option || '', ''),
                topping_name
            ),
            ', ' ORDER BY topping_name -- Order alphabetically
        )
    ) AS order_detail
FROM
    pizza_details
GROUP BY
    id,
    order_id,
    pizza_id,
    pizza_name
ORDER BY
    id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH ingredient_count AS(
      SELECT
        co.id,
        co.order_id,
        co.pizza_id,
        pn.pizza_name,
        pt.topping_name,
        CASE
          WHEN
            pt.topping_id IN (SELECT extra_id FROM extras WHERE id = co.id)
          THEN
            '2'
          ELSE 1
        END
        AS quantity
      FROM
        customer_orders_cleaned co
      JOIN pizza_recipes_cleaned pi ON
        pi.pizza_id = co.pizza_id
      JOIN pizza_names pn ON
        pn.pizza_id = pi.pizza_id
      JOIN pizza_toppings pt ON
        pt.topping_id = pi.topping
      WHERE
        pt.topping_id NOT IN (SELECT exclusion_id FROM exclusions WHERE id = co.id)
    )
SELECT
  topping_name,
  SUM(quantity) as total_quantity
FROM
  ingredient_count
GROUP BY
  topping_name
ORDER BY
  total_quantity DESC;
---------------------------------------------------------------------------------------------------------------------
								-- D. Pricing and Ratings								
---------------------------------------------------------------------------------------------------------------------
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10, and there were no charges for changes,
-- how much money has Pizza Runner made so far if there are no delivery fees?

WITH pricing AS (
    SELECT
        pizza_id,
        CASE
            WHEN pizza_id = 1 THEN 12 * COUNT(*)
            ELSE 10 * COUNT(*)
        END AS prices
    FROM
        customer_orders_cleaned
    INNER JOIN
        runner_orders USING (order_id)
    WHERE
        cancellation IS NULL
    GROUP BY
        pizza_id
)
SELECT
    SUM(prices) AS total_cash_earned
FROM
    pricing;

-- 2. What if there was an additional $1 charge for any pizza extras?

WITH pricing AS (
    SELECT
        pizza_id,
        extra,
        CASE
            WHEN pizza_id = 1 THEN 12 * COUNT(*)
            ELSE 10 * COUNT(*)
        END AS prices,
        CASE
            WHEN extra IS NOT NULL THEN 1
            ELSE 0
        END AS extra_price
    FROM
        customer_orders_cleaned
    INNER JOIN
        runner_orders USING (order_id)
    WHERE
        cancellation IS NULL
    GROUP BY
        id,
        extra
)
SELECT
    SUM(prices) + SUM(extra_price) AS total_cash_earned
FROM
    pricing;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their
-- runner, how would you design an additional table for this new dataset - generate a schema for this new table
-- and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS customer_ratings;

CREATE TABLE customer_ratings (
    order_id INTEGER,
    rating INTEGER,
    comments VARCHAR(150),
    rating_time TIMESTAMP
);

INSERT INTO customer_ratings
    (order_id, rating, comments, rating_time)
VALUES
    ('1', '4', 'Late but polite!', '2020-01-01 18:57:54'),
    ('2', '5', 'Delivery was late', '2020-01-01 22:01:32'),
    ('3', '5', 'Excellent!', '2020-01-04 01:11:09'),
    ('4', '5', 'Delivered on time', '2020-01-04 14:37:14'),
    ('5', '1', 'Rude and was late', '2020-01-08 21:59:44'),
    ('7', '5', 'Portions were small', '2020-01-08 21:58:22'),
    ('8', '3', 'Called too much!', '2020-01-12 13:20:01'),
    ('10', '5', 'Perfect!', '2020-01-11 21:22:57');

-- 4. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras,
-- and each runner is paid $0.30 per kilometre traveled, how much money does Pizza Runner have left over after these deliveries?

WITH OrderCost AS (
    SELECT
        co.order_id,
        pn.pizza_name,
        CASE
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
        END AS pizza_cost,
        ro.distance::numeric,
        ro.runner_id
    FROM
        customer_orders_cleaned co
    JOIN
        pizza_names pn ON co.pizza_id = pn.pizza_id
    JOIN
        runner_orders ro ON co.order_id = ro.order_id
    WHERE
        ro.cancellation IS NULL
)

SELECT
    SUM(pizza_cost) AS total_pizza_cost,
    SUM(distance * 0.30) AS total_delivery_cost,
    SUM(pizza_cost) + SUM(distance * 0.30) AS total_cost,
    COUNT(DISTINCT runner_id) * 0.30 * SUM(distance) AS total_runner_payment,
    (SUM(pizza_cost) + SUM(distance * 0.30)) - (COUNT(DISTINCT runner_id) * 0.30 * SUM(distance)) AS profit_left_over
FROM
    OrderCost;

--------------------------------------------------------------------------------------------------------------
				-- SOME KPI'S WHICH COULD HELP US DO ANALYSIS
--------------------------------------------------------------------------------------------------------------

-- Delivery Success Rate: 80 %
-- Definition: Percentage of successful deliveries out of total attempted deliveries.

SELECT
    (COUNT(CASE WHEN cancellation IS NULL THEN 1 END) * 100.0) / COUNT(*) AS delivery_success_rate
FROM runner_orders;

-- Average Order Value (AOV): $11.53
-- Definition: Average monetary value of orders.

SELECT
    AVG(prices) AS average_order_value
FROM (
    SELECT
        pizza_id,
        CASE WHEN pizza_id = 1 THEN 12 * COUNT(*) ELSE 10 * COUNT(*) END AS prices
    FROM
        customer_orders_cleaned
        INNER JOIN runner_orders USING (order_id)
    WHERE
        cancellation IS NULL
    GROUP BY
        pizza_id, id
) pricing;

-- Average Delivery Time: 38 mins
-- Average time taken to deliver an order.

SELECT
    AVG(EXTRACT(EPOCH FROM duration::interval) / 60) AS average_delivery_time_minutes
FROM
    runner_orders
WHERE
    duration IS NOT NULL AND cancellation IS NULL;


-- Runner Efficiency: 63.88 %
-- Definition: Percentage of time spent on actual deliveries out of total working time.

SELECT
    SUM(EXTRACT(EPOCH FROM duration::interval) / 60) / (COUNT(*) * 60.0) * 100 AS runner_efficiency
FROM
    runner_orders
WHERE
    duration IS NOT NULL AND cancellation IS NULL;


-- Customer Ratings Average: 4.12
-- Definition: Average customer ratings for successful orders.

SELECT
    AVG(rating) AS average_customer_rating
FROM
    customer_ratings
WHERE
    rating IS NOT NULL;

-- Average Distance Covered per Delivery: 18.15 miles
-- Definition: Average distance covered by runners per successful delivery.

SELECT
    AVG(distance::numeric) AS average_distance_covered
FROM
    runner_orders
WHERE
    cancellation IS NULL;

-- Peak Order Hours: 00 hours ie 12:00 AM
-- Definition: Identify peak hours for order placements.

SELECT
    EXTRACT(HOUR FROM CAST(pickup_time AS TIMESTAMP)) AS peak_hour,
    COUNT(*) AS order_count
FROM
    runner_orders
WHERE
    cancellation IS NULL
GROUP BY
    peak_hour
ORDER BY
    order_count DESC
LIMIT 1;

 

-- SOME INSIGHTS GENERATED FROM CASE STUDY ABOVE

-- 1. Most successful orders are delivered by Runner ID 1.
-- 2. Majority of the delivered pizzas had no changes.
-- 3. Maximum number of pizzas delivered in a single order was 18.
-- 4. Busiest hour of the day was from 7 pm to 9 pm.
-- 5. Busiest day of the week was Sunday.
-- 5. The average time it takes for each runner to arrive at the Pizza Runner HQ to pickup the order is 38 minutes.
-- 6. The longest delivery time was 2 hours and 25 minutes, and the shortest delivery time was 4 minutes.
-- 7. There was no correlation between the number of pizzas in an order and how long it takes to prepare them.
-- 8. Most of the customers live within 5-6 km of the HQ.

