-- =============================================================================
-- Module 2: Joins & Relationships -- Exercise Stubs
-- =============================================================================
--
-- Connect to the database:
--   docker compose exec db psql -U learner record_shop
--
-- These exercises combine data from multiple tables. Make sure you understand
-- the schema: artists, albums, genres, sales.
--
-- Solutions: see solutions.sql (try on your own first!)
-- =============================================================================

-- Exercise 1: List all albums with their artist name (INNER JOIN).


-- Exercise 2: List all albums showing artist name and genre name.


-- Exercise 3: Find all artists who have at least one album in the database.
--             (Show each artist once.)


-- Exercise 4: Find all artists who have NO albums in the database (LEFT JOIN).


-- Exercise 5: List all sales showing the album title and artist name.


-- Exercise 6: List every genre and the number of albums in each genre.
--             Include genres that have zero albums.


-- Exercise 7: Find all albums that have never been sold (no matching sales rows).


-- Exercise 8: List all albums along with their genre name.
--             Include albums that have no genre assigned (NULL genre_id).


-- Exercise 9: Using table aliases, write a query that joins albums, artists,
--             and genres to show: album title, artist name, genre name.


-- Exercise 10: (Stretch) Write a self-join or cross-join of your choice to
--              explore the concept. For example: pair every artist with every
--              genre, or find artists from the same country.
