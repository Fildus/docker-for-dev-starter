.PHONY: dev dev_with_logs dev_rebuild clean php node phpstan php-cs-fix test extraInfos
user := $(shell id -u)
group := $(shell id -g)
docker_compose_dev := USER_ID=$(user) GROUP_ID=$(group) docker-compose -f docker/docker-compose.dev.yaml --env-file ".env.local"

## Development environment
dev: .env.local vendor public/build ## run development server
	$(docker_compose_dev) up --build -d
	make extraInfos

dev_with_logs: .env.local vendor public/build ## run development server
	make extraInfos
	$(docker_compose_dev) up --build

dev_rebuild: ## rebuild all
	make -B vendor public/build
	$(docker_compose_dev) up --build -d
	$(docker_compose_dev) exec php bin/phpunit
	make extraInfos

clean: ## remove container, images, network, and ignored files
	$(docker_compose_dev) down --remove-orphans
	rm -fR var/ vendor/ node_modules/ .phpunit.result.cache bin/.phpunit public/build

## Bash
php: ## Get php bash
	$(docker_compose_dev) exec php bash

node: ## Get node bash
	$(docker_compose_dev) exec node bash

## INSPECTION
phpstan: ## run phpstan inspection
	$(docker_compose_dev) exec php vendor/bin/phpstan analyse -c phpstan.neon

php-cs-fix: vendor ## run php-cs-filter inspection
	$(docker_compose_dev) exec php vendor/bin/php-cs-fixer fix --allow-risky=yes

## Tests
test: .env.local vendor public/build ## run tests watcher
	$(docker_compose_dev) exec php vendor/bin/phpunit-watcher watch

# Dependencies
public/build: node_modules
	$(docker_compose_dev) run --rm node yarn build

node_modules: yarn.lock
	$(docker_compose_dev) run --rm node yarn

yarn.lock:

vendor: composer.lock
	$(docker_compose_dev) run --rm php composer install

composer.lock:

.env.local:
	cp ./.env.dev.dist ./.env.local

extraInfos:
	@echo "\n\033[0;33m \342\232\231 DEV! \033[0m"
	@echo "\033[0;32mdevelopment server:\033[0m http://localhost:$(shell cat .env.local | grep NGINX_PORT= | cut -d '=' -f2)"
	@echo "\033[0;32mphpmyadmin:\033[0m http://localhost:$(shell cat .env.local | grep PHPMYADMIN_PORT= | cut -d '=' -f2)"
	@echo "- \033[0;34muser:\033[0m $(shell cat .env.local | grep MYSQL_USER= | cut -d '=' -f2)"
	@echo "- \033[0;34mpassword:\033[0m $(shell cat .env.local | grep MYSQL_PASSWORD= | cut -d '=' -f2)"
	@echo "\033[0;32mmailhog:\033[0m http://localhost:$(shell cat .env.local | grep MAILHOG_PORT_2= | cut -d '=' -f2)\n"

.DEFAULT_GOAL := help
help:
	-@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^## )' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
.PHONY: help