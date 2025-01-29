create database caseretail
use caseretail
SELECT* FROM Customers
SELECT* FROM Stores_Info
SELECT* FROM ProductsInfo
SELECT* FROM Orders
SELECT* FROM OrderPayments
SELECT* FROM OrderReview_Ratings

--data cleaning

--REMOVING THE CUSTOMERS WHO HAVE NOT DONE ANY ORDERS 
	DELETE FROM customers
	WHERE NOT EXISTS (
		SELECT 1
		FROM orders
		WHERE orders.Customer_id = customers.Custid
	);

--Removed the order IDs from the order payment table that are not in the orders table. 
	DELETE FROM OrderPayments
	WHERE NOT EXISTS (
		SELECT 1
		FROM orders
		WHERE orders.order_id = OrderPayments.order_id
	);

--Removed the order IDs from the order review table that are not in the orders table.
	DELETE FROM OrderReview_Ratings
	WHERE NOT EXISTS (
		SELECT 1
		FROM orders
		WHERE orders.order_id = OrderReview_Ratings.order_id
	);

--Removed the store IDs from which no orders have been processed.
	DELETE FROM Stores_Info
	WHERE NOT EXISTS (
		SELECT 1
		FROM orders
		WHERE orders.Delivered_StoreID = Stores_Info.StoreID
	);

----------UPDATING THE QUANTITY AND THE TOTAL AMOUNT VALUE----------------
UPDATE Orders
SET Quantity = 1
WHERE order_id ='8272b63d03f5f79c56e9e4120aec44ef'

UPDATE Orders
SET Total_Amount = (Quantity*MRP)+ Discount
WHERE order_id ='8272b63d03f5f79c56e9e4120aec44ef'

SELECT * FROM Orders
WHERE order_id ='8272b63d03f5f79c56e9e4120aec44ef'

UPDATE Orders
SET Quantity = 1
WHERE order_id ='ab14fdcfbe524636d65ee38360e22ce8'

UPDATE Orders
SET Total_Amount = (Quantity*MRP)+ Discount
WHERE order_id ='ab14fdcfbe524636d65ee38360e22ce8'

SELECT * FROM Orders
WHERE order_id ='ab14fdcfbe524636d65ee38360e22ce8'


UPDATE Orders
SET Quantity = 1
WHERE order_id ='1b15974a0141d54e36626dca3fdc731a'

UPDATE Orders
SET Total_Amount = (Quantity*MRP)+ Discount
WHERE order_id ='1b15974a0141d54e36626dca3fdc731a'

SELECT * FROM Orders
WHERE order_id ='1b15974a0141d54e36626dca3fdc731a'


--no.of customre
select count(distinct(Custid)) CUSTOMER_COUNT from Customers

--no.of male and female customers
select count(distinct(Custid)) MALE_COUNT from Customers where Gender='M'
select count(distinct(Custid)) FEMALE_COUNT from Customers where Gender='F'

-- no.of orders
SELECT  COUNT(DISTINCT(order_id)) ORDER_COUNT FROM orders

--AVERAGE DISCOUNT PER CUSOMER
	SELECT
		ROUND(AVG(DISCOUNT),0) AVG_DISCOUNT_PER_CUSTOMRE
	FROM (
			SELECT
			Customer_id,
			SUM(Discount) DISCOUNT
			FROM orders
			GROUP BY Customer_id 
		)result


--REVENUE
	SELECT
		SUM(Total_Amount) REVENUE
	FROM ORDERS

--PROFIT 
	SELECT
		ROUND(SUM(Total_Amount)-SUM(Cost_Per_Unit*Quantity),0) AS PROFIT
	FROM orders

--cost   
	SELECT 
		ROUND(SUM(Cost_Per_Unit*Quantity),0) COST
	FROM orders


--AVERAGE PROFIT PER CUSTOMER
	SELECT
		round(AVG(PROFIT),0) AVG_PROFIT_PER_CUSTOMER
	FROM(
			SELECT
			Customer_id,
			SUM(Total_Amount)-SUM(Cost_Per_Unit*Quantity) AS PROFIT
			FROM orders
			GROUP BY Customer_id
		)result

--AVERAGE SALES PER CUSTOMER
	SELECT
		round(AVG(SALES),0) AS AVERAGE_SALES_PER_CUSTOMER
	FROM(
			SELECT
			Customer_id,
			SUM(Total_Amount) SALES
			FROM ORDERS
			GROUP BY Customer_id
		)result


--NO.OF CATEGORIES AND PRODUCT 
	SELECT
		COUNT(DISTINCT(product_id)),
		COUNT(DISTINCT(Category))  No_OF_CATEORY
	FROM ProductsInfo

--NO.OF PAYMENT METHOD
	SELECT
		COUNT(DISTINCT(payment_type)) AS PAYMENT_TYPE
	FROM OrderPayments

--AVERAGE CATEGORY PER ORDER
	SELECT
		AVG(CATEGORY) AVG_CATEGORY_PER_CUSTOMER
	FROM(
			SELECT
			order_id,
			COUNT(P.Category) CATEGORY
			FROM orders O
			JOIN ProductsInfo P ON P.product_id = O.product_id
			GROUP BY order_id
		)result


----------One time buyers percentage and repeate buyer percentage ------------------

	SELECT
		 ROUND(SUM(CASE WHEN number_of_transacton =1 THEN 1 ELSE 0 END) *1.0/COUNT(*)*100,0) AS [One time Purchase %],
		 ROUND(SUM(CASE WHEN number_of_transacton >1 THEN 1 ELSE 0 END)*1.0 /COUNT(*)*100,0) AS [Repeate Purchase %]
	FROM (
		SELECT
		Customer_id,
		count(Bill_date_timestamp) as number_of_transacton
		FROM Orders
		GROUP BY  Customer_id
		) result



--total stores,STATES,region
	SELECT
		COUNT(DISTINCT(StoreID)) STORE_ID,
		COUNT(DISTINCT(seller_state)) STATES,
		COUNT(DISTINCT(Region)) region 
	FROM Stores_Info


-- Number of New Customers Acquired Every Month:
	SELECT
		YEAR(entry_of_new_cust) as YEAR,
		MONTH(entry_of_new_cust) as MONTH,
		COUNT(Customer_id) as new_cust
	FROM (
			SELECT
			DISTINCT Customer_id,
			MIN(bill_date_timestamp) as entry_of_new_cust
			FROM
			Orders
			GROUP BY Customer_id
		) AS tbl
	GROUP BY year(entry_of_new_cust), MONTH(entry_of_new_cust)
	ORDER BY YEAR,MONTH


--Understand the retention of customers on month on month basis 

	WITH cohort AS --Finding customers first purchase date and year
	(
		SELECT 
		customer_id,
		DATEPART(YEAR, MIN(bill_date_timestamp)) AS cohort_year,
		DATEPART(MONTH, MIN(bill_date_timestamp)) AS cohort_month
		FROM orders
		GROUP BY customer_id
	),monthly_purchases AS  --getting all purchase month and year of the customer
	(
		SELECT 
		customer_id,
		DATEPART(YEAR, bill_date_timestamp) AS purchase_year,
		DATEPART(MONTH, bill_date_timestamp) AS purchase_month
		FROM orders
	),cohort_size AS --getting the year and month wise number of unique customers
	(
		SELECT 
		cohort_year,
		cohort_month,
		COUNT(DISTINCT customer_id) AS cohort_size
		FROM cohort
		GROUP BY cohort_year, cohort_month
	)
	
	SELECT
		c.cohort_year,--first purchase year
		c.cohort_month, --first purchase month
		mp.purchase_year,
		mp.purchase_month,
		COUNT(DISTINCT mp.customer_id) AS retained_customers,
		COUNT(DISTINCT mp.customer_id) * 100.0 / cs.cohort_size AS retention_rate
	FROM cohort c
	JOIN monthly_purchases mp ON c.customer_id = mp.customer_id
	JOIN cohort_size cs ON c.cohort_year = cs.cohort_year and c.cohort_month = cs.cohort_month
	GROUP BY c.cohort_year, c.cohort_month, mp.purchase_year, mp.purchase_month, cs.cohort_size
	ORDER BY c.cohort_year, c.cohort_month, mp.purchase_year, mp.purchase_month

--How the revenues from existing/new customers on month on month basis 

SELECT 
revenue_year,
revenue_month,
customer_type,
SUM(revenue) AS total_revenue
FROM 
(
SELECT 
o.customer_id,
YEAR(o.bill_date_timestamp) AS revenue_year,
MONTH(o.bill_date_timestamp) AS revenue_month,
SUM(o.total_amount) OVER (PARTITION BY o.customer_id, YEAR(o.bill_date_timestamp), MONTH(o.bill_date_timestamp)) AS revenue,
CASE 
WHEN o.bill_date_timestamp = fp.first_purchase_date THEN 'new' ELSE 'existing' END AS customer_type
FROM orders o
INNER JOIN 
(
SELECT 
customer_id,
MIN(bill_date_timestamp) AS first_purchase_date
FROM 
orders
GROUP BY 
customer_id
) fp ON o.customer_id = fp.customer_id) as revenueclassification
GROUP BY revenue_year, revenue_month, customer_type
ORDER BY revenue_year, revenue_month, customer_type

--sales and quantity by category

select
p.category,
sum(o.total_amount) as total_sales,
sum(o.quantity) as total_quantity
from
orders o
join
productsinfo p on o.product_id = p.product_id
group by
p.category
order by
sum(o.total_amount) desc

--Sales and Quantity by Channel
select
o.Channel,
sum(o.total_amount) as total_sales,
sum(o.quantity) as total_quantity
from
orders o
group by
o.Channel
order by
sum(o.total_amount)


--POPULAR PRODUCT BY STATE AND REGION
select
Region,
seller_state,
product_id,
total_quantity,
total_sales,
row_num
from
(select si.Region,si.seller_state, 
o.product_id,
sum(o.quantity) as total_quantity, 
sum(o.total_amount) as total_sales,
row_number() over(partition by seller_state order by sum(total_amount) desc) as row_num
from orders o
join productsinfo p on o.product_id = p.product_id
join Stores_Info si on o.delivered_storeid = si.StoreID
group by si.Region,si.seller_state, p.category,o.product_id) as TBL
where row_num =1
order by seller_state,row_num




--POPULAR Category BY STATE AND REGION

select
Region,
seller_state,
Category,
total_quantity,
total_sales,
row_num
from
(select si.Region,si.seller_state, 
p.Category,
sum(o.quantity) as total_quantity, 
sum(o.total_amount) as total_sales,
row_number() over(partition by seller_state order by sum(total_amount) desc) as row_num
from orders o
join productsinfo p on o.product_id = p.product_id
join Stores_Info si on o.delivered_storeid = si.StoreID
group by si.Region,si.seller_state, p.category) as TBL
where row_num =1
order by seller_state,row_num



--List the top 10 most expensive products sorted by price and their contribution to sales

SELECT top 10
o.product_id,
p.Category,
round(sum(Total_Amount),2)  Sales
FROM Orders o
join ProductsInfo p on o.product_id=p.product_id
group by o.product_id,p.Category
ORDER BY Sales DESC


-- Behaviour of customer satisfaction score

	WITH CustomerSales AS (
 -- Calculate total sales for each customer
    SELECT 
        Customer_ID,
        SUM(Total_Amount) AS TotalSales
    FROM orders 
    GROUP BY 
        Customer_id
),
CustomerSatisfactionSales AS (
    -- Join the total sales with customer satisfaction scores
    SELECT 
        cs.Customer_ID,
        r.Customer_Satisfaction_Score,
        cs.TotalSales
    FROM orders c
    JOIN CustomerSales cs
    ON c.Customer_id = cs.Customer_id
	join OrderReview_Ratings r 
	on c.order_id=r.order_id
)
SELECT 
    Customer_Satisfaction_Score,
    AVG(TotalSales) AS AverageSales
FROM 
    CustomerSatisfactionSales
GROUP BY 
    Customer_Satisfaction_Score
ORDER BY 
    Customer_Satisfaction_Score



--------Top 10-performing & worst 10 performance stores in terms of sales--------

SELECT top 10
S.StoreID, 
count(O.Bill_date_timestamp) as TOP_10
FROM Orders O
JOIN Stores_Info S ON O.Delivered_StoreID = S.StoreID
group by S.StoreID
order by TOP_10 desc

SELECT top 10
S.StoreID, 
count(Bill_date_timestamp) as Worst_10
FROM Orders O
JOIN Stores_Info S ON O.Delivered_StoreID = S.StoreID
group by S.StoreID
order by Worst_10 



--RFM SEGMENTATION

SELECT
COUNT( DISTINCT customer_id),
RFM_Segment
FROM
(
SELECT
recencytable.Customer_id,
CASE WHEN Recency_rate ='Premium' or Frequency_rate = 'Premium' or Monetary_rate ='Premium' THEN 'Premium'
     WHEN Recency_rate ='Gold' or Frequency_rate ='Gold' or Monetary_rate='Gold' THEN 'Gold'
     WHEN Recency_rate ='Silver' or Frequency_rate ='Silver' or Monetary_rate ='Silver' THEN 'Silver' ELSE 'Standard' END AS RFM_Segment
FROM
(
SELECT customer_id,
CASE WHEN no_of_active_days BETWEEN 0 AND 114 THEN 'Standard'
	 WHEN no_of_active_days BETWEEN 115 AND 228 THEN 'Silver'
	 WHEN no_of_active_days BETWEEN 229 AND 342 THEN 'Gold' ELSE 'Premium' END AS Recency_rate
 FROM
 ( 
 SELECT
 DATEDIFF(DAY,MIN(Bill_date_timestamp),MAX(Bill_date_timestamp)) AS no_of_active_days,
 customer_id
 FROM orders
 GROUP BY customer_id
 ) a
 ) recencytable
INNER JOIN
 (
 SELECT
 customer_id,
 year_no,
 quarter,
 CASE WHEN no_of_orders between 0 and 10 THEN 'Standard'
	  WHEN no_of_orders between 11 and 20 THEN 'Silver'
	  WHEN no_of_orders between 21 and 40 THEN 'Gold' ELSE 'Premium' END AS Frequency_rate
 FROM
 (
SELECT 
Customer_id,
year_no, 
Quarter,
SUM(no_of_orders) as no_of_orders
FROM
 (
 SELECT 
 Customer_id,
 year_no,
 CASE WHEN month_no/3 in (1,2,3,4) THEN month_no/3 ELSE FLOOR((month_no/3)+1) END AS Quarter,
 no_of_orders
 FROM
 (
 SELECT
 customer_id,
 YEAR(Bill_date_timestamp) as year_no, 
 MONTH(Bill_date_timestamp) as month_no, 
 COUNT(DISTINCT order_id) as no_of_orders
 FROM orders
 GROUP BY Customer_id,
 (Bill_date_timestamp),year(Bill_date_timestamp)
 ) a
) b
GROUP BY Customer_id,year_no,Quarter
)c
) frequencytable ON recencytable.Customer_id=frequencytable.Customer_id
INNER JOIN
(
SELECT
customer_id, 
year_no,
quarter,
CASE WHEN sales_amount BETWEEN 0 AND 2000 THEN 'Standard'
	 WHEN sales_amount BETWEEN 2001 AND 4000 THEN 'Silver'
	 WHEN sales_amount BETWEEN 4001 AND 6000 THEN 'Gold' ELSE 'Premium' END AS Monetary_rate
FROM
(
SELECT
Customer_id, 
year_no, 
Quarter, 
SUM(total_sales) AS sales_amount
FROM
(
SELECT Customer_id,year_no,
CASE WHEN month_no/3 in (1,2,3,4) THEN month_no/3 ELSE FLOOR((month_no/3)+1) END AS Quarter,
total_sales
FROM
(
SELECT
customer_id,
YEAR(Bill_date_timestamp) AS year_no, 
MONTH(Bill_date_timestamp) AS month_no, 
SUM(total_amount) AS total_sales
FROM orders
GROUP BY Customer_id,MONTH(Bill_date_timestamp),YEAR(Bill_date_timestamp)
) a
) b
GROUP BY Customer_id,year_no,Quarter
)c
) monetarytable ON frequencytable.Customer_id=monetarytable.Customer_id
) rfmvalue
GROUP BY RFM_Segment



--Find out the number of customers who purchased in all the channels and find the key metrics.

WITH channels AS
(
SELECT
customer_id,
COUNT(DISTINCT channel) AS Channel
FROM orders
GROUP BY customer_id
)
,ALL_CHANNEL AS (
SELECT
customer_id
FROM channels
WHERE Channel = (SELECT COUNT(DISTINCT channel) FROM orders)
)

SELECT
c.customer_id,
COUNT(DISTINCT o.order_id) AS total_orders,
SUM(o.total_amount) AS total_revenue,
AVG(o.total_amount) AS avg_order_value,
SUM(o.quantity) AS total_quantity,
AVG(o.discount) AS avg_discount
FROM ALL_CHANNEL c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id

--Understand the behavior of one time buyers and repeat buyers

WITH customer_order_counts AS (
SELECT
customer_id,
COUNT(order_id) AS order_count
FROM orders
GROUP BY customer_id
)
SELECT
'one_time_buyers' AS buyer_type,
COUNT(customer_id) AS customer_count,
SUM(total_revenue) AS total_revenue,
AVG(total_revenue) AS avg_revenue_per_customer,
SUM(total_orders) AS total_orders,
AVG(total_orders) AS avg_orders_per_customer,
SUM(total_quantity) AS total_quantity,
AVG(total_quantity) AS avg_quantity_per_customer,
AVG(total_discount) AS avg_discount_per_customer
FROM (
SELECT
customer_id,
SUM(total_amount) AS total_revenue,
COUNT(order_id) AS total_orders,
SUM(quantity) AS total_quantity,
AVG(discount) AS total_discount
FROM orders
WHERE customer_id in (
SELECT
customer_id
FROM customer_order_counts
WHERE order_count = 1
)
GROUP BY customer_id
) AS one_time_buyers
UNION ALL
SELECT
'repeat_buyers' AS buyer_type,
COUNT(customer_id) AS customer_count,
SUM(total_revenue) AS total_revenue,
AVG(total_revenue) AS avg_revenue_per_customer,
SUM(total_orders) AS total_orders,
AVG(total_orders) AS avg_orders_per_customer,
SUM(total_quantity) AS total_quantity,
AVG(total_quantity) AS avg_quantity_per_customer,
AVG(total_discount) AS avg_discount_per_customer
FROM (
SELECT
customer_id,
SUM(total_amount) AS total_revenue,
COUNT(order_id) AS total_orders,
SUM(quantity) AS total_quantity,
AVG(discount) AS total_discount
FROM orders
WHERE customer_id in (
SELECT
customer_id
FROM customer_order_counts
WHERE order_count > 1
)
GROUP BY customer_id
) AS repeat_buyers


--Understand the behavior of discount seekers & non discount seekers

-------Understand the behavior of discount seekers & non discount seekers

 --discount seekers
  SELECT  
  Customer_id, 
  SUM(Discount)  discount_taken, 
  SUM(Total_Amount) AS total_sales
  FROM orders
  WHERE Discount>0
  GROUP BY Customer_id
  ORDER BY discount_taken DESC, total_sales DESC

SELECT
COUNT(Customer_id) COUNT_OF_DISCOUNT_SEEKER
FROM
(
 SELECT
  Customer_id, 
  SUM(Discount)  discount_taken, 
  SUM(Total_Amount) AS total_sales
  FROM orders
  WHERE Discount>0
  GROUP BY Customer_id
)S

 --non-discount seekers
  select Customer_id, sum(Discount) as discount_taken, sum(Total_Amount) as total_sales
  from Orders
  where Discount=0
  group by Customer_id
  order by total_sales desc
  
  SELECT
  COUNT(Customer_id) COUNT_OF_NON_DISCOUNT_SEEKERS
  FROM
  (
  select Customer_id, sum(Discount) as discount_taken, sum(Total_Amount) as total_sales
  from Orders
  where Discount=0
  group by Customer_id
  )D

  --total sales made by male and female customers
 SELECT
 (TOTAL_SALES/(SELECT SUM(Total_Amount) FROM orders))*100 AS [% OF SALES]
 FROM(
 SELECT
  C.Gender,
  SUM(Total_Amount) AS TOTAL_SALES
  FROM Customers C
  JOIN orders O ON O.Customer_id =C.Custid
  GROUP BY C.Gender ) D

  
  --CUSTOMER PREFERENCE

  --PREFERRED CHANNEL
  SELECT  TOP 1
  CHANNEL,
  SUM(Total_Amount) AS CHANNEL
  FROM orders O 
  GROUP BY Channel
  ORDER BY SUM(Total_Amount) DESC


  --PREFERRED PAYMENT TYPE
  SELECT  TOP 1
  payment_type,
  SUM(Total_Amount) AS CHANNEL
  FROM OrderPayments OP 
  JOIN orders O ON O.order_id =OP.order_id
  GROUP BY payment_type
  ORDER BY SUM(Total_Amount) DESC

  --PREFERRED STORE
   SELECT  TOP 1
  StoreID,
  SUM(Total_Amount) AS CHANNEL
  FROM Stores_Info S 
  JOIN orders O ON O.Delivered_StoreID = S.StoreID
  GROUP BY StoreID
  ORDER BY SUM(Total_Amount) DESC

  --PREFERRED CATEGORY
  SELECT  TOP 1
  Category,
  SUM(Total_Amount) AS CHANNEL
  FROM ProductsInfo P 
  JOIN orders O ON O.product_id = P.product_id
  GROUP BY Category
  ORDER BY SUM(Total_Amount) DESC



  --Understand the behavior of customers who purchased one category and purchased multiple categories

--customers who has purchased from one category - FINDING AVG SALES
SELECT
COUNT(Customer_id) as no_of_customers, 
AVG(sales_amount) as avg_sales
FROM
( --below code finds the no of customers with only 1 category
SELECT 
Customer_id, 
COUNT(DISTINCT category) AS count_of_categories, 
SUM(Total_Amount)  sales_amount
FROM Orders O
INNER JOIN ProductsInfo p ON o.product_id=p.product_id
GROUP BY customer_id
HAVING COUNT(DISTINCT Category)=1
)  Y


--customers who has purchased from multiple category
SELECT
COUNT(customer_id) [NO OF CUSTOMERS] ,
AVG(sales_amount) as [AVG SALE]
FROM
( --below code finds the no of customers with 2 and above category
SELECT
Customer_id, 
COUNT(DISTINCT category) as count_of_categories,
SUM(Total_Amount) as sales_amount
FROM Orders o
INNER JOIN ProductsInfo p ON o.product_id=p.product_id
GROUP BY customer_id
HAVING COUNT(DISTINCT Category)>1
)  A



 -- 3.Cross-Selling (Which products are selling together)
--Hint: We need to find which of the top 10 combinations of products are selling together in each transaction.  
--(combination of 2 or 3 buying together) 

WITH ProductPairs AS (
    SELECT 
        a.order_id,
        a.Product_ID AS Product1,
        b.Product_ID AS Product2
    FROM 
        orders a
    JOIN 
        orders b ON a.order_id = b.order_id AND a.product_id < b.product_id
),
ProductTriplets AS (
    SELECT 
        a.order_id,
        a.product_id AS Product1,
        b.product_id AS Product2
       
    FROM 
        orders a
    JOIN 
         orders b ON a.order_id = b.order_id AND a.product_id < b.product_id
    JOIN 
         orders c ON a.order_id = c.order_id AND b.product_id < c.product_id
),
ProductCombinations AS (
    SELECT 
        Product1,
        Product2,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            Product1,
            Product2
          FROM 
            ProductPairs
        UNION ALL
        SELECT 
            Product1,
            Product2
        FROM 
            ProductTriplets
    ) AS Combined
    GROUP BY 
        Product1, Product2
)
SELECT top 10
    Product1,
    Product2,
    Frequency
FROM 
    ProductCombinations
ORDER BY 
    Frequency DESC


--Total Sales & Percentage of sales by category 
WITH category_sales AS (
SELECT
PI.category,
SUM(total_amount) AS total_sales
FROM Orders O
join productsinfo as Pi on Pi.product_id = O.product_id
GROUP BY category
),
total_sales AS (
SELECT
SUM(total_sales) AS total_sales
FROM category_sales
)
SELECT
cs.category,
cs.total_sales,
ROUND((cs.total_sales / ts.total_sales) * 100, 2) AS percentage_of_sales
FROM
category_sales cs,
total_sales ts
ORDER BY cs.total_sales DESC;





--CATEGORY PENETRATIPON 
WITH CategoryPenetration AS (
SELECT 
YEAR(o.Bill_date_timestamp) AS year,
MONTH(o.Bill_date_timestamp) AS month,
p.category,
COUNT(DISTINCT o.order_id) * 100.0 / SUM(COUNT(DISTINCT o.order_id)) OVER (PARTITION BY YEAR(o.Bill_date_timestamp), MONTH(o.Bill_date_timestamp)) AS category_penetration
FROM Orders o
INNER JOIN productsinfo p ON o.product_id = p.product_id
GROUP BY YEAR(o.Bill_date_timestamp),MONTH(o.Bill_date_timestamp),p.category
),RankedCategories AS 
(
SELECT 
year,
month,
category,
category_penetration,
ROW_NUMBER() OVER (PARTITION BY year ORDER BY category_penetration DESC) AS rank  -- using row number i have made the partion by year to get the top 3 records alone
FROM CategoryPenetration
)
SELECT 
year,
month,
category,
category_penetration
FROM RankedCategories
WHERE rank <= 3
ORDER BY year, month, category_penetration DESC


--Cross Category Analysis by month on Month 
--by region

SELECT 
region,
MONTH(Bill_date_timestamp) AS month_of_billing, 
COUNT(order_id) AS no_of_orders, 
COUNT( distinct Category) AS no_of_categories 
FROM Orders AS o
INNER JOIN ProductsInfo AS p ON o.product_id = p.product_id
JOIN Stores_Info s ON s.StoreID = o.Delivered_StoreID
GROUP BY region,MONTH(Bill_date_timestamp)


 --5. Customer satisfaction towards category & product 
--Which categories (top 10) are maximum rated & minimum rated and average rating score? 

--top 10 max rated products and categories
select top 10 orders.product_id,category,max(Customer_Satisfaction_Score) as max_rated
from OrderReview_Ratings as ratings
inner join Orders as orders
on ratings.order_id=orders.order_id
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
where Category!='#N/A'
group by orders.product_id,Category
order by max_rated desc;


--top 10 min rated products and categories

select top 10 orders.product_id,category,min(Customer_Satisfaction_Score) as min_rated
from OrderReview_Ratings as ratings
inner join Orders as orders
on ratings.order_id=orders.order_id
inner join ProductsInfo as pd_info
on orders.product_id=pd_info.product_id
where Category!='#N/A'
group by orders.product_id,Category
order by min_rated asc;

--highest and least sales and their contribution to sales

WITH monthly_sales AS (
    SELECT 
        MONTH(Bill_date_timestamp) AS sale_month,
        SUM(Total_Amount) AS monthly_sales 
    FROM Orders
    GROUP BY  MONTH(Bill_date_timestamp)     
),
total_sales AS (
    SELECT 
        SUM(Total_Amount) AS total_sales
    FROM Orders
)

-- months with the highest sales, their sales amount, and their percentage contribution
SELECT 
    ms.sale_month,
    ms.monthly_sales,
	ts.total_sales,
   round((ms.monthly_sales * 100.0 / ts.total_sales),2) AS percentage_contribution
FROM 
    monthly_sales ms
    CROSS JOIN total_sales ts
ORDER BY 
    ms.monthly_sales asc;



--Sales trend by month   
--Is there any seasonality in the sales (weekdays vs. weekends, months, days of week, weeks etc.)?
--Total Sales by Week of the Day, Week, Month, Quarter, Weekdays vs. weekends etc."


select weekday, round((sum(sales_amount)/(select sum(Total_Amount) from orders))* 100,0) as weekday_sales
from
(select year(Bill_date_timestamp) as year, 
datename(month, Bill_date_timestamp) as month,
datename(quarter, Bill_date_timestamp) as quarter,
DATENAME(week, Bill_date_timestamp) as week,
datename(dw, Bill_date_timestamp) as weekday,
round(sum(Total_Amount),2) as sales_amount
from Orders
group by year(Bill_date_timestamp),
datename(month, Bill_date_timestamp),
datename(quarter, Bill_date_timestamp),
DATENAME(week, Bill_date_timestamp),
datename(dw, Bill_date_timestamp) 
) a
group by weekday
order by weekday_sales desc


--total sales by year and month

select year, month, sum(sales_amount) as monthly_sales
from
(select year(Bill_date_timestamp) as year, 
datename(month, Bill_date_timestamp) as month,
datename(quarter, Bill_date_timestamp) as quarter,
DATENAME(week, Bill_date_timestamp) as week,
datename(dw, Bill_date_timestamp) as weekday,
round(sum(Total_Amount),2) as sales_amount
from Orders
group by year(Bill_date_timestamp),
datename(month, Bill_date_timestamp),
datename(quarter, Bill_date_timestamp),
DATENAME(week, Bill_date_timestamp),
datename(dw, Bill_date_timestamp) 
) a
group by year, month
order by monthly_sales desc

--Customers who started in each month and understand their behavior in the respective months
-- Which Month cohort has maximum retention?

--Perform cohort analysis (customer retention for month on month and retention for fixed month)
--. Perform cohort analysis (customer retention for month on month and retention for fixed month)

WITH first_purchase AS (
    SELECT 
        Customer_id, 
        MIN(DATEPART(month, Bill_date_timestamp)) AS first_purchase_month,
        MIN(YEAR(Bill_date_timestamp)) AS first_purchase_year
    FROM 
        orders
    GROUP BY 
        customer_id
)
SELECT 
    customer_id, 
    first_purchase_month,
    first_purchase_year
FROM 
    first_purchase;


-- Monthly Retention
--Calculate the number of retained customers for each cohort month over subsequent months.

WITH cohort AS (
    SELECT 
        customer_id, 
        MIN(DATEADD(month, DATEDIFF(month, 0, Bill_date_timestamp), 0)) AS cohort_month
    FROM 
        orders
    GROUP BY 
        customer_id
),
retention AS (
    SELECT 
        c.cohort_month,
        DATEADD(month, DATEDIFF(month, c.cohort_month, p.Bill_date_timestamp), c.cohort_month) AS purchase_month,
        COUNT(DISTINCT c.customer_id) AS customer_count
    FROM 
        cohort c
        JOIN orders p ON c.customer_id = p.customer_id
    GROUP BY 
        c.cohort_month,
        DATEADD(month, DATEDIFF(month, c.cohort_month, p.Bill_date_timestamp), c.cohort_month)
)
SELECT 
    cohort_month,
    purchase_month,
    customer_count
FROM 
    retention
ORDER BY 
    cohort_month,
    purchase_month;

--Calculate the number of customers retained after a fixed period (e.g., 3 months).
  WITH cohort AS (
    SELECT 
        customer_id, 
        MIN(DATEADD(month, DATEDIFF(month, 0, Bill_date_timestamp), 0)) AS cohort_month
    FROM 
        orders
    GROUP BY 
        customer_id
),
fixed_retention AS (
    SELECT 
        c.cohort_month,
        DATEADD(month, 3, c.cohort_month) AS third_month,
        COUNT(DISTINCT p.customer_id) AS retained_customers
    FROM 
        cohort c
        LEFT JOIN orders p 
        ON c.customer_id = p.customer_id 
        AND p.Bill_date_timestamp >= DATEADD(month, 3, c.cohort_month)
        AND p.Bill_date_timestamp < DATEADD(month, 4, c.cohort_month)
    GROUP BY 
        c.cohort_month,
        DATEADD(month, 3, c.cohort_month)
)
SELECT 
    cohort_month,
    third_month,
    retained_customers
FROM 
    fixed_retention
ORDER BY 
    cohort_month;


/*6. Perform cohort analysis (customer retention for month on month and retention for fixed month)
*/
--Which Month cohort has maximum retention?
select year, month, count(customer_id) as no_of_customers_retained
from
(select year(Bill_date_timestamp) as year, MONTH(Bill_date_timestamp) as month, Customer_id, 
rank() over (partition by customer_id order by year(Bill_date_timestamp),month(Bill_date_timestamp)) as rnk
from orders
group by MONTH(Bill_date_timestamp), Customer_id,year(Bill_date_timestamp) 
) a
where rnk>1
group by month, year
;

--"Customers who started in each month and understand their behavior in the respective months"
select year, month, region, seller_state, count(distinct a.Customer_id) as no_of_customers,
sum(total_amount) as total_sales
from
(select year(Bill_date_timestamp) as year, MONTH(Bill_date_timestamp) as month, Customer_id, 
rank() over (partition by customer_id order by year(Bill_date_timestamp),month(Bill_date_timestamp)) as rnk
from orders
group by MONTH(Bill_date_timestamp), Customer_id,year(Bill_date_timestamp) 
) a
inner join orders o
on a.Customer_id=o.Customer_id
inner join Stores_Info si
on o.Delivered_StoreID=si.StoreID
where rnk>1
group by month, year, Region, seller_state
order by total_sales desc









/********COHORT Analysis*********/

WITH FirstPurchase AS (
    SELECT
        Customer_id,
        MIN(Bill_date_timestamp) AS FirstPurchaseDate
    FROM orders
    GROUP BY Customer_id
),
Cohort AS (
    SELECT
        Customer_id,
        FORMAT(FirstPurchaseDate, 'yyyy-MM') AS CohortMonth
    FROM FirstPurchase
),
MonthlyRetention AS (
    SELECT
        c.CohortMonth,
        FORMAT(o.Bill_date_timestamp, 'yyyy-MM') AS RetentionMonth,
        COUNT(DISTINCT o.Customer_id) AS RetainedCustomers
    FROM Cohort c
    JOIN orders o ON c.Customer_id = o.Customer_id
    GROUP BY c.CohortMonth, FORMAT(o.Bill_date_timestamp, 'yyyy-MM')
),
CohortSizes AS (
    SELECT
        CohortMonth,
        COUNT(DISTINCT Customer_id) AS CohortSize
    FROM Cohort
    GROUP BY CohortMonth
)
SELECT
    mr.CohortMonth,
    mr.RetentionMonth,
    mr.RetainedCustomers,
    cs.CohortSize,
    (CAST(mr.RetainedCustomers AS FLOAT) / cs.CohortSize) * 100 AS RetentionRate
FROM MonthlyRetention mr
JOIN CohortSizes cs ON mr.CohortMonth = cs.CohortMonth
ORDER BY mr.CohortMonth, mr.RetentionMonth;









