# Docker Sample For Client Projects

## Что входит в sample

Этот sample нужен для быстрого локального разворачивания клиентского магазина в новой папке проекта вида `~/projects/[project-name]`.

## Требования

Перед началом работы должны быть установлены:
- `docker`
- `docker compose`
- `make`
- `unzip`
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

После клонирования нужно загрузить в корень проекта клиентский архив вида `backup_*.zip`.

Итоговая структура должна быть такой:

```text
~/projects/client-project/
├── backup_*.zip
├── docker/
├── scripts/
├── mariadb/
├── docker-compose.yml
├── Makefile
└── local_conf.php
```

## Первая инициализация проекта

Первая инициализация запускается одной командой:

```bash
make init domain=client-domain.ru backup=backup_4.19.1.SP1_28Mar2026_082008.zip
```

Команда делает следующее:
- распаковывает архив магазина в корень проекта
- ищет SQL-дамп в `var/restore/*.sql`
- подставляет домен в `local_conf.php`
- подставляет домен в Apache vhost-конфиги
- сохраняет домен проекта в `.client-domain`
- очищает локальную папку `mariadb/`
- запускает `make up`
- ждёт готовности MariaDB
- пересоздаёт базу `cscart`
- импортирует найденный SQL
- создаёт симлинк `AGENTS.md` из `~/projects/AGENTS.md`, если файл существует
- создаёт симлинк `docs` из `~/projects/docs`, если папка существует

## Повседневная работа

Поднять уже инициализированный проект:

```bash
make up
```

Остановить проект:

```bash
make down
```

## Что делают команды

`make init`
- используется только для первичного разворачивания проекта
- требует `domain=...` и `backup=...`
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
make init domain=client-domain.ru backup=backup_*.zip
```

## Типовой сценарий

```bash
git clone <repo-url> ~/projects/client-project
cd ~/projects/client-project
cp /path/to/backup_*.zip .
make init domain=client-domain.ru backup=backup_*.zip
make down
make up
```
