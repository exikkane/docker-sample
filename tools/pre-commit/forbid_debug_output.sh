#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

files="$(staged_files_matching '\.(php|tpl)$' | filter_excluded_files)"

if [ -z "$files" ]; then
    exit 0
fi

status=0

while IFS= read -r file; do
    [ -n "$file" ] || continue

    if rg -n 'fn_print_r|fn_print_die' "$file" >/dev/null 2>&1; then
        rg -n 'fn_print_r|fn_print_die' "$file"
        status=1
    fi
done <<< "$files"

if [ "$status" -ne 0 ]; then
    echo "Debug output helpers are forbidden in committed code." >&2
fi

exit "$status"
