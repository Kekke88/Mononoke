#-----------------------------------------------------------
# Argumants
#-----------------------------------------------------------

service ?= http.php
tag ?= mononoke
ports ?= 80:80
APP_NAME = mononoke

#-----------------------------------------------------------
# Management
#-----------------------------------------------------------

help: ## Show this help message
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## .*$$' $(MAKEFILE_LIST) \
    	| awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-20s %s\n", $$1, $$2}'

build: ## Build container based on current Docker file with "tag" argument. Example: "make build tag=mononoke"
	@echo "Building single container with tag ${tag}"
	docker build -t ${tag} .

run: ## Run container with given tag, ports and service. Example: "make run tag=mononoke ports=8080:80 service=http.php"
	@echo "Running single container tagged as ${tag}. Ports: ${ports}"
	docker run --rm --name ${tag} -p ${ports} ${tag} examples/${service}

stop: ## Stop running container with given tag. Example: "make stop tag=mononoke"
	@echo "Stop container tagged as ${tag}."
	docker stop ${tag}

up: ## Start all containers specified in docker-compose. Example: "make up service=sns.php". Default service: http.php
	@echo "Running containers in the background..."
	SERVICE_FILE=$(service) docker compose up -d

down: ## Stop all containers specified in docker-compose.
	@echo "Stopping and removing containers..."
	docker compose down --remove-orphans

build.all: ## Build all containers specified in docker-compose
	@echo "Building all containers..."
	docker compose build

ps: ## Show list of running containers
	@echo "Listing running containers..."
	docker compose ps

restart: ## Restart all containers
	@echo "Restarting containers..."
	docker compose restart

logs: ## View output from containers
	docker compose logs --tail 500

fl: ## Follow output from containers (short of 'follow logs')
	docker compose logs --tail 500 -f

#-----------------------------------------------------------
# Application
#-----------------------------------------------------------

shell: ## Enter the mononoke container
	docker compose exec ${APP_NAME} /bin/bash