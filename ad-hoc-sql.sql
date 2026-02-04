-- .1
alter table dim_customers rename to dim_customer;

select market from dim_customer where
customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market
order by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020 unique_products_2021 percentage_chg

select x.a as unique_product_2020,
y.b as unique_products_2021, round((b-a)*100/a,2) as percentage_chg from(
select count(distinct(product_code)) as a
from fact_sales_monthly where fiscal_year = 2020) x,(select count(distinct(product_code)) as b
from fact_sales_monthly where fiscal_year = 2021) y;

-- 3.
select segment,count(distinct(product_code)) as product_count
from dim_product group by segment order by product_count desc;

-- 4. 
with cte1 as 
(select p.segment as a, count(distinct(fs.product_code))as b 
from dim_product p, fact_sales_monthly fs where p.product_code = fs.product_code
group by fs.fiscal_year,p.segment
having fs.fiscal_year="2020"),
cte2 as (select p.segment as c,count(distinct(fs.product_code)) as d 
from dim_product p, fact_sales_monthly fs where p.product_code = fs.product_code
group by fs.fiscal_year,p.segment
having fs.fiscal_year="2021")
select cte1.a as segment ,cte1.b as product_count_2020,cte2.d as product_count_2021,
(cte2.d-cte1.b) as difference from cte1,cte2 where cte1.a = cte2.c;

-- 5.
select f.product_code,p.product,f.manufacturing_cost from fact_manufacturing_cost f join 
dim_product p on f.product_code = p.product_code where manufacturing_cost in(
select max(manufacturing_cost) from fact_manufacturing_cost union 
select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

-- 6. 
select c.customer_code,c.customer,round(avg(pre_invoice_discount_pct),2)*100 as average_discount_percentage
from fact_pre_invoice_deductions d join dim_customer c
on d.customer_code = c.customer_code 
where c.market = "India" AND fiscal_year = "2021" group by customer_code,c.customer
order by average_discount_percentage desc
limit 5;

-- 7. 
select concat(monthname(fs.date),'(',year(fs.date),')') as 'Month', fs.fiscal_year,
round(sum(g.gross_price*fs.sold_quantity),2) as gross_sales_amount 
from fact_sales_monthly fs join dim_customer c 
on fs.customer_code = c.customer_code join fact_gross_price g on fs.product_code = g.product_code
where c.customer = 'Atliq Exclusive' group by month,fs.fiscal_year
order by fs.fiscal_year;

-- 8.
select case 
when month(date) in (9,10,11) then 'Q1'
when month(date) in (12,1,2) then 'Q2'
when month(date) in (3,4,5) then 'Q3'
else 'Q4' end as quarters,sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly where fiscal_year = 2020
group by Quarters order by total_sold_quantity desc;

-- 9.
with temp_table as (
select c.channel,sum(s.sold_quantity*g.gross_price) as total_sales
from fact_sales_monthly s join fact_gross_price g on s.product_code = g.product_code
join dim_customer c on s.customer_code = c.customer_code where s.fiscal_year = 2021 group by c.channel
order by total_sales desc)
select channel,round(total_sales/1000000,2) as gross_sales_in_millions,
round(total_sales/(sum(total_sales) over())*100,2) as percentage from temp_table;

-- 10.
with temp_table as(
select division, s.product_code,concat(p.product," ","(",p.variant,")") as product,
sum(sold_quantity) as total_sold_quantity,
rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly s join dim_product p on s.product_code = p.product_code 
where fiscal_year = 2021
group by division,s.product_code, p.product,p.variant) 
select * from temp_table where rank_order in (1,2,3);