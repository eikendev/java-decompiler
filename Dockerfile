# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1: fetch the upstream release artifacts. Bump the versions below by
# hand; Dependabot only covers the base images and GitHub Actions.
# ---------------------------------------------------------------------------
FROM docker.io/library/debian:trixie-slim AS fetch

ARG CFR_VERSION=0.152
ARG VINEFLOWER_VERSION=1.12.0
ARG JADX_VERSION=1.5.6
ARG DEX2JAR_VERSION=2.4.38

RUN set -eux \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl unzip \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /dl

RUN set -eux \
	&& curl -fsSL -o cfr.jar "https://github.com/leibnitz27/cfr/releases/download/${CFR_VERSION}/cfr-${CFR_VERSION}.jar" \
	&& curl -fsSL -o vineflower.jar "https://github.com/Vineflower/vineflower/releases/download/${VINEFLOWER_VERSION}/vineflower-${VINEFLOWER_VERSION}.jar" \
	&& curl -fsSL -o jadx.zip "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" \
	&& curl -fsSL -o dex2jar.zip "https://github.com/ThexXTURBOXx/dex2jar/releases/download/${DEX2JAR_VERSION}/dex-tools-${DEX2JAR_VERSION}.zip" \
	&& mkdir -p out/cfr out/vineflower out/jadx \
	&& mv cfr.jar out/cfr/cfr.jar \
	&& mv vineflower.jar out/vineflower/vineflower.jar \
	&& unzip -q jadx.zip -d out/jadx \
	&& rm -f out/jadx/bin/*.bat \
	&& unzip -q dex2jar.zip -d dex2jar \
	&& mv "dex2jar/dex-tools-${DEX2JAR_VERSION}" out/dex2jar \
	&& rm -f out/dex2jar/*.bat \
	&& chmod 0755 out/jadx/bin/jadx out/dex2jar/*.sh

# ---------------------------------------------------------------------------
# Stage 2: build Krakatau v2 (Rust). Upstream only considers the v2
# assembler/disassembler finished; the v2 decompiler is a work in progress
# and the v1 decompiler needs Python 2, so only `krak2 dis` is shipped.
# Krakatau publishes no releases, so the v2 branch head is used.
# ---------------------------------------------------------------------------
FROM docker.io/library/rust:1-slim-trixie AS krakatau

ARG KRAKATAU_REF=v2

RUN set -eux \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates git \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN set -eux \
	&& git init -q . \
	&& git remote add origin https://github.com/Storyyeller/Krakatau.git \
	&& git fetch -q --depth 1 origin "${KRAKATAU_REF}" \
	&& git checkout -q FETCH_HEAD \
	&& cargo build --release \
	&& strip target/release/krak2

# ---------------------------------------------------------------------------
# Stage 3: runtime image.
# ---------------------------------------------------------------------------
FROM docker.io/library/debian:trixie-slim AS runtime

RUN set -eux \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		astyle \
		ca-certificates \
		openjdk-21-jre-headless \
		procyon-decompiler \
		unzip \
	&& rm -rf /var/lib/apt/lists/* \
	&& useradd --uid 1000 --user-group --no-create-home decompiler

COPY --from=fetch /dl/out /opt
COPY --from=krakatau /src/target/release/krak2 /usr/local/bin/krak2
COPY --chmod=0755 src/init /usr/local/bin/java-decompiler

ENV INFILES=/infiles \
	LIBFILES=/libfiles \
	OUTFILES=/outfiles \
	HOME=/tmp \
	PATH=/opt/jadx/bin:/opt/dex2jar:/usr/local/bin:/usr/bin:/bin

VOLUME ["/infiles", "/libfiles", "/outfiles"]

USER decompiler

ENTRYPOINT ["/usr/local/bin/java-decompiler"]

LABEL org.opencontainers.image.title="Java Decompiler" \
	org.opencontainers.image.description="CFR, Vineflower, Procyon, jadx and Krakatau in one container for batch decompilation of JAR and APK files." \
	org.opencontainers.image.source="https://github.com/eikendev/java-decompiler" \
	org.opencontainers.image.licenses="MIT"
