#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

php_files="$(staged_files_matching '\.php$' | filter_excluded_files)"

if [ -z "$php_files" ]; then
    exit 0
fi

status=0

while IFS= read -r file; do
    [ -n "$file" ] || continue

    if ! php -l "$file"; then
        status=1
    fi
done <<< "$php_files"

exit "$status"
