# hp

`head` for parquet files. Point it at a parquet file, a hive-partitioned
folder, or a glob, and it prints the first and last rows. Reading and
drawing are done by the [duckdb CLI](https://duckdb.org/docs/stable/clients/cli/overview).

```
$ hp data/raw
┌─────────┬─────────────────────┬───────────┬───┬─────────────┬─────────┬───────────┐
│ trip_id │      pickup_at      │   zone    │ … │ distance_km │ driver  │  ratings  │
│   i64   │    datetime[μs]     │    str    │ … │     f64     │   str   │ list[i64] │
├─────────┼─────────────────────┼───────────┼───┼─────────────┼─────────┼───────────┤
│       0 │ 2023-01-01 06:00:00 │ downtown  │ … │         0.5 │ NULL    │ [1, 1]    │
│       1 │ 2023-01-01 06:10:00 │ harbour   │ … │         2.2 │ D-031   │ [2, 2]    │
│       2 │ 2023-01-01 06:20:00 │ west side │ … │         3.9 │ D-062   │ [3, 3]    │
│       3 │ 2023-01-01 06:30:00 │ airport   │ … │         5.6 │ D-093   │ [1, 4]    │
│       4 │ 2023-01-01 06:40:00 │ north end │ … │         7.3 │ D-124   │ [2, 5]    │
│       5 │ 2023-01-01 06:50:00 │ downtown  │ … │         9.0 │ D-155   │ [3, 1]    │
│       6 │ 2023-01-01 07:00:00 │ harbour   │ … │        10.7 │ NULL    │ [1, 2]    │
│       7 │ 2023-01-01 07:10:00 │ west side │ … │        12.4 │ D-217   │ [2, 3]    │
│       8 │ 2023-01-01 07:20:00 │ airport   │ … │        14.1 │ D-248   │ [3, 4]    │
│       9 │ 2023-01-01 07:30:00 │ north end │ … │        15.8 │ D-279   │ [1, 5]    │
│       · │          ·          │    ·      │ … │           · │   ·     │   ·       │
│       · │          ·          │    ·      │ … │           · │   ·     │   ·       │
│       · │          ·          │    ·      │ … │           · │   ·     │   ·       │
│  149990 │ 2025-12-14 09:40:00 │ downtown  │ … │        23.5 │ D-790   │ [2, 1]    │
│  149991 │ 2025-12-14 09:50:00 │ harbour   │ … │        25.2 │ D-821   │ [3, 2]    │
│  149992 │ 2025-12-14 10:00:00 │ west side │ … │        26.9 │ NULL    │ [1, 3]    │
│  149993 │ 2025-12-14 10:10:00 │ airport   │ … │        28.6 │ D-883   │ [2, 4]    │
│  149994 │ 2025-12-14 10:20:00 │ north end │ … │        30.3 │ D-014   │ [3, 5]    │
│  149995 │ 2025-12-14 10:30:00 │ downtown  │ … │         2.0 │ D-045   │ [1, 1]    │
│  149996 │ 2025-12-14 10:40:00 │ harbour   │ … │         3.7 │ D-076   │ [2, 2]    │
│  149997 │ 2025-12-14 10:50:00 │ west side │ … │         5.4 │ D-107   │ [3, 3]    │
│  149998 │ 2025-12-14 11:00:00 │ airport   │ … │         7.1 │ NULL    │ [1, 4]    │
│  149999 │ 2025-12-14 11:10:00 │ north end │ … │         8.8 │ D-169   │ [2, 5]    │
└─────────┴─────────────────────┴───────────┴───┴─────────────┴─────────┴───────────┘
  150000 rows (20 shown)                                       10 columns (6 shown)
```

```
$ hp --glimpse --partition data/raw
Rows: 150000
Columns: 11
$ trip_id     <i64>          0, 1, 2, 3, 4
$ pickup_at   <datetime[μs]> 2023-01-01 06:00:00, 2023-01-01 06:10:00, 2023-01-01 06:20:00, 202…
$ zone        <str>          "downtown", "harbour", "west side", "airport", "north end"
$ fare        <decimal[8,2]> 5.00, 5.37, 5.74, 6.11, 6.48
$ tipped      <bool>         true, false, false, false, false
$ passengers  <i64>          1, 4, 3, 2, 1
$ payment     <str>          "card", "cash", "app", "card", "cash"
$ distance_km <f64>          0.5, 2.2, 3.9, 5.6, 7.3
$ driver      <str>          null, "D-031", "D-062", "D-093", "D-124"
$ ratings     <list[i64]>    [1, 1], [2, 2], [3, 3], [1, 4], [2, 5]
$ year        <i64>          2023, 2023, 2023, 2023, 2023
```

## Install

You need duckdb v2.0.0 or newer (`brew install duckdb`) and any POSIX shell.
`hp` is a single script, so put it on your `PATH`:

```sh
ln -s "$PWD/hp" ~/.local/bin/hp
```

## Usage

```
hp [options] PATH...

  -n N           show the first N rows (default: the first 10 and last 10);
                 with --glimpse, show N values per column (default 5)
  --glimpse      one line per column with its type and first values,
                 like dplyr or polars glimpse
  --all          show every column (default: collapse middle columns to …
                 so the table fits the terminal)
  --partition    show hive partition key columns (default: hidden)
  --types STYLE  type names: polars (default) or duckdb
  -h, --help     show this help
```

`PATH` can be:

- a file: `hp trips.parquet`
- a folder, read as `FOLDER/**/*.parquet`: `hp data/raw`
- a glob, quoted so duckdb expands it rather than your shell:
  `hp 'data/raw/year=2024/**/*.parquet'`

Several paths are read as one dataset.

Environment variables:

- `HP_DUCKDB` picks the duckdb binary to run.
- `COLUMNS` sets the output width. By default `hp` uses the terminal's width,
  and when the output is piped it doesn't collapse any columns.

`~/.duckdbrc` is never read.

## How it works

`hp` is a small shell script. It writes one SQL script and runs it in a
single duckdb session (`duckdb -no-init -no-agent`). That session:

1. Gets each file's row count from the parquet footers, without reading any data.
2. Reads the first 10 rows from the first file(s) and the last 10 from the
   last file(s), filtering on file name and row number so duckdb skips every
   other file and row group. With `-n N` it reads only the first N rows.
3. Draws those rows as duckdb's normal table, which collapses middle columns
   and marks the gap with `·` rows.
4. Reads the drawn table back and swaps in polars type names. It also
   rewrites the footer so it shows the dataset's real row count.

On a 60M-row, 2.5 GB dataset, `hp` takes about 0.15 s and 225 MB. A plain
`duckdb -c "FROM 'data/**/*.parquet'"` takes 1.6 s and 2.8 GB, because duckdb
holds the whole result in memory to show its last rows.

Files are read in sorted path order, the same order duckdb uses. "First" and
"last" rows follow that order. Note that a string sort puts `k=10` before
`k=2`.

## Tests

```sh
tests/run.sh            # compare output with tests/expected/
tests/run.sh --update   # accept the current output as expected
```

The fixtures are built with duckdb in a temporary folder. The tests also
check that `hp --types duckdb` draws exactly what plain duckdb draws for the
same data, apart from the footer.
