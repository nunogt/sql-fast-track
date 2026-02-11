-- =============================================================================
-- Module 3: Aggregation & Grouping -- Exercise Stubs
-- =============================================================================
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
--
-- These exercises focus on aggregate functions, GROUP BY, and HAVING.
-- Most queries will combine joins from Module 2 with aggregation.
--
-- Solutions: see solutions.sql (try on your own first!)
-- =============================================================================

-- Exercise 1: Count the total number of albums in the database.


-- Exercise 2: Find the minimum, maximum, and average album price.


-- Exercise 3: Count the number of albums per artist (show artist name and count).


-- Exercise 4: Find the total number of sales (sum of quantity) per album.


-- Exercise 5: Find the total sales revenue per artist
--             (quantity * album price, grouped by artist).


-- Exercise 6: Find the genre with the most albums.


-- Exercise 7: Find artists who have more than 3 albums.


-- Exercise 8: Find the average album price per decade
--             (e.g. 1970s, 1980s -- hint: integer division or date_trunc).


-- Exercise 9: List genres where the average album price is above 25.00.


-- Exercise 10: Find the top 3 best-selling albums by total quantity sold.
