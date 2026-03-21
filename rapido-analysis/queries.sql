-- Analyze total distance traveled by each user and identify high-usage users who have traveled more than 20 km, indicating high engagement.

Select user_id,
       SUM(distance_km) as total_distance
from `Rapido.rides`
group by user_id
having sum(distance_km) > 20
order by user_id;


--Evaluate average ride distance across vehicle types and identify vehicle categories with higher-than-average trip lengths (>8 km), indicating premium or long-distance usage patterns.
select vehicle_type, 
       round(avg(distance_km),2) as avg_distance
from `Rapido.rides`
group by vehicle_type
having avg(distance_km) > 8
order by vehicle_type; 

-- Identify active users who have completed more than two rides to understand repeat usage behavior.

select user_id, 
      count(ride_id) as total_rides
from `Rapido.rides`
group by user_id
having count(ride_id) > 2
order by user_id;



-- Detect users who signed up but have never taken a ride, highlighting potential onboarding or activation issues.

Select user_id, first_name
from `Rapido.users`
where user_id not in (select DISTINCT user_id from `Rapido.rides`)
order by user_id;


-- Identify early adopters by finding users who signed up on the earliest date, useful for understanding initial user base behavior.

select * 
from `Rapido.users`
where signup_date = (select min(signup_date) from `Rapido.users`)


-- Identify users who have taken at least one long-distance ride (>10 km), indicating premium usage behavior.

Select user_id
from `Rapido.rides`
group by user_id
having max(distance_km) > 10
order by user_id;





-- Compare ride distribution between Cab AC and Cab Non AC for rides longer than the average distance, to analyze preference for premium services in longer trips.

Select sum(case when vehicle_type = 'Cab AC' then 1 else 0 end) as Cab_ac_count,
sum(case when vehicle_type = 'Cab Non AC' then 1 else 0 end) as Cab_non_ac_count
from `Rapido.rides`
where distance_km > (select avg(distance_km) from `Rapido.rides`);


--Generate a unified list of all unique ride locations (start and end) to understand operational coverage.

Select distinct start_location as location
from `Rapido.rides`

UNION DISTINCT

Select distinct end_location as location
from `Rapido.rides`

  
-- Analyze user-level ride activity and identify users whose total travel distance exceeds the overall average, indicating high-value users.

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


--Segment users based on their average ride distance into Low (<8 km), Medium (8–12 km), and High (>12 km) categories to understand behavioral patterns.

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



--Identify rides that exceed the average distance for their respective vehicle type to detect outlier or premium trips.


select user_id, ride_id
from `Rapido.rides` t1
where distance_km > (select avg(distance_km) 
 from `Rapido.rides` t2 
 where t1.vehicle_type = t2.vehicle_type 
 group by vehicle_type)
order by user_id, ride_id;


-- Identify rides that exceed the average distance for their respective vehicle type to detect outlier or premium trips.

Select 
round(sum(case when captain_rating = 0 then 1 else 0 end) *100/count(*),2) as captain_zero_percentage
from `Rapido.rides`



--Calculate the percentage of rides with zero captain rating to assess service quality issues.

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



-- Evaluate average ride distance for users who signed up in May 2025 to understand early engagement behavior.

select avg(distance_km) as avg_distance
from `Rapido.rides`
where user_id in (select user_id 
                  from `Rapido.users`
                  where signup_date between '2025-05-01' and '2025-05-31');

use signup date < '2025-06-01' so This avoids missing users who signed up on 2025-05-31 with a time component.


--Identify users who have used the highest number of different vehicle types, indicating diverse usage behavior.

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
