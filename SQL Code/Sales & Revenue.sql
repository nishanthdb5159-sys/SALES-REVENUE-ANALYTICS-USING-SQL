create database if not exists Sales_And_Revenu_Analysis;

use Sales_And_Revenu_Analysis;

select * from customers;
select count(*) as No_Of_Records from customers;
describe customers;
-- The Customers Table consists informations about Customers with reguardes to Customer_id,region,and signup_date. The Table contains 500 records. --

select * from order_items;
select count(*) as No_Of_Records from order_items;
describe order_items;
-- The Order_Items Table consists information about Order_items with reguards to Order_id,Product_id,Quantity and Line_total. The Table contains 50114 records. --

select * from orders;
select count(*) as N0_Of_Records from orders;
describe orders;
-- The Orders Table consists information about Orders with reguards to Order_id,Customer_id,Order_date. The Table contains 20000 records. --

select * from products;
select count(*) as No_Of_Records from products;
describe products;
-- The Orders Table consists information about products with reguards to Product_id,Category,Price. The Table contains 100 records. --

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Section 1 REVENUE ANALYSIS #

# 1.What is the total revenue for the company?

select * from order_items;

select count(*) as Total_Items_Sold,round(sum(line_total),3) as Total_Revenue from order_items;

/*  The Total revenue for the company over the year is 3,75,61,953.91 generated with the sales of 50114 items. */

# 2.What is monthly revenue for 2023?

select * from order_items;
select * from orders;

select monthname(order_date) as Month_Name,month(order_date) as Month_Number,round(sum(line_total),3) as Monthly_Revenue from  order_items oi join orders o using (order_id)
group by Month_Name,Month_number order by Month_Number asc;

/* The output offers the revenue generated from each month. With February generating least revenue and August generating highest. */ 

# 3.What is the month-over-month (MoM) revenue growth?

with monthly_revenue as (
select monthname(order_date) as Month_Name,month(order_date) as Month_Number,round(sum(line_total),3) as Monthly_Revenue from  order_items oi join orders o using (order_id)
group by Month_Name,Month_number order by month_number asc),
mom_growth as (
select Month_Name,Month_Number,Monthly_Revenue,lag(Monthly_Revenue) over (order by Month_Number) as previous_month_revenue from monthly_revenue)
select Month_Name,Month_Number,Monthly_Revenue,previous_month_revenue,
round((Monthly_Revenue - previous_month_revenue) * 100/ previous_month_revenue,2) as mom_revenue_growth_percentage
from mom_growth order by Month_Number ;

/* May observes highest growth rate of 8.02% and february has decline of -10.02%. */

# 4.Which month had the highest and lowest revenue?

create view Monthly_Revenue as 
select monthname(order_date) as Month_Name,month(order_date) as Month_Number,round(sum(line_total),3) as Monthly_Revenue from  order_items oi join orders o using (order_id)
group by Month_Name,Month_number order by Month_number;

with Month_Rank as (
select Month_Name,Monthly_Revenue,dense_rank() over(order by Monthly_Revenue desc) as Month_rank from Monthly_Revenue)
select * from Month_Rank where Month_rank=1 or Month_rank=12;

/* August has generated the highest revenue worth 33,17,235.96 and Februrary has gwnwrated the lowest revenue worth 29,55,295.66. */

# 5.What is the running total of revenue over time?

select * from Monthly_Revenue;

select Month_Name,Month_Number,Monthly_Revenue,round(sum(Monthly_Revenue) over (order by Month_Number rows between unbounded preceding and current row),3) as running_total_revenue
from Monthly_Revenue order by Month_Number;

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Section 2 PRODUCT PERFORMANCE #

# 1.Which top 10 products generate the most revenue?

select * from order_items;
select Product_id,sum(quantity) as Total_Sales,round(sum(line_total),3) as Total_Revenue from order_items
group by Product_id order by Total_Revenue desc limit 10;

/* Out of 100 productes there are 10 productes that have generated revenue greater than 600000 with Product_id 6 generating the highest revenue worth 7,79,415.85
and product_id 96 generating the least amoung the top 10 worth 6,71,568.24 */

# 2.What is the average order value (AOV)?

select round((sum(line_total)/max(order_id)),3) as Average_Order_Value from order_items;

/* The average order value is 1878.098 */

# 3.How many items are sold per order on average?

select sum(quantity)/max(order_id) as Average_item_Per_Order from order_items;

/* On an avaerage Per customer purchaces 7.5 quantity of item per order */

# 4.Which products show a decline in sales over time?

with product_monthly_sales as (
select oi.product_id,monthname(order_date) as Month_Name,month(order_date) as Month_Number,round(sum(line_total),3) as Monthly_Revenue from order_items oi join orders o using (order_id) 
group by oi.product_id,Month_Name,Month_Number),
sales_trend as (
select product_id,Month_Name,Month_Number,Monthly_Revenue,
lag(Monthly_Revenue) over (partition by product_id order by Month_Number) as previous_month_revenue from product_monthly_sales
)
select product_id,Month_Name,Month_Number,Monthly_Revenue,previous_month_revenue
from sales_trend where Monthly_Revenue < previous_month_revenue order by Month_Number;

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Product Analysis Questions #

# 1.Which products have the highest sales volume?

select product_id,sum(quantity) as Quantity from order_items group by product_id order by quantity desc limit 10;

/* The Top 10 products have been sold more than 1500 times through out the year representing their popularity. Product_id 63 has the highest times sold with 
1659 times sold. */

# 2.Are high-priced products contributing more to revenue or are low-priced high-volume products?

with Price_Category as (select *,case
when Price>(select avg(Price) from products) then "High"
else "Low" end as Price_Rank from products)
select p.price_rank,sum(quantity) as Total_Quantity,round(sum(line_total),3) as Total_Price from Price_Category p join order_items oi using (product_id)
group by p.price_rank order by Total_Price desc;

/* High Price items contribute more rater than low price items. */ 

# 3.What is the revenue distribution by product category?

select p.category,sum(quantity) as Total_Sales,round(sum(line_total),3) as Total_Revenue from order_items oi join products p using (Product_id)
group by p.category order by Total_Revenue desc;

/* Food has the highest contribution to the total revenue and clothing has the least cntibution. Furniture has the highest quantity and electronics has the lowest quantity. */

# 5.What is the price vs quantity relationship across products?

select oi.product_id,sum(quantity) as Total_Quantity_Per_Product,p.price from order_items oi join products p using (product_id)
group by oi.product_id,p.price order by price desc;



# 6.Are certain categories more popular in specific periods?

with category_monthly_sales as (
select p.category,monthname(order_date) as Month_Name,month(order_date) as Month_Number,round(sum(line_total),3) as monthly_Revenue,sum(quantity) as Total_Quantity
from orders o join order_items oi using (order_id) join products p using(product_id)
group by p.category,Month_Name,Month_Number
)
select category,Month_Name,monthly_Revenue,Total_Quantity,rank() over (partition by Month_Number order by monthly_Revenue desc) as category_rank_in_period
from category_monthly_sales order by Month_Number,category_rank_in_period;

/* The popularity of each categorical item varies with each month. With food beeing most popular comming first in 8 different month and furniture being second comming first in 
4 different months. */

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------# 

# Customer Analysis Questions # 

# 1.How many unique customers have placed orders? 

select * from customers;

select count(distinct(customer_id)) as NO_Of_Unique_Customers from orders;

/* 500 unique customers have placed 20000 orders. */

# 2.What is the revenue contribution by customer region?

select * from customers;
select * from order_items;

select c.region,round(sum(line_total),3) as Total_Revenue from customers c join orders o using (customer_id) join order_items oi using(order_id)
group by region order by Total_Revenue desc;

/* The customers in the West region have contributed most to the total revenue and South has the leat contribution. */

# 3.Which regions have the highest average order value?

select * from customers;
select * from order_items;

select c.region,avg(quantity) as AVG_Quantity from customers c join orders o using (customer_id) join order_items oi using(order_id)
group by c.region order by AVG_Quantity desc limit 1;

/* The Customers in West region have placed highest average order with each customer place 3.0159 items per order in average. */

# 4.Who are the top 10 customers by total spending?

select * from customers;
select * from order_items;

select c.customer_id,round(sum(line_total),3) as Total_Revenue from customers c join orders o using (customer_id) join order_items oi using(order_id)
group by c.customer_id order by Total_Revenue desc limit 10;


# 5.What percentage of customers are repeat buyers?

with customer_orders as (
select customer_id,count(order_id) as total_orders from orders group by customer_id)
select round(sum(case when total_orders > 1 then 1 
				 else 0 end) * 100.0 / count(*),2)
as repeat_customer_percentage from customer_orders;

/* 100% of them are repeat buyers. */

# 6.How long after signup do customers typically place their first order? 

select * from customers;
select * from orders;
select * from order_items;

with Cust_info as(
select c.customer_id,c.signup_date,o.order_date,dense_rank() over(partition by customer_id order by order_date asc) as Rank_Date 
from customers c join orders o using (customer_id) join order_items oi using(order_id) where order_date>=signup_date)
select customer_id,datediff(order_date, signup_date) as Duration_To_Place_Order from Cust_info where Rank_date=1;


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Order & Purchasing Behavior Questions #

# 1.How many orders are placed per customer on average?

with Order_Num as (
select distinct customer_id,count(*) as Order_Num from orders group by customer_id)
select avg(Order_Num) as AVG_Order_Num from Order_Num;

/* On an average each customer has placed 40 items per order through out the year. */

# 2.What is the distribution of order sizes (small vs large orders)?

with order_values as (
select order_id,sum(quantity) as Order_Size from order_items group by order_id),
order_size_classification as (
select order_id,Order_Size,case 
when Order_Size <10 then 'small'
else 'large' end as Size_Discription
from order_values)
select Size_Discription,count(*) as order_count,round(count(*) * 100.0 / sum(count(*)) over (),2) as percentage_of_orders
from order_size_classification group by Size_Discription;

/* Customers who placed smaller orders dominate with 68.06% of the total order as compared larger order with only 31.95% of the total order. */

# 3.Which orders generate the highest revenue?

select * from order_items;
select order_id,sum(quantity) as Total_Quantity,sum(line_total) as Total_Revenue from order_items group by order_id order by Total_Revenue desc limit 1;
select * from order_items where order_id=5984;

/* The order_id 5984 ha generated the highest revenue with total quantity of 19 productes with total reveue of 8,922.85. */

# 4.Are larger orders associated with certain categories?

with order_values as (
select order_id,sum(quantity) as Order_Size from order_items group by order_id order by Order_Size desc),
large_orders as (
select order_id from order_values where Order_Size >15)
select p.category,count(distinct o.order_id) as large_order_count
from large_orders lo join orders o using(order_id) join order_items oi using(order_id) join products p using(product_id)
group by p.category order by large_order_count desc;

/* Furniture offers largest orders. */

# 5.How does order frequency vary by region? 

select * from customers;
select * from orders;
select * from order_items;

select c.region,count(distinct o.order_date) as count_Date from customers c join orders o using (customer_id) join order_items oi using (order_id)
group by c.region;


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Time-Based & Trend Analysis #

# 1.How does customer acquisition change over time?

with first_orders as (
select customer_id,min(order_date) as first_order_date from orders group by customer_id)
select monthname(first_order_date) as Month_Name,month(first_order_date) as Month_Number,count(customer_id) as new_customers
from first_orders group by Month_Name,Month_Number order by Month_Number;

/* Most of the new customers are aquired in the begining of the month. */ 

# 2.Are there noticeable sales spikes around specific months?

select * from monthly_revenue order by Monthly_Revenue desc;


# 3.How does category performance evolve over time?

select * from order_items;
select * from orders;
select * from products;

select p.category,monthname(o.order_date) as Month_Name,month(o.order_date) as Month_Number,round(sum(line_total),3) as Total_Revenue
from orders o join order_items oi using (order_id) join products p using (product_id)
group by p.category,Month_Name,Month_Number order by category asc,Month_Number asc;


# 4.What is the customer lifetime value (CLV) by region?

with customer_lifetime_revenue as (
select o.customer_id,round(sum(oi.line_total),3) as lifetime_revenue from orders o join order_items oi using(order_id) group by o.customer_id)
select c.region,round(avg(clr.lifetime_revenue), 2) as avg_clv,count(distinct c.customer_id) as total_customers
from customer_lifetime_revenue clr join customers c using(customer_id) group by c.region order by avg_clv desc;

/* South has the highest avg_clv value with total customers of 108. */

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

# Data Science-Oriented Questions # 

# 1.Can customers be segmented based on spending behavior?

with customer_spending as (
select o.customer_id,round(sum(oi.line_total),3) as total_spent from orders o join order_items oi using(order_id) group by o.customer_id)
select customer_id,total_spent,case
when total_spent < 60000 then 'low_spender'
when total_spent between 60000 and 100000 then 'medium_spender'
else 'high_spender' end as spending_segment
from customer_spending order by total_spent desc;

/* Most of the customers come under the category of medium_spender where as leat of them come under the category of Low _spender and High_spenders. */

# 2.What factors most influence order value?

#-----number of items per order

with order_metrics as (
select order_id,sum(quantity) as total_items,sum(line_total) as order_revenue from order_items group by order_id)
select total_items,round(avg(order_revenue), 2) as avg_order_value from order_metrics group by total_items order by avg_order_value desc;

#-----number of categories per order

with order_category_metrics as (
select oi.order_id,round(sum(line_total),3) as order_revenue,p.category from order_items oi join products p using(product_id) group by oi.order_id,p.category)
select category,round(avg(order_revenue), 2) as avg_order_value from order_category_metrics group by category order by avg_order_value desc;








