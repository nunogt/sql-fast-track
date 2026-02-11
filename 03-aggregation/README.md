# Module 3 -- Aggregation & Grouping

**Goal:** Summarise data -- counts, totals, averages -- and filter grouped results.

**Estimated time:** 3-4 hours

**Prerequisites:** Module 2 (Joins).

---

## Topics

### 1. Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`

Aggregate functions collapse many rows into a single summary value. They are the foundation of reporting and analytics in SQL.

| Function | Purpose | Example |
|----------|---------|---------|
| `COUNT(...)` | Number of rows/values | How many albums? |
| `SUM(expr)` | Total of a numeric column | Total quantity sold |
| `AVG(expr)` | Arithmetic mean | Average album price |
| `MIN(expr)` | Smallest value | Cheapest album |
| `MAX(expr)` | Largest value | Most expensive album |

#### Examples

```sql
SELECT COUNT(*) AS total_albums FROM albums;
```

```
 total_albums
--------------
           31
```

```sql
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive,
    ROUND(AVG(price), 2) AS average_price
FROM albums;
```

```
 cheapest | most_expensive | average_price
----------+----------------+---------------
    17.99 |          34.99 |         25.61
```

> **NULL handling:** `SUM`, `AVG`, `MIN`, and `MAX` all **skip NULLs**. Two albums in our database have `NULL` prices — they are excluded from the average. This is usually what you want, but be aware of it.

```sql
-- 31 albums total, but only 29 have a price
SELECT COUNT(*) AS total, COUNT(price) AS with_price FROM albums;
```

```
 total | with_price
-------+------------
    31 |         29
```

---

### 2. `COUNT(*)` vs `COUNT(column)` vs `COUNT(DISTINCT column)`

These three forms look similar but behave very differently. Getting them confused is a common source of bugs.

| Form | What it counts | NULLs | Duplicates |
|------|---------------|-------|------------|
| `COUNT(*)` | Rows | Counts all rows regardless | Counts all |
| `COUNT(column)` | Non-NULL values in that column | **Skips NULLs** | Counts duplicates |
| `COUNT(DISTINCT column)` | Unique non-NULL values | **Skips NULLs** | **Skips duplicates** |

```sql
SELECT
    COUNT(*)                AS total_rows,
    COUNT(price)            AS non_null_prices,
    COUNT(DISTINCT genre_id) AS distinct_genres
FROM albums;
```

```
 total_rows | non_null_prices | distinct_genres
------------+-----------------+-----------------
         31 |              29 |               7
```

- `COUNT(*)` = 31 — every row, regardless of NULLs.
- `COUNT(price)` = 29 — two albums have `NULL` price.
- `COUNT(DISTINCT genre_id)` = 7 — eight genres exist, but one album has `NULL` genre_id (not counted) and `Classical` has no albums linked to it.

> **Rule of thumb:** Use `COUNT(*)` when you want to count rows. Use `COUNT(column)` when you specifically want to count non-NULL values. Use `COUNT(DISTINCT column)` when you want unique values.

---

### 3. `GROUP BY`

Without `GROUP BY`, aggregate functions operate on the entire table and return one row. `GROUP BY` splits the rows into groups, and the aggregate function runs once per group.

#### Syntax

```sql
SELECT group_column, AGGREGATE(value_column)
FROM table
GROUP BY group_column;
```

#### Example: albums per genre

```sql
SELECT g.name AS genre, COUNT(*) AS album_count
FROM albums al
JOIN genres g ON al.genre_id = g.id
GROUP BY g.name
ORDER BY album_count DESC;
```

```
   genre    | album_count
------------+-------------
 Rock       |          13
 Jazz       |           6
 Electronic |           5
 Hip-Hop    |           2
 Pop        |           2
 Reggae     |           1
 Soul       |           1
```

How it works:
1. The `JOIN` combines albums with genres (30 rows — Currents has `NULL` genre_id and is excluded by `INNER JOIN`).
2. `GROUP BY g.name` splits the 30 rows into groups, one per genre.
3. `COUNT(*)` counts the rows in each group.

#### The GROUP BY rule

Every column in the `SELECT` list must be either:
1. Listed in `GROUP BY`, **or**
2. Inside an aggregate function.

```sql
-- WRONG: title is not grouped or aggregated
SELECT ar.name, al.title, COUNT(*)
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name;
-- ERROR: column "al.title" must appear in the GROUP BY clause
--        or be used in an aggregate function

-- CORRECT: only grouped and aggregated columns
SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name;
```

#### Grouping by multiple columns

You can group by more than one column to get finer-grained breakdowns:

```sql
SELECT ar.name AS artist, g.name AS genre, COUNT(*) AS albums
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
JOIN genres g ON al.genre_id = g.id
GROUP BY ar.name, g.name
ORDER BY ar.name, g.name;
```

```
     artist     |   genre    | albums
----------------+------------+--------
 Amy Winehouse  | Soul       |      1
 Björk          | Electronic |      1
 Björk          | Pop        |      1
 Bob Marley     | Reggae     |      1
 Daft Punk      | Electronic |      2
 David Bowie    | Pop        |      1
 David Bowie    | Rock       |      2
 ...
```

Each unique combination of `(artist, genre)` gets its own row.

---

### 4. `HAVING`

`WHERE` filters individual rows **before** grouping. `HAVING` filters groups **after** aggregation.

#### Syntax

```sql
SELECT group_column, AGGREGATE(...)
FROM table
WHERE row_condition          -- filters rows BEFORE grouping
GROUP BY group_column
HAVING aggregate_condition;  -- filters groups AFTER aggregation
```

#### Example: artists with more than 2 albums

```sql
SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name
HAVING COUNT(*) > 2
ORDER BY album_count DESC;
```

```
    name     | album_count
-------------+-------------
 Pink Floyd  |           4
 The Beatles |           4
 David Bowie |           3
```

#### `WHERE` vs `HAVING`

```sql
-- WHERE: exclude Jazz albums BEFORE grouping, then count
SELECT g.name, COUNT(*) AS album_count
FROM albums al
JOIN genres g ON al.genre_id = g.id
WHERE g.name <> 'Jazz'
GROUP BY g.name
HAVING COUNT(*) > 2;

-- HAVING alone: group ALL albums, then keep only groups with count > 2
SELECT g.name, COUNT(*) AS album_count
FROM albums al
JOIN genres g ON al.genre_id = g.id
GROUP BY g.name
HAVING COUNT(*) > 2;
```

> **Common mistake:** You cannot put an aggregate in a `WHERE` clause. `WHERE SUM(quantity) > 10` is a syntax error. Always use `HAVING` for conditions on aggregated values.

---

### 5. Combining joins with aggregation

The most common real-world pattern: join tables to combine related data, then group and aggregate to summarise it.

#### Query execution order

Understanding the logical order helps you reason about what goes where:

```
1. FROM / JOIN     ← combine tables
2. WHERE           ← filter individual rows
3. GROUP BY        ← form groups
4. HAVING          ← filter groups
5. SELECT          ← compute columns and aggregates
6. ORDER BY        ← sort results
7. LIMIT / OFFSET  ← restrict output
```

This is why you can't use a column alias from `SELECT` in a `WHERE` clause (step 2 runs before step 5), but you **can** use it in `ORDER BY` (step 6 runs after step 5).

#### Example: total sales revenue per artist

This query joins three tables, groups by artist, and calculates revenue:

```sql
SELECT
    ar.name AS artist,
    SUM(s.quantity * al.price) AS revenue
FROM artists ar
JOIN albums al ON ar.id = al.artist_id
JOIN sales s  ON al.id  = s.album_id
GROUP BY ar.name
ORDER BY revenue DESC;
```

```
     artist     | revenue
----------------+---------
 Pink Floyd     |  269.91
 The Beatles    |  195.93
 John Coltrane  |  133.96
 David Bowie    |  119.95
 Daft Punk      |   87.96
 Miles Davis    |   82.97
 Amy Winehouse  |   80.97
 Nirvana        |   79.96
 Bob Marley     |   68.97
 Radiohead      |   67.97
 Kendrick Lamar |   47.98
 Björk          |   43.98
 Nina Simone    |   21.99
```

Note: artists with no sales (Adele, Kraftwerk, Tame Impala) don't appear because `INNER JOIN` requires a matching sale. Albums with `NULL` price (DAMN.) also contribute nothing because `quantity * NULL` is `NULL`, which `SUM` skips.

#### Example: average price per decade

Using integer division to bucket years into decades:

```sql
SELECT
    (release_year / 10) * 10 AS decade,
    ROUND(AVG(price), 2) AS avg_price
FROM albums
WHERE price IS NOT NULL
GROUP BY (release_year / 10) * 10
ORDER BY decade;
```

```
 decade | avg_price
--------+-----------
   1950 |     28.49
   1960 |     26.99
   1970 |     28.88
   1980 |     20.49
   1990 |     21.19
   2000 |     22.66
   2010 |     24.49
```

The expression `release_year / 10` uses integer division (truncates the decimal), then `* 10` rounds down to the decade start. So 1977 → 197 → 1970.

---

## Exercises

See [`exercises.sql`](exercises.sql) -- 10 queries covering counts, totals, averages, and grouped results.

After you've attempted each exercise, check your work against [`solutions.sql`](solutions.sql).

---

## Quiz

Test your understanding after completing the exercises. Try to answer each question before expanding the answer.

**1. What is the difference between `COUNT(*)` and `COUNT(price)`?**

<details><summary>Answer</summary>

`COUNT(*)` counts all rows, including those where `price` is NULL. `COUNT(price)` counts only rows where `price` is not NULL. In our database: `COUNT(*)` = 31, `COUNT(price)` = 29.

</details>

**2. Can you use `WHERE` to filter on the result of `SUM()`? Why or why not?**

<details><summary>Answer</summary>

No. `WHERE` filters individual rows **before** grouping and aggregation, so aggregate results don't exist yet at that stage. Use `HAVING` to filter on aggregate values.

</details>

**3. What happens if you SELECT a column that is not in the GROUP BY and not aggregated?**

<details><summary>Answer</summary>

PostgreSQL raises an error: the column must appear in the `GROUP BY` clause or be used inside an aggregate function. (Some databases like MySQL allow this with unpredictable results, but PostgreSQL enforces it strictly.)

</details>

**4. Write a query to find the number of albums per genre.**

<details><summary>Answer</summary>

```sql
SELECT g.name AS genre, COUNT(*) AS album_count
FROM albums al
JOIN genres g ON al.genre_id = g.id
GROUP BY g.name
ORDER BY album_count DESC;
```

</details>

**5. Write a query to find artists with more than 3 albums.**

<details><summary>Answer</summary>

```sql
SELECT ar.name, COUNT(*) AS album_count
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
GROUP BY ar.name
HAVING COUNT(*) > 3;
```

Returns Pink Floyd (4) and The Beatles (4).

</details>

**6. What is the difference between `HAVING COUNT(*) > 5` and `WHERE count > 5`?**

<details><summary>Answer</summary>

`HAVING COUNT(*) > 5` filters groups after aggregation — it keeps only groups with more than 5 rows. `WHERE count > 5` attempts to filter individual rows based on a column literally named `count` (not the aggregate function). If no such column exists, it's an error.

</details>

**7. How do NULLs affect `AVG()`?**

<details><summary>Answer</summary>

`AVG()` **skips** NULL values entirely. It divides the sum of non-NULL values by the count of non-NULL values. So if you have prices `[10, 20, NULL]`, `AVG(price)` = 15, not 10.

</details>

**8. Can you GROUP BY a column alias defined in the SELECT clause?**

<details><summary>Answer</summary>

In PostgreSQL, **yes** — you can reference a SELECT alias in `GROUP BY`. However, this is a PostgreSQL extension; the SQL standard requires using the original expression. For maximum portability, repeat the expression in `GROUP BY`.

</details>

**9. Write a query to find the genre with the highest total sales revenue.**

<details><summary>Answer</summary>

```sql
SELECT g.name AS genre, SUM(s.quantity * al.price) AS revenue
FROM genres g
JOIN albums al ON g.id = al.genre_id
JOIN sales s  ON al.id = s.album_id
GROUP BY g.name
ORDER BY revenue DESC
LIMIT 1;
```

</details>

**10. What does `GROUP BY 1, 2` mean (using numbers instead of column names)?**

<details><summary>Answer</summary>

The numbers refer to the **position** of columns in the `SELECT` list. `GROUP BY 1, 2` groups by the first and second selected columns. It's a shorthand — convenient for complex expressions, but can hurt readability. Supported in PostgreSQL.

</details>
