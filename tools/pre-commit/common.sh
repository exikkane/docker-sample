#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_CONFIG="$PROJECT_ROOT/tools/pre-commit/project.conf"

cd "$PROJECT_ROOT"

if [ -f "$PROJECT_CONFIG" ]; then
    # shellcheck disable=SC1090
    source "$PROJECT_CONFIG"
fi

ADDONS_ROOT="${ADDONS_ROOT:-app/addons}"
LANGS_ROOT="${LANGS_ROOT:-var/langs}"
EXCLUDE_REGEX="${EXCLUDE_REGEX:-^app/lib/|^app/addons/[^/]+/lib/|^var/cache/|^var/files/}"
PHPCS_STANDARD="${PHPCS_STANDARD:-phpcs.xml.dist}"
PHPCS_BIN="${PHPCS_BIN:-phpcs}"
CHECK_HARDCODED_STRINGS="${CHECK_HARDCODED_STRINGS:-1}"
MAX_ADDED_FILE_KB="${MAX_ADDED_FILE_KB:-2048}"

staged_files() {
    git diff --cached --name-only --diff-filter=ACMR
}

staged_files_matching() {
    local pattern="$1"

    staged_files | grep -E "$pattern" || true
}

assert_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a git work tree; pre-commit hooks require git." >&2
        exit 1
    fi
}

filter_excluded_files() {
    if [ -n "${EXCLUDE_REGEX:-}" ]; then
        grep -Ev "$EXCLUDE_REGEX" || true
    else
        cat
    fi
}
