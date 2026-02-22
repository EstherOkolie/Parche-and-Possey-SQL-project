/*  
PARCHE & POSSEY PAPER COMPANY 
SQL SALES & OPERATIONS ANALYSIS 
*/ 
/* What are the distinct marketing/web channels available? */ 
SELECT DISTINCT channel 
FROM web_events; 
/* How many account holders does Parche & Possey have? */ 
SELECT COUNT(*) AS total_accounts 
FROM accounts; 
/* How many web events came from the 'direct' channel? */ 
SELECT COUNT(channel) AS total_direct_channel 
FROM web_events 
WHERE channel = 'direct'; 
/* What is the average price per unit for gloss paper and poster paper? */ 
SELECT  
ROUND(SUM(gloss_amt_usd) / NULLIF(SUM(gloss_qty), 0), 1) AS gloss_price_per_unit, 
ROUND(SUM(poster_amt_usd) / NULLIF(SUM(poster_qty), 0), 1) AS 
poster_price_per_unit 
FROM orders; 
/* What are the maximum and minimum quantities ordered for standard paper? */ 
SELECT 
MAX(standard_qty) AS max_standard_qty_ordered, 
MIN(standard_qty) AS min_standard_qty_ordered 
FROM orders; 
/* What is the average quantity ordered for standard and poster paper? */ 
SELECT 
AVG(standard_qty) AS avg_standard_qty_ordered, 
AVG(poster_qty) AS avg_poster_qty_ordered 
FROM orders; 
/* Which accounts have spent 300,000 USD or more in total? */ 
SELECT  
account_id, 
SUM(total_amt_usd) AS total_amt_spent 
FROM orders 
GROUP BY account_id 
HAVING SUM(total_amt_usd) >= 300000 
ORDER BY total_amt_spent DESC; 
/* How many accounts have placed more than 20 orders? */ 
SELECT COUNT(*) AS total_accounts 
FROM ( 
SELECT  
account_id, 
COUNT(account_id) AS total_orders 
FROM orders 
GROUP BY account_id 
HAVING COUNT(account_id) > 20 
) AS t; 
/* Which day of the week has the highest number of orders? */ 
SELECT TOP 1 
DATEPART(WEEKDAY, occurred_at) AS day_of_week, 
COUNT(id) AS total_orders 
FROM orders 
GROUP BY DATEPART(WEEKDAY, occurred_at) 
ORDER BY total_orders DESC; 
/* Which hour of the day has the highest number of orders? */ 
SELECT TOP 1 
DATEPART(HOUR, occurred_at) AS hour_of_day, 
COUNT(id) AS total_orders 
FROM orders 
GROUP BY DATEPART(HOUR, occurred_at) 
ORDER BY total_orders DESC; 
/* Which month had the most orders and in which year? */ 
SELECT TOP 1 
DATEPART(MONTH, occurred_at) AS month, 
DATEPART(YEAR, occurred_at) AS year, 
COUNT(occurred_at) AS total_orders 
FROM orders 
GROUP BY  
DATEPART(MONTH, occurred_at), 
DATEPART(YEAR, occurred_at) 
ORDER BY total_orders DESC; 
/* Classify each order as High, Medium, or Small based on total quantity */ 
SELECT  
account_id, 
occurred_at, 
total, 
CASE  
WHEN total > 500 THEN 'High order' 
WHEN total > 200 THEN 'Medium order' 
ELSE 'Small order' 
END AS order_type 
FROM orders; 
/* Which accounts have at least 50 orders? */ 
SELECT 
a.name, 
o.account_id, 
COUNT(o.account_id) AS total_orders 
FROM accounts AS a 
INNER JOIN orders AS o 
ON a.id = o.account_id 
GROUP BY a.name, o.account_id 
HAVING COUNT(o.account_id) >= 50 
ORDER BY total_orders DESC; 
/* How many sales reps manage more than 5 accounts? */ 
SELECT COUNT(*) AS count_of_sales_rep 
FROM ( 
SELECT  
s.id, 
s.name, 
COUNT(a.sales_rep_id) AS total_accounts 
FROM sales_reps AS s 
INNER JOIN accounts AS a 
ON s.id = a.sales_rep_id 
GROUP BY s.id, s.name 
HAVING COUNT(a.sales_rep_id) > 5 
) AS t; 
/* Identify sales reps who manage more than 5 accounts*/ 
WITH sales_rep_accounts AS ( 
SELECT  
s.id, 
s.name, 
COUNT(a.sales_rep_id) AS total_accounts 
FROM sales_reps AS s 
INNER JOIN accounts AS a 
ON s.id = a.sales_rep_id 
GROUP BY s.id, s.name 
HAVING COUNT(a.sales_rep_id) > 5 
) 
SELECT  
name, 
total_accounts 
FROM sales_rep_accounts; 
/* Identify the top-performing sales rep by total sales in each region */ 
WITH rep_sales AS ( 
    SELECT  
        s.name AS rep_name, 
        r.name AS region_name, 
        SUM(o.total_amt_usd) AS total_amt 
    FROM orders AS o 
    JOIN accounts AS a ON a.id = o.account_id 
    JOIN sales_reps AS s ON s.id = a.sales_rep_id 
    JOIN region AS r ON r.id = s.region_id 
    GROUP BY s.name, r.name 
), 
region_max_sales AS ( 
    SELECT  
        region_name, 
        MAX(total_amt) AS total_amt 
    FROM rep_sales 
    GROUP BY region_name 
) 
SELECT  
    r.rep_name, 
    r.region_name, 
    r.total_amt 
FROM rep_sales r 
JOIN region_max_sales m 
    ON r.region_name = m.region_name 
   AND r.total_amt = m.total_amt; 
 
/* What is the total number of units ordered per account*/ 
SELECT  
account_id, 
SUM(total) AS total_units 
FROM orders 
GROUP BY account_id 
ORDER BY account_id; 
/* What is the running total of units ordered per account over time? */ 
SELECT  
account_id, 
occurred_at, 
total, 
SUM(total) OVER ( 
PARTITION BY account_id  
ORDER BY account_id, occurred_at 
) AS running_total 
FROM orders; 
/* Which sales representative generated the highest total sales (total_amt_usd) 
in each region, and how much revenue did they contribute? */ 
WITH t1 AS ( 
SELECT 
s.name AS rep_name, 
        r.name AS region_name, 
        SUM(o.total_amt_usd) AS total_amt 
    FROM sales_reps s 
    JOIN accounts a  
        ON a.sales_rep_id = s.id 
    JOIN orders o  
        ON o.account_id = a.id 
    JOIN region r  
        ON r.id = s.region_id 
    GROUP BY s.name, r.name 
), 
t2 AS ( 
    SELECT 
        region_name, 
        MAX(total_amt) AS total_amt 
    FROM t1 
    GROUP BY region_name 
) 
SELECT 
    t1.rep_name, 
    t1.region_name, 
    t1.total_amt 
FROM t1 
JOIN t2 
    ON t1.region_name = t2.region_name 
   AND t1.total_amt = t2.total_amt; 