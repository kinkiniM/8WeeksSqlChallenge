/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(price) AS total_amount_spent 
FROM sales 
JOIN menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id; 

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT customer_id, MIN(product_name) AS first_ordered_item
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT sales.product_id, 
	   product_name, 
       COUNT(sales.product_id) AS no_of_times_ordered
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.product_id, product_name
ORDER BY no_of_times_ordered DESC
LIMIT 1;
-- 5. Which item was the most popular for each customer?
WITH ranked_item AS
 (
	SELECT customer_id, 
           product_name, 
           COUNT(sales.product_id) AS no_of_times_ordered,
	       DENSE_RANK() OVER( PARTITION BY customer_id 
                              ORDER BY COUNT(sales.product_id) DESC) 
		   AS item_rank
     FROM sales 
     JOIN menu ON sales.product_id = menu.product_id
     GROUP BY customer_id, product_name
 )
SELECT customer_id, product_name, no_of_times_ordered
FROM ranked_item
WHERE item_rank = 1; 

-- 6. Which item was purchased first by the customer after they became a member?
SELECT members.customer_id, 
       menu.product_id,  
       product_name, 
       order_date 
FROM members 
JOIN sales ON sales.customer_id = members.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date > join_date;

-- 7. Which item was purchased just before the customer became a member?

SELECT members.customer_id ,menu.product_id, product_name, order_date 
FROM members 
JOIN sales ON sales.customer_id = members.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date < join_date;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT members.customer_id ,
       order_date,join_date,  
       COUNT(menu.product_id) AS total_item, 
       SUM(price) AS total_amount_spent
FROM members 
JOIN sales on sales.customer_id = members.customer_id
JOIN menu on sales.product_id = menu.product_id
GROUP BY customer_id, order_date, join_date
HAVING order_date > join_date;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_aquired AS
(
	SELECT customer_id, product_name, price,
		CASE
			WHEN product_name = 'sushi' THEN (price*10)*2
			ELSE(price*10)
		END AS points
	FROM sales 
	JOIN menu ON sales.product_id = menu.product_id
)
SELECT customer_id, SUM(points) AS total_points
FROM points_aquired 
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH first_week_orders AS
(
    SELECT members.customer_id,
           product_name,
           price,
           order_date,
		   join_date,
	       CASE 
				WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price * 2
				ELSE price * 10
		   END AS earned_points
    FROM sales 
    JOIN members ON sales.customer_id = members.customer_id
    JOIN menu ON menu.product_id = sales.product_id
    WHERE order_date <= '2021-01-31' 
	      AND members.customer_id IN ('A', 'B') 
)
SELECT customer_id, 
       SUM(earned_points) AS total_points
FROM first_week_orders
GROUP BY customer_id;


/* Bonus questions */
SELECT sales.customer_id,
       order_date,
       product_name,	
       price,
       CASE
			WHEN join_date IS NULL THEN 'N'
			WHEN  join_date > order_date THEN 'N'
            ELSE 'Y'
		END AS member_
FROM sales 
LEFT JOIN menu ON sales.product_id = menu.product_id 
LEFT JOIN members ON  members.customer_id = sales.customer_id
ORDER BY sales.customer_id, order_date;


/* Rank all things */

WITH cust_rank AS
(
	SELECT sales.customer_id,
       order_date,
       product_name,	
       price,
       CASE
			WHEN join_date IS NULL THEN 'N'
			WHEN  join_date > order_date THEN 'N'
            ELSE 'Y'
		END AS member_
	FROM sales 
	LEFT JOIN menu ON sales.product_id = menu.product_id 
	LEFT JOIN members ON  members.customer_id = sales.customer_id
)
SELECT * ,
       CASE
		  WHEN member_ != 'N'
            THEN DENSE_RANK() OVER(PARTITION BY customer_id, member_
								    ORDER BY order_date)
		  ELSE NULL
	   END as rank_
FROM cust_rank;



