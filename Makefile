IMAGE := ghcr.io/eikendev/java-decompiler
LOCAL := local/java-decompiler
RUNTIME ?= podman

ifeq ($(RUNTIME),podman)
USER_FLAG := --userns=keep-id
else
USER_FLAG := --user $(shell id -u):$(shell id -g)
endif

MOUNTS := \
	-v "$(PWD)/infiles:/infiles:Z,ro" \
	-v "$(PWD)/libfiles:/libfiles:Z,ro" \
	-v "$(PWD)/outfiles:/outfiles:Z,rw"

.PHONY: build
build:
	$(RUNTIME) build -t $(LOCAL) .

.PHONY: run_debug
run_debug: dirs
	$(RUNTIME) run -ti --rm $(USER_FLAG) $(MOUNTS) $(LOCAL)

.PHONY: run
run: dirs
	$(RUNTIME) pull $(IMAGE):latest
	$(RUNTIME) run -ti --rm $(USER_FLAG) $(MOUNTS) $(IMAGE):latest

.PHONY: test
test: build
	tests/smoke.sh $(LOCAL) $(RUNTIME)

.PHONY: check
check: lint

.PHONY: lint
lint:
	shellcheck src/init tests/smoke.sh

.PHONY: dirs
dirs:
	mkdir -p infiles libfiles outfiles
