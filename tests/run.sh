#!/bin/sh
# Compare hp's output with tests/expected/. Run with --update to accept the
# current output instead.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

# 100 rows in 4 hive partitions; one thread keeps the files identical everywhere.
duckdb -no-init -no-agent -cmd "SET threads = 1" -c "COPY (
    SELECT i AS id, 'name_' || i AS name, [i, i + 1] AS arr,
           CASE WHEN i % 7 = 0 THEN NULL ELSE i * 1.5 END AS value, (i % 4)::INT AS year
    FROM range(100) t(i)
) TO 'data' (FORMAT parquet, PARTITION_BY (year))"

# A column added in a later file must still show up.
mkdir -p evolve
duckdb -no-init -no-agent -c "COPY (SELECT 1 AS id) TO 'evolve/a.parquet'; COPY (SELECT 2 AS id, 3.5 AS score) TO 'evolve/b.parquet'"

fail=0
check() {
	name=$1
	shift
	"$here/../hp" "$@" >"$name.out" 2>&1 || echo "[exit $?]" >>"$name.out"
	if [ "${UPDATE:-}" = 1 ]; then
		cp "$name.out" "$here/expected/$name.txt"
	elif ! diff -u "$here/expected/$name.txt" "$name.out"; then
		fail=1
	fi
}

[ "${1:-}" = --update ] && UPDATE=1 && mkdir -p "$here/expected"

check default data
check first-3 -n 3 data
check partition -n 3 --partition data
check glimpse --glimpse data
check glimpse-2 --glimpse -n 2 --partition 'data/**/*.parquet'
check missing nope.parquet
check new-column evolve
check bad-option --bogus data

[ "$fail" = 0 ] && echo "all tests passed"
exit "$fail"
