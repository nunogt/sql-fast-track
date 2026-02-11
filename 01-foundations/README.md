# Module 1 -- Foundations

**Goal:** Understand relational concepts and write basic SELECT queries.

**Estimated time:** 3-4 hours

---

## Topics

### 1. Tables, rows, columns, primary keys

A relational database stores data in **tables**. Think of a table as a spreadsheet: it has named **columns** (fields) and **rows** (records).

- A **column** defines one piece of information and has a fixed data type (text, number, date, etc.).
- A **row** is one entry -- for example, one album or one artist.
- A **primary key** (PK) is a column (or set of columns) that uniquely identifies each row. Primary keys are always unique and never NULL.

#### The Record Shop schema

This course uses a fictional vinyl record shop with four tables:

```
genres              artists             albums                        sales
──────────          ──────────          ────────────────────          ──────────
id (PK)             id (PK)             id (PK)                       id (PK)
name                name                title                         album_id  → albums(id)
                    country             artist_id  → artists(id)      quantity
                                        genre_id   → genres(id)       sale_date
                                        release_year
                                        price
```

The arrows (`→`) indicate **foreign keys** -- columns that reference the primary key of another table. For example, every album has an `artist_id` that points to a row in the `artists` table. Foreign keys are how relational databases link tables together. You'll explore them in depth in Module 2.

#### Common data types

| Type | Description | Example |
|------|-------------|---------|
| `INTEGER` | Whole numbers | `release_year`, `quantity` |
| `SERIAL` | Auto-incrementing integer (used for IDs) | `id` |
| `VARCHAR(n)` | Variable-length text, up to *n* characters | `name VARCHAR(100)` |
| `NUMERIC(p,s)` | Exact decimal with *p* total digits and *s* decimal places | `price NUMERIC(6,2)` → up to 9999.99 |
| `DATE` | Calendar date (no time component) | `sale_date` |
| `BOOLEAN` | `TRUE`, `FALSE`, or `NULL` | (not used in our schema) |

`SERIAL` is a PostgreSQL shorthand: it creates an `INTEGER` column with a default value from an auto-incrementing sequence. You almost never need to supply a value for `SERIAL` columns -- the database fills them in.

---

### 2. `SELECT ... FROM`

`SELECT` retrieves data from a table. It is the most-used SQL statement.

#### Syntax

```sql
SELECT column1, column2, ...
FROM table_name;
```

#### Select all columns

The `*` wildcard returns every column:

```sql
SELECT *
FROM artists;
```

```
 id |      name       | country
----+-----------------+---------
  1 | Pink Floyd      | UK
  2 | Miles Davis     | US
  3 | Radiohead       | UK
  4 | Kendrick Lamar  | US
  5 | Daft Punk       | France
  ...
```

#### Select specific columns

List only the columns you need:

```sql
SELECT title, price
FROM albums;
```

```
              title               | price
----------------------------------+-------
 The Dark Side of the Moon        | 29.99
 Wish You Were Here               | 27.99
 The Wall                         | 31.99
 ...
```

> **Tip:** In production code, always name your columns explicitly rather than using `SELECT *`. It makes queries easier to read and protects against unexpected schema changes.

---

### 3. `WHERE`

`WHERE` filters rows so only those matching a condition are returned.

#### Syntax

```sql
SELECT columns
FROM table_name
WHERE condition;
```

#### Comparison operators

| Operator | Meaning |
|----------|---------|
| `=` | Equal |
| `<>` or `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

```sql
-- Albums released after 2000
SELECT title, release_year
FROM albums
WHERE release_year > 2000;
```

```
          title           | release_year
--------------------------+--------------
 Discovery                |         2001
 Random Access Memories   |         2013
 To Pimp a Butterfly      |         2015
 DAMN.                    |         2017
 Back to Black            |         2006
 Currents                 |         2015
```

Notice that `Kid A` (released in 2000) does **not** appear -- `2000 > 2000` is false. To include 2000, use `>=`.

#### Logical operators: `AND`, `OR`, `NOT`

Combine multiple conditions:

```sql
-- Albums from the 1970s priced under 30
SELECT title, release_year, price
FROM albums
WHERE release_year >= 1970
  AND release_year <= 1979
  AND price < 30.00;
```

```
              title               | release_year | price
----------------------------------+--------------+-------
 Wish You Were Here               |         1975 | 27.99
 Animals                          |         1977 | 26.99
 The Rise and Fall of Ziggy ...   |         1972 | 28.99
 Heroes                           |         1977 | 25.99
```

Use parentheses to control precedence when mixing `AND` and `OR`:

```sql
-- Albums that are (Rock OR Jazz) AND priced over 25
SELECT title, genre_id, price
FROM albums
WHERE (genre_id = 1 OR genre_id = 2)
  AND price > 25.00;
```

Without parentheses, `AND` binds more tightly than `OR`. The expression `a OR b AND c` is interpreted as `a OR (b AND c)`, which is probably not what you want. **When in doubt, add parentheses.**

#### `IN` -- matching a list of values

```sql
-- Artists from the US or UK
SELECT name, country
FROM artists
WHERE country IN ('US', 'UK');
```

`IN` is shorthand for multiple `OR` conditions. The query above is equivalent to:

```sql
WHERE country = 'US' OR country = 'UK'
```

#### `BETWEEN` -- inclusive range

```sql
-- Albums released in the 1980s
SELECT title, release_year
FROM albums
WHERE release_year BETWEEN 1980 AND 1989;
```

`BETWEEN` includes both endpoints. It is equivalent to:

```sql
WHERE release_year >= 1980 AND release_year <= 1989
```

#### `IS NULL` / `IS NOT NULL`

`NULL` represents missing or unknown data. You **cannot** test for it with `=`:

```sql
-- WRONG: this returns no rows, even when price is NULL
SELECT * FROM albums WHERE price = NULL;

-- CORRECT: use IS NULL
SELECT title, price
FROM albums
WHERE price IS NULL;
```

```
  title   | price
----------+-------
 DAMN.    |
 Currents |
```

> **Why?** In SQL, `NULL = NULL` evaluates to `NULL` (unknown), not `TRUE`. The `WHERE` clause only keeps rows where the condition is `TRUE`, so `= NULL` comparisons silently return nothing. Always use `IS NULL` or `IS NOT NULL`.

#### NULL and three-valued logic

SQL uses three-valued logic: `TRUE`, `FALSE`, and `NULL` (unknown). When `NULL` enters a logical expression, the result is often `NULL`:

**AND truth table:**

| `AND` | TRUE | FALSE | NULL |
|-------|------|-------|------|
| **TRUE** | TRUE | FALSE | NULL |
| **FALSE** | FALSE | FALSE | FALSE |
| **NULL** | NULL | FALSE | NULL |

**OR truth table:**

| `OR` | TRUE | FALSE | NULL |
|------|------|-------|------|
| **TRUE** | TRUE | TRUE | TRUE |
| **FALSE** | TRUE | FALSE | NULL |
| **NULL** | TRUE | NULL | NULL |

**NOT:**

| Expression | Result |
|------------|--------|
| `NOT TRUE` | FALSE |
| `NOT FALSE` | TRUE |
| `NOT NULL` | NULL |

The key rule: **any arithmetic or comparison with NULL produces NULL** (with specific exceptions like `IS NULL`).

```sql
SELECT 1 + NULL;       -- NULL
SELECT 'hello' = NULL; -- NULL
SELECT NULL = NULL;    -- NULL
SELECT NULL IS NULL;   -- TRUE  (the exception)
```

---

### 4. `ORDER BY` and `LIMIT` / `OFFSET`

#### `ORDER BY` -- sorting results

Without `ORDER BY`, SQL does **not** guarantee any particular row order. Use `ORDER BY` to sort:

```sql
-- Albums sorted by price, cheapest first
SELECT title, price
FROM albums
WHERE price IS NOT NULL
ORDER BY price ASC;
```

- `ASC` (ascending) is the default -- smallest first, A before Z, oldest date first.
- `DESC` (descending) -- largest first, Z before A, newest date first.

Sort by multiple columns -- the second column breaks ties in the first:

```sql
-- Sort by release year (newest first), then by title (A-Z) within each year
SELECT title, release_year
FROM albums
ORDER BY release_year DESC, title ASC;
```

> **NULL sort order:** In PostgreSQL, NULLs sort **last** in ascending order and **first** in descending order. You can override this with `NULLS FIRST` or `NULLS LAST`.

#### `LIMIT` -- restricting the number of rows

```sql
-- The 5 cheapest albums
SELECT title, price
FROM albums
WHERE price IS NOT NULL
ORDER BY price ASC
LIMIT 5;
```

```
       title       | price
--------------------+-------
 Let's Dance        | 17.99
 Discovery          | 18.99
 In Utero           | 18.99
 Nevermind          | 19.99
 Pastel Blues        | 19.99
```

#### `OFFSET` -- skipping rows

`OFFSET` skips a number of rows before returning results. Combined with `LIMIT`, it's used for pagination:

```sql
-- Skip the first 5, then return the next 5 (i.e. "page 2")
SELECT title, price
FROM albums
WHERE price IS NOT NULL
ORDER BY price ASC
LIMIT 5 OFFSET 5;
```

> **Tip:** `LIMIT` without `ORDER BY` returns an unpredictable set of rows. Always pair them together.

---

### 5. Column aliases (`AS`)

Rename columns in the output for readability:

```sql
SELECT
    title       AS album_title,
    price       AS price_usd,
    price * 0.9 AS discounted_price
FROM albums
WHERE price IS NOT NULL;
```

```
          album_title           | price_usd | discounted_price
--------------------------------+-----------+------------------
 The Dark Side of the Moon      |     29.99 |          26.991
 Wish You Were Here             |     27.99 |          25.191
 ...
```

Aliases only affect the query output -- they do not change anything in the database.

> **Note:** The `AS` keyword is technically optional (`SELECT title album_title` works), but always include it for clarity.

---

### 6. `DISTINCT`

`DISTINCT` removes duplicate rows from the result:

```sql
-- All unique countries where our artists are from
SELECT DISTINCT country
FROM artists;
```

```
 country
----------
 France
 Germany
 Iceland
 Jamaica
 UK
 US
 (NULL)
```

Notice that `NULL` appears as a distinct value.

`DISTINCT` works on the full row, so with multiple columns it returns unique *combinations*:

```sql
-- Which genres appear in which decades?
SELECT DISTINCT genre_id, (release_year / 10) * 10 AS decade
FROM albums
WHERE release_year IS NOT NULL
ORDER BY decade, genre_id;
```

> **Performance note:** `DISTINCT` requires the database to sort or hash every result row to find duplicates. On large tables this can be slow. Only use it when you actually need unique values.

---

## Exercises

See [`exercises.sql`](exercises.sql) -- 10 progressive queries against the Record Shop database.

After you've attempted each exercise, check your work against [`solutions.sql`](solutions.sql).

---

## Quiz

Test your understanding after completing the exercises. Try to answer each question before expanding the answer.

**1. What does `SELECT *` return?**

<details><summary>Answer</summary>

All columns and all rows from the specified table.

</details>

**2. What is the difference between `WHERE x = NULL` and `WHERE x IS NULL`?**

<details><summary>Answer</summary>

`WHERE x = NULL` always evaluates to NULL (unknown), so it returns **no rows** -- even when `x` is actually NULL. `WHERE x IS NULL` correctly tests for NULL values and returns rows where `x` has no value.

</details>

**3. Given a table with 100 rows, what does `SELECT DISTINCT category FROM products` return?**

<details><summary>Answer</summary>

One row for each unique value in the `category` column. The number of rows depends on how many distinct categories exist, not the total row count.

</details>

**4. Write a query to find all albums released between 1970 and 1979, sorted by price descending.**

<details><summary>Answer</summary>

```sql
SELECT title, release_year, price
FROM albums
WHERE release_year BETWEEN 1970 AND 1979
ORDER BY price DESC;
```

</details>

**5. What does `LIMIT 5 OFFSET 10` do?**

<details><summary>Answer</summary>

Skips the first 10 rows and returns the next 5. This is commonly used for pagination (e.g. "page 3" of results with 5 rows per page).

</details>

**6. If a `WHERE` clause uses `OR`, how do you ensure correct precedence with `AND`?**

<details><summary>Answer</summary>

Use parentheses. `AND` binds more tightly than `OR`, so `WHERE a = 1 OR b = 2 AND c = 3` is interpreted as `WHERE a = 1 OR (b = 2 AND c = 3)`. To change the grouping, write `WHERE (a = 1 OR b = 2) AND c = 3`.

</details>

**7. What is the result of `SELECT 1 + NULL`?**

<details><summary>Answer</summary>

`NULL`. Any arithmetic operation involving NULL produces NULL.

</details>

**8. Write a query to find all albums where the price is not set (NULL).**

<details><summary>Answer</summary>

```sql
SELECT title, price
FROM albums
WHERE price IS NULL;
```

</details>

**9. What is the difference between `WHERE country IN ('US', 'UK')` and using `OR`?**

<details><summary>Answer</summary>

They produce identical results. `IN ('US', 'UK')` is shorthand for `country = 'US' OR country = 'UK'`. The `IN` form is more readable, especially with many values.

</details>

**10. Explain what a primary key guarantees about a column's values.**

<details><summary>Answer</summary>

A primary key guarantees two things: every value is **unique** (no two rows share the same value) and every value is **not NULL** (every row must have a value). Together, these ensure that every row can be uniquely identified.

</details>
