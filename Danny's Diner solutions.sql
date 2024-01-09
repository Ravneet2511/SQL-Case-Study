/* 
DANNY DINER CASE STUDY SOLUTION BY RAVNEET SINGH 
LINK =>> https://8weeksqlchallenge.com/case-study-1/

*/

Use dannys_diner;
----------------------------------------------------------------------------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id as customers, sum(m.price) as price_spent
FROM sales s 
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

----------------------------------------------------------------------------------------------------------------------

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id as customers, count(distinct s.order_date) as visiting_days
FROM sales s
GROUP BY s.customer_id;

----------------------------------------------------------------------------------------------------------------------

-- 3. What was the first item from the menu purchased by each customer?

WITH ordered_orders AS (
  SELECT 
    s.customer_id as customer_id,
    s.order_date,
    m.product_name as product_name,
    DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rrank
  FROM sales s
  INNER JOIN menu m ON s.product_id = m.product_id
)
SELECT 
  oo.customer_id AS customer,
  oo.product_name AS product
FROM ordered_orders oo
WHERE oo.rrank = 1
group by oo.customer_id, oo.product_name;

----------------------------------------------------------------------------------------------------------------------

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name as product, count(s.product_id) as most_times_sold
from menu m inner join sales s on m.product_id = s.product_id
group by m.product_name
order by count(s.product_id) desc limit 1;

----------------------------------------------------------------------------------------------------------------------

-- 5. Which item was the most popular for each customer?

WITH orders AS (
  SELECT 
    sales.customer_id AS customer, 
    menu.product_name AS product, 
    COUNT(sales.product_id) AS order_count,
    DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) AS rrank
  FROM dannys_diner.menu
  JOIN dannys_diner.sales
    ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)
SELECT 
  o.customer, 
  o.product
FROM orders o 
WHERE rrank = 1;

----------------------------------------------------------------------------------------------------------------------

-- 6. Which item was purchased first by the customer after they became a member?

WITH joining_purchase AS (
  SELECT 
    mem.customer_id AS cust, 
    sal.product_id AS prod,
    ROW_NUMBER() OVER (PARTITION BY mem.customer_id ORDER BY sal.order_date) AS rnum
  FROM members mem
  INNER JOIN sales sal ON mem.customer_id = sal.customer_id AND mem.join_date < sal.order_date
)
SELECT 
  j.cust AS customer, 
  m.product_name AS product_before_joining
FROM joining_purchase j
INNER JOIN menu m ON j.prod = m.product_id
WHERE j.rnum = 1
ORDER BY j.cust;

----------------------------------------------------------------------------------------------------------------------

-- 7. Which item was purchased just before the customer became a member?

WITH preceding_purchase AS (
  SELECT 
    mem.customer_id AS customer,
    sal.product_id AS product,
    sal.order_date,
    ROW_NUMBER() OVER (PARTITION BY mem.customer_id ORDER BY sal.order_date) AS rnum
  FROM members mem
  JOIN sales sal ON mem.customer_id = sal.customer_id
  WHERE sal.order_date <= mem.join_date
)

SELECT 
  pp.customer AS customer,
  m.product_name AS product
FROM preceding_purchase pp
JOIN menu m ON pp.product = m.product_id
WHERE pp.rnum = 3
ORDER BY pp.customer;

----------------------------------------------------------------------------------------------------------------------

-- 8.  What is the total items and amount spent for each member before they became a member?

WITH info AS (
  SELECT 
    mem.customer_id AS cust, 
    sal.product_id AS prod
  FROM members mem
  INNER JOIN sales sal ON mem.customer_id = sal.customer_id
  AND sal.order_date < mem.join_date
)

SELECT 
  inf.cust AS customers, 
  COUNT(inf.prod) AS total_prod, 
  SUM(mnu.price) AS amt_spent
FROM info inf
JOIN menu mnu ON inf.prod = mnu.product_id
GROUP BY inf.cust
ORDER BY inf.cust;

----------------------------------------------------------------------------------------------------------------------

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?

SELECT 
  sal.customer_id AS customers, 
  SUM(CASE WHEN mnu.product_id = 1 THEN mnu.price * 20 ELSE mnu.price * 10 END) AS total_points
FROM menu mnu 
INNER JOIN sales sal ON mnu.product_id = sal.product_id
GROUP BY sal.customer_id;

----------------------------------------------------------------------------------------------------------------------

-- 10. In the first week after a customer joins the program (including their join date)
--  they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH mem_info AS (
  SELECT 
    customer_id, 
    join_date, 
    join_date + 6 AS valid_date, 
    LAST_DAY('2021-01-01') AS last_date
  FROM members
)

SELECT 
  sal.customer_id as customers, 
  SUM(CASE
    WHEN mnu.product_name = 'sushi' THEN 2 * 10 * mnu.price
    WHEN sal.order_date BETWEEN mem.join_date AND mem.valid_date THEN 2 * 10 * mnu.price
    ELSE 10 * mnu.price END) AS points
FROM sales sal
JOIN mem_info mem
  ON sal.customer_id = mem.customer_id
  AND sal.order_date <= mem.last_date
JOIN menu mnu
  ON sal.product_id = mnu.product_id
GROUP BY sal.customer_id
ORDER BY sal.customer_id;

----------------------------------------------------------------------------------------------------------------------

-- BONUS QUESTION DATABASE
-- creating basic data tables that Danny and his team 
-- can use to quickly derive insights without needing to join the underlying tables using SQL.

  SELECT
    sal.customer_id AS customer_id,
    sal.order_date AS order_date,
    mnu.product_name AS product_name,
    mnu.price AS price,
    CASE 
      WHEN sal.order_date >= mem.join_date THEN 'Y'
      WHEN sal.order_date < mem.join_date THEN 'N'
      ELSE 'N' 
    END AS member
  FROM 
    sales sal
    LEFT JOIN members mem ON sal.customer_id = mem.customer_id
    INNER JOIN menu mnu ON sal.product_id = mnu.product_id
  ORDER BY 
    sal.customer_id, sal.order_date;

----------------------------------------------------------------------------------------------------------------------

-- RANKING BONUS QUESTION
-- Danny also requires further information about the ranking of customer products,
-- but he purposely does not need the ranking for non-member purchases 
-- so he expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH diner_info AS (
  SELECT
    sal.customer_id AS customer_id,
    sal.order_date AS order_date,
    mnu.product_name AS product_name,
    mnu.price AS price,
    CASE 
      WHEN sal.order_date >= mem.join_date THEN 'Y'
      WHEN sal.order_date < mem.join_date THEN 'N'
      ELSE 'N' 
    END AS member
  FROM 
    sales sal
    LEFT JOIN members mem ON sal.customer_id = mem.customer_id
    INNER JOIN menu mnu ON sal.product_id = mnu.product_id
  ORDER BY 
    sal.customer_id, sal.order_date
)

SELECT 
  *, 
  CASE 
    WHEN member = 'N' THEN NULL 
    ELSE DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) 
  END AS ranking
FROM 
  diner_info;

----------------------------------------------------------------------------------------------------------------------











