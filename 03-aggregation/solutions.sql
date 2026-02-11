-- =============================================================================
-- Module 3: Aggregation & Grouping -- Solutions
-- =============================================================================
--
-- These are reference solutions for the exercises in exercises.sql.
-- Try to solve each exercise on your own before checking here!
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
-- =============================================================================


-- Exercise 1: Count the total number of albums in the database.

SELECT COUNT(*) AS total_albums
FROM albums;

-- Expected: 31


-- Exercise 2: Find the minimum, maximum, and average album price.

SELECT
    MIN(price)            AS min_price,
    MAX(price)            AS max_price,
    ROUND(AVG(price), 2)  AS avg_price
FROM albums;

-- Expected: min = 17.99, max = 34.99, avg = 25.61
-- Note: AVG skips the 2 albums with NULL price (calculates over 29 values)


-- Exercise 3: Count the number of albums per artist (show artist name and count).

SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name
ORDER BY album_count DESC, ar.name;

-- Expected: 15 rows (all artists with at least one album)
--  Pink Floyd     | 4
--  The Beatles    | 4
--  David Bowie    | 3
--  Björk          | 2
--  ... (11 more with 1-2 albums)


-- Exercise 4: Find the total number of sales (sum of quantity) per album.

SELECT al.title, SUM(s.quantity) AS total_sold
FROM albums al
JOIN sales s ON al.id = s.album_id
GROUP BY al.title
ORDER BY total_sold DESC;

-- Expected: 25 rows (only albums that have sales)
--  The Dark Side of the Moon             | 5
--  Nevermind                             | 4
--  Abbey Road                            | 3
--  Back to Black                         | 3
--  Legend                                | 3
--  ...


-- Exercise 5: Find the total sales revenue per artist
--             (quantity * album price, grouped by artist).

SELECT
    ar.name AS artist,
    SUM(s.quantity * al.price) AS revenue
FROM artists ar
JOIN albums al ON ar.id = al.artist_id
JOIN sales s  ON al.id  = s.album_id
GROUP BY ar.name
ORDER BY revenue DESC;

-- Expected: 13 rows
--  Pink Floyd     | 269.91
--  The Beatles    | 195.93
--  John Coltrane  | 133.96
--  David Bowie    | 119.95
--  Daft Punk      |  87.96
--  Miles Davis    |  82.97
--  Amy Winehouse  |  80.97
--  Nirvana        |  79.96
--  Bob Marley     |  68.97
--  Radiohead      |  67.97
--  Kendrick Lamar |  47.98
--  Björk          |  43.98
--  Nina Simone    |  21.99
-- Note: Adele, Kraftwerk, Tame Impala have no sales and don't appear


-- Exercise 6: Find the genre with the most albums.

SELECT g.name AS genre, COUNT(*) AS album_count
FROM genres g
JOIN albums al ON g.id = al.genre_id
GROUP BY g.name
ORDER BY album_count DESC
LIMIT 1;

-- Expected: Rock | 13


-- Exercise 7: Find artists who have more than 3 albums.

SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name
HAVING COUNT(*) > 3
ORDER BY album_count DESC;

-- Expected: Pink Floyd (4), The Beatles (4) — 2 rows


-- Exercise 8: Find the average album price per decade
--             (e.g. 1970s, 1980s -- hint: integer division).

SELECT
    (release_year / 10) * 10 AS decade,
    ROUND(AVG(price), 2)     AS avg_price
FROM albums
WHERE price IS NOT NULL
GROUP BY (release_year / 10) * 10
ORDER BY decade;

-- Expected:
--  1950 | 28.49
--  1960 | 26.99
--  1970 | 28.88
--  1980 | 20.49
--  1990 | 21.19
--  2000 | 22.66
--  2010 | 24.49


-- Exercise 9: List genres where the average album price is above 25.00.

SELECT g.name AS genre, ROUND(AVG(al.price), 2) AS avg_price
FROM genres g
JOIN albums al ON g.id = al.genre_id
WHERE al.price IS NOT NULL
GROUP BY g.name
HAVING AVG(al.price) > 25.00
ORDER BY avg_price DESC;

-- Expected: Jazz (27.82), Soul (26.99), Rock (26.45) — 3 rows


-- Exercise 10: Find the top 3 best-selling albums by total quantity sold.

SELECT al.title, SUM(s.quantity) AS total_sold
FROM albums al
JOIN sales s ON al.id = s.album_id
GROUP BY al.title
ORDER BY total_sold DESC
LIMIT 3;

-- Expected:
--  The Dark Side of the Moon | 5
--  Nevermind                 | 4
--  (one of: Abbey Road / Back to Black / Legend, all tied at 3)
