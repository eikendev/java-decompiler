IMAGE := java-decompiler

.PHONY: build
build:
	podman build \
		-t \
		local/${IMAGE} .

.PHONY: run_debug
run_debug:
	podman run \
		-ti \
		--rm \
		-v ${PWD}/infiles:/infiles:Z,ro \
		-v ${PWD}/libfiles:/libfiles:Z,ro \
		-v ${PWD}/outfiles:/outfiles:Z,rw \
		local/${IMAGE}

.PHONY: run
run:
	podman pull ghcr.io/eikendev/java-decompiler:latest
	podman run \
		-ti \
		--rm \
		-v ${PWD}/infiles:/infiles:Z,ro \
		-v ${PWD}/libfiles:/libfiles:Z,ro \
		-v ${PWD}/outfiles:/outfiles:Z,rw \
		ghcr.io/eikendev/java-decompiler:latest
