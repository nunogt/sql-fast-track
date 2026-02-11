-- =============================================================================
-- Module 1: Foundations -- Solutions
-- =============================================================================
--
-- These are reference solutions for the exercises in exercises.sql.
-- Try to solve each exercise on your own before checking here!
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
-- =============================================================================


-- Exercise 1: List all columns and rows from the albums table.

SELECT *
FROM albums;

-- Returns 31 rows with columns: id, title, artist_id, genre_id, release_year, price


-- Exercise 2: List only the title and release_year of every album.

SELECT title, release_year
FROM albums;

-- Returns 31 rows with just two columns


-- Exercise 3: Find all albums released in the year 1977.

SELECT title, release_year
FROM albums
WHERE release_year = 1977;

-- Expected: Animals, Heroes, Trans-Europe Express (3 rows)


-- Exercise 4: Find all albums with a price less than 20.00.

SELECT title, price
FROM albums
WHERE price < 20.00;

-- Expected: Let's Dance (17.99), Discovery (18.99), In Utero (18.99),
--           Pastel Blues (19.99), Post (19.99), Nevermind (19.99)
-- Note: Albums with NULL price do NOT appear (NULL < 20 is NULL, not TRUE)


-- Exercise 5: Find all albums released between 1980 and 1989 (inclusive).

SELECT title, release_year
FROM albums
WHERE release_year BETWEEN 1980 AND 1989;

-- Expected: Let's Dance (1983), Legend (1984) — 2 rows


-- Exercise 6: Find all artists whose country is 'US' or 'UK'.

SELECT name, country
FROM artists
WHERE country IN ('US', 'UK');

-- Expected: Pink Floyd, Miles Davis, Radiohead, Kendrick Lamar, David Bowie,
--           Nina Simone, The Beatles, Nirvana, Amy Winehouse, John Coltrane,
--           Adele — 11 rows


-- Exercise 7: Find all albums where the price is NULL (not yet set).

SELECT title, price
FROM albums
WHERE price IS NULL;

-- Expected: DAMN., Currents — 2 rows


-- Exercise 8: List all albums sorted by release_year descending,
--             then by title ascending.

SELECT title, release_year
FROM albums
ORDER BY release_year DESC, title ASC;

-- First rows: Currents (2015), DAMN. (2017), To Pimp a Butterfly (2015), ...
-- Within the same year, titles are sorted alphabetically


-- Exercise 9: List the first 5 albums sorted by price ascending (cheapest first).

SELECT title, price
FROM albums
WHERE price IS NOT NULL
ORDER BY price ASC
LIMIT 5;

-- Expected (top two are fixed; the three 19.99 albums tie, so only 2 fit):
--  Let's Dance    | 17.99
--  Discovery      | 18.99
--  In Utero       | 18.99
--  (two of: Nevermind / Pastel Blues / Post, all at 19.99)
-- Note: We exclude NULL prices with WHERE so they don't appear


-- Exercise 10: List all distinct release years that appear in the albums table, sorted.

SELECT DISTINCT release_year
FROM albums
ORDER BY release_year;

-- Expected: 1958, 1959, 1965, 1966, 1967, 1969, 1970, 1972, 1973, 1975,
--           1977, 1979, 1983, 1984, 1991, 1993, 1995, 1997, 2000, 2001,
--           2006, 2013, 2015, 2017 — 24 distinct years
