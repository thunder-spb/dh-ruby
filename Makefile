.ONESHELL:
SHELL := /bin/bash
.DEFAULT_GOAL := help
$(V).SILENT:

DIR := ${CURDIR}

IMAGE_NAME := thunderspb/ruby
DOCKER := $(shell which docker)
RUBY_VERSIONS := 2.5.1 2.6.6 2.7.2

build:
	$(DOCKER) build --build-arg RUBY_VERSION=$(RUBY_VER) --tag $(TAG) .

build-all: ## Build all containers
	@for RUBY_VER in $(RUBY_VERSIONS); do $(MAKE) build-$$RUBY_VER; done;

build-%: ## Build user defined Ruby version
	$(eval RUBY_VER="${*}")
	$(MAKE) build RUBY_VER=$(RUBY_VER) TAG=$(IMAGE_NAME):$(RUBY_VER)

push-all: ## Push all built containers
	@for RUBY_VER in $(RUBY_VERSIONS); do $(MAKE) push-$${RUBY_VER}; done;

push-%: ## Push built container to Docker Hub
	$(eval RUBY_VER="${*}")
	$(DOCKER) push $(IMAGE_NAME):$(RUBY_VER)

.PHONY: help
help: ## Show this usage message
	@printf "\n%s\n\n" "usage: make <target>"
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
