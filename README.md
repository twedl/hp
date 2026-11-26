# hp

`head` for parquet files. It's a thin wrapper around the
[duckdb CLI](https://duckdb.org/docs/stable/clients/cli/overview) that runs
`duckdb -c "FROM read_parquet(...)"` on a file, a hive-partitioned folder,
or a glob.

```
$ hp data/raw
┌─────────┬─────────────────────┬───────────┬───┬─────────┬─────────┐
│ trip_id │      pickup_at      │   zone    │ … │ driver  │ ratings │
│  int64  │      timestamp      │  varchar  │ … │ varchar │ int64[] │
├─────────┼─────────────────────┼───────────┼───┼─────────┼─────────┤
│       0 │ 2023-01-01 06:00:00 │ downtown  │ … │ NULL    │ [1, 1]  │
│       1 │ 2023-01-01 06:10:00 │ harbour   │ … │ D-031   │ [2, 2]  │
│       2 │ 2023-01-01 06:20:00 │ west side │ … │ D-062   │ [3, 3]  │
│       3 │ 2023-01-01 06:30:00 │ airport   │ … │ D-093   │ [1, 4]  │
│       4 │ 2023-01-01 06:40:00 │ north end │ … │ D-124   │ [2, 5]  │
│       5 │ 2023-01-01 06:50:00 │ downtown  │ … │ D-155   │ [3, 1]  │
│       6 │ 2023-01-01 07:00:00 │ harbour   │ … │ NULL    │ [1, 2]  │
│       7 │ 2023-01-01 07:10:00 │ west side │ … │ D-217   │ [2, 3]  │
│       8 │ 2023-01-01 07:20:00 │ airport   │ … │ D-248   │ [3, 4]  │
│       9 │ 2023-01-01 07:30:00 │ north end │ … │ D-279   │ [1, 5]  │
│       · │          ·          │    ·      │ … │ ·       │   ·     │
│       · │          ·          │    ·      │ … │ ·       │   ·     │
│       · │          ·          │    ·      │ … │ ·       │   ·     │
│  149990 │ 2025-12-14 09:40:00 │ downtown  │ … │ D-790   │ [2, 1]  │
│  149991 │ 2025-12-14 09:50:00 │ harbour   │ … │ D-821   │ [3, 2]  │
│  149992 │ 2025-12-14 10:00:00 │ west side │ … │ NULL    │ [1, 3]  │
│  149993 │ 2025-12-14 10:10:00 │ airport   │ … │ D-883   │ [2, 4]  │
│  149994 │ 2025-12-14 10:20:00 │ north end │ … │ D-014   │ [3, 5]  │
│  149995 │ 2025-12-14 10:30:00 │ downtown  │ … │ D-045   │ [1, 1]  │
│  149996 │ 2025-12-14 10:40:00 │ harbour   │ … │ D-076   │ [2, 2]  │
│  149997 │ 2025-12-14 10:50:00 │ west side │ … │ D-107   │ [3, 3]  │
│  149998 │ 2025-12-14 11:00:00 │ airport   │ … │ NULL    │ [1, 4]  │
│  149999 │ 2025-12-14 11:10:00 │ north end │ … │ D-169   │ [2, 5]  │
└─────────┴─────────────────────┴───────────┴───┴─────────┴─────────┘
  150000 rows (20 shown)                       10 columns (5 shown)

$ hp --glimpse data/raw
Rows: 150000
Columns: 10
$ trip_id     <BIGINT> 0, 1, 2, 3, 4
$ pickup_at   <TIMESTAMP> 2023-01-01 06:00:00, 2023-01-01 06:10:00, 202…
$ zone        <VARCHAR> downtown, harbour, west side, airport, north end
$ fare        <DECIMAL(8,2)> 5.00, 5.37, 5.74, 6.11, 6.48
$ tipped      <BOOLEAN> true, false, false, false, false
$ passengers  <BIGINT> 1, 4, 3, 2, 1
$ payment     <VARCHAR> card, cash, app, card, cash
$ distance_km <DOUBLE> 0.5, 2.2, 3.9, 5.6, 7.3
$ driver      <VARCHAR> NULL, D-031, D-062, D-093, D-124
$ ratings     <BIGINT[]> [1, 1], [2, 2], [3, 3], [1, 4], [2, 5]
```

## Usage

```
hp [options] PATH...

  -n N         show the first N rows (default: the first 10 and last 10;
               with --glimpse, 5 values per column)
  --glimpse    one line per column: name, type, first values
  --all        show every column instead of collapsing the middle ones
  --partition  show hive partition columns (hidden by default)
```

`PATH` can be a parquet file, a folder (read as `FOLDER/**/*.parquet`), or a
glob. Quote a glob so duckdb expands it rather than your shell, e.g.
`hp 'data/raw/year=2024/*.parquet'`. Several paths are read as one dataset.
`~/.duckdbrc` is ignored.

Without `-n`, duckdb reads the whole dataset to find the last rows. On a big
dataset, use `-n`, which only reads the first rows.

## Install

You need duckdb v2.0.0 or newer (`brew install duckdb`). Then put the script
on your `PATH`:

```sh
ln -s "$PWD/hp" ~/.local/bin/hp
```

## Tests

```sh
tests/run.sh            # compare output with tests/expected/
tests/run.sh --update   # accept the current output
```
