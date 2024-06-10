/*
Question #1: 
*/

-- q1 solution:

SELECT DISTINCT cu.state, -- I used SELECT DISTINCT to assess the unique state values available in the customer data
COUNT(DISTINCT cu.customer_id) AS total_customers -- I used COUNT DISTINCT to count the number of customers per unique state value
FROM customers cu
GROUP BY cu.state;

/*
By assessing the unique state values against the number of customers per state value we are getting an overview of the quarter performance of the last three months for each state.
*/

/*
Question #2: 
*/

-- q2 solution:

SELECT
  CASE WHEN cu.state = 'US State' THEN 'California' 
  ELSE cu.state 
  END AS clean_state, -- I used CASE WHEN to reassign the 'US State' value to 'California'
  COUNT(DISTINCT o.order_id) AS total_completed_orders -- I used COUNT DISTINCT to count the total number of orders for every state
FROM
  customers cu
INNER JOIN -- I used an INNER JOIN to combine the two tables needed and only include orders for which customer data is available
  orders o ON o.user_id = cu.customer_id
WHERE
  o.status = 'Complete' -- I used a filter to include just the completed orders
GROUP BY
  clean_state;
/*
By cleaning the data and reassining the wrong state value we are able to get an overview of the total completed orders per state in order to analise the quarter performance accurately, although some data is missing as we did not have all customer data available
*/

/*
Question #3: 
*/

-- q3 solution:

WITH total_order_items AS ( -- I used a WITH and UNION ALL statement to get the the total number of orders from order_items and order_items_vintage combined
  SELECT * FROM order_items oi
  UNION ALL
  SELECT * FROM order_items_vintage oiv
) 
SELECT
  CASE
    WHEN cu.state = 'US State' THEN 'California'
    WHEN cu.state IS NULL THEN 'Missing Data'
    ELSE cu.state
  END AS clean_state, -- -- I used CASE WHEN to reassign the 'US State' value to 'California' and also to assign the records to 'Missing Data' if customer data was missing
  COUNT(DISTINCT toi.order_id) AS total_completed_orders, -- I used COUNT DISTINCT to count the total number of orders for every state for each different group
  COUNT(DISTINCT oi.order_id) AS official_completed_orders,
  COUNT(DISTINCT oiv.order_id) AS vintage_completed_orders
FROM
  total_order_items toi
LEFT JOIN -- I used LEFT JOINS to combine the three tables needed and make sure we are not losing any data
  customers cu ON toi.user_id = cu.customer_id
LEFT JOIN
  orders o ON o.order_id = toi.order_id
LEFT JOIN
  order_items oi ON oi.order_item_id = toi.order_item_id
LEFT JOIN
  order_items_vintage oiv ON oiv.order_item_id = toi.order_item_id
WHERE
  o.status = 'Complete' -- I used a filter to include just the completed orders
GROUP BY
  clean_state;
 
/*
By using LEFT JOINS and assigning a 'Missing Data' value to the missing records we ensure we are not missing any data and that our analysis is correct. 
However, the results of my query were different in some of the values to the expected outcome and I could not figure out why. 
*/

/*
Question #4: 
*/

-- q4 solution:

WITH total_order_items AS (
  SELECT * FROM order_items oi
  UNION ALL
  SELECT * FROM order_items_vintage oiv
)
SELECT
  CASE
    WHEN cu.state = 'US State' THEN 'California'
    WHEN cu.state IS NULL THEN 'Missing Data'
    ELSE cu.state
  END AS clean_state,
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN toi.order_id END) AS total_completed_orders, 
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oi.order_id END) AS official_completed_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oiv.order_id END) AS vintage_completed_orders,
  SUM(oi.sale_price) + SUM(oiv.sale_price) AS total_revenue -- I reused the query from question 3 but I modified the COUNT(DISTINCT) expressions to only count completed orders and added a SUM expression for total revenue which includes all orders
FROM
  total_order_items toi
LEFT JOIN
  customers cu ON toi.user_id = cu.customer_id
LEFT JOIN
  orders o ON o.order_id = toi.order_id
LEFT JOIN
  order_items oi ON oi.order_item_id = toi.order_item_id
LEFT JOIN
  order_items_vintage oiv ON oiv.order_item_id = toi.order_item_id
GROUP BY
  clean_state;

/*
Adding the SUM of the revenue for all orders and not just the completed allows us to compare the total revenue with the completed orders and generate valuable business analysis. 
However, the results of my query were different in some of the values to the expected outcome and I could not figure out why. 
*/

/*
Question #5: 
*/

-- q5 solution:

WITH total_order_items AS (
  SELECT * FROM order_items oi
  UNION ALL
  SELECT * FROM order_items_vintage oiv
)
SELECT
  CASE
    WHEN cu.state = 'US State' THEN 'California'
    WHEN cu.state IS NULL THEN 'Missing Data'
    ELSE cu.state
  END AS clean_state,
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN toi.order_id END) AS total_completed_orders, 
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oi.order_id END) AS official_completed_orders,
  COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oiv.order_id END) AS vintage_completed_orders,
  SUM(oi.sale_price) + SUM(oiv.sale_price) AS total_revenue, 
  COUNT(toi.returned_at) AS returned_items -- I reused the query from question 4 but I also counted the number of returned_items form the total_order_items table created in the WITH statement to identify all returned order items
FROM
  total_order_items toi
LEFT JOIN
  customers cu ON toi.user_id = cu.customer_id
LEFT JOIN
  orders o ON o.order_id = toi.order_id
LEFT JOIN
  order_items oi ON oi.order_item_id = toi.order_item_id
LEFT JOIN
  order_items_vintage oiv ON oiv.order_item_id = toi.order_item_id
GROUP BY
  clean_state; 

/*
Adding the COUNT of the returned_items allows us to understand how many items have been returned after being ordered to get a better picture of the business situation and how to improve the sales. 
However, the results of my query were different in some of the values to the expected outcome and I could not figure out why. 
*/

/*
Question #6: 
*/

-- q6 solution:

WITH total_order_items AS (
    SELECT * FROM order_items oi
    UNION ALL
    SELECT * FROM order_items_vintage oiv
)

SELECT
    CASE
        WHEN cu.state = 'US State' THEN 'California'
        WHEN cu.state IS NULL THEN 'Missing Data'
        ELSE cu.state
    END AS clean_state,
    COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN toi.order_id END) AS total_completed_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oi.order_id END) AS official_completed_orders,
    COUNT(DISTINCT CASE WHEN o.status = 'Complete' THEN oiv.order_id END) AS vintage_completed_orders,
    SUM(oi.sale_price) + SUM(oiv.sale_price) AS total_revenue,
    COUNT(toi.returned_at) AS returned_items,
    COUNT(DISTINCT CASE WHEN toi.returned_at IS NOT NULL THEN toi.order_item_id END) / -- I reused the query from question 4 and calculated the return_rate by dividing the count of distinct order items with a return (returned_at IS NOT NULL) by the total count of distinct order items (COUNT(DISTINCT toi.order_item_id). I also used CAST with the denominator to make it a float and calculate the return rate and ensure accurate division
    CAST(COUNT(DISTINCT toi.order_item_id) AS FLOAT) AS return_rate 
FROM
    total_order_items toi
LEFT JOIN
    customers cu ON toi.user_id = cu.customer_id
LEFT JOIN
    orders o ON o.order_id = toi.order_id
LEFT JOIN
    order_items oi ON oi.order_item_id = toi.order_item_id
LEFT JOIN
    order_items_vintage oiv ON oiv.order_item_id = toi.order_item_id
GROUP BY
    clean_state;

/*
Adding the return_rate allows us to have a benchmark and understand what number of returned items is acceptable. 
However, the results of my query were different in some of the values to the expected outcome and I could not figure out why. 
*/