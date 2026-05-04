#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

php_files="$(staged_files_matching '\.php$' | filter_excluded_files)"

if [ -z "$php_files" ]; then
    exit 0
fi

if command -v phpcbf >/dev/null 2>&1; then
    phpcbf_bin="$(command -v phpcbf)"
elif [ -x vendor/bin/phpcbf ]; then
    phpcbf_bin="vendor/bin/phpcbf"
else
    echo "phpcbf not found. Install PHP_CodeSniffer or make it available in PATH." >&2
    exit 1
fi

"$phpcbf_bin" --standard="$PHPCS_STANDARD" $php_files
git add $php_files
