-- Rank customers by total lifetime order amount
SELECT customer_id,
       SUM(amount) as total_spend,
       DENSE_RANK() OVER(ORDER BY SUM(amount) desc) as rnk
FROM `Flipkart.orders`
GROUP BY customer_id
ORDER BY SUM(amount) desc


-- Customer’s Top Spending Product Category
WITH category_total_spend AS (
SELECT
       o.customer_id,
       p.category,
       SUM(i.quantity * i.price) as category_spend
FROM 
       `Flipkart.orders` o JOIN `Flipkart.order_items` i ON o.order_id = i.order_id
       JOIN `Flipkart.products` p ON i.product_id = p.product_id
GROUP BY 
       o.customer_id, p.category
),

Ranked_category AS (
       SELECT
              customer_id,
              category,
              category_spend,
              DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY category_spend desc) as category_rank
       FROM 
              category_total_spend

)

SELECT
       customer_id,
       category,
       category_spend,
       category_rank
FROM
       ranked_category
WHERE
       category_rank = 1
ORDER BY 
       customer_id

-- City-wise Revenue Leaders
WITH ranked_customers AS (
SELECT
       c.city,
       o.customer_id,
       SUM(o.amount) as total_revenue,
       DENSE_RANK() OVER (PARTITION BY c.city ORDER BY SUM(o.amount) desc) as dense_rank

FROM 
       `Flipkart.customers` c JOIN `Flipkart.orders` o ON c.customer_id = o.customer_id
GROUP BY 
       c.city,o.customer_id
)
SELECT
       city,
       customer_id,
       total_revenue,
       dense_rank
FROM 
       ranked_customers
WHERE 
       dense_rank IN (1,2)
ORDER BY
       city asc, dense_rank asc

-- Order-to-Order Spend Change
WITH order_to_order AS (
       SELECT
              customer_id,
              order_id,
              amount as current_amount,
              LAG(amount) OVER(
                     PARTITION BY customer_id 
                     ORDER BY order_date asc, order_id asc) as previous_amount
       FROM 
              `Flipkart.orders`
)

SELECT
       customer_id,
       order_id,
       current_amount,
       previous_amount,
       current_amount - previous_amount as change_amount
FROM 
       order_to_order
ORDER BY 
       customer_id 

-- Detect Spending Drop
WITH order_to_order AS (
       SELECT
              customer_id,
              order_id,
              amount as current_amount,
              LAG(amount) OVER(
                     PARTITION BY customer_id 
                     ORDER BY order_date asc, order_id asc) as prev_amount
       FROM 
              `Flipkart.orders`

)

SELECT
       customer_id,
       order_id,
       prev_amount,
       current_amount,
       CASE
           WHEN current_amount < prev_amount THEN 'YES' 
           ELSE 'NO'
       END AS drop_flag
FROM 
       order_to_order
ORDER BY 
       customer_id 


-- Identify Last Order Without Using COUNT
WITH order_to_order AS (
SELECT
       customer_id,
       order_id,
       amount as current_amount,
       LEAD(amount) OVER(
              PARTITION BY customer_id 
              ORDER BY order_date asc, order_id asc) as next_amount

FROM
       `Flipkart.orders`
)

SELECT
       customer_id,
       order_id,
       CASE 
           WHEN next_amount IS NULL THEN 'last_order'
           ELSE 'not_last_order'
       END AS order_flag
FROM 
       order_to_order
ORDER BY 
       customer_id asc

-- Order Value Jump Detection
WITH order_to_order AS (
       SELECT
              customer_id,
              order_id,
              amount as current_amount,
              LEAD(amount) OVER(
                     PARTITION BY customer_id 
                     ORDER BY order_date asc, order_id asc) as next_amount
       FROM 
              `Flipkart.orders`

)

SELECT
       customer_id,
       order_id,
       current_amount,
       next_amount,
       CASE
           WHEN next_amount > current_amount THEN 'YES' 
           ELSE 'NO'
       END AS increase_flag
FROM 
       order_to_order
ORDER BY 
       customer_id

-- Spend Volatility Indicator
WITH order_to_order AS (
       SELECT
              customer_id,
              order_id,
              amount as current_amount,
              LAG(amount) OVER(
                     PARTITION BY customer_id 
                     ORDER BY order_date asc, order_id asc) as prev_amount,
              LEAD(amount) OVER(
                     PARTITION BY customer_id 
                     ORDER BY order_date asc, order_id asc) as next_amount
       FROM 
              `Flipkart.orders`

)

SELECT
       customer_id,
       order_id,
       current_amount,
       prev_amount,
       next_amount,
       CASE
           WHEN ABS(prev_amount - current_amount) > 10000 
              or ABS(current_amount - next_amount) > 10000 THEN 'VOLATILE' 
           ELSE 'STABLE'
       END AS volatile_flag
FROM 
       order_to_order
ORDER BY 
       customer_id


-- Top Products per Customer
WITH total_quantity_per_product AS (
       SELECT
              o.customer_id,
              i.product_id,
              SUM(quantity) as total_quantity
       FROM 
              `Flipkart.orders` o JOIN `Flipkart.order_items` i ON o.order_id = i.order_id
       GROUP BY
              o.customer_id, i.product_id

),
ranked_products AS(
       SELECT
              customer_id,
              product_id,
              total_quantity,
              DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY total_quantity desc) AS product_rank
       FROM 
              total_quantity_per_product

)

SELECT
       customer_id,
       product_id,
       total_quantity,
       product_rank

FROM
       ranked_products
WHERE
       product_rank IN (1,2)
ORDER BY 
       customer_id

-- First and Last Purchase Amount per Customer
SELECT
       customer_id,
       order_id,
       amount,
       FIRST_VALUE(amount) OVER(PARTITION BY customer_id ORDER BY order_date asc, order_id asc) AS first_order_amount,
       LAST_VALUE(amount) OVER(PARTITION BY customer_id ORDER BY order_date asc, order_id asc 
                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_order_amount
FROM 
       `Flipkart.orders`
ORDER BY 
       customer_id

-- Growth / Decline Indicator
WITH ordered_amount AS (
SELECT
       customer_id,
       order_id,
       amount,
       FIRST_VALUE(amount) OVER(PARTITION BY customer_id ORDER BY order_date asc, order_id asc) AS first_order_amount,
       LAST_VALUE(amount) OVER(PARTITION BY customer_id ORDER BY order_date asc, order_id asc 
                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_order_amount
FROM 
       `Flipkart.orders`

)
SELECT
       DISTINCT
       customer_id,
       CASE
           WHEN last_order_amount > first_order_amount THEN 'growth'
           WHEN last_order_amount < first_order_amount THEN 'decline'
           ELSE 'stable'
       END AS customer_trend
FROM
       ordered_amount

ORDER BY 
       customer_id

-- Second Highest Order per Customer
WITH ordered_amount AS (
SELECT
       customer_id,
       order_id,
       amount,
       NTH_VALUE(amount,2) OVER(PARTITION BY customer_id ORDER BY amount desc
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as second_highest_amount
FROM 
       `Flipkart.orders`

)
SELECT
       customer_id,
       order_id,
       amount,
       second_highest_amount 
FROM
       ordered_amount
WHERE 
       amount = second_highest_amount

ORDER BY 
       customer_id

