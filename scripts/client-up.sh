#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="${ROOT_DIR}/.client-domain"
HOSTS_FILE="/etc/hosts"

if [[ ! -f "${STATE_FILE}" ]]; then
    echo "Domain state file not found: ${STATE_FILE}. Run make init domain=... backup=... first." >&2
    exit 1
fi

DOMAIN="$(tr -d '\n' < "${STATE_FILE}")"

if [[ -z "${DOMAIN}" ]]; then
    echo "Domain state file is empty: ${STATE_FILE}" >&2
    exit 1
fi

update_hosts() {
    local project_marker
    local start_marker
    local end_marker
    local temp_file

    project_marker="$(basename "${ROOT_DIR}"):${ROOT_DIR}"
    start_marker="# >>> ${project_marker} >>>"
    end_marker="# <<< ${project_marker} <<<"
    temp_file="$(mktemp)"

    awk -v start="${start_marker}" -v end="${end_marker}" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "${HOSTS_FILE}" > "${temp_file}"

    {
        printf "\n%s\n" "${start_marker}"
        printf "127.0.0.1 %s\n" "${DOMAIN}"
        printf "%s\n" "${end_marker}"
    } >> "${temp_file}"

    sudo cp "${temp_file}" "${HOSTS_FILE}"
    rm -f "${temp_file}"
}

update_hosts

sudo service apache2 stop
sudo docker compose config -q
sudo docker compose up -d --force-recreate --remove-orphans
