# Faasos_Data_Analysis
### Objective
This project, which is mostly based on MySQL, required me to solve a variety of challenging queries. I also had to deal with a lot of null values and incorrect data types, as well as do data cleansing, data modeling, and data transformation.

### Complex Queries
#### Q1 How many successful orders were delivered by each driver?
        select driver_id, count(distinct order_id) as successful_orders from driver_order where cancellation not in 
        ('Customer Cancellation','Cancellation') group by driver_id;

#### Q2  How many of each type of roll was delivered?
         select roll_id, count(roll_id) as total_rolls from customer_orders where order_id in (
           select order_id from (select *, case when cancellation  in 
              ('Customer Cancellation','Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) as a where order_cancel_details ='nc' )
                 group by roll_id ;

#### Q3 what was the maximum number of rolls ordered in a single order?
        select a.order_id, count(c.roll_id) as count_rolls from
        (select *, case when cancellation  in 
         ('Customer Cancellation','Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order) as a inner join customer_orders c 
          on a.order_id = c.order_id where order_cancel_details = 'nc' group by a.order_id order by count_rolls desc limit 1;

#### Q4  for each customer, how many delivered rolls had at least 1 change and how many had no change
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

#### Q5  what was the total number of rolls ordered for each hour of the day?
         select hours_bucket,count(hours_bucket) as no_of_orders from 
         (select concat(hour(order_date),'-',hour(order_date)+1 ) hours_bucket  from customer_orders) a
         group by hours_bucket;

#### Q6 what was the number of orders for each day of the week?
     select day_of_week,count(distinct order_id) as no_of_orders from
     (select *,  dayname(order_date) as day_of_week from customer_orders) a
     group by day_of_week;

#### Q7 Is there any relationship between the number of rolls and how long the order takes to prepare?
     select order_id,count(roll_id) as cnt, round(sum(diff)/count(roll_id),0) as time_to_pre_order from 
     (select a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date,
     b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) diff
     from customer_orders a inner join driver_order b on a.order_id = b.order_id where b.pickup_time is not null)a group by order_id;

#### Q8  what was the average distance travelled for each customer#
         select customer_id, round(avg(distance),2) as avg_distance from
         (select * from (select *, row_number() over(partition by order_id order by diff) rnk from
          (select a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date,
           b.driver_id, b.pickup_time, cast(trim(replace(b.distance,'km','')) as decimal (4,2)) as distance, b.duration, b.cancellation,timestampdiff(minute,a.order_date,b.pickup_time) diff
           from customer_orders a inner join driver_order b on a.order_id = b.order_id where b.pickup_time is not null)a)b where rnk = 1)c
            group by customer_id;

#### Q9  what was the difference between the longest and shortest delivery times for all orders?
         select max(durations)-min(durations) as differnce from
         (select order_id, duration, cast(case when duration like '%min%' then left(duration,locate('m',duration)-1) else duration end as decimal) as durations 
          from driver_order where duration is not null)a;

#### Q10 what was the average speed for each driver for each delivery and do you notice any trend for these values?
        select a.order_id, a.driver_id, a.distance/a.durations as speed, b.cnt from 
        (select order_id,driver_id,cast(case when duration like '%min%' then left(duration,locate('m',duration)-1) else duration end as decimal) 
         as durations, cast(trim(replace(distance,'km','')) as decimal (4,2)) as distance
         from driver_order where distance is not null)a inner join (select order_id, count(roll_id) cnt from customer_orders 
          group by order_id)b on a.order_id = b.order_id;
