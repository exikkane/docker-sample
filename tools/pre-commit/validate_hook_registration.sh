#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

status=0
addon_dirs="$(staged_files_matching "^${ADDONS_ROOT}/[^/]+/(func\.php|init\.php)$" | sed -E "s#^(${ADDONS_ROOT}/[^/]+)/.*#\\1#" | sort -u || true)"

if [ -z "$addon_dirs" ]; then
    exit 0
fi

while IFS= read -r addon_dir; do
    [ -n "$addon_dir" ] || continue

    addon_id="${addon_dir#${ADDONS_ROOT}/}"
    func_file="$addon_dir/func.php"
    init_file="$addon_dir/init.php"

    if [ ! -f "$func_file" ] || [ ! -f "$init_file" ]; then
        continue
    fi

    registered="$(awk '
        /fn_register_hooks[[:space:]]*\(/ { in_block=1 }
        in_block { print }
        in_block && /\)[[:space:]]*;/ { in_block=0 }
    ' "$init_file" | sed -nE "s/.*'([a-zA-Z0-9_]+)'.*/\\1/p" | sort -u)"

    while IFS= read -r hook_name; do
        [ -n "$hook_name" ] || continue

        if ! grep -q "function[[:space:]]\+fn_${addon_id}_${hook_name}[[:space:]]*(" "$func_file"; then
            echo "Hook $hook_name is registered in $init_file but handler fn_${addon_id}_${hook_name} was not found in $func_file" >&2
            status=1
        fi
    done <<< "$registered"
done <<< "$addon_dirs"

exit "$status"
