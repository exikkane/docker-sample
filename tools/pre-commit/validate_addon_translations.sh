#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

assert_git_repo

status=0
rg_bin="$(command -v rg || true)"
addon_dirs="$(staged_files_matching "^${ADDONS_ROOT}/[^/]+/addon\.xml$" | sed -E "s#^(${ADDONS_ROOT}/[^/]+)/addon\\.xml#\\1#" | sort -u || true)"
po_files="$(staged_files_matching "^${LANGS_ROOT}/[^/]+/addons/[^/]+\\.po$" || true)"

for po_file in $po_files; do
    addon_dirs="${addon_dirs}"$'\n'"$(echo "$po_file" | sed -E "s#^${LANGS_ROOT}/[^/]+/addons/([^/]+)\\.po\$#${ADDONS_ROOT}/\\1#")"
done

addon_dirs="$(printf '%s\n' "$addon_dirs" | sed '/^$/d' | sort -u)"

if [ -z "$addon_dirs" ]; then
    exit 0
fi

while IFS= read -r addon_dir; do
    [ -n "$addon_dir" ] || continue

    addon_xml="$addon_dir/addon.xml"
    addon_id="${addon_dir#${ADDONS_ROOT}/}"

    if [ ! -f "$addon_xml" ]; then
        continue
    fi

    xml_id="$(sed -nE 's#.*<id>([^<]+)</id>.*#\1#p' "$addon_xml" | head -n 1)"

    if [ -z "$xml_id" ]; then
        echo "Cannot determine addon id from $addon_xml" >&2
        status=1
        continue
    fi

    if [ "$xml_id" != "$addon_id" ]; then
        echo "addon.xml id '$xml_id' does not match directory '$addon_id' in $addon_xml" >&2
        status=1
    fi

    staged_po_for_addon="$(staged_files_matching "^${LANGS_ROOT}/[^/]+/addons/${addon_id}\\.po$" || true)"

    while IFS= read -r po_file; do
        [ -n "$po_file" ] || continue

        if [ -n "$rg_bin" ]; then
            has_required_entries="$("$rg_bin" -n "msgctxt \"Addons::name::${addon_id}\"|msgctxt \"Addons::description::${addon_id}\"" "$po_file" || true)"
            wrong_ctx="$("$rg_bin" -n 'msgctxt "Addons::(name|description)::[^"]+"' "$po_file" | grep -v "Addons::name::${addon_id}\"" | grep -v "Addons::description::${addon_id}\"" || true)"
        else
            has_required_entries="$(grep -nE "msgctxt \"Addons::name::${addon_id}\"|msgctxt \"Addons::description::${addon_id}\"" "$po_file" || true)"
            wrong_ctx="$(grep -nE 'msgctxt "Addons::(name|description)::[^"]+"' "$po_file" | grep -v "Addons::name::${addon_id}\"" | grep -v "Addons::description::${addon_id}\"" || true)"
        fi

        if [ -z "$has_required_entries" ]; then
            echo "PO file does not contain Addons::name/description entries for ${addon_id}: $po_file" >&2
            status=1
        fi

        if [ -n "$wrong_ctx" ]; then
            echo "$wrong_ctx"
            echo "PO file contains Addons::name/description for a different addon id: $po_file" >&2
            status=1
        fi
    done <<< "$staged_po_for_addon"
done <<< "$addon_dirs"

exit "$status"
