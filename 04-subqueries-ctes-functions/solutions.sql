-- =============================================================================
-- Module 4: Subqueries, CTEs & Essential Functions -- Solutions
-- =============================================================================
--
-- These are reference solutions for the exercises in exercises.sql.
-- Try to solve each exercise on your own before checking here!
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
-- =============================================================================


-- Exercise 1: Find all albums priced above the average album price (subquery).

SELECT title, price
FROM albums
WHERE price > (SELECT AVG(price) FROM albums)
ORDER BY price DESC;

-- Expected: 14 rows (avg is 25.61, so all albums priced above that)
--  A Love Supreme  | 34.99
--  Bitches Brew    | 32.99
--  Blue Train      | 31.99
--  The Wall        | 31.99
--  ... down to ...
--  Heroes          | 25.99


-- Exercise 2: Find artists whose total sales revenue exceeds 100
--             (use a CTE to calculate revenue first).

WITH artist_revenue AS (
    SELECT
        ar.name AS artist,
        SUM(s.quantity * al.price) AS revenue
    FROM artists ar
    JOIN albums al ON ar.id = al.artist_id
    JOIN sales s  ON al.id  = s.album_id
    GROUP BY ar.name
)
SELECT artist, revenue
FROM artist_revenue
WHERE revenue > 100
ORDER BY revenue DESC;

-- Expected: 4 rows
--  Pink Floyd     | 269.91
--  The Beatles    | 195.93
--  John Coltrane  | 133.96
--  David Bowie    | 119.95


-- Exercise 3: Categorise each album by era using CASE:
--             'Classic' (pre-1980), 'Modern' (1980-1999), 'Recent' (2000+).

SELECT title, release_year,
    CASE
        WHEN release_year < 1980 THEN 'Classic'
        WHEN release_year < 2000 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM albums
ORDER BY release_year;

-- Expected: 31 rows — 17 Classic, 7 Modern, 7 Recent


-- Exercise 4: Find all albums with 'love' in the title (case-insensitive).

SELECT title
FROM albums
WHERE title ILIKE '%love%';

-- Expected: A Love Supreme (1 row)


-- Exercise 5: List all albums, replacing NULL prices with 'N/A' in the output
--             (hint: COALESCE + CAST).

SELECT title, COALESCE(CAST(price AS TEXT), 'N/A') AS price_display
FROM albums
ORDER BY title;

-- Expected: 31 rows. Currents and DAMN. show 'N/A'; all others show the price.


-- Exercise 6: Find artists who exist in the sales table (use EXISTS).

SELECT ar.name
FROM artists ar
WHERE EXISTS (
    SELECT 1
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    WHERE al.artist_id = ar.id
)
ORDER BY ar.name;

-- Expected: 13 rows (all artists except Adele, Kraftwerk, Tame Impala)


-- Exercise 7: Show each album's title in uppercase and its title length.

SELECT title, UPPER(title) AS upper_title, LENGTH(title) AS title_length
FROM albums
ORDER BY title_length DESC;

-- Expected: 31 rows
--  Sgt. Pepper's Lonely Hearts Club Band | SGT. PEPPER'S... | 37
--  The Rise and Fall of Ziggy Stardust   | THE RISE AND...  | 35
--  The Dark Side of the Moon             | THE DARK SIDE... | 25
--  ...


-- Exercise 8: Using a CTE, find the top-selling genre by total quantity.

WITH genre_sales AS (
    SELECT g.name AS genre, SUM(s.quantity) AS total_qty
    FROM genres g
    JOIN albums al ON g.id = al.genre_id
    JOIN sales s  ON al.id = s.album_id
    GROUP BY g.name
)
SELECT genre, total_qty
FROM genre_sales
ORDER BY total_qty DESC
LIMIT 1;

-- Expected: Rock | 25


-- Exercise 9: Extract the sale year from sale_date and count sales per year.

SELECT
    EXTRACT(YEAR FROM sale_date)::INTEGER AS sale_year,
    COUNT(*) AS num_sales,
    SUM(quantity) AS total_qty
FROM sales
GROUP BY sale_year
ORDER BY sale_year;

-- Expected:
--  2024 | 35 | 46
--  2025 |  4 |  4


-- Exercise 10: Rewrite exercise 1 (albums above average price) as a CTE
--              instead of a subquery.

WITH avg AS (
    SELECT AVG(price) AS avg_price FROM albums
)
SELECT al.title, al.price
FROM albums al
CROSS JOIN avg
WHERE al.price > avg.avg_price
ORDER BY al.price DESC;

-- Expected: same 14 rows as exercise 1
