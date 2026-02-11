# SQL Cheat Sheet

A condensed reference covering the most important SQL concepts. All examples use the Record Shop database.

---

## Query execution order

The logical order in which SQL processes a query (not the order you write it):

```
1. FROM / JOIN       ← pick tables, combine rows
2. WHERE             ← filter individual rows
3. GROUP BY          ← form groups
4. HAVING            ← filter groups
5. SELECT            ← compute columns, aliases, window functions
6. DISTINCT          ← remove duplicate rows
7. ORDER BY          ← sort results
8. LIMIT / OFFSET    ← restrict output
```

**Why it matters:** You can't use a `SELECT` alias in `WHERE` (step 2 runs before step 5), but you **can** use it in `ORDER BY` (step 7 runs after step 5).

```sql
-- Works: alias in ORDER BY
SELECT price * 0.9 AS discounted FROM albums ORDER BY discounted;

-- Fails: alias in WHERE
SELECT price * 0.9 AS discounted FROM albums WHERE discounted < 20;
-- ERROR: column "discounted" does not exist
```

---

## SELECT basics

```sql
SELECT *                          FROM albums;                -- all columns
SELECT title, price               FROM albums;                -- specific columns
SELECT title AS album_title       FROM albums;                -- alias
SELECT DISTINCT country           FROM artists;               -- unique values
SELECT title FROM albums          WHERE price > 25;           -- filter
SELECT title FROM albums          ORDER BY price DESC;        -- sort
SELECT title FROM albums          LIMIT 5 OFFSET 10;          -- paginate
```

## WHERE operators

```sql
WHERE price = 29.99                       -- equal
WHERE price <> 29.99                      -- not equal (also !=)
WHERE price > 25 AND release_year < 1980  -- logical AND
WHERE genre_id = 1 OR genre_id = 2       -- logical OR
WHERE country IN ('US', 'UK', 'France')   -- match list
WHERE release_year BETWEEN 1970 AND 1979  -- inclusive range
WHERE price IS NULL                       -- test for NULL
WHERE price IS NOT NULL                   -- test for non-NULL
WHERE title LIKE 'The %'                  -- pattern (case-sensitive)
WHERE title ILIKE '%love%'                -- pattern (case-insensitive)
```

---

## Join types

```
Table A         Table B          Result rows
─────────       ─────────        ────────────────────────────────────

INNER JOIN      Matching rows only          A ∩ B
                                            (rows with a match in BOTH tables)

LEFT JOIN       All of A + matches from B   All A, NULLs where B has no match
RIGHT JOIN      All of B + matches from A   All B, NULLs where A has no match
FULL OUTER JOIN All of A + all of B         NULLs on both sides where no match
CROSS JOIN      Every A row × every B row   Cartesian product (no ON clause)
Self-join       Table joined to itself      Uses aliases to distinguish copies
```

```sql
-- INNER JOIN: albums with artist names (only matching rows)
SELECT al.title, ar.name
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id;

-- LEFT JOIN: all artists, even those with no albums
SELECT ar.name, al.title
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id;

-- LEFT JOIN + IS NULL: find unmatched rows
SELECT ar.name FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
WHERE al.id IS NULL;                      -- artists with no albums

-- Multi-table join
SELECT al.title, ar.name, g.name AS genre
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
JOIN genres g  ON al.genre_id  = g.id;

-- Self-join: artists from the same country
SELECT a1.name, a2.name, a1.country
FROM artists a1
JOIN artists a2 ON a1.country = a2.country AND a1.id < a2.id;
```

---

## Aggregation

```sql
COUNT(*)                -- count all rows (including NULLs)
COUNT(price)            -- count non-NULL values
COUNT(DISTINCT genre_id)-- count unique non-NULL values
SUM(quantity)           -- total
AVG(price)              -- mean (skips NULLs)
MIN(price)              -- smallest
MAX(price)              -- largest
```

### GROUP BY + HAVING

```sql
SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name                    -- one row per artist
HAVING COUNT(*) > 3                 -- filter: only artists with 4+ albums
ORDER BY album_count DESC;
```

**Rule:** Every column in `SELECT` must be in `GROUP BY` or inside an aggregate.

**WHERE vs HAVING:** `WHERE` filters rows *before* grouping. `HAVING` filters groups *after* aggregation. You cannot put aggregates in `WHERE`.

---

## Subqueries and CTEs

```sql
-- Scalar subquery (returns one value)
SELECT title FROM albums
WHERE price > (SELECT AVG(price) FROM albums);

-- List subquery (returns a set)
SELECT title FROM albums
WHERE artist_id IN (SELECT id FROM artists WHERE country = 'UK');

-- EXISTS (correlated — references outer query)
SELECT ar.name FROM artists ar
WHERE EXISTS (
    SELECT 1 FROM sales s
    JOIN albums al ON s.album_id = al.id
    WHERE al.artist_id = ar.id
);

-- CTE (Common Table Expression)
WITH album_counts AS (
    SELECT artist_id, COUNT(*) AS cnt
    FROM albums GROUP BY artist_id
)
SELECT ar.name, ac.cnt
FROM artists ar JOIN album_counts ac ON ar.id = ac.artist_id;
```

---

## Essential functions

### CASE

```sql
SELECT title,
    CASE
        WHEN release_year < 1980 THEN 'Classic'
        WHEN release_year < 2000 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM albums;
```

### COALESCE

```sql
COALESCE(price, 0)                  -- first non-NULL: returns price, or 0 if NULL
COALESCE(CAST(price AS TEXT), 'N/A')-- display 'N/A' for missing prices
```

### String functions

```sql
UPPER('hello')                      -- 'HELLO'
LOWER('Hello')                      -- 'hello'
LENGTH('hello')                     -- 5
TRIM('  hi  ')                      -- 'hi'
SUBSTRING('hello' FROM 2 FOR 3)    -- 'ell'
CONCAT('a', NULL, 'b')             -- 'ab'   (NULL-safe)
'a' || NULL || 'b'                 -- NULL   (NULL propagates)
```

### Date functions

```sql
EXTRACT(YEAR FROM sale_date)        -- 2024
date_trunc('month', sale_date)      -- 2024-03-01
CURRENT_DATE                        -- today's date
NOW()                               -- current timestamp
AGE(sale_date)                      -- interval since that date
```

---

## Window functions

Window functions compute values across rows **without collapsing** them (unlike GROUP BY).

```sql
function() OVER (
    [PARTITION BY col]    -- optional: reset per group
    ORDER BY col          -- row ordering
)
```

### Ranking

```sql
-- For values 5, 3, 3, 1:
ROW_NUMBER()  -- 1, 2, 3, 4  (unique, ties broken arbitrarily)
RANK()        -- 1, 2, 2, 4  (same rank for ties, gap after)
DENSE_RANK()  -- 1, 2, 2, 3  (same rank for ties, no gap)
```

```sql
-- Rank albums by price
SELECT title, price,
    RANK() OVER (ORDER BY price DESC) AS price_rank
FROM albums WHERE price IS NOT NULL;

-- Top 2 most expensive albums per genre
SELECT * FROM (
    SELECT g.name AS genre, al.title, al.price,
        ROW_NUMBER() OVER (PARTITION BY g.name ORDER BY al.price DESC) AS rn
    FROM albums al JOIN genres g ON al.genre_id = g.id
    WHERE al.price IS NOT NULL
) ranked WHERE rn <= 2;
```

### LAG / LEAD

```sql
-- Previous and next sale dates
SELECT sale_date,
    LAG(sale_date)  OVER (ORDER BY sale_date) AS prev_date,
    LEAD(sale_date) OVER (ORDER BY sale_date) AS next_date
FROM sales;
```

### Running totals

```sql
SELECT sale_date, quantity,
    SUM(quantity) OVER (ORDER BY sale_date, id) AS running_total
FROM sales;
```

---

## Data modification

```sql
-- INSERT
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('Album Name', 1, 1, 2024, 19.99);

-- Multi-row INSERT
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('A', 1, 1, 2024, 19.99), ('B', 1, 1, 2024, 21.99);

-- INSERT ... RETURNING
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('New Album', 1, 1, 2024, 19.99)
RETURNING id, title;

-- UPDATE (always use WHERE unless you mean to update all rows)
UPDATE albums SET price = ROUND(price * 1.10, 2) WHERE genre_id = 2;

-- DELETE (always use WHERE unless you mean to delete all rows)
DELETE FROM albums WHERE id = 31;

-- DELETE with subquery
DELETE FROM albums
WHERE NOT EXISTS (SELECT 1 FROM sales s WHERE s.album_id = albums.id);
```

---

## DDL (Data Definition)

```sql
CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,                    -- auto-increment, unique, not null
    name       VARCHAR(100) NOT NULL,                 -- required
    email      VARCHAR(200) NOT NULL UNIQUE,           -- required + unique
    country    VARCHAR(50),                            -- optional (nullable)
    balance    NUMERIC(8,2) CHECK (balance >= 0),     -- must be non-negative
    artist_id  INTEGER REFERENCES artists (id),       -- foreign key
    created_at TIMESTAMP NOT NULL DEFAULT NOW()        -- auto-set on insert
);

CREATE VIEW view_name AS SELECT ...;                  -- saved query
CREATE OR REPLACE VIEW view_name AS SELECT ...;       -- update a view
DROP VIEW IF EXISTS view_name;                        -- remove a view
DROP TABLE IF EXISTS table_name;                      -- remove a table
```

---

## Transactions

```sql
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;       -- make permanent

-- or if something goes wrong:
ROLLBACK;     -- discard all changes since BEGIN
```

---

## Set operations

```sql
SELECT name FROM artists UNION     SELECT name FROM genres;  -- combine, deduplicate
SELECT name FROM artists UNION ALL SELECT name FROM genres;  -- combine, keep dupes
SELECT a FROM t1 INTERSECT SELECT a FROM t2;                 -- rows in BOTH
SELECT a FROM t1 EXCEPT    SELECT a FROM t2;                 -- rows in t1 but NOT t2
```

Both queries must have the same number of columns with compatible types.

---

## NULL gotchas

| Trap | Why | Fix |
|------|-----|-----|
| `WHERE x = NULL` | Returns no rows. `NULL = NULL` → `NULL`, not `TRUE`. | `WHERE x IS NULL` |
| `COUNT(col)` | Skips NULLs. | Use `COUNT(*)` to count all rows. |
| `AVG(col)` | Skips NULLs (divides by non-NULL count only). | Use `COALESCE(col, 0)` if you want NULLs treated as zero. |
| `NOT IN (…, NULL)` | Always returns empty. `x <> NULL` → `NULL` → entire `NOT IN` fails. | Use `NOT EXISTS` instead. |
| `ORDER BY col` | NULLs sort last (ASC) or first (DESC). | Add `NULLS FIRST` or `NULLS LAST`. |
| `'a' \|\| NULL` | Result is `NULL`. The `\|\|` operator propagates NULL. | Use `CONCAT('a', NULL)` → `'a'`. |

```sql
-- NOT IN trap: returns 0 rows because NULL poisons the check
SELECT 'match' WHERE 1 NOT IN (2, 3, NULL);    -- (0 rows)

-- Safe alternative: NOT EXISTS
SELECT ar.name FROM artists ar
WHERE NOT EXISTS (SELECT 1 FROM albums al WHERE al.artist_id = ar.id);
```

---

## Top 10 patterns

### 1. Find duplicates

```sql
SELECT release_year, COUNT(*) AS n
FROM albums GROUP BY release_year HAVING COUNT(*) > 2;
```

### 2. Nth highest value

```sql
-- 2nd most expensive album
SELECT title, price FROM albums
WHERE price IS NOT NULL
ORDER BY price DESC LIMIT 1 OFFSET 1;
```

### 3. Running total

```sql
SELECT sale_date, quantity,
    SUM(quantity) OVER (ORDER BY sale_date, id) AS running_total
FROM sales;
```

### 4. Gaps in sequences

```sql
SELECT sale_date, prev_date, sale_date - prev_date AS gap_days FROM (
    SELECT sale_date, LAG(sale_date) OVER (ORDER BY sale_date) AS prev_date
    FROM sales
) sub WHERE sale_date - prev_date > 14;
```

### 5. Top-N per group

```sql
SELECT genre, title, price FROM (
    SELECT g.name AS genre, al.title, al.price,
        ROW_NUMBER() OVER (PARTITION BY g.name ORDER BY al.price DESC) AS rn
    FROM albums al JOIN genres g ON al.genre_id = g.id
    WHERE al.price IS NOT NULL
) ranked WHERE rn <= 2;
```

### 6. EXISTS vs IN

```sql
-- EXISTS: correlated, often clearer for "does a match exist?"
SELECT ar.name FROM artists ar
WHERE EXISTS (SELECT 1 FROM albums al WHERE al.artist_id = ar.id);

-- IN: simpler for static or small lists
SELECT title FROM albums WHERE genre_id IN (1, 2);
```

### 7. Pivot / conditional aggregation

```sql
SELECT g.name,
    COUNT(CASE WHEN al.release_year < 1980 THEN 1 END) AS classic,
    COUNT(CASE WHEN al.release_year >= 2000 THEN 1 END) AS recent
FROM albums al JOIN genres g ON al.genre_id = g.id
GROUP BY g.name;
```

### 8. Self-join

```sql
SELECT a1.name, a2.name, a1.country
FROM artists a1 JOIN artists a2
    ON a1.country = a2.country AND a1.id < a2.id;
```

### 9. Date arithmetic

```sql
SELECT EXTRACT(YEAR FROM sale_date) AS yr, COUNT(*) FROM sales GROUP BY yr;
SELECT date_trunc('month', sale_date) AS month, SUM(quantity) FROM sales GROUP BY month;
```

### 10. NULL-safe comparison

```sql
-- IS DISTINCT FROM: treats NULL as a comparable value
SELECT * FROM albums WHERE genre_id IS DISTINCT FROM 1;
-- Returns albums where genre_id is NOT 1, including those where genre_id IS NULL
-- (unlike <> 1, which would exclude NULLs)
```
