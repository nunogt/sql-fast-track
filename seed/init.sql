-- =============================================================================
-- Record Shop -- seed schema & sample data
-- =============================================================================
-- This file is mounted into the PostgreSQL container and runs automatically
-- on first `docker compose up`.
--
-- Schema: 4 tables for a fictional vinyl record shop.
--
-- To reset the database from scratch:
--   docker compose down -v && docker compose up -d
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. genres
-- ---------------------------------------------------------------------------
CREATE TABLE genres (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------------
-- 2. artists
-- ---------------------------------------------------------------------------
CREATE TABLE artists (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    country VARCHAR(50)              -- NULL = unknown / not yet entered
);

-- ---------------------------------------------------------------------------
-- 3. albums
-- ---------------------------------------------------------------------------
CREATE TABLE albums (
    id           SERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    artist_id    INTEGER NOT NULL REFERENCES artists (id),
    genre_id     INTEGER REFERENCES genres (id),
    release_year INTEGER,
    price        NUMERIC(6,2)         -- NULL = price not yet set
);

-- ---------------------------------------------------------------------------
-- 4. sales
-- ---------------------------------------------------------------------------
CREATE TABLE sales (
    id        SERIAL PRIMARY KEY,
    album_id  INTEGER NOT NULL REFERENCES albums (id),
    quantity  INTEGER NOT NULL DEFAULT 1,
    sale_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- =============================================================================
-- Sample data
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Genres (8 rows)
-- ---------------------------------------------------------------------------
INSERT INTO genres (name) VALUES
    ('Rock'),          -- 1
    ('Jazz'),          -- 2
    ('Hip-Hop'),       -- 3
    ('Electronic'),    -- 4
    ('Pop'),           -- 5
    ('Soul'),          -- 6
    ('Classical'),     -- 7
    ('Reggae');        -- 8

-- ---------------------------------------------------------------------------
-- Artists (16 rows — one with NULL country, one with no albums)
-- ---------------------------------------------------------------------------
INSERT INTO artists (name, country) VALUES
    ('Pink Floyd',      'UK'),       -- 1
    ('Miles Davis',     'US'),       -- 2
    ('Radiohead',       'UK'),       -- 3
    ('Kendrick Lamar',  'US'),       -- 4
    ('Daft Punk',       'France'),   -- 5
    ('David Bowie',     'UK'),       -- 6
    ('Nina Simone',     'US'),       -- 7
    ('Bob Marley',      'Jamaica'),  -- 8
    ('Björk',           'Iceland'),  -- 9
    ('The Beatles',     'UK'),       -- 10
    ('Nirvana',         'US'),       -- 11
    ('Amy Winehouse',   'UK'),       -- 12
    ('Kraftwerk',       'Germany'),  -- 13
    ('John Coltrane',   'US'),       -- 14
    ('Tame Impala',     NULL),       -- 15  (country unknown)
    ('Adele',           'UK');       -- 16  (no albums in the shop yet)

-- ---------------------------------------------------------------------------
-- Albums (31 rows — 2 with NULL price, spread across decades and genres)
-- ---------------------------------------------------------------------------
INSERT INTO albums (title, artist_id, genre_id, release_year, price) VALUES
    -- Pink Floyd (4 albums → used in HAVING exercises)
    ('The Dark Side of the Moon',             1, 1, 1973, 29.99),   -- 1
    ('Wish You Were Here',                    1, 1, 1975, 27.99),   -- 2
    ('The Wall',                              1, 1, 1979, 31.99),   -- 3
    ('Animals',                               1, 1, 1977, 26.99),   -- 4

    -- Miles Davis
    ('Kind of Blue',                          2, 2, 1959, 24.99),   -- 5
    ('Bitches Brew',                          2, 2, 1970, 32.99),   -- 6

    -- Radiohead
    ('OK Computer',                           3, 1, 1997, 22.99),   -- 7
    ('Kid A',                                 3, 4, 2000, 21.99),   -- 8

    -- Kendrick Lamar (one album has NULL price)
    ('To Pimp a Butterfly',                   4, 3, 2015, 23.99),   -- 9
    ('DAMN.',                                 4, 3, 2017, NULL),    -- 10

    -- Daft Punk
    ('Discovery',                             5, 4, 2001, 18.99),   -- 11
    ('Random Access Memories',                5, 4, 2013, 24.99),   -- 12

    -- David Bowie
    ('The Rise and Fall of Ziggy Stardust',   6, 1, 1972, 28.99),   -- 13
    ('Heroes',                                6, 1, 1977, 25.99),   -- 14
    ('Let''s Dance',                          6, 5, 1983, 17.99),   -- 15

    -- Nina Simone
    ('I Put a Spell on You',                  7, 2, 1965, 21.99),   -- 16
    ('Pastel Blues',                           7, 2, 1965, 19.99),   -- 17

    -- Bob Marley
    ('Legend',                                 8, 8, 1984, 22.99),   -- 18

    -- Björk
    ('Homogenic',                             9, 4, 1997, 23.99),   -- 19
    ('Post',                                  9, 5, 1995, 19.99),   -- 20

    -- The Beatles (4 albums → used in HAVING exercises)
    ('Abbey Road',                           10, 1, 1969, 27.99),   -- 21
    ('Sgt. Pepper''s Lonely Hearts Club Band', 10, 1, 1967, 29.99), -- 22
    ('Revolver',                             10, 1, 1966, 26.99),   -- 23
    ('Let It Be',                            10, 1, 1970, 24.99),   -- 24

    -- Nirvana
    ('Nevermind',                            11, 1, 1991, 19.99),   -- 25
    ('In Utero',                             11, 1, 1993, 18.99),   -- 26

    -- Amy Winehouse
    ('Back to Black',                        12, 6, 2006, 26.99),   -- 27

    -- Kraftwerk
    ('Trans-Europe Express',                 13, 4, 1977, 29.99),   -- 28

    -- John Coltrane ('love' in title → used in ILIKE exercises)
    ('A Love Supreme',                       14, 2, 1965, 34.99),   -- 29
    ('Blue Train',                           14, 2, 1958, 31.99),   -- 30

    -- Tame Impala (NULL genre and price — recently added, incomplete data)
    ('Currents',                             15, NULL, 2015, NULL); -- 31

-- ---------------------------------------------------------------------------
-- Sales (38 rows — some albums have zero sales; dates span 2024-2025)
-- ---------------------------------------------------------------------------
INSERT INTO sales (album_id, quantity, sale_date) VALUES
    -- Pink Floyd
    (1,  2, '2024-01-15'),   -- Dark Side of the Moon
    (1,  3, '2024-07-20'),   -- Dark Side of the Moon
    (2,  1, '2024-03-10'),   -- Wish You Were Here
    (2,  1, '2024-09-05'),   -- Wish You Were Here
    (3,  1, '2024-02-28'),   -- The Wall
    (3,  1, '2024-11-12'),   -- The Wall

    -- Miles Davis
    (5,  1, '2024-04-03'),   -- Kind of Blue
    (5,  1, '2025-01-18'),   -- Kind of Blue
    (6,  1, '2024-06-22'),   -- Bitches Brew

    -- Radiohead
    (7,  2, '2024-05-14'),   -- OK Computer
    (8,  1, '2024-08-30'),   -- Kid A

    -- Kendrick Lamar
    (9,  1, '2024-03-25'),   -- To Pimp a Butterfly
    (9,  1, '2025-01-05'),   -- To Pimp a Butterfly

    -- Daft Punk
    (11, 2, '2024-04-18'),   -- Discovery
    (12, 1, '2024-10-31'),   -- Random Access Memories
    (12, 1, '2025-02-14'),   -- Random Access Memories

    -- David Bowie
    (13, 1, '2024-01-08'),   -- Ziggy Stardust
    (13, 1, '2024-06-15'),   -- Ziggy Stardust
    (14, 1, '2024-09-22'),   -- Heroes
    (15, 2, '2024-12-25'),   -- Let's Dance

    -- Nina Simone
    (16, 1, '2024-02-14'),   -- I Put a Spell on You

    -- Bob Marley
    (18, 2, '2024-07-04'),   -- Legend
    (18, 1, '2025-01-30'),   -- Legend

    -- Björk
    (19, 1, '2024-05-20'),   -- Homogenic
    (20, 1, '2024-11-08'),   -- Post

    -- The Beatles
    (21, 2, '2024-03-17'),   -- Abbey Road
    (21, 1, '2024-08-09'),   -- Abbey Road
    (22, 1, '2024-04-25'),   -- Sgt. Pepper's
    (22, 1, '2024-10-10'),   -- Sgt. Pepper's
    (23, 1, '2024-06-30'),   -- Revolver
    (24, 1, '2024-12-01'),   -- Let It Be

    -- Nirvana
    (25, 3, '2024-02-05'),   -- Nevermind
    (25, 1, '2024-09-15'),   -- Nevermind

    -- Amy Winehouse
    (27, 2, '2024-05-01'),   -- Back to Black
    (27, 1, '2024-10-20'),   -- Back to Black

    -- John Coltrane
    (29, 1, '2024-01-22'),   -- A Love Supreme
    (29, 1, '2024-07-14'),   -- A Love Supreme
    (30, 1, '2024-04-08'),   -- Blue Train
    (30, 1, '2024-11-28');   -- Blue Train

-- =============================================================================
-- Albums with NO sales: Animals (4), DAMN. (10), Pastel Blues (17),
--                       In Utero (26), Trans-Europe Express (28), Currents (31)
--
-- Artists with NO albums: Adele (16)
--
-- Albums with NULL price: DAMN. (10), Currents (31)
-- =============================================================================
