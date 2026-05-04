#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

if [ "$CHECK_HARDCODED_STRINGS" != "1" ]; then
    exit 0
fi

files="$(staged_files_matching "^(${ADDONS_ROOT}/|design/.*/addons/).*\\.(php|tpl)$" | filter_excluded_files)"

if [ -z "$files" ]; then
    exit 0
fi

status=0
pattern='("[A-ZА-Я][^"]*[[:space:]][^"]*"|'\''[A-ZА-Я][^'\'']*[[:space:]][^'\'']*'\'')'

while IFS= read -r file; do
    [ -n "$file" ] || continue

    if rg -n "$pattern" "$file" | grep -Ev '__\(|msgid|msgstr|msgctxt|Addons::|Languages::|Settings(Sections|Options|Variants)::|schema|https?://' >/dev/null 2>&1; then
        rg -n "$pattern" "$file" | grep -Ev '__\(|msgid|msgstr|msgctxt|Addons::|Languages::|Settings(Sections|Options|Variants)::|schema|https?://'
        echo "Potential hardcoded UI strings found in addon code: $file" >&2
        status=1
    fi
done <<< "$files"

exit "$status"
