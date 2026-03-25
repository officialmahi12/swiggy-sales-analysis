SELECT * FROM swiggy_data

-- Data Validation & Cleaning
-- Null Check

SELECT 
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;


--Blank or Empty Strings
SELECT *
FROM swiggy_data
WHERE 
    State = '' 
 OR City = '' 
 OR Restaurant_Name = '' 
 OR Location = '' 
 OR Category = '' 
 OR Dish_Name = '';

--Duplicate Detection
SELECT 
    State, City, order_date, restaurant_name, location, category,
    dish_name, price_INR, rating, rating_count,
    COUNT(*) AS CNT
FROM swiggy_data
GROUP BY 
    State, City, order_date, restaurant_name, location, category,
    dish_name, price_INR, rating, rating_count
HAVING COUNT(*) > 1;
 
--Duplicate Remove

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY State, City, order_date, restaurant_name, location, category,
                            dish_name, price_INR, rating, rating_count
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM swiggy_data
)
DELETE FROM cte WHERE rn > 1;

--CREATING SCHEMA
--DIMENTION TABLES
--DATE TABLE

CREATE TABLE dim_date (
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    Full_Date DATE,
    Year INT,
    Month INT,
    Month_Name VARCHAR(20),
    Quarter INT,
    Day INT,
    Week INT
);

CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);

CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);

CREATE TABLE dim_dish (
    dish_id INT IDENTITY(1,1) PRIMARY KEY,
    Dish_Name VARCHAR(200)
);

CREATE TABLE dim_category(
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category VARCHAR(200)
);
SELECT * FROM dim_category ;

--CREATE FACT TABLE 

CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    Rating_Count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

SELECT * FROM fact_swiggy_orders ;

--INSERT DATA IN TABLES
--dim_date

INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH, Order_Date),
    DATEPART(QUARTER, Order_Date),
    DAY(Order_Date),
    DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

SELECT * FROM dim_date;

--dim_location

INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT
    State,
    City,
    Location
FROM swiggy_data;

SELECT * FROM dim_location;

--dim_restaurant

INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
    Restaurant_Name
FROM swiggy_data;

SELECT * FROM dim_restaurant;

--dim_category

INSERT INTO dim_category (Category)
SELECT DISTINCT
    Category
FROM swiggy_data;

SELECT * FROM dim_category;

--dim_dish

INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
    Dish_Name
FROM swiggy_data;

SELECT * FROM dim_dish;

--FACT_TABLE

INSERT INTO fact_swiggy_orders (
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd 
    ON dd.Full_Date = s.Order_Date

JOIN dim_location dl 
    ON dl.State = s.State
   AND dl.City = s.City
   AND dl.Location = s.Location

JOIN dim_restaurant dr 
    ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc 
    ON dc.Category = s.Category

JOIN dim_dish dsh 
    ON dsh.Dish_Name = s.Dish_Name;

SELECT * FROM fact_swiggy_orders;
 


 SELECT * 
FROM fact_swiggy_orders f

JOIN dim_date d 
    ON f.date_id = d.date_id

JOIN dim_location l 
    ON f.location_id = l.location_id

JOIN dim_restaurant r 
    ON f.restaurant_id = r.restaurant_id

JOIN dim_category c 
    ON f.category_id = c.category_id

JOIN dim_dish di 
    ON f.dish_id = di.dish_id;

--KPIs

-- Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;

-- Total Revenue (INR Million)
SELECT ROUND(SUM(Price_INR) / 1000000.0, 2) AS Total_Revenue_INR_Million
FROM fact_swiggy_orders;

-- Average Dish Price
SELECT ROUND(AVG(Price_INR), 2) AS Avg_Dish_Price_INR
FROM fact_swiggy_orders;

-- Average Rating
SELECT ROUND(AVG(Rating), 2) AS Avg_Rating
FROM fact_swiggy_orders;



--Date-Based Analysis

-- Monthly Order Trends
SELECT 
    d.Year,
    d.Month,
    d.Month_Name,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY d.Year, d.Month;

-- Quarterly Order Trends
SELECT 
    d.Year,
    d.Quarter,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Quarter
ORDER BY d.Year, d.Quarter;

-- Year-Wise Growth
WITH yearly AS (
    SELECT 
        d.Year,
        COUNT(f.order_id) AS Total_Orders,
        ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million
    FROM fact_swiggy_orders f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.Year
)
SELECT 
    Year,
    Total_Orders,
    Revenue_INR_Million,
    LAG(Total_Orders) OVER (ORDER BY Year) AS Prev_Year_Orders,
    ROUND(
        100.0 * (Total_Orders - LAG(Total_Orders) OVER (ORDER BY Year)) 
        / NULLIF(LAG(Total_Orders) OVER (ORDER BY Year), 0), 2
    ) AS Order_Growth_Pct,
    ROUND(
        100.0 * (Revenue_INR_Million - LAG(Revenue_INR_Million) OVER (ORDER BY Year)) 
        / NULLIF(LAG(Revenue_INR_Million) OVER (ORDER BY Year), 0), 2
    ) AS Revenue_Growth_Pct
FROM yearly
ORDER BY Year;

-- Day-of-Week Patterns
SELECT 
    DATENAME(WEEKDAY, d.Full_Date) AS Day_Name,
    DATEPART(WEEKDAY, d.Full_Date) AS Day_Number,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(AVG(f.Price_INR), 2) AS Avg_Order_Value
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.Full_Date), DATEPART(WEEKDAY, d.Full_Date)
ORDER BY Day_Number;


--Location-Based Analysis

-- Top 10 Cities by Order Volume
SELECT TOP 10
    l.City,
    l.State,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City, l.State
ORDER BY Total_Orders DESC;

-- Revenue Contribution by State
SELECT 
    l.State,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million,
    ROUND(
        100.0 * SUM(f.Price_INR) / SUM(SUM(f.Price_INR)) OVER (), 2
    ) AS Revenue_Share_Pct
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.State
ORDER BY Revenue_INR_Million DESC;

--Food Performance

-- Top 10 Restaurants by Orders
SELECT TOP 10
    r.Restaurant_Name,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million,
    ROUND(AVG(f.Rating), 2) AS Avg_Rating
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY Total_Orders DESC;

-- Top Categories by Orders
SELECT 
    c.Category,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million,
    ROUND(AVG(f.Rating), 2) AS Avg_Rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category
ORDER BY Total_Orders DESC;

-- Most Ordered Dishes
SELECT TOP 10
    d.Dish_Name,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(AVG(f.Price_INR), 2) AS Avg_Price,
    ROUND(AVG(f.Rating), 2) AS Avg_Rating
FROM fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.Dish_Name
ORDER BY Total_Orders DESC;

-- Cuisine Performance → Orders + Avg Rating
SELECT 
    c.Category AS Cuisine,
    COUNT(f.order_id) AS Total_Orders,
    ROUND(AVG(f.Rating), 2) AS Avg_Rating,
    ROUND(AVG(f.Price_INR), 2) AS Avg_Price,
    ROUND(SUM(f.Price_INR) / 1000000.0, 2) AS Revenue_INR_Million
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category
ORDER BY Total_Orders DESC;

--Customer Spending Insights

-- Spend Bucket Distribution
SELECT 
    CASE 
        WHEN Price_INR < 100              THEN 'Under 100'
        WHEN Price_INR BETWEEN 100 AND 199 THEN '100–199'
        WHEN Price_INR BETWEEN 200 AND 299 THEN '200–299'
        WHEN Price_INR BETWEEN 300 AND 499 THEN '300–499'
        ELSE '500+'
    END AS Spend_Bucket,
    COUNT(order_id) AS Total_Orders,
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 2) AS Order_Share_Pct,
    ROUND(AVG(Price_INR), 2) AS Avg_Price_In_Bucket
FROM fact_swiggy_orders
GROUP BY 
    CASE 
        WHEN Price_INR < 100              THEN 'Under 100'
        WHEN Price_INR BETWEEN 100 AND 199 THEN '100–199'
        WHEN Price_INR BETWEEN 200 AND 299 THEN '200–299'
        WHEN Price_INR BETWEEN 300 AND 499 THEN '300–499'
        ELSE '500+'
    END
ORDER BY 
    MIN(Price_INR);

--Ratings Analysis

-- Distribution of Dish Ratings (1–5)
SELECT 
    FLOOR(Rating) AS Rating_Band,
    CASE FLOOR(Rating)
        WHEN 1 THEN '1 - Poor'
        WHEN 2 THEN '2 - Below Average'
        WHEN 3 THEN '3 - Average'
        WHEN 4 THEN '4 - Good'
        WHEN 5 THEN '5 - Excellent'
    END AS Rating_Label,
    COUNT(order_id) AS Total_Orders,
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 2) AS Distribution_Pct
FROM fact_swiggy_orders
WHERE Rating BETWEEN 1 AND 5
GROUP BY FLOOR(Rating)
ORDER BY Rating_Band;