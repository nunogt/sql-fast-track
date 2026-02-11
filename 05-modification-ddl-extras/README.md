# Module 5 -- Data Modification, DDL & Extras

**Goal:** Round out your SQL knowledge with write operations, schema design basics, and window functions.

**Estimated time:** 3-4 hours

**Prerequisites:** Module 4 (Subqueries, CTEs & Functions).

> **Warning:** Topics 1-4 modify data or schema. If you want to reset the database to its original state at any point, run:
> ```bash
> docker compose down -v && docker compose up -d
> ```

---

## Topics

### 1. `INSERT`, `UPDATE`, `DELETE`

So far, every query has been read-only. These three statements let you **write** data.

#### `INSERT` — adding rows

```sql
-- Insert a single row
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('OK Human', 3, 1, 2021, 22.99);
```

You can omit `SERIAL` columns (like `id`) — they auto-increment. You can also omit nullable columns and they default to `NULL`.

#### Multi-row INSERT

```sql
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES
    ('Amnesiac', 3, 4, 2001, 21.99),
    ('Hail to the Thief', 3, 1, 2003, 20.99);
```

#### `INSERT ... RETURNING`

PostgreSQL can return the newly created rows, which is useful for getting auto-generated IDs:

```sql
INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('In Rainbows', 3, 1, 2007, 23.99)
RETURNING id, title;
```

```
 id |    title
----+--------------
 32 | In Rainbows
```

#### `UPDATE` — modifying existing rows

```sql
-- Increase all Rock album prices by 10%
UPDATE albums
SET price = ROUND(price * 1.10, 2)
WHERE genre_id = 1;
```

> **Critical:** Always include a `WHERE` clause unless you intentionally want to update **every** row. `UPDATE albums SET price = 0` with no `WHERE` sets **all** prices to zero.

#### UPDATE with a subquery or join

```sql
-- Set price to the genre average for albums that have no price
UPDATE albums
SET price = sub.avg_price
FROM (
    SELECT genre_id, ROUND(AVG(price), 2) AS avg_price
    FROM albums
    WHERE price IS NOT NULL
    GROUP BY genre_id
) AS sub
WHERE albums.genre_id = sub.genre_id
  AND albums.price IS NULL;
```

#### `DELETE` — removing rows

```sql
-- Delete all albums that have never been sold
DELETE FROM albums
WHERE id NOT IN (SELECT album_id FROM sales);
```

Or using `NOT EXISTS`:

```sql
DELETE FROM albums al
WHERE NOT EXISTS (
    SELECT 1 FROM sales s WHERE s.album_id = al.id
);
```

> **Critical:** Like `UPDATE`, always use a `WHERE` clause unless you mean to delete everything. `DELETE FROM albums` with no `WHERE` empties the entire table.

#### `DELETE` with foreign key constraints

If you try to delete an artist who has albums, the database will reject it because the `albums.artist_id` foreign key references `artists.id`. You must delete the dependent rows first (or set up `ON DELETE CASCADE` when creating the table).

---

### 2. `CREATE TABLE`

`CREATE TABLE` defines a new table with its columns, data types, and constraints.

#### Syntax

```sql
CREATE TABLE table_name (
    column_name  DATA_TYPE  CONSTRAINTS,
    ...
    TABLE_LEVEL_CONSTRAINTS
);
```

#### Example: a customers table

```sql
CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(200) NOT NULL UNIQUE,
    country    VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

#### Constraint reference

| Constraint | Level | Purpose |
|------------|-------|---------|
| `NOT NULL` | Column | Column must have a value |
| `UNIQUE` | Column or table | No duplicate values allowed |
| `PRIMARY KEY` | Column or table | Shorthand for `NOT NULL` + `UNIQUE`; one per table |
| `FOREIGN KEY ... REFERENCES` | Column or table | Value must exist in another table |
| `CHECK (condition)` | Column or table | Value must satisfy a boolean expression |
| `DEFAULT value` | Column | Value used when none is provided on insert |

#### Example with all constraint types

```sql
CREATE TABLE order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES orders (id),
    product_id  INTEGER NOT NULL,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(8,2) NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)  -- table-level: no duplicate product in same order
);
```

#### Useful modifiers

- `ON DELETE CASCADE`: when the referenced row is deleted, automatically delete the dependent rows.
- `ON DELETE SET NULL`: when the referenced row is deleted, set the foreign key column to NULL.

```sql
-- If an artist is deleted, delete all their albums too
CREATE TABLE albums_example (
    id        SERIAL PRIMARY KEY,
    title     VARCHAR(200) NOT NULL,
    artist_id INTEGER REFERENCES artists (id) ON DELETE CASCADE
);
```

---

### 3. Views

A **view** is a saved query that you can use like a table. It doesn't store data — it runs the underlying query each time you select from it.

#### Creating a view

```sql
CREATE VIEW sales_report AS
SELECT
    al.title,
    ar.name   AS artist,
    g.name    AS genre,
    SUM(s.quantity) AS total_sold,
    SUM(s.quantity * al.price) AS revenue
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
JOIN genres g  ON al.genre_id  = g.id
JOIN sales s   ON al.id        = s.album_id
GROUP BY al.title, ar.name, g.name;
```

#### Using a view

```sql
-- Use it just like a table
SELECT * FROM sales_report ORDER BY revenue DESC LIMIT 5;
```

```
           title           |   artist   | genre | total_sold | revenue
---------------------------+------------+-------+------------+---------
 The Dark Side of the Moon | Pink Floyd | Rock  |          5 |  149.95
 Abbey Road                | The Beatles| Rock  |          3 |   83.97
 Back to Black             | Amy Wine.. | Soul  |          3 |   80.97
 Nevermind                 | Nirvana    | Rock  |          4 |   79.96
 A Love Supreme            | John Col.. | Jazz  |          2 |   69.98
```

#### When to use views

- **Simplify complex queries** you run often — define once, reuse many times.
- **Restrict access** — expose only certain columns or pre-filtered rows.
- **Provide stable interfaces** — if the underlying tables change, update the view definition instead of every query.

#### Replacing a view

```sql
CREATE OR REPLACE VIEW sales_report AS
    ... -- updated query
```

#### Dropping a view

```sql
DROP VIEW IF EXISTS sales_report;
```

---

### 4. Transactions

A **transaction** groups multiple operations into a single atomic unit: either they **all** succeed, or they **all** get rolled back. This prevents the database from ending up in a half-finished state.

#### Syntax

```sql
BEGIN;                  -- start a transaction

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;                 -- make the changes permanent
```

If something goes wrong mid-transaction:

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- Oops, wrong amount! Undo everything:

ROLLBACK;               -- discard all changes since BEGIN
```

#### Key properties (ACID)

| Property | Meaning |
|----------|---------|
| **Atomicity** | All operations succeed or none do |
| **Consistency** | The database moves from one valid state to another |
| **Isolation** | Concurrent transactions don't interfere with each other |
| **Durability** | Committed changes survive crashes |

#### Practical example

```sql
BEGIN;

-- Insert a new artist and their album in one atomic operation
INSERT INTO artists (name, country) VALUES ('Portishead', 'UK');

INSERT INTO albums (title, artist_id, genre_id, release_year, price)
VALUES ('Dummy', currval('artists_id_seq'), 4, 1994, 21.99);

COMMIT;
```

If the second `INSERT` fails (e.g. invalid `genre_id`), the first `INSERT` is also rolled back — you won't end up with an artist who has no albums.

> **Note:** In `psql`, every statement outside of an explicit `BEGIN` block runs in its own auto-committed transaction.

---

### 5. Window functions

Window functions perform calculations across a set of rows **related to the current row**, without collapsing them into a single output row (unlike `GROUP BY`).

#### Syntax

```sql
function_name() OVER (
    [PARTITION BY column]   -- optional: reset per group
    ORDER BY column         -- defines row order
    [frame_clause]          -- optional: which rows to include
)
```

#### `ROW_NUMBER()` — unique sequential number

Assigns a unique number to each row within the window. Ties are broken arbitrarily.

```sql
SELECT
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    title, price
FROM albums
WHERE price IS NOT NULL
ORDER BY row_num;
```

```
 row_num |                 title                 | price
---------+---------------------------------------+-------
       1 | A Love Supreme                        | 34.99
       2 | Bitches Brew                          | 32.99
       3 | Blue Train                            | 31.99
       4 | The Wall                              | 31.99
       5 | The Dark Side of the Moon             | 29.99
       6 | Sgt. Pepper's Lonely Hearts Club Band | 29.99
       7 | Trans-Europe Express                  | 29.99
       ...
```

Blue Train and The Wall both cost 31.99, but they get different row numbers (3 and 4). The order between them is arbitrary.

#### `RANK()` and `DENSE_RANK()` — handling ties

These three functions differ in how they handle ties:

| Function | Ties | Gap after tie? | Example for values 5, 3, 3, 3, 1 |
|----------|------|---------------|-----------------------------------|
| `ROW_NUMBER()` | Broken arbitrarily | N/A | 1, 2, 3, 4, 5 |
| `RANK()` | Same rank | Yes — skips numbers | 1, 2, 2, 2, 5 |
| `DENSE_RANK()` | Same rank | No — consecutive | 1, 2, 2, 2, 3 |

```sql
-- Compare all three on album sales
WITH album_sales AS (
    SELECT al.title, SUM(s.quantity) AS total_sold
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    GROUP BY al.title
)
SELECT
    title, total_sold,
    ROW_NUMBER() OVER (ORDER BY total_sold DESC) AS row_num,
    RANK()       OVER (ORDER BY total_sold DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY total_sold DESC) AS dense_rank
FROM album_sales
ORDER BY total_sold DESC
LIMIT 8;
```

```
              title               | total_sold | row_num | rank | dense_rank
----------------------------------+------------+---------+------+------------
 The Dark Side of the Moon        |          5 |       1 |    1 |          1
 Nevermind                        |          4 |       2 |    2 |          2
 Abbey Road                       |          3 |       3 |    3 |          3
 Back to Black                    |          3 |       4 |    3 |          3
 Legend                           |          3 |       5 |    3 |          3
 The Wall                         |          2 |       6 |    6 |          4
 Kind of Blue                     |          2 |       7 |    6 |          4
 A Love Supreme                   |          2 |       8 |    6 |          4
```

Notice: three albums tied at 3 copies. `RANK` gives them all 3 and skips to 6. `DENSE_RANK` gives them all 3 and continues to 4.

#### `PARTITION BY` — windowing within groups

`PARTITION BY` resets the window for each group, like a per-group `ORDER BY`:

```sql
-- Rank albums by total sales within each genre
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
```

```
   genre    |                 title                 | total_sold | genre_rank
------------+---------------------------------------+------------+------------
 Electronic | Random Access Memories                |          2 |          1
 Electronic | Discovery                             |          2 |          1
 Electronic | Homogenic                             |          1 |          3
 Electronic | Kid A                                 |          1 |          3
 Hip-Hop    | To Pimp a Butterfly                   |          2 |          1
 Jazz       | Kind of Blue                          |          2 |          1
 Jazz       | A Love Supreme                        |          2 |          1
 Jazz       | Blue Train                            |          2 |          1
 ...
 Rock       | The Dark Side of the Moon             |          5 |          1
 Rock       | Nevermind                             |          4 |          2
 Rock       | Abbey Road                            |          3 |          3
 ...
```

The rank resets to 1 for each genre.

#### `LAG()` and `LEAD()` — accessing adjacent rows

`LAG(column, n)` looks back *n* rows. `LEAD(column, n)` looks forward. Default *n* is 1.

```sql
-- Each sale with the previous sale's date
SELECT
    id, sale_date, quantity,
    LAG(sale_date) OVER (ORDER BY sale_date, id) AS prev_sale_date
FROM sales
ORDER BY sale_date, id
LIMIT 6;
```

```
 id | sale_date  | quantity | prev_sale_date
----+------------+----------+----------------
 17 | 2024-01-08 |        1 |
  1 | 2024-01-15 |        2 | 2024-01-08
 36 | 2024-01-22 |        1 | 2024-01-15
 32 | 2024-02-05 |        3 | 2024-01-22
 21 | 2024-02-14 |        1 | 2024-02-05
  5 | 2024-02-28 |        1 | 2024-02-14
```

The first row has `NULL` for `prev_sale_date` because there's no previous row.

#### Running totals with `SUM() OVER`

Any aggregate function can be used as a window function by adding `OVER`:

```sql
SELECT
    sale_date, quantity,
    SUM(quantity) OVER (ORDER BY sale_date, id) AS running_total
FROM sales
ORDER BY sale_date, id
LIMIT 6;
```

```
 sale_date  | quantity | running_total
------------+----------+---------------
 2024-01-08 |        1 |             1
 2024-01-15 |        2 |             3
 2024-01-22 |        1 |             4
 2024-02-05 |        3 |             7
 2024-02-14 |        1 |             8
 2024-02-28 |        1 |             9
```

The `running_total` accumulates with each row. Without `PARTITION BY`, it runs across all rows.

#### Window functions vs GROUP BY

| | GROUP BY | Window function |
|---|---------|----------------|
| **Output rows** | One row per group | All original rows preserved |
| **Columns** | Must be grouped or aggregated | Can include any column |
| **Use case** | Summary reports | Per-row calculations with context |

---

### 6. Set operations

Set operations combine the results of two or more `SELECT` queries.

#### Rules

1. Both queries must have the **same number of columns**.
2. Corresponding columns must have **compatible types**.
3. Column names come from the **first** query.

#### `UNION` / `UNION ALL`

`UNION` combines results and **removes duplicates**. `UNION ALL` keeps duplicates (and is faster).

```sql
-- All artist and genre names in one list
SELECT name FROM artists
UNION
SELECT name FROM genres
ORDER BY name;
```

```
      name
----------------
 Adele
 Amy Winehouse
 Björk
 Bob Marley
 Classical
 Daft Punk
 ...
 Rock
 Soul
 Tame Impala
 The Beatles
(24 rows)
```

16 artists + 8 genres = 24 unique names (no overlapping names in our data, so `UNION ALL` would also give 24 rows here).

#### `INTERSECT`

Returns only rows that appear in **both** queries:

```sql
-- Countries that are also genre names (none in our data)
SELECT country FROM artists WHERE country IS NOT NULL
INTERSECT
SELECT name FROM genres;
-- (0 rows)
```

#### `EXCEPT`

Returns rows from the first query that are **not** in the second:

```sql
-- Artist countries other than 'UK'
SELECT DISTINCT country FROM artists WHERE country IS NOT NULL
EXCEPT
SELECT 'UK'
ORDER BY country;
```

```
 country
---------
 France
 Germany
 Iceland
 Jamaica
 US
```

> **Tip:** `UNION`, `INTERSECT`, and `EXCEPT` all remove duplicates by default. Add `ALL` (e.g. `UNION ALL`, `EXCEPT ALL`) to keep duplicates.

---

## Exercises

See [`exercises.sql`](exercises.sql) -- 10 exercises covering writes, DDL, and window functions.

After you've attempted each exercise, check your work against [`solutions.sql`](solutions.sql).

---

## Quiz

Test your understanding after completing the exercises. Try to answer each question before expanding the answer.

**1. What is the difference between `DELETE` and `TRUNCATE`?**

<details><summary>Answer</summary>

`DELETE` removes rows one at a time, can use a `WHERE` clause, fires triggers, and can be rolled back inside a transaction. `TRUNCATE` removes **all** rows instantly (much faster on large tables), cannot use `WHERE`, and resets sequences. Both leave the table structure intact.

</details>

**2. What does `NOT NULL` enforce on a column?**

<details><summary>Answer</summary>

`NOT NULL` requires every row to have a value for that column. Any `INSERT` or `UPDATE` that would set the column to `NULL` is rejected with an error.

</details>

**3. Write a `CREATE TABLE` statement for a simple `customers` table with an id, name, and email (email must be unique).**

<details><summary>Answer</summary>

```sql
CREATE TABLE customers (
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE
);
```

</details>

**4. What is the difference between `UNION` and `UNION ALL`?**

<details><summary>Answer</summary>

`UNION` removes duplicate rows from the combined result. `UNION ALL` includes all rows, including duplicates. `UNION ALL` is faster because it skips the deduplication step.

</details>

**5. What happens if you `UPDATE` without a `WHERE` clause?**

<details><summary>Answer</summary>

**Every row** in the table is updated. For example, `UPDATE albums SET price = 0` would set the price of all 31 albums to zero.

</details>

**6. Explain the difference between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`.**

<details><summary>Answer</summary>

For the values 10, 8, 8, 5:
- `ROW_NUMBER()`: 1, 2, 3, 4 — unique numbers, ties broken arbitrarily.
- `RANK()`: 1, 2, 2, 4 — tied rows get the same rank, then a gap (skips 3).
- `DENSE_RANK()`: 1, 2, 2, 3 — tied rows get the same rank, no gap.

</details>

**7. What does `ROLLBACK` do inside a transaction?**

<details><summary>Answer</summary>

`ROLLBACK` **discards all changes** made since the last `BEGIN`. The database returns to the state it was in before the transaction started. No data is modified.

</details>

**8. Why would you create a view instead of just saving the SQL in a file?**

<details><summary>Answer</summary>

A view lives in the database and can be referenced by other queries, used in joins, and have permissions applied. It also provides a stable interface — if the underlying tables change, you update the view definition instead of every query in every file. Other users and applications can use it without knowing the underlying complexity.

</details>

**9. Write a window function to rank albums by price within each genre.**

<details><summary>Answer</summary>

```sql
SELECT
    g.name AS genre, al.title, al.price,
    RANK() OVER (PARTITION BY g.name ORDER BY al.price DESC) AS price_rank
FROM albums al
JOIN genres g ON al.genre_id = g.id
WHERE al.price IS NOT NULL;
```

</details>

**10. What is the difference between `DELETE FROM albums` and `DROP TABLE albums`?**

<details><summary>Answer</summary>

`DELETE FROM albums` removes all **rows** but keeps the table structure — you can still `INSERT` into it. `DROP TABLE albums` removes the **entire table** — structure, data, indexes, and all. The table no longer exists.

</details>
