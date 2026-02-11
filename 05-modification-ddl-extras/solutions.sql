-- =============================================================================
-- Module 5: Data Modification, DDL & Extras -- Solutions
-- =============================================================================
--
-- These are reference solutions for the exercises in exercises.sql.
-- Try to solve each exercise on your own before checking here!
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
--
-- WARNING: exercises 1-4 modify data. To reset:
--   docker compose down -v && docker compose up -d
-- =============================================================================


-- Exercise 1: Insert a new album into the albums table.

INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('In Rainbows', 3, 1, 2007, 23.99)
RETURNING id, title;

-- Expected: one new row with an auto-generated id (32) and title 'In Rainbows'
-- The album is by Radiohead (artist_id = 3), genre Rock (genre_id = 1)


-- Exercise 2: Increase the price of all albums in a specific genre by 10%.
-- (Using Jazz, genre_id = 2, as an example)

UPDATE albums
SET price = ROUND(price * 1.10, 2)
WHERE genre_id = 2
RETURNING title, price;

-- Expected: 6 Jazz albums updated with new prices
--  Kind of Blue          | 27.49  (was 24.99)
--  Bitches Brew          | 36.29  (was 32.99)
--  I Put a Spell on You  | 24.19  (was 21.99)
--  Pastel Blues           | 21.99  (was 19.99)
--  A Love Supreme        | 38.49  (was 34.99)
--  Blue Train            | 35.19  (was 31.99)


-- Exercise 3: Delete all albums that have never been sold
--             (hint: LEFT JOIN or NOT EXISTS).

-- First, see what will be deleted:
-- SELECT al.title FROM albums al
-- LEFT JOIN sales s ON al.id = s.album_id
-- WHERE s.id IS NULL;

DELETE FROM albums al
WHERE NOT EXISTS (
    SELECT 1 FROM sales s WHERE s.album_id = al.id
);

-- Expected: 6 rows deleted (Animals, DAMN., Pastel Blues, In Utero,
--           Trans-Europe Express, Currents)
-- Note: if you ran exercise 1 first, the newly inserted album (In Rainbows)
-- will also be deleted if it has no sales


-- Exercise 4: Create a view called "sales_report" that shows
--             album title, artist name, genre, total quantity sold, and revenue.

CREATE VIEW sales_report AS
SELECT
    al.title,
    ar.name   AS artist,
    g.name    AS genre,
    SUM(s.quantity)            AS total_sold,
    SUM(s.quantity * al.price) AS revenue
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
JOIN genres g  ON al.genre_id  = g.id
JOIN sales s   ON al.id        = s.album_id
GROUP BY al.title, ar.name, g.name;

-- Then query it:
-- SELECT * FROM sales_report ORDER BY revenue DESC LIMIT 5;


-- Exercise 5: Write a CREATE TABLE statement for a "customers" table with
--             appropriate columns and constraints.

CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(200) NOT NULL UNIQUE,
    country    VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Note: this creates an empty table. You can verify with: \d customers


-- Exercise 6: Rank all albums by price (highest first) using ROW_NUMBER().

SELECT
    ROW_NUMBER() OVER (ORDER BY price DESC) AS price_rank,
    title,
    price
FROM albums
WHERE price IS NOT NULL
ORDER BY price_rank;

-- Expected: 29 rows (excludes 2 albums with NULL price)
--  1 | A Love Supreme  | 34.99
--  2 | Bitches Brew    | 32.99
--  3 | Blue Train      | 31.99
--  4 | The Wall        | 31.99
--  ...


-- Exercise 7: Rank albums by total sales within each genre
--             using RANK() with PARTITION BY.

WITH album_sales AS (
    SELECT al.title, g.name AS genre, SUM(s.quantity) AS total_sold
    FROM albums al
    JOIN genres g ON al.genre_id = g.id
    JOIN sales s ON al.id = s.album_id
    GROUP BY al.title, g.name
)
SELECT
    genre, title, total_sold,
    RANK() OVER (PARTITION BY genre ORDER BY total_sold DESC) AS genre_rank
FROM album_sales
ORDER BY genre, genre_rank;

-- Expected: 25 rows (only albums with sales, grouped by genre)
-- Rock:       Dark Side (5, rank 1), Nevermind (4, rank 2), Abbey Road (3, rank 3), ...
-- Jazz:       Kind of Blue / A Love Supreme / Blue Train tied (2, rank 1), ...
-- Electronic: Random Access Memories / Discovery tied (2, rank 1), ...


-- Exercise 8: For each sale, show the previous sale's date using LAG().

SELECT
    id,
    sale_date,
    quantity,
    LAG(sale_date) OVER (ORDER BY sale_date, id) AS prev_sale_date
FROM sales
ORDER BY sale_date, id;

-- Expected: 39 rows. First row has NULL prev_sale_date.
--  17 | 2024-01-08 | 1 |            (NULL — first sale)
--   1 | 2024-01-15 | 2 | 2024-01-08
--  36 | 2024-01-22 | 1 | 2024-01-15
--  ...


-- Exercise 9: Calculate a running total of sales quantity, ordered by sale_date.

SELECT
    id,
    sale_date,
    quantity,
    SUM(quantity) OVER (ORDER BY sale_date, id) AS running_total
FROM sales
ORDER BY sale_date, id;

-- Expected: 39 rows. Running total accumulates from 1 up to 50 (total of all quantities).
--  17 | 2024-01-08 | 1 |  1
--   1 | 2024-01-15 | 2 |  3
--  36 | 2024-01-22 | 1 |  4
--  32 | 2024-02-05 | 3 |  7
--  ...


-- Exercise 10: Use UNION to combine a list of all artist names and all genre names
--              into a single result set with one column called "name".

SELECT name FROM artists
UNION
SELECT name FROM genres
ORDER BY name;

-- Expected: 24 rows (16 artists + 8 genres, all unique names)
--  Adele
--  Amy Winehouse
--  Björk
--  ...
--  Rock
--  Soul
--  Tame Impala
--  The Beatles
