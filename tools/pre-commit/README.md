# CS-Cart Pre-commit Kit

Reusable `pre-commit` kit for CS-Cart projects.

## Files

- `.pre-commit-config.yaml`
- `phpcs.xml.dist`
- `tools/pre-commit/*.sh`
- `tools/pre-commit/project.conf`

## Project Settings

Project-specific settings live in `tools/pre-commit/project.conf`.

Default example:

```bash
ADDONS_ROOT="app/addons"
LANGS_ROOT="var/langs"
EXCLUDE_REGEX='(^app/lib/|^app/addons/[^/]+/lib/|^var/cache/|^var/files/)'
PHPCS_STANDARD="phpcs.xml.dist"
PHPCS_BIN="${PHPCS_BIN:-phpcs}"
CHECK_HARDCODED_STRINGS="${CHECK_HARDCODED_STRINGS:-1}"
MAX_ADDED_FILE_KB="${MAX_ADDED_FILE_KB:-2048}"
```

## Usage

Install `pre-commit`, `phpcs`, and `phpcbf`, then run:

```bash
make hooks-install
```

Or manually:

```bash
pre-commit install
pre-commit run --all-files
```

`phpcs` and `phpcbf` should be available either in `PATH` or as `vendor/bin/phpcs` and `vendor/bin/phpcbf`.

`list(...)` is forbidden in staged `*.php` files; commit is blocked until it is replaced with `[...]`.
