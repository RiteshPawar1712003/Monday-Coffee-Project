-- Monday Coffee -- Data Analysis
select * from city; 
select * from customers;
select * from products;
select * from sales;

-- Reports & data analysis 
--  Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does? 
select city_name,round(population*0.25)/1000000 as NO_of_people_consumed_coffee, 
city_rank 
from city
order by population desc;  
-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023? 
select sum(total) as total_revenue from sales
where extract(year from sale_date)=2023 and
extract(quarter from sale_date)=4;

select round(sum(s.total)) as total_revenue,ci.city_name from customers c join sales s
on s.customer_id =c.customer_id join  city ci
on c.city_id=ci.city_id
where extract(year from sale_date)=2023 and
extract(quarter from sale_date)=4
group by ci.city_name;



-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
select p.product_name,count(s.sale_id) as total_orders from products p right join sales s
on p.product_id=s.product_id
group by p.product_name
order by total_orders desc;



-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city
select ci.city_name ,sum(s.total) as total_sales,round(sum(s.total) /count(distinct c.customer_id),2)as "Average sales ",count(distinct c.customer_id) as "No. of customer"from sales s  join customers c
on s.customer_id=c.customer_id join city ci 
on c.city_id=ci.city_id
group by ci.city_name
order by sum(s.total) desc;



-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
   
   with city_table as(
   select city_name,population,round((population*0.25/1000000),2) as Coffee_consumers from city
   ),
   customers_table as (
   select ci.city_name ,count(distinct c.customer_id) as current_consumers from city ci join
   customers c on ci.city_id=c.city_id
   group by ci.city_name
   )
   select customers_table.city_name,
		  customers_table.current_consumers,
          city_table. Coffee_consumers from city_table join customers_table
          on city_table.city_name=customers_table.city_name;
   
   -- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from (select p.product_name,ci.city_name,count(s.sale_id) as total_sales,
   dense_rank()over(partition by city_name order by count(sale_id)desc) as ranks
    from products p join sales s
   on p.product_id=s.product_id join customers c on
   s.customer_id=c.customer_id join city ci on
   c.city_id=ci.city_id
   group by ci.city_name,p.product_name) as t1
   where ranks<=3;




-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name , count(distinct c.customer_id) from customers c join
city ci on ci.city_id=c.city_id join sales s
on c.customer_id=s.customer_id join products p 
on s.product_id=p.product_id
where p.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by city_name;






-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions
WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            CAST(SUM(s.total) AS DECIMAL(10,2)) /
            CAST(COUNT(DISTINCT s.customer_id) AS DECIMAL(10,2)),
        2) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c 
        ON s.customer_id = c.customer_id
    JOIN city ci 
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)

SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        CAST(cr.estimated_rent AS DECIMAL(10,2)) /
        CAST(ct.total_cx AS DECIMAL(10,2)),
    2) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct 
    ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales s
    JOIN customers c 
        ON c.customer_id = s.customer_id
    JOIN city ci 
        ON ci.city_id = c.city_id
    GROUP BY 
        ci.city_name,
        YEAR(s.sale_date),
        MONTH(s.sale_date)
),

growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) 
            OVER (PARTITION BY city_name 
                  ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)

SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        ((cr_month_sale - last_month_sale) / last_month_sale) * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;


   
   
  
-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) 
            AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) 
            AS estimated_coffee_consumer_in_millions
    FROM city
)

SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / NULLIF(ct.total_cx, 0), 2) 
        AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;

-- Recomendation
-- City 1: Pune
	-- 1.Average rent per customer is very low.
	-- 2.Highest total revenue.
	-- 3.Average sales per customer is also high.

-- City 2: Delhi
	-- 1.Highest estimated coffee consumers at 7.7 million.
	-- 2.Highest total number of customers, which is 68.
	-- 3.Average rent per customer is 330 (still under 500).

-- City 3: Jaipur
	-- 1.Highest number of customers, which is 69.
	-- 2.Average rent per customer is very low at 156.
	-- 3.Average sales per customer is better at 11.6k.




