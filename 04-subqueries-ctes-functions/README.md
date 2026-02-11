# Module 4 -- Subqueries, CTEs & Essential Functions

**Goal:** Write nested queries, use common table expressions, and leverage the most-used built-in functions.

**Estimated time:** 3-4 hours

**Prerequisites:** Module 3 (Aggregation & Grouping).

---

## Topics

### 1. Subqueries in `WHERE` (scalar and list)

A subquery is a query nested inside another query. When used in a `WHERE` clause, it lets you filter rows based on the result of a second query.

#### Scalar subquery — returns a single value

Use a scalar subquery with comparison operators (`=`, `>`, `<`, etc.):

```sql
-- Albums priced above the average
SELECT title, price
FROM albums
WHERE price > (SELECT AVG(price) FROM albums)
ORDER BY price DESC;
```

```
                 title                 | price
---------------------------------------+-------
 A Love Supreme                        | 34.99
 Bitches Brew                          | 32.99
 Blue Train                            | 31.99
 The Wall                              | 31.99
 The Dark Side of the Moon             | 29.99
 Sgt. Pepper's Lonely Hearts Club Band | 29.99
 Trans-Europe Express                  | 29.99
 The Rise and Fall of Ziggy Stardust   | 28.99
 Abbey Road                            | 27.99
 Wish You Were Here                    | 27.99
 Back to Black                         | 26.99
 Animals                               | 26.99
 Revolver                              | 26.99
 Heroes                                | 25.99
(14 rows)
```

How it works:
1. The inner query `SELECT AVG(price) FROM albums` runs first and returns a single number (25.61).
2. The outer query uses that number to filter: `WHERE price > 25.61`.

#### List subquery — returns a set of values

Use a list subquery with `IN`:

```sql
-- Albums by artists from the UK
SELECT title
FROM albums
WHERE artist_id IN (
    SELECT id FROM artists WHERE country = 'UK'
)
ORDER BY title;
```

The inner query returns a set of artist IDs, and the outer query keeps only albums whose `artist_id` is in that set. You could also write this with a `JOIN` — both approaches work; use whichever reads more clearly.

---

### 2. Correlated subqueries and `EXISTS`

A **non-correlated** subquery (like the examples above) runs once. A **correlated** subquery references the outer query, so it runs once per outer row.

#### `EXISTS`

`EXISTS` returns `TRUE` if the subquery produces at least one row. It's the most common use of correlated subqueries.

```sql
-- Artists who have at least one sale
SELECT ar.name
FROM artists ar
WHERE EXISTS (
    SELECT 1
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    WHERE al.artist_id = ar.id   -- references outer query
)
ORDER BY ar.name;
```

```
      name
----------------
 Amy Winehouse
 Björk
 Bob Marley
 Daft Punk
 David Bowie
 John Coltrane
 Kendrick Lamar
 Miles Davis
 Nina Simone
 Nirvana
 Pink Floyd
 Radiohead
 The Beatles
(13 rows)
```

For each artist in the outer query, the inner query checks if any sales exist for that artist. If yes, `EXISTS` returns `TRUE` and the artist is included.

#### `NOT EXISTS`

The opposite — find rows with **no** match:

```sql
-- Artists with no sales at all
SELECT ar.name
FROM artists ar
WHERE NOT EXISTS (
    SELECT 1
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    WHERE al.artist_id = ar.id
)
ORDER BY ar.name;
```

```
    name
-------------
 Adele
 Kraftwerk
 Tame Impala
```

> **EXISTS vs JOIN:** Both can solve the same problem. `EXISTS` is often clearer for "does a match exist?" questions and avoids accidental row duplication that can happen with joins. Performance is usually comparable — the database optimiser often generates the same plan for both.

---

### 3. Subqueries in `FROM` (derived tables)

You can use a subquery as a temporary table in the `FROM` clause. This is called a **derived table** and must have an alias.

```sql
SELECT artist, album_count
FROM (
    SELECT ar.name AS artist, COUNT(*) AS album_count
    FROM artists ar
    JOIN albums al ON ar.id = al.artist_id
    GROUP BY ar.name
) AS artist_counts
WHERE album_count >= 3;
```

```
   artist    | album_count
-------------+-------------
 The Beatles |           4
 David Bowie |           3
 Pink Floyd  |           4
```

The inner query calculates album counts per artist. The outer query filters on that result. This approach works, but CTEs (next section) are usually more readable for the same purpose.

---

### 4. CTEs (`WITH ... AS`)

A **Common Table Expression** (CTE) lets you define a named result set at the top of a query, then reference it below. Think of it as a named, temporary view that exists only for the duration of the query.

#### Syntax

```sql
WITH cte_name AS (
    SELECT ...
)
SELECT ...
FROM cte_name
WHERE ...;
```

#### Example: rewriting the derived table as a CTE

```sql
WITH artist_counts AS (
    SELECT ar.name AS artist, COUNT(*) AS album_count
    FROM artists ar
    JOIN albums al ON ar.id = al.artist_id
    GROUP BY ar.name
)
SELECT artist, album_count
FROM artist_counts
WHERE album_count >= 3;
```

Same result, but the logic flows top-to-bottom instead of inside-out.

#### Multiple CTEs

You can define several CTEs separated by commas. Later CTEs can reference earlier ones:

```sql
WITH album_sales AS (
    SELECT al.id, al.title, al.price, SUM(s.quantity) AS total_qty
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    GROUP BY al.id, al.title, al.price
),
album_revenue AS (
    SELECT title, total_qty, price * total_qty AS revenue
    FROM album_sales
)
SELECT title, total_qty, revenue
FROM album_revenue
ORDER BY revenue DESC
LIMIT 5;
```

> **CTE vs subquery:** CTEs are generally preferred for readability, especially when the same result set is referenced multiple times or when nesting would be deep. Performance is usually identical — PostgreSQL typically inlines CTEs into the main query.

---

### 5. `CASE WHEN`

`CASE` adds conditional (if/else) logic to queries. There are two forms.

#### Searched CASE (most common)

Evaluates a series of conditions and returns the value for the first one that's true:

```sql
SELECT title, release_year,
    CASE
        WHEN release_year < 1980 THEN 'Classic'
        WHEN release_year < 2000 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM albums
ORDER BY release_year;
```

```
                 title                 | release_year |   era
---------------------------------------+--------------+---------
 Blue Train                            |         1958 | Classic
 Kind of Blue                          |         1959 | Classic
 ...
 Let's Dance                           |         1983 | Modern
 Legend                                |         1984 | Modern
 ...
 Kid A                                 |         2000 | Recent
 Discovery                             |         2001 | Recent
 ...
(31 rows)
```

Conditions are evaluated top to bottom. The first match wins — so an album from 1990 matches `WHEN release_year < 2000` and gets 'Modern', never reaching `ELSE`.

#### Simple CASE

Compares a single expression against values:

```sql
SELECT g.name,
    CASE g.name
        WHEN 'Rock'  THEN 'Popular'
        WHEN 'Pop'   THEN 'Popular'
        WHEN 'Jazz'  THEN 'Niche'
        ELSE 'Other'
    END AS category
FROM genres g;
```

The searched form is more flexible (it can test different columns and use ranges), so it's used more often in practice.

#### CASE in aggregation

`CASE` is powerful inside aggregate functions:

```sql
-- Count albums per era in a single row
SELECT
    COUNT(CASE WHEN release_year < 1980 THEN 1 END) AS classic,
    COUNT(CASE WHEN release_year BETWEEN 1980 AND 1999 THEN 1 END) AS modern,
    COUNT(CASE WHEN release_year >= 2000 THEN 1 END) AS recent
FROM albums;
```

```
 classic | modern | recent
---------+--------+--------
      17 |      7 |      7
```

---

### 6. `COALESCE`

`COALESCE` returns the **first non-NULL argument**. It's the standard way to provide a fallback value for NULLs.

```sql
-- Replace NULL price with 0 for calculations
SELECT title, COALESCE(price, 0) AS price
FROM albums
WHERE price IS NULL OR price < 20
ORDER BY price;
```

```
    title    | price
-------------+-------
 Currents    |  0.00
 DAMN.       |  0.00
 Let's Dance | 17.99
 ...
```

#### COALESCE with display formatting

To show a text placeholder for NULLs, combine with `CAST`:

```sql
SELECT title, COALESCE(CAST(price AS TEXT), 'N/A') AS price_display
FROM albums
ORDER BY title;
```

Currents and DAMN. display `N/A` instead of a blank.

#### Multiple arguments

`COALESCE` can take any number of arguments. It returns the first non-NULL one:

```sql
SELECT COALESCE(NULL, NULL, 'fallback');  -- 'fallback'
SELECT COALESCE(NULL, 42, 99);           -- 42
```

---

### 7. Key string and date functions

#### String functions

| Function | Purpose | Example | Result |
|----------|---------|---------|--------|
| `UPPER(s)` | Uppercase | `UPPER('hello')` | `HELLO` |
| `LOWER(s)` | Lowercase | `LOWER('Hello')` | `hello` |
| `LENGTH(s)` | Character count | `LENGTH('hello')` | `5` |
| `TRIM(s)` | Remove leading/trailing whitespace | `TRIM('  hi  ')` | `hi` |
| `SUBSTRING(s FROM n FOR len)` | Extract part of a string | `SUBSTRING('hello' FROM 2 FOR 3)` | `ell` |
| `CONCAT(a, b, ...)` | Concatenate (NULL-safe) | `CONCAT('a', NULL, 'b')` | `ab` |
| `\|\|` | Concatenate (NULL propagates) | `'a' \|\| NULL \|\| 'b'` | `NULL` |

The key difference between `CONCAT` and `||`: **`CONCAT` treats NULL as an empty string**, while `||` propagates NULL (any `NULL` makes the whole result `NULL`).

```sql
SELECT
    title,
    UPPER(title) AS upper_title,
    LENGTH(title) AS title_length
FROM albums
ORDER BY title_length DESC
LIMIT 3;
```

```
                 title                 |              upper_title              | title_length
---------------------------------------+---------------------------------------+--------------
 Sgt. Pepper's Lonely Hearts Club Band | SGT. PEPPER'S LONELY HEARTS CLUB BAND |           37
 The Rise and Fall of Ziggy Stardust   | THE RISE AND FALL OF ZIGGY STARDUST   |           35
 The Dark Side of the Moon             | THE DARK SIDE OF THE MOON             |           25
```

#### Date functions

| Function | Purpose | Example | Result |
|----------|---------|---------|--------|
| `EXTRACT(field FROM date)` | Pull out a part of a date | `EXTRACT(YEAR FROM DATE '2024-03-15')` | `2024` |
| `date_trunc(field, date)` | Truncate to a precision | `date_trunc('month', DATE '2024-03-15')` | `2024-03-01` |
| `NOW()` | Current date and time | `NOW()` | *(current timestamp)* |
| `CURRENT_DATE` | Current date (no time) | `CURRENT_DATE` | *(today's date)* |
| `AGE(timestamp)` | Interval from a date to now | `AGE(DATE '2024-01-15')` | *(interval)* |

```sql
-- Count sales per year
SELECT
    EXTRACT(YEAR FROM sale_date)::INTEGER AS sale_year,
    COUNT(*) AS num_sales,
    SUM(quantity) AS total_qty
FROM sales
GROUP BY sale_year
ORDER BY sale_year;
```

```
 sale_year | num_sales | total_qty
-----------+-----------+-----------
      2024 |        35 |        46
      2025 |         4 |         4
```

> **Note:** `EXTRACT` returns a `NUMERIC` type. The `::INTEGER` cast is optional but gives cleaner output.

---

### 8. `LIKE` / `ILIKE`

Pattern matching with two wildcards:
- `%` — matches any sequence of characters (including empty).
- `_` — matches exactly one character.

| Pattern | Matches | Doesn't match |
|---------|---------|---------------|
| `'A%'` | Alice, Abbey Road, A | Bob |
| `'%love%'` | A Love Supreme, Loveless | Above |
| `'_i%'` | Pink Floyd, Discovery | Animals (A is not one char before i) |
| `'The %'` | The Wall, The Beatles | They |

#### `LIKE` (case-sensitive)

```sql
SELECT title FROM albums WHERE title LIKE 'The %' ORDER BY title;
```

```
             title
-------------------------------
 The Dark Side of the Moon
 The Rise and Fall of Ziggy Stardust
 The Wall
```

#### `ILIKE` (case-insensitive, PostgreSQL extension)

```sql
SELECT title FROM albums WHERE title ILIKE '%love%';
```

```
     title
----------------
 A Love Supreme
```

`ILIKE` is a PostgreSQL extension. In standard SQL, you'd use `LOWER(title) LIKE '%love%'` for case-insensitive matching.

> **Performance note:** `LIKE` and `ILIKE` with a leading `%` (e.g. `'%love%'`) cannot use a standard B-tree index — the database must scan every row. For large tables, consider a trigram index (`pg_trgm` extension) or full-text search.

---

## Exercises

See [`exercises.sql`](exercises.sql) -- 10 queries exploring subqueries, CTEs, and functions.

After you've attempted each exercise, check your work against [`solutions.sql`](solutions.sql).

---

## Quiz

Test your understanding after completing the exercises. Try to answer each question before expanding the answer.

**1. What is the difference between a correlated and a non-correlated subquery?**

<details><summary>Answer</summary>

A **non-correlated** subquery is independent — it runs once and its result is used by the outer query. A **correlated** subquery references a column from the outer query, so it is re-evaluated for each outer row.

</details>

**2. Rewrite this subquery as a CTE: `SELECT * FROM albums WHERE price > (SELECT AVG(price) FROM albums)`**

<details><summary>Answer</summary>

```sql
WITH avg_price AS (
    SELECT AVG(price) AS val FROM albums
)
SELECT al.*
FROM albums al, avg_price
WHERE al.price > avg_price.val;
```

Or using a cross join explicitly:

```sql
WITH avg_price AS (
    SELECT AVG(price) AS val FROM albums
)
SELECT al.*
FROM albums al
CROSS JOIN avg_price
WHERE al.price > avg_price.val;
```

</details>

**3. What does `COALESCE(price, 0)` return when price is NULL? When price is 19.99?**

<details><summary>Answer</summary>

When `price` is NULL: returns `0` (the first non-NULL argument). When `price` is 19.99: returns `19.99` (it's already non-NULL, so the fallback is never reached).

</details>

**4. Write a CASE expression to categorise albums as 'Classic' (pre-1980), 'Modern' (1980-1999), or 'Recent' (2000+).**

<details><summary>Answer</summary>

```sql
CASE
    WHEN release_year < 1980 THEN 'Classic'
    WHEN release_year < 2000 THEN 'Modern'
    ELSE 'Recent'
END
```

</details>

**5. What is the difference between `LIKE 'A%'` and `LIKE '_A%'`?**

<details><summary>Answer</summary>

`LIKE 'A%'` matches strings that **start with** A. `LIKE '_A%'` matches strings where A is the **second character** (the `_` matches exactly one character in the first position).

</details>

**6. Can a CTE reference another CTE defined earlier in the same WITH clause?**

<details><summary>Answer</summary>

Yes. CTEs in the same `WITH` clause are evaluated in order, and later CTEs can reference earlier ones. This is one of the key advantages of CTEs over subqueries.

</details>

**7. What does `EXTRACT(YEAR FROM sale_date)` return?**

<details><summary>Answer</summary>

The year component of the date as a number. For example, if `sale_date` is `2024-03-15`, it returns `2024`.

</details>

**8. Write a query using EXISTS to find artists who have at least one sale.**

<details><summary>Answer</summary>

```sql
SELECT ar.name
FROM artists ar
WHERE EXISTS (
    SELECT 1
    FROM albums al
    JOIN sales s ON al.id = s.album_id
    WHERE al.artist_id = ar.id
);
```

</details>

**9. What is the difference between `CONCAT('a', NULL, 'b')` and `'a' || NULL || 'b'`?**

<details><summary>Answer</summary>

`CONCAT('a', NULL, 'b')` returns `'ab'` — it treats NULL as an empty string. `'a' || NULL || 'b'` returns `NULL` — the `||` operator propagates NULL (any NULL operand makes the result NULL).

</details>

**10. When would you choose a CTE over a subquery?**

<details><summary>Answer</summary>

CTEs are preferred when: (1) the query would otherwise be deeply nested, (2) you need to reference the same result set more than once, or (3) you want top-to-bottom readability. Subqueries are fine for simple, one-off filters. Performance is usually the same.

</details>
