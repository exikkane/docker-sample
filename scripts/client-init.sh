#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOMAIN="${1:-}"
STATE_FILE="${ROOT_DIR}/.client-domain"
PROJECTS_ROOT="$(dirname "${ROOT_DIR}")"

if [[ -z "${DOMAIN}" ]]; then
    echo "Domain is required. Usage: make init domain=client.example" >&2
    exit 1
fi

if [[ -f "${ROOT_DIR}/.gitignore.env" && ! -e "${ROOT_DIR}/.gitignore" ]]; then
    mv "${ROOT_DIR}/.gitignore.env" "${ROOT_DIR}/.gitignore"
fi

update_local_conf() {
    local file_path="${1}"

    if [[ ! -f "${file_path}" ]]; then
        echo "Config file not found: ${file_path}" >&2
        exit 1
    fi

    perl -0pi -e "s/\\\$config\\['http_host'\\]\\s*=\\s*'[^']*';/\\\$config['http_host'] = '${DOMAIN}';/g; s/\\\$config\\['https_host'\\]\\s*=\\s*'[^']*';/\\\$config['https_host'] = '${DOMAIN}';/g" "${file_path}"
}

update_vhost() {
    local file_path="${1}"

    if [[ ! -f "${file_path}" ]]; then
        echo "Vhost file not found: ${file_path}" >&2
        exit 1
    fi

    perl -0pi -e "s/ServerName\\s+\\S+/ServerName ${DOMAIN}/g" "${file_path}"
}

find_sql_dump() {
    local extracted_dir="${1}"

    find "${extracted_dir}/var/restore" -maxdepth 1 -type f -name '*.sql' | sort | head -n 1
}

wait_for_mariadb() {
    local retries=60

    until sudo docker compose exec -T mariadb mariadb -uroot -proot -e "SELECT 1" >/dev/null 2>&1; do
        retries=$((retries - 1))
        if [[ "${retries}" -le 0 ]]; then
            echo "MariaDB is not ready for authenticated queries in time." >&2
            exit 1
        fi
        sleep 2
    done
}

ensure_shared_links() {
    local source_path target_path

    for source_path in "${PROJECTS_ROOT}/AGENTS.md" "${PROJECTS_ROOT}/docs"; do
        if [[ ! -e "${source_path}" ]]; then
            continue
        fi

        target_path="${ROOT_DIR}/$(basename "${source_path}")"

        if [[ -L "${target_path}" ]]; then
            ln -sfn "${source_path}" "${target_path}"
            continue
        fi

        if [[ ! -e "${target_path}" ]]; then
            ln -s "${source_path}" "${target_path}"
        fi
    done
}

ensure_shared_links

SQL_DUMP="$(find_sql_dump "${ROOT_DIR}")"

if [[ -z "${SQL_DUMP}" || ! -f "${SQL_DUMP}" ]]; then
    echo "SQL dump not found in ${ROOT_DIR}/var/restore. Put a .sql backup there before make init." >&2
    exit 1
fi

update_local_conf "${ROOT_DIR}/local_conf.php"
update_vhost "${ROOT_DIR}/docker/apache/vhost.conf"
update_vhost "${ROOT_DIR}/docker/apache/vhost-ssl.conf"

printf '%s\n' "${DOMAIN}" > "${STATE_FILE}"

echo "Setting permissions on var/"
if [[ -d "${ROOT_DIR}/var" ]]; then
    sudo chmod -R 0777 "${ROOT_DIR}/var"
fi

echo "Resetting MariaDB data directory"
mkdir -p "${ROOT_DIR}/mariadb"
sudo find "${ROOT_DIR}/mariadb" -mindepth 1 -delete

echo "Starting containers"
make -C "${ROOT_DIR}" up

echo "Waiting for MariaDB"
wait_for_mariadb

echo "Recreating database"
sudo docker compose exec -T mariadb mariadb -uroot -proot -e "DROP DATABASE IF EXISTS cscart; CREATE DATABASE cscart CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

echo "Importing SQL dump ${SQL_DUMP}"
sudo docker compose exec -T mariadb mariadb -uroot -proot cscart < "${SQL_DUMP}"

echo "Initialization completed for ${DOMAIN}"
