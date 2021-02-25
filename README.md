# Java Decompiler

## About

This Docker image is equipped with four Java decompilers:
- [CFR](https://www.benf.org/other/cfr/)
- [Fernflower](https://github.com/JetBrains/intellij-community/tree/master/plugins/java-decompiler/engine)
- [Krakatau](https://github.com/Storyyeller/Krakatau)
- [Procyon](https://github.com/mstrobel/procyon)

It also includes [Enjarify](https://github.com/Storyyeller/enjarify) and [jadx](https://github.com/skylot/jadx) for the decompilation of APK files.

## Usage

First, create a directory `./infiles` that contains all your JAR and APK files you want to decompile.

Then, in case the targeted files depend on any external library, put a copy of these libraries in JAR format into a directory `./libfiles`.
Some decompilers depend on this to work properly.

Next, prepare an empty directory `./outfiles`, which is where the output of the decompilers will be written to.

Lastly, run the Docker image via the following command.

```bash
docker run \
	-ti \
	--rm \
	-v "$PWD/infiles:/infiles:Z,ro" \
	-v "$PWD/libfiles:/libfiles:Z,ro" \
	-v "$PWD/outfiles:/outfiles:Z,rw" \
	eikendev/java-decompiler
```

If you want to use [Podman](https://podman.io/), simply switch `docker` to `podman` at the start of the command.
