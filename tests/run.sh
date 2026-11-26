#!/bin/sh
# Golden-output tests for hp.
#
#   tests/run.sh            run the tests
#   tests/run.sh --update   rewrite tests/expected/ from the current output
#
# Fixtures are generated with duckdb into a temp folder. Output is captured at
# COLUMNS=100 in UTC so it doesn't depend on the terminal or time zone.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
hp=$here/../hp
expected=$here/expected
DUCKDB=${HP_DUCKDB:-duckdb}
update=0
[ "${1:-}" = --update ] && update=1

work=$(mktemp -d "${TMPDIR:-/tmp}/hp-test.XXXXXX")
trap 'rm -rf "$work"' EXIT
cd "$work"

# One thread, so partitioned writes keep row order and fixtures are the same
# on every machine.
duck() { "$DUCKDB" -no-init -no-agent -bail -cmd "SET threads = 1" "$@"; }

# 100 rows, 16 columns + 2 hive keys, 4 files of 25 rows.
duck -c "COPY (
    SELECT i AS id, 'name_' || i AS name, i * 1.5 AS value, DATE '2024-01-01' + i::INT AS dt,
           [i, i + 1] AS arr, {'a': i, 'b': 'x'} AS st,
           i % 3 AS c1, i % 5 AS c2, i % 7 AS c3, i % 11 AS c4, 'longish text column ' || i AS c5,
           i % 13 AS c6, i % 17 AS c7, i % 19 AS c8, i % 23 AS c9, i % 29 AS c10,
           (i % 4)::INT AS year, (i % 2)::INT AS region
    FROM range(100) t(i)
) TO 'hive' (FORMAT parquet, PARTITION_BY (year, region))"

# 30 one-row files: the first and last 10 rows each span 10 files.
duck -c "COPY (SELECT range AS id, range AS k FROM range(30)) TO 'tiny' (FORMAT parquet, PARTITION_BY (k))"

# Row counts around the 23-row cutoff, and an empty file.
duck -c "COPY (SELECT range AS id FROM range(23)) TO 'r23.parquet'"
duck -c "COPY (SELECT range AS id FROM range(24)) TO 'r24.parquet'"
duck -c "COPY (SELECT 1 AS id WHERE false) TO 'r0.parquet'"
cp r23.parquet "it's.parquet"
mkdir empty

# One column of each type, for the polars type names.
duck -c "COPY (SELECT
    1::TINYINT a, 1::SMALLINT b, 1::INTEGER c, 1::BIGINT d, 1::UTINYINT f, 1::USMALLINT g,
    1::UINTEGER h, 1::UBIGINT i, 1.5::FLOAT j, 1.5::DOUBLE k, 1.5::DECIMAL(10,2) l, 'x' m,
    true n, 'ab'::BLOB o, DATE '2024-01-01' p, TIME '01:02:03' q,
    TIMESTAMP '2024-01-01 01:02:03' r, TIMESTAMP_MS '2024-01-01' s, TIMESTAMP_NS '2024-01-01' t,
    NULL::TIMESTAMPTZ v, INTERVAL 1 DAY w, '6f1c2a4e-3c1b-4a4e-9b7e-2f8a1d3c4b5a'::UUID x,
    [[1, 2], [3]] y, {'p': {'q': 1, 'r': [1.5::DECIMAL(4,1)]}, 's': 'x'} aa, MAP {'k': 1} bb,
    [{'a': 1, 'b': 2}] cc, NULL::VARCHAR dd, ['a', NULL] ee
) TO 'types.parquet'"

export COLUMNS=100 TZ=UTC
pass=0
fail=0

# check NAME CMD...: run CMD, capture stdout, stderr and exit status, and
# compare with tests/expected/NAME.txt.
check() {
	name=$1
	shift
	set +e
	"$@" >"$work/$name.out" 2>&1
	echo "[exit $?]" >>"$work/$name.out"
	set -e
	if [ "$update" = 1 ]; then
		mkdir -p "$expected"
		cp "$work/$name.out" "$expected/$name.txt"
	elif diff -u "$expected/$name.txt" "$work/$name.out" >"$work/$name.diff" 2>&1; then
		pass=$((pass + 1))
		return
	else
		fail=$((fail + 1))
		echo "FAIL $name"
		cat "$work/$name.diff"
	fi
}

# same_as_duckdb NAME PATH...: hp --types duckdb must print exactly what plain
# duckdb prints (top 10 / bottom 10 at the same width), down to the table's
# bottom border. Only the footer may differ. PATHs must not contain quotes.
same_as_duckdb() {
	name=$1
	shift
	list=
	for p in "$@"; do list="${list:+$list, }'$p'"; done
	"$hp" --types duckdb "$@" | sed '/^└/q' >"$work/$name.hp"
	duck -cmd ".maxrows 20" -cmd ".maxwidth $COLUMNS" \
		-c "FROM read_parquet([$list], hive_partitioning = false)" | sed '/^└/q' >"$work/$name.duckdb"
	if diff -u "$work/$name.duckdb" "$work/$name.hp" >"$work/$name.diff"; then
		pass=$((pass + 1))
	else
		fail=$((fail + 1))
		echo "FAIL $name (hp differs from plain duckdb)"
		cat "$work/$name.diff"
	fi
}

check default "$hp" hive
check partition "$hp" --partition -n 3 hive
check all "$hp" --all -n 2 hive
check types-duckdb "$hp" --types duckdb hive
check glimpse "$hp" --glimpse hive
check glimpse-options "$hp" --glimpse -n 2 --types=duckdb --partition hive
check glimpse-types "$hp" --glimpse types.parquet
check table-types "$hp" -n1 types.parquet
check tiny "$hp" tiny
check rows-23 "$hp" r23.parquet
check rows-24 "$hp" r24.parquet
check rows-0 "$hp" r0.parquet
check n-past-end "$hp" -n 50 r23.parquet
check several-paths "$hp" r24.parquet "it's.parquet"
check glob "$hp" -n 2 'hive/year=1/**/*.parquet'
check no-files "$hp" empty
check missing-file "$hp" nope.parquet
check bad-option "$hp" --bogus hive
check bad-n "$hp" -n x hive
check bad-types "$hp" --types arrow hive
check no-paths "$hp"
check help "$hp" --help

if [ "$update" = 0 ]; then
	same_as_duckdb same-hive 'hive/**/*.parquet'
	same_as_duckdb same-tiny 'tiny/**/*.parquet'
	same_as_duckdb same-order r24.parquet 'tiny/**/*.parquet' r23.parquet
fi

if [ "$update" = 1 ]; then
	echo "updated $expected"
else
	echo "$pass passed, $fail failed"
	[ "$fail" -eq 0 ]
fi
