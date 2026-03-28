.PHONY: init up down build serve migrate clearcache

init:
	bash scripts/client-init.sh "$(domain)" "$(backup)"

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
