-- Monday Coffee -- Data Analysis
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis
-- Q1. Coffe Consumers Count
-- How many pepople in each city are estimated to consume coffee,given that 25% of the population does ?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
From city
ORDER BY 2 DESC

-- Q.2
-- Total Revenue from coffee sales
-- What is the total rvenue generated from coffe sales across all cities in the last quearter of 2023?

SELECT
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4

	
SELECT
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN CUSTOMERS AS C
on S.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
  GROUP BY 1
  ORDER BY 2 DESC

  -- Q3
  -- sales count for each Product
  -- How many units of each coffe product have beesn sold ?

  SELECT  
    p.product_name,
    COUNT(s.sale_id) as total_orders
  FROM products as p
  LEFT JOIN
  sales as s
  ON s.product_id = p.product_id
  GROUP BY 1
  ORDER BY 2 DESC

-- Q4
-- Average sales amount per city
-- What is the average sales amount per customer in each city?
-- city and the total sales
-- no. of customers in these city
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(s.customer_id) as total_cx,
	ROUND(
		SUM(s.total)::numeric/
			COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

-- Q5
-- Provide a list of cities along with their populations estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as
(
SELECT
    city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers
FROM city
),
customers_table
AS
(SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales AS s
JOIN customers AS c
    ON c.customer_id = s.customer_id
JOIN city AS ci
    ON ci.city_id = c.city_id
GROUP BY 1
)
SELECT
	customers_table.city_name,
	city_table.coffee_consumers as coffe_consumer_in_millions,
	customers_table.unique_cx
FROM city_table 
JOIN 
customers_table 
ON city_table.city_name = customers_table.city_name

-- Q6
-- Top selling products by city
--what are the top 3 selling products in each city based on sales volume?
SELECT *
FROM
(SELECT
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) as total_orders,
	DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2 
) as t1
WHERE rank >=3

-- Q7 customer segmentation city
-- How many unique customers are there in each city who have purchased coffee product ?

SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1
 
  
-- Q.8
--- Average sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
  
WITH city_table
AS (
	SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
	SUM(s.total)::numeric/
		COUNT(DISTINCT s.customer_id)::numeric
		,2) as avg_sale_pr_cx

FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

),
city_rent
AS
(SELECT 
	city_name,
	estimated_rent
FROM city
)
SELECT
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent::numeric/
							ct.total_cx::numeric
	, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name

--Q.9
-- Monthly sales Growth
-- Sales growth rate: calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city.
WITH
monthly_sales
AS

(SELECT 
	ci.city_name,
	EXTRACT(MONTH FROM sale_date) as month,
	EXTRACT(YEAR FROM sale_date) as YEAR,
	SUM(s.total) as total_sale
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio
AS
(
SELECT
	city_name,
	month,
	year,
	total_sale as cr_month_sale,
	LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM monthly_sales
)
SELECT 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
	, 2
	) as growth_ratio
FROM growth_ratio
WHERE
	last_month_sale IS NOT NULL

--Q.10
-- Mraket Potential analysis
-- identify top 3 city based on highest sale, retirn city name, total sale, total rent, total,customer,estimated coffe conusmer

WITH city_table
AS
( 
	SELECT
	ci.city_name,
	SUM(s.total)as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
		SUM(s.total)::numeric/
			COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx

FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent
AS 
(SELECT
	city_name,
	estimated_rent,
	ROUND((population * 0.25)/1000000,3 ) as estimated_coffee_consumer_in_millions
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
						ct.total_cx::numeric
		,2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC
	
