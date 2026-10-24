select * from walmart

-- EDA
select count(*) from walmart

select 
	payment_method,
	count(*) as total_count
from walmart
group by payment_method

select 
	count(distinct branch)
from walmart

select max(quantity)
from walmart

select min(quantity)
from walmart

-- Business Problems
-- Find the number of payment method and number of transaction, number of quantity sold
select 
	payment_method,
	count(*) as payment_count,
	sum(quantity) as quantity_sold
from walmart
group by payment_method

-- Which category received the highest average rating in each branch
select *
from
(select
	branch,
	category,
	avg(rating) as avg_rating,
	rank() over(partition by branch order by avg(rating) desc) as rank
from walmart
group by branch, category
) as ranked_data
where rank = 1

--  Busiest day of the week for each branch based on transaction volume?
select 
* from
(select 
	branch,
	format(try_convert(Date, date, 3), 'dddd') as day_name,
	count(*) as no_transaction,
	rank() over(partition by branch order by avg(rating) desc) as rank
from walmart
group by branch, format(try_convert(Date, date, 3), 'dddd')
) as ranked_data
where rank = 1

-- How many items were sold through each payment method?
select 
	payment_method,
	sum(quantity) as item_sales
from walmart
group by payment_method
order by item_sales desc


--  What are the average, minimum, and maximum ratings for each category in each city?
select
	category,
	city,
	avg(rating) as avg_rating,
	min(rating) as min_rating,
	max(rating) as max_rating
from walmart
group by category, city

-- What is the total profit for each category, ranked from highest to lowest?
 select 
	category,
	sum(total) as revenue,
	sum(total * profit_margin) as profit
 from walmart
 group by category
 order by profit asc
 
 
 -- What is the most frequently used payment method in each branch?
with cte_ranked
as
(select
	branch,
	payment_method,
	count(*) as total_trans,
	rank() over(partition by branch order by count(*) desc) as ranked
from walmart
group by branch, payment_method
)
select * from cte_ranked
where ranked = 1

-- How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
select 
	branch,
	CASE 
        WHEN TRY_CONVERT(time, [time]) >= '06:00:00' AND TRY_CONVERT(time, [time]) < '12:00:00' THEN 'Morning'
        WHEN TRY_CONVERT(time, [time]) >= '12:00:00' AND TRY_CONVERT(time, [time]) < '18:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
	count(*) as transactions

from walmart
GROUP BY 
	branch,
    CASE 
        WHEN TRY_CONVERT(time, [time]) >= '06:00:00' AND TRY_CONVERT(time, [time]) < '12:00:00' THEN 'Morning'
        WHEN TRY_CONVERT(time, [time]) >= '12:00:00' AND TRY_CONVERT(time, [time]) < '18:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END
order by branch, transactions desc

-- Which branches experienced the largest decrease in revenue compared to the previous year?
-- decrease ratio = last year revenue - current revenue / last year revenue * 100

with revenue_2022
as
(
select 
 branch,
 sum(total) as total_revenue_2022
from walmart
where format(try_convert(Date, [date], 3), 'yyyy') = '2022'
group by branch
),

revenue_2023
as
(
select 
branch,
sum(total) as total_revenue_2023
from walmart
where format(try_convert(Date, [date], 3), 'yyyy') = '2023'
group by branch
)

select top 5
ls.branch,
ls.total_revenue_2022 as last_year,
cs.total_revenue_2023 as current_year,
Cast(
((TRY_CAST(ls.total_revenue_2022 AS DECIMAL(18,2)) - TRY_CAST(cs.total_revenue_2023 AS DECIMAL(18,2))) 
 / TRY_CAST(ls.total_revenue_2022 AS DECIMAL(18,2))) * 100.0  as DECIMAL(18,2)) AS decrease_ratio 
from 
revenue_2022 as ls
join 
revenue_2023 as cs
on ls.branch = cs.branch
where ls.total_revenue_2022 > cs.total_revenue_2023
order by Cast(
((TRY_CAST(ls.total_revenue_2022 AS DECIMAL(18,2)) - TRY_CAST(cs.total_revenue_2023 AS DECIMAL(18,2))) 
 / TRY_CAST(ls.total_revenue_2022 AS DECIMAL(18,2))) * 100.0  as DECIMAL(18,2)) desc
