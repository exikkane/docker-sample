#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

new_php_files="$(
    git diff --cached --name-only --diff-filter=A \
    | grep -E '\.php$' \
    | filter_excluded_files \
    || true
)"

if [ -z "$new_php_files" ]; then
    exit 0
fi

status=0

while IFS= read -r file; do
    [ -n "$file" ] || continue

    if ! head -n 8 "$file" | grep -q 'Larionov\.tech'; then
        echo "Missing required Larionov.tech header in new PHP file: $file" >&2
        status=1
    fi
done <<< "$new_php_files"

exit "$status"
