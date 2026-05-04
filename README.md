# Docker Sample For Client Projects

## Что входит в sample

Этот sample нужен для быстрого локального разворачивания клиентского магазина в новой папке проекта вида `~/projects/[project-name]`.

## Требования

Перед началом работы должны быть установлены:
- `docker`
- `docker compose`
- `make`
- `sudo`

Также текущий пользователь должен иметь возможность запускать:
- `sudo docker compose ...`
- `sudo service apache2 stop`
- `sudo service apache2 start`

## Создание нового проекта

Новый проект нужно получать клонированием репозитория сразу в целевую папку проекта.

```bash
git clone <repo-url> ~/projects/client-project
cd ~/projects/client-project
```

После клонирования в проекте уже должны быть:
- файлы магазина
- SQL-дамп в `var/restore/*.sql`
- pre-commit kit для проекта

Итоговая структура должна быть такой:

```text
~/projects/client-project/
├── docker/
├── scripts/
├── var/
│   └── restore/
│       └── backup_*.sql
├── mariadb/
├── tools/
├── docker-compose.yml
├── Makefile
├── .pre-commit-config.yaml
├── phpcs.xml.dist
└── local_conf.php
```

## Первая инициализация проекта

Первая инициализация запускается одной командой:

```bash
make init domain=client-domain.ru
```

Команда делает следующее:
- создаёт симлинк `AGENTS.md` из `~/projects/AGENTS.md`, если файл существует
- создаёт симлинк `docs` из `~/projects/docs`, если папка существует
- ищет SQL-дамп в `var/restore/*.sql`
- подставляет домен в `local_conf.php`
- подставляет домен в Apache vhost-конфиги
- сохраняет домен проекта в `.client-domain`
- очищает локальную папку `mariadb/`
- запускает `make up`
- ждёт готовности MariaDB
- пересоздаёт базу `cscart`
- импортирует найденный SQL

## Повседневная работа

Поднять уже инициализированный проект:

```bash
make up
```

Остановить проект:

```bash
make down
```

## Установка git hooks

В sample уже встроен CS-Cart pre-commit kit. После первого клонирования проекта нужно один раз установить hooks:

```bash
make hooks-install
```

Команда:
- проверяет наличие `pre-commit` и `phpcs`
- если их нет, пытается установить автоматически
- выполняет `pre-commit install`
- если есть staged-файлы, запускает `pre-commit` только по ним
- если staged-файлов нет, только устанавливает hooks без полного прогона по проекту

Для автоустановки используются:
- `pipx`, `apt-get` или локальный `python3 -m venv` для `pre-commit`
- `apt-get` или `composer` для `phpcs`

Если в системе уже есть `vendor/bin/phpcs`, он тоже будет использован.

## Что делают команды

`make init`
- используется только для первичного разворачивания проекта
- требует `domain=...`
- автоматически запускает `make up`

`make up`
- читает домен из `.client-domain`
- добавляет запись в `/etc/hosts`
- поднимает контейнеры

`make down`
- удаляет запись проекта из `/etc/hosts`
- останавливает контейнеры

## Работа с /etc/hosts

При `make up` в `/etc/hosts` автоматически добавляется блок вида:

```text
# >>> client-project:/home/exikane/projects/client-project >>>
127.0.0.1 client-domain.ru
# <<< client-project:/home/exikane/projects/client-project <<<
```

При `make down` этот блок автоматически удаляется.

## Важные правила

- `make init` и `make up` запускаются без `sudo`
- внутри скриптов `sudo` вызывается только там, где это нужно
- если запускать `sudo make init`, файлы проекта могут стать owned by `root`
- `make init` всегда очищает локальную папку `mariadb/` перед запуском контейнеров
- `make init` рассчитан на первичное развёртывание или полную переинициализацию проекта

## Если нужно развернуть проект заново

Если проект нужно полностью инициализировать заново в той же папке, достаточно снова выполнить:

```bash
make init domain=client-domain.ru
```

## Типовой сценарий разработчика

```bash
git clone <repo-url> ~/projects/client-project
cd ~/projects/client-project
make init domain=client-domain.ru
make hooks-install
make down
make up
```
