FROM docker.io/library/debian AS buildbase

RUN set -xe \
	&& apt-get update \
	&& apt-get install -y openjdk-11-jdk \
	&& apt-get clean

FROM docker.io/library/debian AS runtimebase

RUN set -xe \
	&& apt-get update \
	&& apt-get install -y openjdk-11-jre python2 python3 procyon-decompiler unzip astyle \
	&& apt-get clean

FROM buildbase AS dependencies

ARG GRADLE_VERSION=7.4.2
ARG GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip

ARG CFR_VERSION=0.152
ARG CFR_URL=https://github.com/leibnitz27/cfr/releases/download/${CFR_VERSION}/cfr-${CFR_VERSION}.jar

ARG FERNFLOWER_URL=https://github.com/fesh0r/fernflower/archive/master.tar.gz

ARG JRT_EXTRACTOR_URL=https://github.com/Storyyeller/jrt-extractor/archive/master.tar.gz

ARG KRAKATAU_URL=https://github.com/Storyyeller/Krakatau/archive/master.tar.gz

ARG JADX_VERSION=1.3.5
ARG JADX_URL=https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip

ARG ENJARIFY_URL=https://github.com/Storyyeller/enjarify/archive/master.tar.gz

RUN set -xe \
	&& apt-get update \
	&& apt-get install -y curl unzip

# A recent version of Gradle is needed to build Fernflower.
RUN set -xe \
	&& curl -q -s -S -L --create-dirs -o ./gradle.zip $GRADLE_URL \
	&& unzip ./gradle.zip \
	&& mv ./gradle-${GRADLE_VERSION}/lib/* /usr/local/lib \
	&& mv ./gradle-${GRADLE_VERSION}/bin/* /usr/local/bin

WORKDIR /dependencies

RUN set -xe \
	&& curl -q -s -S -L --create-dirs -o ./out/cfr.jar $CFR_URL \
	&& curl -q -s -S -L --create-dirs -o ./fernflower.tgz $FERNFLOWER_URL \
	&& mkdir -p ./fernflower && tar -C ./fernflower --strip-components=1 -xf fernflower.tgz \
	&& (cd fernflower && gradle jar) \
	&& mv ./fernflower/build/libs/fernflower.jar ./out \
	&& curl -q -s -S -L --create-dirs -o ./jrt-extractor.tgz $JRT_EXTRACTOR_URL \
	&& mkdir -p ./jrt-extractor && tar -C ./jrt-extractor --strip-components=1 -xf jrt-extractor.tgz \
	&& (cd ./jrt-extractor && javac JRTExtractor.java && java -ea JRTExtractor) \
	&& mv ./jrt-extractor/rt.jar ./out \
	&& curl -q -s -S -L --create-dirs -o ./krakatau.tgz $KRAKATAU_URL \
	&& mkdir -p ./krakatau && tar -C ./krakatau --strip-components=1 -xf krakatau.tgz \
	&& mv ./krakatau ./out \
	&& curl -q -s -S -L --create-dirs -o ./jadx.zip $JADX_URL \
	&& mkdir ./out/jadx \
	&& (cd ./out/jadx && unzip ../../jadx.zip) \
	&& curl -q -s -S -L --create-dirs -o ./enjarify.tgz $ENJARIFY_URL \
	&& mkdir -p ./enjarify && tar -C ./enjarify --strip-components=1 -xf enjarify.tgz \
	&& mv ./enjarify ./out

FROM runtimebase AS runtime

COPY --from=dependencies /dependencies/out /opt

ENV INFILES="/infiles" \
	LIBFILES="/libfiles" \
	OUTFILES="/outfiles" \
	JAVA_XMX="2G"

COPY ./src/init /init

RUN chmod 540 /init

ENTRYPOINT ["/init"]
