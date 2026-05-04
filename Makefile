.PHONY: init up down build serve migrate clearcache hooks-install

init:
	bash scripts/client-init.sh "$(domain)"

up:
	bash scripts/client-up.sh

down:
	bash scripts/client-down.sh

build:
	sudo docker compose config -q && \
	sudo docker compose build --pull

reboot:
	make down && make up

rebuild:
	make down && make build && make up

hooks-install:
	bash scripts/hooks-install.sh
