IMAGE := java-decompiler

.PHONY: build
build:
	podman build \
		-t \
		local/${IMAGE} .

.PHONY: run
run:
	podman run \
		-ti \
		--rm \
		-v ${PWD}/infiles:/infiles:Z,ro \
		-v ${PWD}/libfiles:/libfiles:Z,ro \
		-v ${PWD}/outfiles:/outfiles:Z,rw \
		local/${IMAGE}
