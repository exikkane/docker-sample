#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

php_files="$(staged_files_matching '\.php$' | filter_excluded_files)"

if [ -z "$php_files" ]; then
    exit 0
fi

if command -v "$PHPCS_BIN" >/dev/null 2>&1; then
    phpcs_bin="$(command -v "$PHPCS_BIN")"
elif [ -x vendor/bin/phpcs ]; then
    phpcs_bin="vendor/bin/phpcs"
else
    echo "phpcs not found. Install PHP_CodeSniffer or make it available in PATH." >&2
    exit 1
fi

"$phpcs_bin" --standard="$PHPCS_STANDARD" $php_files
