#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTS_FILE="/etc/hosts"
PROJECT_MARKER="$(basename "${ROOT_DIR}"):${ROOT_DIR}"
START_MARKER="# >>> ${PROJECT_MARKER} >>>"
END_MARKER="# <<< ${PROJECT_MARKER} <<<"

remove_hosts_entry() {
    local temp_file

    temp_file="$(mktemp)"

    awk -v start="${START_MARKER}" -v end="${END_MARKER}" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "${HOSTS_FILE}" > "${temp_file}"

    sudo cp "${temp_file}" "${HOSTS_FILE}"
    rm -f "${temp_file}"
}

if grep -qF "${START_MARKER}" "${HOSTS_FILE}" 2>/dev/null; then
    remove_hosts_entry
fi

echo "Stopping containers"
sudo docker compose config -q
sudo docker compose down --remove-orphans
sudo service apache2 start
