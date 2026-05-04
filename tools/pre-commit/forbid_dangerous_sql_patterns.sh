#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

files="$(staged_files_matching '\.php$' | filter_excluded_files)"

if [ -z "$files" ]; then
    exit 0
fi

status=0
pattern='REPLACE[[:space:]]+INTO|ON[[:space:]]+DUPLICATE[[:space:]]+KEY[[:space:]]+UPDATE|SQL_CALC_FOUND_ROWS|ORDER[[:space:]]+BY[[:space:]]+FIELD[[:space:]]*\('

while IFS= read -r file; do
    [ -n "$file" ] || continue

    if rg -n -i "$pattern" "$file" >/dev/null 2>&1; then
        rg -n -i "$pattern" "$file"
        status=1
    fi
done <<< "$files"

if [ "$status" -ne 0 ]; then
    echo "Dangerous SQL patterns forbidden by project docs were found." >&2
fi

exit "$status"
