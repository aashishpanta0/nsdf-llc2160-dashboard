.PHONY: build
build:
	@docker build --platform linux/amd64 -t nasa-oceanic .

# The cache folder must exist and be writable by the container's user (UID 10001).
.PHONY: cache-dir
cache-dir:
	@mkdir -p visus_cache_can_be_erased && chmod 1777 visus_cache_can_be_erased

.PHONY: dev
dev: cache-dir
	@docker compose watch

.PHONY: up
up: cache-dir
	@docker compose up -d

.PHONY: down
down:
	@docker compose down -v

.PHONY: clean-cache
clean-cache:
	@rm -rf visus_cache_can_be_erased
