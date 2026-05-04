#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

files="$(staged_files_matching '\.(tpl|php|js)$' | filter_excluded_files)"

if [ -z "$files" ]; then
    exit 0
fi

status=0

while IFS= read -r file; do
    [ -n "$file" ] || continue

    case "$file" in
        *.tpl)
            if rg -n 'style="' "$file" >/dev/null 2>&1; then
                rg -n 'style="' "$file"
                echo "Inline CSS is forbidden in TPL files: $file" >&2
                status=1
            fi
        ;;
    esac

    if rg -n 'javascript:' "$file" >/dev/null 2>&1; then
        rg -n 'javascript:' "$file"
        echo "javascript: URLs are forbidden: $file" >&2
        status=1
    fi
done <<< "$files"

exit "$status"
