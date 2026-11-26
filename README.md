# hp

`head` for parquet files, using the
[duckdb CLI](https://duckdb.org/docs/stable/clients/cli/overview).

`hp` shows the first rows of a parquet file, a hive-partitioned folder, or a
glob. With `--glimpse` it shows one row per column instead, with each
column's type and first few values.

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
└─────────┴─────────────────────┴───────────┴───┴─────────┴─────────┘
  10 rows                                      10 columns (5 shown)
```

```
$ hp --glimpse data/raw
┌─────────────┬──────────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│   Column    │     Type     │        Row 1        │        Row 2        │        Row 3        │
├─────────────┼──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ trip_id     │ int64        │                   0 │                   1 │                   2 │
│ pickup_at   │ timestamp    │ 2023-01-01 06:00:00 │ 2023-01-01 06:10:00 │ 2023-01-01 06:20:00 │
│ zone        │ varchar      │            downtown │             harbour │           west side │
│ fare        │ decimal(8,2) │                5.00 │                5.37 │                5.74 │
│ tipped      │ boolean      │                true │               false │               false │
│ passengers  │ int64        │                   1 │                   4 │                   3 │
│ payment     │ varchar      │                card │                cash │                 app │
│ distance_km │ double       │                 0.5 │                 2.2 │                 3.9 │
│ driver      │ varchar      │                NULL │               D-031 │               D-062 │
│ ratings     │ int64[]      │              [1, 1] │              [2, 2] │              [3, 3] │
└─────────────┴──────────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

## Install

### Requirements

- **duckdb 2.0.0 or newer**, as a `duckdb` command on your `PATH`. A shell
  alias won't work, because `hp` is a script and can't see aliases. To
  install duckdb, use `brew install duckdb` or the official installer
  (`curl https://install.duckdb.org | sh`). The installer's output tells you
  how to add duckdb to your `PATH`.
- A POSIX shell (`/bin/sh` on Linux and macOS).

### Option 1: download the script

```sh
mkdir -p ~/.local/bin
curl -fsSL <GITLAB_URL>/-/raw/main/hp -o ~/.local/bin/hp
chmod +x ~/.local/bin/hp
```

To update, run the same `curl` command again. Use the git option below if
the project is private, because it uses your normal GitLab login. Change
`main` if the project's default branch has another name.

### Option 2: clone the repository

```sh
git clone <GITLAB_URL>.git ~/src/hp
mkdir -p ~/.local/bin
ln -s ~/src/hp/hp ~/.local/bin/hp
```

To update, run `git -C ~/src/hp pull`.

### Check that it works

```sh
hp --help
```

If you get `command not found`, `~/.local/bin` isn't on your `PATH`. Add
this line to `~/.bashrc` or `~/.zshrc`, then open a new terminal:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```
hp [OPTION]... PATH...

  -n, --lines=N    show the first N rows (default 10; with --glimpse, N
                   values per column, default 3)
  -g, --glimpse    one line per column: name, type, first values
                   (duckdb's .columns view)
  -a, --all        show every column instead of collapsing the middle ones
  -p, --partition  show hive partition columns (hidden by default)
  -h, --help       show this help

As with head, -N means -n N. Short options can be combined: -gp, -gn3.
```

### Examples

```sh
hp trips.parquet                  # first 10 rows
hp -n 50 trips.parquet            # first 50 rows (or -50, -n50, --lines=50)
hp data/raw                       # a folder, e.g. a hive-partitioned dataset
hp -p data/raw                    # also show partition columns like year
hp 'data/raw/year=2024/*.parquet' # a glob, in quotes
hp jan.parquet feb.parquet        # several files, read as one dataset
hp -g data/raw                    # glimpse: 3 values per column
hp -gn5 data/raw                  # glimpse with 5 values per column
hp data/raw | less -S             # every column; scroll sideways in less
```

### What a PATH can be

- **A file:** `trips.parquet`.
- **A folder:** read as `FOLDER/**/*.parquet`, so files in subfolders are
  included. Files that don't end in `.parquet` are skipped, such as
  `_SUCCESS` or `.crc` files.
- **A glob:** for example `'data/raw/**/*.parquet'`. Put it in quotes so duckdb
  expands it rather than your shell. Unquoted, zsh stops with
  `no matches found` when nothing matches, and bash may pass only some of the
  files.

## How it works

`hp` runs a single duckdb command:

```sh
duckdb -no-init -no-agent -cmd ".rows" -cmd ".maxrows -1" -cmd ".maxwidth 0" \
  -c "FROM read_parquet([PATH, ...], hive_partitioning = false, union_by_name = true) LIMIT 10"
```

`--glimpse` swaps `.rows` for `.columns`, `-p` sets `hive_partitioning` to
`true`, and `-a` raises `.maxwidth`.

### Good to know

- **Which rows are "first":** paths are read in the order you give them, and
  each folder or glob in sorted path order. String sorting puts `k=10`
  before `k=2`.
- **Partition columns are hidden by default.** Values in folder names, such
  as `year=2024`, aren't shown as columns unless you pass `-p`. Columns
  stored inside the files are always shown.
- **Columns that only some files have are still shown.** Files without the
  column show `NULL`. To find all the columns, duckdb reads every file's
  footer.
- **`~/.duckdbrc` is never read.** Its settings don't apply, such as
  `extension_directory` or S3 credentials. Local parquet files don't need
  any of that. Remote paths (`s3://`, `https://`) need duckdb extensions
  and credentials, so they may not work.
- **Narrow terminals:** duckdb collapses the middle columns to `…` to fit
  the table. In `--glimpse` the columns are the values, so the middle values
  collapse instead, and you may see "Row 2, Row 3" without "Row 1". Use `-a`
  to show everything, or `-n` to show fewer values.
- **Pipes and notebooks:** there's no terminal width, so every column is
  printed. Use `less -S` to scroll sideways. In a Jupyter cell (`!hp ...`)
  the output can be very wide.
- **A 5-second pause:** in a terminal, duckdb asks for the background color
  so it can color its output. If your terminal never answers, duckdb waits
  5 seconds and prints a timeout warning. `export NO_COLOR=1` turns that off.

## Development

`hp` is a single file: [`hp`](hp). The tests build small parquet datasets
with duckdb and compare `hp`'s output with the files in `tests/expected/`:

```sh
tests/run.sh            # run the tests
tests/run.sh --update   # accept the current output as expected
```

## License

MIT. See [LICENSE](LICENSE).
