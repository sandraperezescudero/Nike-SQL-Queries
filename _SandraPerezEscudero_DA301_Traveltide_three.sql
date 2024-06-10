/*
Question #1:
Calculate the number of flights with a departure time during the work week (Monday through Friday) and the number of flights departing during the weekend (Saturday or Sunday).

Expected column names: working_cnt, weekend_cnt
*/

-- q1 solution:

SELECT
    COUNT(CASE WHEN DATE_PART('dow', departure_time) IN (1,2,3,4,5) THEN 1 END) AS working_cnt,
    COUNT(CASE WHEN DATE_PART('dow', departure_time) IN (0,6) THEN 1 END) AS weekend_cnt
FROM
    flights;

/*
This query counts the number of flights departing during the weekdays (Monday through Friday) and during the weekend (Saturday and Sunday) separately. 
The DATE_PART function extracts the day of the week (represented as an integer where Sunday is 0 and Saturday is 6) from the departure_time column. 
The CASE statements within the COUNT function increment the count based on whether the day of the week falls within the weekday or weekend categories.
*/


/*

Question #2: 
For users that have booked at least 2  trips with a hotel discount, it is possible to calculate their average hotel discount, and maximum hotel discount. write a solution to find users whose maximum hotel discount is strictly greater than the max average discount across all users.

Expected column names: user_id

*/

-- q2 solution:

WITH UserHotelDiscounts AS (
    SELECT
        user_id,
        AVG(hotel_discount_amount) AS avg_hotel_discount,
        MAX(hotel_discount_amount) AS max_hotel_discount
    FROM
        sessions
    WHERE
   			hotel_discount_amount IS NOT NULL
  			AND hotel_discount = TRUE
        AND cancellation = FALSE
        AND trip_id IS NOT NULL
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT trip_id) >= 2
)
SELECT
    user_id
FROM
    UserHotelDiscounts
WHERE
    max_hotel_discount > (SELECT MAX(avg_hotel_discount) FROM UserHotelDiscounts);

/*
- CTE (Common Table Expression) - UserHotelDiscounts:
Selects the user_id, calculates the average (avg_hotel_discount), and maximum (max_hotel_discount) hotel discount amount for each user.
Filters the sessions data based on the conditions:
hotel_discount_amount is not null
hotel_discount is true
cancellation is false
trip_id is not null
Groups the data by user_id.
Includes only those users who have booked at least two trips with a hotel discount.

- Main Query:
Selects user_id from the UserHotelDiscounts CTE.
Filters the users where the maximum hotel discount (max_hotel_discount) is greater than the maximum average hotel discount (MAX(avg_hotel_discount)).

Overall, this query identifies users who have booked at least two trips with a hotel discount and have a maximum hotel discount greater than the maximum average hotel discount across all users meeting the criteria.

*/

/*
Question #3: 
when a customer passes through an airport we count this as one “service”.

for example:

suppose a group of 3 people book a flight from LAX to SFO with return flights. In this case the number of services for each airport is as follows:

3 services when the travelers depart from LAX

3 services when they arrive at SFO

3 services when they depart from SFO

3 services when they arrive home at LAX

for a total of 6 services each for LAX and SFO.

find the airport with the most services.

Expected column names: airport

*/

-- q3 solution:

WITH AirportServices AS (
    SELECT
        origin_airport AS airport,
        SUM(seats) AS total_services
    FROM
        flights
    GROUP BY
        origin_airport
    UNION ALL
    SELECT
        destination_airport AS airport,
        SUM(CASE WHEN return_flight_booked THEN seats * 2 ELSE seats END) AS total_services
    FROM
        flights
    GROUP BY
        destination_airport
)
SELECT
    airport
FROM
    AirportServices
ORDER BY
    total_services DESC
LIMIT 1;

/*
This SQL query aims to identify the airport with the highest total number of services based on the number of seats booked in flights. 
Here's a breakdown of the query:

- AirportServices CTE:
It calculates the total number of services for each airport.
For each origin airport, it sums the number of seats booked using SUM(seats).
For each destination airport, it checks if a return flight was booked. If so, it doubles the number of seats using SUM(CASE WHEN return_flight_booked THEN seats * 2 ELSE seats END). Otherwise, it just sums the seats.
The results are combined using UNION ALL to include both origin and destination airports.

- Main Query:
It selects the airport code from the AirportServices CTE.
Results are ordered by the total number of services in descending order (ORDER BY total_services DESC).
It retrieves only the top airport with the highest total services using LIMIT 1.

In summary, this query calculates the total number of services for each airport, considering both departures and arrivals, and identifies the airport with the highest total services by sorting the results in descending order and selecting the top result.
*/


/*
Question #4: 
using the definition of “services” provided in the previous question, we will now rank airports by total number of services. 

write a solution to report the rank of each airport as a percentage, where the rank as a percentage is computed using the following formula: 

`percent_rank = (airport_rank - 1) * 100 / (the_number_of_airports - 1)`

The percent rank should be rounded to 1 decimal place. airport rank is ascending, such that the airport with the least services is rank 1. If two airports have the same number of services, they also get the same rank.

Return by ascending order of rank

E**xpected column names: airport, percent_rank**

Expected column names: airport, percent_rank
*/

-- q4 solution:

WITH AirportServices AS (
    SELECT
        origin_airport AS airport,
        SUM(seats) AS departures
    FROM
        flights
    GROUP BY
        origin_airport
    UNION ALL
    SELECT
        destination_airport AS airport,
        SUM(CASE WHEN return_flight_booked THEN seats * 2 ELSE seats END) AS departures
    FROM
        flights
    GROUP BY
        destination_airport
),
RankedAirports AS (
    SELECT
        airport,
        SUM(departures) AS total_services,
        RANK() OVER (ORDER BY SUM(departures) ASC) AS airport_rank
    FROM
        AirportServices
    GROUP BY
        airport
)
SELECT
    airport,
    ROUND((PERCENT_RANK() OVER (ORDER BY airport_rank) * 100.0)::numeric, 1) AS percent_rank
FROM
    RankedAirports
ORDER BY
    airport_rank ASC;

/*
This query calculates the total number of services for each airport based on the flights table, where each flight represents a "service." 
It accounts for both departing and arriving flights at each airport, considering the number of seats booked. 
If a return flight is booked, it counts as an additional service.

Here's a breakdown:

- AirportServices CTE:
It calculates the total number of departures for each airport.
SUM(seats) is used to calculate the total number of seats for each origin airport.
For destination airports, SUM(CASE WHEN return_flight_booked THEN seats * 2 ELSE seats END) is used to double the number of seats if a return flight is booked.
The results are combined using UNION ALL to include both origin and destination airports.

- RankedAirports CTE:
It aggregates the total number of services for each airport obtained from the AirportServices CTE.
The SUM(departures) function calculates the total services for each airport.
The RANK() window function assigns a rank to each airport based on the total number of services.

- Main Query:
It selects the airport code and computes the percent rank for each airport based on its rank obtained from the RankedAirports CTE.
The PERCENT_RANK() window function calculates the percentile rank of each airport based on its rank position relative to other airports.
The ROUND() function rounds the percent rank to one decimal place.
Results are ordered by airport rank in ascending order.

Overall, this query provides a ranked list of airports based on the total number of services they offer, with each airport's rank represented as a percentage.
*/
