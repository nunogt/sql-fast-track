# Module 2 -- Joins & Relationships

**Goal:** Understand table relationships and combine data from multiple tables.

**Estimated time:** 3-4 hours

**Prerequisites:** Module 1 (SELECT, WHERE, ORDER BY).

---

## Topics

### 1. Foreign keys and table relationships

In Module 1, every query used a single table. But the Record Shop data is split across four tables. **Foreign keys** are the links between them.

A foreign key is a column in one table that references the primary key of another table. It says: "this value must exist over there."

#### Record Shop relationships

```
artists             albums                         sales
──────────          ──────────────────────         ──────────
id (PK) ◄────────  artist_id (FK)                 id (PK)
name                id (PK) ◄───────────────────  album_id (FK)
country             title                          quantity
                    genre_id (FK) ──────────►      sale_date
                    release_year          genres
                    price                 ──────────
                                          id (PK)
                                          name
```

- Every album **must** have an `artist_id` that exists in `artists.id` (NOT NULL + FK).
- Every album **may** have a `genre_id` that exists in `genres.id` (nullable FK — some albums don't have a genre assigned yet).
- Every sale **must** have an `album_id` that exists in `albums.id`.

#### Relationship types

| Type | Meaning | Example |
|------|---------|---------|
| One-to-many | One row in table A relates to many rows in table B | One artist has many albums |
| Many-to-one | The reverse perspective of one-to-many | Many albums belong to one artist |
| Many-to-many | Rows in A relate to many in B and vice versa | (Not in our schema, but common with junction tables) |

All three relationships in the Record Shop are **one-to-many**: one artist → many albums, one genre → many albums, one album → many sales.

#### Why not put everything in one table?

You could store the artist name directly in the albums table, but then:

- **Redundancy:** "Pink Floyd" would be repeated for every album. If you need to fix a typo, you'd have to update many rows.
- **Inconsistency:** One row might say "Pink Floyd" and another "pink floyd".
- **Wasted space:** The same string stored over and over.

Splitting data into related tables and linking them with foreign keys is called **normalisation**. Joins let you recombine the data at query time.

---

### 2. `INNER JOIN`

`INNER JOIN` returns only the rows where there is a match in **both** tables. Rows with no match are excluded from the result.

#### Syntax

```sql
SELECT columns
FROM table_a
INNER JOIN table_b ON table_a.column = table_b.column;
```

The `ON` clause specifies how the tables relate — almost always matching a foreign key to a primary key.

#### Example: albums with artist names

```sql
SELECT al.title, ar.name AS artist
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id
ORDER BY al.id;
```

```
               title                |     artist
------------------------------------+----------------
 The Dark Side of the Moon          | Pink Floyd
 Wish You Were Here                 | Pink Floyd
 The Wall                           | Pink Floyd
 Animals                            | Pink Floyd
 Kind of Blue                       | Miles Davis
 Bitches Brew                       | Miles Davis
 OK Computer                        | Radiohead
 ...
(31 rows)
```

Every album has a non-NULL `artist_id`, so all 31 albums appear. But Adele (an artist with no albums) does **not** appear — there are no matching rows in `albums` for her.

#### What happens to unmatched rows?

They disappear. `INNER JOIN` is strict: **no match, no row**. This is the key difference from `LEFT JOIN`.

#### Joining more than two tables

Chain multiple `JOIN` clauses to combine three or more tables:

```sql
SELECT al.title, ar.name AS artist, g.name AS genre
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id
INNER JOIN genres g  ON al.genre_id  = g.id
ORDER BY al.id;
```

```
               title                |     artist      | genre
------------------------------------+-----------------+------------
 The Dark Side of the Moon          | Pink Floyd      | Rock
 Wish You Were Here                 | Pink Floyd      | Rock
 The Wall                           | Pink Floyd      | Rock
 ...
 A Love Supreme                     | John Coltrane   | Jazz
 Blue Train                         | John Coltrane   | Jazz
(30 rows)
```

Notice: **30 rows**, not 31. Currents has `genre_id = NULL`, so the join to `genres` finds no match, and `INNER JOIN` drops it.

> **Tip:** `INNER JOIN` and `JOIN` are synonyms. The `INNER` keyword is optional, but including it makes your intent clear.

---

### 3. `LEFT JOIN` / `RIGHT JOIN`

#### `LEFT JOIN` (LEFT OUTER JOIN)

`LEFT JOIN` returns **all rows from the left table**, plus matching rows from the right table. Where there is no match, the right-side columns are filled with `NULL`.

#### Syntax

```sql
SELECT columns
FROM left_table
LEFT JOIN right_table ON left_table.col = right_table.col;
```

#### Example: all artists, even those with no albums

```sql
SELECT ar.name, al.title
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
ORDER BY ar.name;
```

```
      name       |               title
-----------------+------------------------------------
 Adele           |
 Amy Winehouse   | Back to Black
 Björk           | Homogenic
 Björk           | Post
 Bob Marley      | Legend
 ...
 Pink Floyd      | The Dark Side of the Moon
 Pink Floyd      | Wish You Were Here
 Pink Floyd      | The Wall
 Pink Floyd      | Animals
 ...
(32 rows)
```

Adele appears with `NULL` in the title column — she has no albums, but `LEFT JOIN` keeps her.

#### Finding rows with no match

A common pattern: use `LEFT JOIN` + `WHERE ... IS NULL` to find rows that **don't** have a match:

```sql
-- Artists who have no albums
SELECT ar.name
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
WHERE al.id IS NULL;
```

```
 name
-------
 Adele
(1 row)
```

How it works:
1. `LEFT JOIN` produces a row for every artist. For Adele, all `albums` columns are NULL.
2. `WHERE al.id IS NULL` keeps only the rows where the join found no match.

This is one of the most useful patterns in SQL.

#### `ON` vs `WHERE` in a LEFT JOIN

This distinction matters:

- Conditions in `ON` control **how rows are matched** during the join. Non-matching right-side rows become NULLs.
- Conditions in `WHERE` filter **after the join** — they can eliminate rows entirely.

```sql
-- ON: shows all artists, but only matches Rock albums (genre_id = 1)
SELECT ar.name, al.title
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id AND al.genre_id = 1
WHERE al.id IS NULL;
-- Returns artists who have no Rock albums (many artists)

-- WHERE: joins all albums, then filters to Rock — non-Rock artists disappear
SELECT ar.name, al.title
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
WHERE al.genre_id = 1;
-- Returns only artists who HAVE Rock albums
```

Rule of thumb: if you want to **preserve** all left-side rows, put the filter in `ON`. If you want to **eliminate** non-matching rows, put it in `WHERE`.

#### `RIGHT JOIN`

`RIGHT JOIN` is the mirror of `LEFT JOIN` — it keeps all rows from the **right** table. In practice, most people rewrite `RIGHT JOIN` as `LEFT JOIN` by swapping the table order, since it reads more naturally (left-to-right).

```sql
-- These two queries produce identical results:

-- Using RIGHT JOIN
SELECT ar.name, al.title
FROM albums al
RIGHT JOIN artists ar ON al.artist_id = ar.id;

-- Equivalent LEFT JOIN (more common)
SELECT ar.name, al.title
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id;
```

---

### 4. `CROSS JOIN`

`CROSS JOIN` produces the **Cartesian product**: every row from table A paired with every row from table B. No `ON` clause is needed.

```sql
SELECT ar.name, g.name AS genre
FROM artists ar
CROSS JOIN genres g
ORDER BY ar.name, g.name;
```

With 16 artists and 8 genres, this produces **128 rows** (16 × 8) — every possible artist-genre combination.

`CROSS JOIN` is rarely used in practice, but it's important to understand because:
1. It's what happens when you accidentally omit the `ON` clause.
2. It's useful for generating combinations (e.g. a report template with every possible category).

> **Warning:** Cross-joining large tables can produce enormous result sets. Two 10,000-row tables would produce 100,000,000 rows.

---

### 5. Self-joins

A self-join joins a table to **itself**. You must use table aliases so that SQL can distinguish between the two "copies" of the table.

#### Example: artists from the same country

```sql
SELECT
    a1.name AS artist_1,
    a2.name AS artist_2,
    a1.country
FROM artists a1
JOIN artists a2
    ON  a1.country = a2.country
    AND a1.id < a2.id          -- avoid pairing an artist with itself
ORDER BY a1.country, a1.name;
```

```
   artist_1    |   artist_2    | country
---------------+---------------+---------
 Daft Punk     | Kraftwerk     | ...
 Miles Davis   | Kendrick Lamar| US
 Miles Davis   | Nina Simone   | US
 ...
 Pink Floyd    | Radiohead     | UK
 Pink Floyd    | David Bowie   | UK
 Pink Floyd    | The Beatles   | UK
 ...
```

The `a1.id < a2.id` condition is essential — without it you'd get both `(Pink Floyd, Radiohead)` and `(Radiohead, Pink Floyd)`, plus `(Pink Floyd, Pink Floyd)`.

Self-joins are useful whenever you need to compare rows within the same table: finding duplicates, hierarchical data (employee → manager), or as shown above, finding related entries.

---

### 6. Table aliases

As joins grow to involve multiple tables, fully-qualified names get verbose. Table aliases keep things readable.

#### Without aliases

```sql
SELECT albums.title, artists.name, genres.name
FROM albums
INNER JOIN artists ON albums.artist_id = artists.id
INNER JOIN genres  ON albums.genre_id  = genres.id;
```

#### With aliases

```sql
SELECT al.title, ar.name AS artist, g.name AS genre
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id
INNER JOIN genres g   ON al.genre_id  = g.id;
```

Common conventions:
- Use short, consistent abbreviations: `al` for albums, `ar` for artists, `g` for genres, `s` for sales.
- Define the alias right after the table name in the `FROM` or `JOIN` clause.
- Once you define an alias, you **must** use it — you can no longer refer to the table by its full name in that query.

---

## Exercises

See [`exercises.sql`](exercises.sql) -- 10 queries that combine data across the Record Shop tables.

After you've attempted each exercise, check your work against [`solutions.sql`](solutions.sql).

---

## Quiz

Test your understanding after completing the exercises. Try to answer each question before expanding the answer.

**1. What is a foreign key, and what does it enforce?**

<details><summary>Answer</summary>

A foreign key is a column that references the primary key of another table. It enforces **referential integrity**: you cannot insert a value that doesn't exist in the referenced table, and you cannot delete a referenced row without first handling the dependent rows.

</details>

**2. What is the difference between `INNER JOIN` and `LEFT JOIN`?**

<details><summary>Answer</summary>

`INNER JOIN` returns only rows with a match in **both** tables — unmatched rows are excluded. `LEFT JOIN` returns **all** rows from the left table, filling in NULLs for right-side columns where there is no match.

</details>

**3. If table A has 3 rows and table B has 4 rows, how many rows does a `CROSS JOIN` produce?**

<details><summary>Answer</summary>

12 rows (3 × 4). A cross join produces the Cartesian product — every combination of rows from both tables.

</details>

**4. Write a query to list all albums with their artist name using an INNER JOIN.**

<details><summary>Answer</summary>

```sql
SELECT al.title, ar.name AS artist
FROM albums al
INNER JOIN artists ar ON al.artist_id = ar.id;
```

</details>

**5. How would you find artists who have no albums in the database?**

<details><summary>Answer</summary>

```sql
SELECT ar.name
FROM artists ar
LEFT JOIN albums al ON ar.id = al.artist_id
WHERE al.id IS NULL;
```

Use `LEFT JOIN` to keep all artists, then filter for rows where the join found no match (`al.id IS NULL`).

</details>

**6. What happens to unmatched rows in an `INNER JOIN`?**

<details><summary>Answer</summary>

They are excluded from the result. If a row in the left table has no matching row in the right table (or vice versa), it does not appear in the output.

</details>

**7. Can you join more than two tables in a single query? How?**

<details><summary>Answer</summary>

Yes. Chain multiple `JOIN` clauses:

```sql
SELECT al.title, ar.name, g.name
FROM albums al
JOIN artists ar ON al.artist_id = ar.id
JOIN genres g  ON al.genre_id  = g.id;
```

Each `JOIN` adds another table to the result. You can join as many tables as needed.

</details>

**8. What is a self-join and when would you use one?**

<details><summary>Answer</summary>

A self-join joins a table to itself using aliases to distinguish the two copies. It's useful when you need to compare rows within the same table — for example, finding artists from the same country, or modelling hierarchies (employee → manager).

</details>

**9. Rewrite this implicit join using explicit JOIN syntax: `SELECT * FROM a, b WHERE a.id = b.a_id`**

<details><summary>Answer</summary>

```sql
SELECT *
FROM a
INNER JOIN b ON a.id = b.a_id;
```

The comma syntax (`FROM a, b`) is an older style that produces a cross join, then filters with `WHERE`. The explicit `JOIN ... ON` syntax is clearer and preferred.

</details>

**10. What is the difference between `ON` and `WHERE` in a LEFT JOIN?**

<details><summary>Answer</summary>

`ON` controls **how rows are matched** during the join. Unmatched right-side rows still appear as NULLs. `WHERE` filters **after** the join — it can eliminate rows entirely, potentially negating the LEFT JOIN's effect. To preserve all left-side rows while filtering the right side, put the filter condition in `ON`.

</details>
