create database PROJECT;
USE PROJECT;


drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date datetime); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');

alter table driver modify reg_date date;
drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01 18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-01 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


-- A. ROLL METRICS
-- How many rolls were ordered
select count(roll_id) as total_rolls from customer_orders;


-- How many unique customer orders were made
select  count( distinct customer_id) as total_customers from customer_orders;

-- How many successful orders were delivered by each driver
select driver_id, count(distinct order_id) as successful_orders from driver_order where cancellation not in 
('Customer Cancellation','Cancellation') group by driver_id;

-- How many of each type of roll was delivered
select roll_id, count(roll_id) as total_rolls from customer_orders where order_id in (
select order_id from (select *, case when cancellation  in 
('Customer Cancellation','Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) as a where order_cancel_details ='nc' )
group by roll_id ;

select c.roll_id, count(c.roll_id) as total_rolls from
(select *, case when cancellation  in 
('Customer Cancellation','Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) as a inner join customer_orders c 
on a.order_id = c.order_id where order_cancel_details = 'nc' group by c.roll_id;


-- how many veg and non veg rolls were ordered by each customer

select c.customer_id,c.roll_id,count(c.roll_id) count_of_roll, r.roll_name from customer_orders c inner join rolls r on c.roll_id = r.roll_id
group by c.customer_id,c.roll_id order by roll_name;

-- what was the maximum number of rolls ordered in a single order
select a.order_id, count(c.roll_id) as count_rolls from
(select *, case when cancellation  in 
('Customer Cancellation','Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) as a inner join customer_orders c 
on a.order_id = c.order_id where order_cancel_details = 'nc' group by a.order_id order by count_rolls desc limit 1;


-- for each customer, how many delivered rolls had at least 1 change and how many had no change
select * from customer_orders;

with temp_customer_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id,customer_id,roll_id,
case when not_include_items is null or not_include_items = '' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included = 'NaN' or extra_items_included = '' then '0' else extra_items_included
end as new_extra_items_included, order_date from customer_orders)
,
temp_driver_order(order_id, driver_id, pickup_time, distance, duration, cancellation) as
(
select order_id, driver_id, pickup_time, distance, duration,
case when cancellation in ('Customer Cancellation','Cancellation') then '0' else 1 end as new_cancellation from driver_order)

select customer_id, change_no_change, count(order_id) as atleast_1_change from
(select *, case when not_include_items = '0' and extra_items_included  = '0' then 'no_change' else 'change' end as change_no_change
from temp_customer_orders where
order_id in (select order_id from temp_driver_order where cancellation != 0 )) a group by customer_id, change_no_change ;

-- How many rolls were delivered that had both exclusions and extracts

with temp_customer_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id,customer_id,roll_id,
case when not_include_items is null or not_include_items = '' then '0' else not_include_items end as new_not_include_items,
case when extra_items_included is null or extra_items_included = 'NaN' or extra_items_included = '' then '0' else extra_items_included
end as new_extra_items_included, order_date from customer_orders)
,
temp_driver_order(order_id, driver_id, pickup_time, distance, duration, cancellation) as
(
select order_id, driver_id, pickup_time, distance, duration,
case when cancellation in ('Customer Cancellation','Cancellation') then '0' else 1 end as new_cancellation from driver_order)
,
final_table (customer_id,order_id,not_include_items,extra_items_included,change_no_change) as 
(select customer_id,order_id,not_include_items,extra_items_included
,case when not_include_items != '0' and extra_items_included  != '0' then 'both_exc_inc' else 'either_exc_or_inc' end as change_no_change
from temp_customer_orders where
order_id in (select order_id from temp_driver_order where cancellation != 0 ) ) 
select change_no_change,count(order_id) as no_of_orders from final_table group by change_no_change;

-- what was the total number of rolls ordered for each hour of the day
select hours_bucket,count(hours_bucket) as no_of_orders from 
(select concat(hour(order_date),'-',hour(order_date)+1 ) hours_bucket  from customer_orders) a
group by hours_bucket;

-- what was the number of orders for each day of the week
select day_of_week,count(distinct order_id) as no_of_orders from
(select *,  dayname(order_date) as day_of_week from customer_orders) a
group by day_of_week;

-- B driver and customer Experience
-- 1. what was the average time in minutes it took for each driver to arrive at the fasoos HQ to pick up the order

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

select driver_id,sum(diff)/count(order_id) as avg_minute from
(select * from
(select *, row_number() over(partition by order_id order by diff) rnk from 
(select a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date,
 b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) diff
from customer_orders a inner join driver_order b on a.order_id = b.order_id where b.pickup_time is not null)d)c where rnk = 1
)e group by driver_id;


-- 2 Is there any relationship between the number of rolls and how long the order takes to prepare?

select order_id,count(roll_id) as cnt, round(sum(diff)/count(roll_id),0) as time_to_pre_order from 
(select a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date,
 b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) diff
from customer_orders a inner join driver_order b on a.order_id = b.order_id where b.pickup_time is not null)a group by order_id;


-- 3. what was the average distance travelled for each customer

select customer_id, round(avg(distance),2) as avg_distance from
(select * from
(select *, row_number() over(partition by order_id order by diff) rnk from
(select a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date,
 b.driver_id, b.pickup_time, cast(trim(replace(b.distance,'km','')) as decimal (4,2)) as distance, b.duration, b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) diff
from customer_orders a inner join driver_order b on a.order_id = b.order_id where b.pickup_time is not null)a)b where rnk = 1)c
group by customer_id;

-- 4. what was the difference between the longest and shortest delivery times for all orders?

select max(durations)-min(durations) as differnce from
(select order_id, duration, cast(case when duration like '%min%' then left(duration,locate('m',duration)-1) else duration end as decimal) as durations 
from driver_order where duration is not null)a;


-- 5. what was the average speed for each driver for each delivery and do you notice any trend for these values?

select a.order_id, a.driver_id, a.distance/a.durations as speed, b.cnt from 
(select order_id,driver_id,cast(case when duration like '%min%' then left(duration,locate('m',duration)-1) else duration end as decimal) 
as durations, cast(trim(replace(distance,'km','')) as decimal (4,2)) as distance
 from driver_order where distance is not null)a inner join (select order_id, count(roll_id) cnt from customer_orders 
 group by order_id)b on a.order_id = b.order_id;
 
 
 -- 6. what is the successful delivery percentage for each driver?
 
 select driver_id, round((s*1.0/c)*100,2) as percentage from 
 (select driver_id, sum(can_per) s, count(driver_id) c from 
 (select driver_id, case when lower(cancellation) like '%cancel%' then 0 else 1 end as can_per from driver_order)a group by driver_id)b;
