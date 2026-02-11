-- =============================================================================
-- Module 5: Data Modification, DDL & Extras -- Exercise Stubs
-- =============================================================================
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
--
-- These exercises involve writing data, defining tables, and window functions.
-- WARNING: exercises 1-4 modify data. If you want to reset, run:
--   docker compose down -v && docker compose up -d
--
-- Solutions: see solutions.sql (try on your own first!)
-- =============================================================================

-- Exercise 1: Insert a new album into the albums table.


-- Exercise 2: Increase the price of all albums in a specific genre by 10%.


-- Exercise 3: Delete all albums that have never been sold
--             (hint: LEFT JOIN or NOT EXISTS).


-- Exercise 4: Create a view called "sales_report" that shows
--             album title, artist name, genre, total quantity sold, and revenue.


-- Exercise 5: Write a CREATE TABLE statement for a "customers" table with
--             appropriate columns and constraints.


-- Exercise 6: Rank all albums by price (highest first) using ROW_NUMBER().


-- Exercise 7: Rank albums by total sales within each genre
--             using RANK() with PARTITION BY.


-- Exercise 8: For each sale, show the previous sale's date using LAG().


-- Exercise 9: Calculate a running total of sales quantity, ordered by sale_date.


-- Exercise 10: Use UNION to combine a list of all artist names and all genre names
--              into a single result set with one column called "name".
