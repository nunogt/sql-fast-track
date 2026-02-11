-- =============================================================================
-- Module 2: Joins & Relationships -- Solutions
-- =============================================================================
--
-- These are reference solutions for the exercises in exercises.sql.
-- Try to solve each exercise on your own before checking here!
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
-- =============================================================================


-- Exercise 1: List all albums with their artist name (INNER JOIN).

SELECT al.title, ar.name AS artist
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id
ORDER BY al.title;

-- Returns 31 rows (every album has an artist_id, so INNER JOIN matches all)


-- Exercise 2: List all albums showing artist name and genre name.

SELECT al.title, ar.name AS artist, g.name AS genre
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id
INNER JOIN genres g   ON al.genre_id  = g.id
ORDER BY al.title;

-- Returns 30 rows (Currents has NULL genre_id, so it's excluded by the INNER JOIN to genres)


-- Exercise 3: Find all artists who have at least one album in the database.
--             (Show each artist once.)

SELECT DISTINCT ar.name
FROM artists ar
INNER JOIN albums al ON ar.id = al.artist_id
ORDER BY ar.name;

-- Returns 15 rows (all artists except Adele, who has no albums)


-- Exercise 4: Find all artists who have NO albums in the database (LEFT JOIN).

SELECT ar.name
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
WHERE al.id IS NULL;

-- Expected: Adele (1 row)


-- Exercise 5: List all sales showing the album title and artist name.

SELECT s.id AS sale_id, al.title, ar.name AS artist, s.quantity, s.sale_date
FROM sales s
INNER JOIN albums al ON s.album_id = al.id
INNER JOIN artists ar ON al.artist_id = ar.id
ORDER BY s.sale_date;

-- Returns 39 rows (every sale has a valid album_id)


-- Exercise 6: List every genre and the number of albums in each genre.
--             Include genres that have zero albums.

SELECT g.name AS genre, COUNT(al.id) AS album_count
FROM genres g
LEFT JOIN albums al ON g.id = al.genre_id
GROUP BY g.name
ORDER BY album_count DESC, g.name;

-- Expected:
--  Rock        | 13
--  Jazz        |  6
--  Electronic  |  5
--  Hip-Hop     |  2
--  Pop         |  2
--  Reggae      |  1
--  Soul        |  1
--  Classical   |  0    ← LEFT JOIN keeps this even with zero albums
-- Note: Currents has NULL genre_id, so it doesn't count toward any genre


-- Exercise 7: Find all albums that have never been sold (no matching sales rows).

SELECT al.title
FROM albums al
LEFT JOIN sales s ON al.id = s.album_id
WHERE s.id IS NULL
ORDER BY al.title;

-- Expected: Animals, Currents, DAMN., In Utero, Pastel Blues, Trans-Europe Express (6 rows)


-- Exercise 8: List all albums along with their genre name.
--             Include albums that have no genre assigned (NULL genre_id).

SELECT al.title, g.name AS genre
FROM albums al
LEFT JOIN genres g ON al.genre_id = g.id
ORDER BY al.title;

-- Returns 31 rows — Currents appears with NULL genre (all others have a genre)


-- Exercise 9: Using table aliases, write a query that joins albums, artists,
--             and genres to show: album title, artist name, genre name.

SELECT al.title, ar.name AS artist, g.name AS genre
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
LEFT JOIN genres g ON al.genre_id = g.id
ORDER BY ar.name, al.title;

-- Returns 31 rows (LEFT JOIN on genres keeps Currents with NULL genre)
-- Note: using LEFT JOIN for genres so albums with no genre still appear


-- Exercise 10: (Stretch) Write a self-join or cross-join of your choice.
--              Example: find artists from the same country.

-- Option A: Self-join — pairs of artists from the same country
SELECT a1.name AS artist_1, a2.name AS artist_2, a1.country
FROM artists a1
JOIN artists a2
    ON  a1.country = a2.country
    AND a1.id < a2.id
ORDER BY a1.country, a1.name;

-- Returns pairs like (Miles Davis, Kendrick Lamar, US), (Pink Floyd, Radiohead, UK), etc.
-- The a1.id < a2.id condition avoids duplicates and self-pairs.

-- Option B: Cross-join — every artist paired with every genre
-- SELECT ar.name, g.name AS genre
-- FROM artists ar
-- CROSS JOIN genres g
-- ORDER BY ar.name, g.name;
-- Returns 128 rows (16 artists × 8 genres)
