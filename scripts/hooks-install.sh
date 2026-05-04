#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APT_UPDATED=0
PRE_COMMIT_VENV_DIR="${ROOT_DIR}/.tools/pre-commit-venv"

cd "${ROOT_DIR}"

export PATH="${HOME}/.local/bin:${PATH}"

ensure_kit_files() {
    local required_paths=(
        ".pre-commit-config.yaml"
        "tools/pre-commit/common.sh"
        "tools/pre-commit/project.conf"
    )
    local required_path

    for required_path in "${required_paths[@]}"; do
        if [[ ! -f "${ROOT_DIR}/${required_path}" ]]; then
            echo "Missing pre-commit kit file: ${ROOT_DIR}/${required_path}" >&2
            echo "Sync the project with docker-sample before running make hooks-install." >&2
            exit 1
        fi
    done
}

run_apt_update_once() {
    if [[ "${APT_UPDATED}" -eq 1 ]]; then
        return 0
    fi

    sudo apt-get update
    APT_UPDATED=1
}

ensure_pre_commit() {
    if command -v pre-commit >/dev/null 2>&1; then
        return 0
    fi

    echo "pre-commit not found. Installing..."

    if command -v pipx >/dev/null 2>&1; then
        pipx install pre-commit
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        run_apt_update_once
        if sudo apt-get install -y pre-commit; then
            return 0
        fi
    fi

    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -m venv --help >/dev/null 2>&1; then
            if command -v apt-get >/dev/null 2>&1; then
                run_apt_update_once
                sudo apt-get install -y python3-venv
            else
                echo "Cannot install pre-commit automatically: python3-venv is unavailable." >&2
                exit 1
            fi
        fi

        python3 -m venv "${PRE_COMMIT_VENV_DIR}"
        "${PRE_COMMIT_VENV_DIR}/bin/pip" install --upgrade pip
        "${PRE_COMMIT_VENV_DIR}/bin/pip" install pre-commit
        export PATH="${PRE_COMMIT_VENV_DIR}/bin:${PATH}"
        return 0
    fi

    echo "Cannot install pre-commit automatically." >&2
    exit 1
}

ensure_phpcs() {
    if command -v phpcs >/dev/null 2>&1 || [[ -x "${ROOT_DIR}/vendor/bin/phpcs" ]]; then
        return 0
    fi

    echo "phpcs not found. Installing..."

    if command -v apt-get >/dev/null 2>&1; then
        run_apt_update_once
        sudo apt-get install -y php-codesniffer
        return 0
    fi

    if command -v composer >/dev/null 2>&1; then
        composer global require squizlabs/php_codesniffer
        return 0
    fi

    echo "Cannot install phpcs automatically." >&2
    exit 1
}

ensure_pre_commit
ensure_phpcs
ensure_kit_files

pre-commit install

staged_files="$(git diff --cached --name-only --diff-filter=ACMR)"

if [[ -n "${staged_files}" ]]; then
    echo "Running pre-commit only for staged files"
    # shellcheck disable=SC2086
    pre-commit run --files ${staged_files}
else
    echo "No staged files found. Hooks installed; skipping immediate run."
    echo "Use 'git add <files>' and commit, or run 'pre-commit run --files <files>' manually."
fi
