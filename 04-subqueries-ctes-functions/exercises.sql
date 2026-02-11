-- =============================================================================
-- Module 4: Subqueries, CTEs & Essential Functions -- Exercise Stubs
-- =============================================================================
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
--
-- These exercises use subqueries, CTEs, CASE, and built-in functions.
--
-- Solutions: see solutions.sql (try on your own first!)
-- =============================================================================

-- Exercise 1: Find all albums priced above the average album price (subquery).


-- Exercise 2: Find artists whose total sales revenue exceeds 100
--             (use a CTE to calculate revenue first).


-- Exercise 3: Categorise each album by era using CASE:
--             'Classic' (pre-1980), 'Modern' (1980-1999), 'Recent' (2000+).


-- Exercise 4: Find all albums with 'love' in the title (case-insensitive).


-- Exercise 5: List all albums, replacing NULL prices with 'N/A' in the output
--             (hint: COALESCE + CAST).


-- Exercise 6: Find artists who exist in the sales table (use EXISTS).


-- Exercise 7: Show each album's title in uppercase and its title length.


-- Exercise 8: Using a CTE, find the top-selling genre by total quantity.


-- Exercise 9: Extract the sale year from sale_date and count sales per year.


-- Exercise 10: Rewrite exercise 1 (albums above average price) as a CTE
--              instead of a subquery.
