-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;


-- Reports & Data Analysis


-- Q.1 
-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC

--🔍 Business Problem

--The company does not know market size in each city. Without understanding how many people could consume coffee, 
--expansion decisions become guesswork.


--💡 Business Impact

--Helps estimate potential demand per city
--Identifies cities with larger target audience
--Avoids opening stores in cities with low coffee consumption potential

------------------------------------------------------------------------------------------------------------------------------------

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


--🔍 Business Problem

--The business wants to know recent performance. Decisions should be based on current momentum, especially before expansion.

--💡 Business Impact

--Shows whether the business is growing or slowing down

-----------------------------------------------------------------------------------------------------------------------------------


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


--🔍 Business Problem

--The company doesn’t know which products actually drive volume. Stocking the wrong products in new stores can lead to losses.

--💡 Business Impact

--Identifies high-demand products
--Helps optimize inventory planning for new outlets
--Reduces wastage and overstocking

------------------------------------------------------------------------------------------------------------------------------------


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as unique_customers,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_per_customer
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 4 DESC

--🔍 Business Problem

-- The business needs to know how much an average customer spends in each city.

--💡 Business Impact

--Identifies cities with high-spending customers
--Helps design pricing and promotion strategies

------------------------------------------------------------------------------------------------------------------------------------


-- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, unique customers, total population & estimated coffee consumers (25%)


SELECT 
    city_name,
    TO_CHAR(population * 0.25, '9,999,999,999') AS estimated_coffee_consumers,
    TO_CHAR(population, '9,999,999,999') AS total_population,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM city AS ci
JOIN customers AS c 
    ON ci.city_id = c.city_id
GROUP BY city_name, population
ORDER BY population * 0.25 DESC;

--🔍 Business Problem

--A city may have low sales but a very large population.

--💡 Business Impact

--Got idea of  market size
--Helps prioritize cities with future growth opportunity

------------------------------------------------------------------------------------------------------------------------------------

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH top_products AS  
     (
	   SELECT 
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
	GROUP BY 1, 2
) 

SELECT * FROM top_products WHERE rank <= 3

--🔍 Business Problem
--Top 3 Selling Products in Each City

--💡 Business Impact

--Enables city-specific product strategy
--inventory stock planning
--Increases customer satisfaction and repeat purchases

------------------------------------------------------------------------------------------------------------------------------------


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customers
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

--🔍 Business Problem
--How many different customers are actually purchasing coffee products in each city?

--💡 Business Impact
--The company can measure customer reach and market penetration.
--It helps evaluate brand popularity across cities.
--It supports better marketing and expansion decisions.

------------------------------------------------------------------------------------------------------------------------------------


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per custo

WITH city_table AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as unique_customers,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_per_customer
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),

city_rent AS
(
SELECT 
	city_name, 
	estimated_rent
FROM city
)

SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.unique_customers,
	ct.avg_sale_per_customer,
	ROUND(cr.estimated_rent::numeric/ct.unique_customers::numeric, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC

--🔍 Business Problem
--How much money we earn from each customer And how much cost (rent) is involved per customer

--💡 Business Impact
--The company can compare earning vs cost in each city
--It helps find cities where profit margins are better
--It prevents opening stores in cities where rent is high but customer spending is low

------------------------------------------------------------------------------------------------------------------------------------


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.total) as total_sales
	FROM sales as s
	JOIN customers as c ON c.customer_id = s.customer_id
	JOIN city as ci ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),

growth_ratio AS
(
	SELECT
		city_name,
		year,
		month,
		total_sales as current_month_sales,
		LAG(total_sales, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
	FROM monthly_sales
)

SELECT
	city_name,
	year,
	month,
	current_month_sales,
	last_month_sales,
	ROUND((current_month_sales-last_month_sales)::numeric/last_month_sales::numeric * 100, 2) as growth_ratio
FROM growth_ratio

--🔍 Business Problem
--Which cities are growing month by month And which cities are losing demand.

--💡 Business Impact
--The company can identify cities where demand is increasing
--It can avoid cities where sales are dropping
--It helps decide the right time to expand

------------------------------------------------------------------------------------------------------------------------------------


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumers

--✅ city_name
--✅ total_sales
--✅ total_rent
--✅ total_customers
--✅ estimated_coffee_consumers (25% population)
--✅ avg_sale_per_customer
--✅ avg_rent_per_customer
--✅ Top 3 cities based on highest sales


WITH city_table AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_per_customer
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),

city_rent AS
(
	SELECT 
		city_name, 
		estimated_rent,
		TO_CHAR(population * 0.25, '9,999,999,999') AS estimated_coffee_consumers
	FROM city
)

SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	estimated_coffee_consumers,
	ct.avg_sale_per_customer,
	ROUND(cr.estimated_rent::numeric/ct.total_customers::numeric, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC


--Final Recommendation 


--City 1 :- Pune 

--🔥 Highest revenue
--💰 Strong average spend per customer
--🏠 Moderate rent
--📊 Good customer base

--City 2 :- Chennai 

--💵 Second highest revenue
--📊 Good customer base
--🏠 Rent manageable 
--⚖ Balanced earning vs cost

--City 3 :- Jaipur

--👥 Highest customer count (69)
--💸 Lowest rent per customer
--📈 Strong revenue compared to cost
--⚖ Very efficient unit economics


--❌ Why Not Bangalore?

--Rent is too high
--Avg rent per customer is highest
--Profit margin risk

--❌ Why Not Delhi?

--Huge market size
--But revenue per customer is lower
--Rent is relatively high
