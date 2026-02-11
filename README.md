# SQL Fast-Track

A hands-on, self-contained SQL course built around a single progressive project: **The Record Shop**.

**Philosophy:** 80/20 rule -- focus on the 20% of SQL that covers 80% of real-world use.

**Estimated effort:** ~15-20 hours across 5 modules (self-paced).

---

## Why Docker Compose?

This course uses a real PostgreSQL database running inside a Docker container. That means:

- **Zero installation of PostgreSQL** -- no system packages, no version conflicts, no configuring `pg_hba.conf`. Docker handles all of it.
- **Identical environment everywhere** -- the same database version, schema, and sample data on every machine, regardless of OS.
- **Disposable and repeatable** -- if you break the data while experimenting, one command resets everything to a clean slate. No consequences for mistakes, which is exactly what you want when learning.
- **Nothing touches your system** -- the database runs in an isolated container. When you're done with the course, `docker compose down -v` removes everything cleanly.

---

## Installing Docker

You need Docker Engine and the Docker Compose plugin (v2). The `docker compose` command (without a hyphen) should work after installation.

### Ubuntu

```bash
# Remove any old versions
sudo apt-get remove docker docker-engine docker.io containerd runc 2>/dev/null

# Install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key and repository
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine + Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Let your user run Docker without sudo
sudo usermod -aG docker $USER
```

Log out and back in (or run `newgrp docker`) for the group change to take effect, then verify:

```bash
docker compose version
```

### Fedora

```bash
# Add Docker's official repository
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker Engine + Compose plugin
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Let your user run Docker without sudo
sudo usermod -aG docker $USER
```

Log out and back in, then verify:

```bash
docker compose version
```

### macOS / Windows

Install [Docker Desktop](https://docs.docker.com/get-docker/), which includes Docker Engine and the Compose plugin. No additional setup needed.

---

## Quick start

```bash
# Clone the repo and enter the directory
git clone git@github.com:nunogt/sql-fast-track.git
cd sql-fast-track

# Start the PostgreSQL database (runs in the background)
docker compose up -d

# Connect with psql
docker compose exec db psql -U learner record_shop

# When you're done for the day
docker compose down

# If you need to reset the database to its original state
docker compose down -v && docker compose up -d
```

### Shell alias

You'll run the `psql` connection command frequently. Save yourself some typing by adding an alias to your shell configuration:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias recordshop='docker compose exec db psql -U learner record_shop'
```

Then reload your shell (`source ~/.bashrc` or `source ~/.zshrc`) and connect with:

```bash
recordshop
```

You can also run one-off queries without entering the interactive shell:

```bash
recordshop -c "SELECT COUNT(*) FROM albums;"
```

---

## GUI alternatives

The `psql` command line is fast and always available inside the container, but if you prefer a graphical interface, any PostgreSQL-compatible GUI can connect to the database while the container is running.

| Tool | Platform | Notes |
|------|----------|-------|
| [DBeaver](https://dbeaver.io/) | Linux, macOS, Windows | Free, open-source, supports many databases. Good all-rounder. |
| [pgAdmin](https://www.pgadmin.org/) | Linux, macOS, Windows (also web) | The official PostgreSQL GUI. Feature-rich but heavier. |
| [DataGrip](https://www.jetbrains.com/datagrip/) | Linux, macOS, Windows | JetBrains commercial tool. Excellent autocompletion and refactoring. Free for students. |

**Connection settings** (same for all tools):

| Setting | Value |
|---------|-------|
| Host | `localhost` |
| Port | `5432` |
| Database | `record_shop` |
| Username | `learner` |
| Password | `learner` |

---

## Modules

| # | Module | Focus |
|---|--------|-------|
| 1 | [Foundations](01-foundations/) | SELECT, WHERE, ORDER BY, LIMIT |
| 2 | [Joins](02-joins/) | INNER JOIN, LEFT JOIN, table relationships |
| 3 | [Aggregation](03-aggregation/) | GROUP BY, HAVING, COUNT/SUM/AVG |
| 4 | [Subqueries, CTEs & Functions](04-subqueries-ctes-functions/) | Subqueries, WITH, CASE, string/date functions |
| 5 | [Modification, DDL & Extras](05-modification-ddl-extras/) | INSERT/UPDATE/DELETE, CREATE TABLE, window functions |

Each module contains:
- `README.md` -- concepts, worked examples, and a quiz with answers
- `exercises.sql` -- hands-on challenges against the Record Shop database
- `solutions.sql` -- reference solutions (try the exercises first!)

---

## Additional resources

- [Cheat sheet](cheatsheet.md) -- condensed reference covering all key concepts and common patterns
