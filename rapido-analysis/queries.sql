-- total distance traveled by each user and return only those users who traveled more than 20 km in total

Select user_id,
       SUM(distance_km) as total_distance
from `Rapido.rides`
group by user_id
having sum(distance_km) > 20
order by user_id;


-- average distance per ride for each vehicle type and return only the vehicle types where the average distance is greater than 8 km.
select vehicle_type, 
       round(avg(distance_km),2) as avg_distance
from `Rapido.rides`
group by vehicle_type
having avg(distance_km) > 8
order by vehicle_type; 

-- Find all users who have more than two rides and display the total number of rides per user, sorted by user_id

select user_id, 
      count(ride_id) as total_rides
from `Rapido.rides`
group by user_id
having count(ride_id) > 2
order by user_id;



-- List all users who have never taken a ride, sorted by user_id (Hint: total 53 users)

Select user_id, first_name
from `Rapido.users`
where user_id not in (select DISTINCT user_id from `Rapido.rides`)
order by user_id;


-- Identify all the user(s) who signed up on the earliest signup date. How many such users are there?

select * 
from `Rapido.users`
where signup_date = (select min(signup_date) from `Rapido.users`)


-- Find users who took at least one ride longer than 10 km. How many such users are there? (Total 27 users)

Select user_id
from `Rapido.rides`
group by user_id
having max(distance_km) > 10
order by user_id;





-- Count the number of rides in Cab AC and Cab Non AC, but only include rides longer than the average distance of all rides.

Select sum(case when vehicle_type = 'Cab AC' then 1 else 0 end) as Cab_ac_count,
sum(case when vehicle_type = 'Cab Non AC' then 1 else 0 end) as Cab_non_ac_count
from `Rapido.rides`
where distance_km > (select avg(distance_km) from `Rapido.rides`);


--Create a combined list of all unique start_locations from Rides and all unique end_location values from Rides in 1 column, name it as location (Total 22 locations)

Select distinct start_location as location
from `Rapido.rides`

UNION DISTINCT

Select distinct end_location as location
from `Rapido.rides`

  
-- Calculate each user’s total rides and total distance, and return only the users whose total distance is greater than the average total distance of all users, sorted by user_id (Total 25 rows)

  WITH user_stats AS (
    SELECT 
        user_id,
        COUNT(ride_id) AS total_rides,
        ROUND(SUM(distance_km), 2) AS total_distance
    FROM `Rapido.rides`
    GROUP BY user_id
)

SELECT
    user_id,
    total_rides,
    total_distance
FROM user_stats
WHERE total_distance > (
    SELECT AVG(total_distance)
    FROM user_stats
)
ORDER BY user_id;


--Find each user’s average ride distance, categorize them as Low (<8 km), Medium (8-12 km), High (>12 km), and count the number of users in each category, sorted by user_count in descending order

with ride_distance_stats as (
  select user_id,
         round(avg(distance_km),2) as user_distance
  from `Rapido.rides`
  group by user_id
)
select case
            when (a.user_distance) < 8 then 'Low'
            when (a.user_distance) between 8 and 12 then 'Medium'
            else 'High'
        end as categories,
        count(user_id) as user_count
from ride_distance_stats a
group by case
            when (a.user_distance) < 8 then 'Low'
            when (a.user_distance) between 8 and 12 then 'Medium'
            else 'High'
        end
order by user_count desc



--Find rides whose distance is greater than the average distance per vehicle type, sorted by user_id and ride_id (Total 49 rows)


select user_id, ride_id
from `Rapido.rides` t1
where distance_km > (select avg(distance_km) 
 from `Rapido.rides` t2 
 where t1.vehicle_type = t2.vehicle_type 
 group by vehicle_type)
order by user_id, ride_id;


-- Find the percentage of rides out of total that had a captain rating = 0

Select 
round(sum(case when captain_rating = 0 then 1 else 0 end) *100/count(*),2) as captain_zero_percentage
from `Rapido.rides`



--Find the users who signed up in April 2025 but have not taken any rides, sorted by user_id (Hint use between to filter on dates, can directly use string values)

select user_id, first_name, last_name
from `Rapido.users`
where signup_date between '2025-04-01' and '2025-04-30' 
and user_id not in (select distinct user_id
                    from `Rapido.rides`)
order by user_id; 

--or

select u.user_id, u.first_name, u.last_name
from `Rapido.users` u
where u.signup_date between '2025-04-01' and '2025-04-30' 
and not exists (select 1
                from `Rapido.rides` r
                where r.user_id = u.user_id)
order by u.user_id; 



-- Find the average distance travelled by users who signed up in May 2025 (Hint use between to filter on dates, can directly use string values)

select avg(distance_km) as avg_distance
from `Rapido.rides`
where user_id in (select user_id 
                  from `Rapido.users`
                  where signup_date between '2025-05-01' and '2025-05-31');

use signup date < '2025-06-01' so This avoids missing users who signed up on 2025-05-31 with a time component.


--Identify the user(s) who have travelled in the maximum number of different vehicle types

with vehicle_stats as (
  select user_id,
         count(Distinct vehicle_type) as vehicle_type_count
  from `Rapido.rides`
  group by user_id
)

select user_id, 
       vehicle_type_count
from vehicle_stats
where vehicle_type_count  = (select max(vehicle_type_count) from vehicle_stats)
