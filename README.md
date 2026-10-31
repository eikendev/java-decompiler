<div align="center">
	<h1>Java Decompiler</h1>
	<h4 align="center">
		Have your decompilers ready when you need them most.
	</h4>
	<p>One container, five engines. Drop in JARs or APKs, get back a source tree per decompiler.</p>
</div>

<p align="center">
	<a href="https://github.com/eikendev/java-decompiler/actions/workflows/ci.yaml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/eikendev/java-decompiler/ci.yaml?branch=main"/></a>&nbsp;
	<a href="https://github.com/eikendev/java-decompiler/pkgs/container/java-decompiler"><img alt="Image" src="https://img.shields.io/badge/ghcr.io-eikendev%2Fjava--decompiler-blue"/></a>&nbsp;
	<a href="https://github.com/eikendev/java-decompiler/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/eikendev/java-decompiler"/></a>&nbsp;
</p>

## 🤔&nbsp;Why

No decompiler gets everything right.
Obfuscated code, unusual compilers (Kotlin, Scala, Groovy), or hand-crafted bytecode break each engine in different places, so the fastest way to a readable result is to run several and compare.
Installing five decompilers with their Java and Rust toolchains is tedious; pulling one image is not.

This also makes the image a convenient front-end for AI-assisted reverse engineering: language models work on source code, not bytecode.
Point the image at a JAR, then let your assistant read `./outfiles`.
See [Using with AI assistants](#-using-with-ai-assistants).

## 📄&nbsp;Usage

Create three directories next to each other:

- `./infiles`: the `.jar`, `.war`, `.ear`, `.class`, `.apk` or `.dex` files to decompile
- `./libfiles`: optional JARs the inputs depend on (helps CFR and Vineflower resolve types)
- `./outfiles`: empty, receives one directory per input and engine

Then run the image.

```bash
docker run --rm -ti \
	--user "$(id -u):$(id -g)" \
	-v "$PWD/infiles:/infiles:ro" \
	-v "$PWD/libfiles:/libfiles:ro" \
	-v "$PWD/outfiles:/outfiles" \
	ghcr.io/eikendev/java-decompiler:latest
```

With [Podman](https://podman.io/) use `--userns=keep-id` instead of `--user`, and add `:Z` to the volume flags on SELinux systems.
`make run` does exactly that.

The image is published for `linux/amd64` and `linux/arm64`, so it runs natively on Apple Silicon and ARM servers.

### Output

For an input `app.jar` you get:

```
outfiles/
├── app.jar-cfr/            # CFR
├── app.jar-cfr.log         # engine log
├── app.jar-vineflower/     # Vineflower
├── app.jar-procyon/        # Procyon
├── app.jar-jadx/           # jadx
└── app.jar-krakatau/       # Krakatau disassembly (.j files)
```

For an APK, jadx decompiles the APK directly (`app.apk-jadx/`), dex2jar converts it to `app.apk-dex2jar/app.apk.jar`, and that JAR is then run through the JVM engines (`app.apk.jar-cfr/`, …).

Existing output directories are skipped, so re-running after adding files only processes what is new.
Engines run in parallel and a crashing engine never stops the others.
The exit code is `2` if any engine failed, with the reason in its `.log` file.

### Options

All options are environment variables (`docker run -e NAME=value …`).

| Variable | Default | Purpose |
|---|---|---|
| `DECOMPILERS` | `cfr,vineflower,procyon,jadx,krakatau` | Engines to run |
| `JOBS` | number of CPUs, at most 4 | Engines running concurrently |
| `JAVA_OPTS` | `-XX:MaxRAMPercentage=25` | JVM flags for every Java based engine (`JAVA_XMX=4G` is still honoured) |
| `FORMAT` | `1` | Reformat all `.java` output with astyle for easier diffing between engines; `0` disables |
| `CFR_ARGS`, `VINEFLOWER_ARGS`, `PROCYON_ARGS`, `JADX_ARGS`, `KRAKATAU_ARGS` | empty | Extra arguments passed to the engine |
| `JADX_ANDROID_ARGS` | `--deobf` | Extra jadx arguments for APK/DEX inputs only |

Example: only the two strongest engines, with 8 GB of heap each.

```bash
docker run --rm --user "$(id -u):$(id -g)" -e DECOMPILERS=cfr,vineflower -e JAVA_XMX=8G \
	-v "$PWD/infiles:/infiles:ro" -v "$PWD/libfiles:/libfiles:ro" -v "$PWD/outfiles:/outfiles" \
	ghcr.io/eikendev/java-decompiler:latest
```

## 🤖&nbsp;Using with AI assistants

Decompilers are deterministic and fast; language models are good at the part decompilers are bad at, namely naming things and explaining intent.
A workflow that works well:

1. Run the image on the artifact, keeping at least two engines so the assistant can cross-check where one produced nonsense.
2. Open `./outfiles` in your coding assistant (for example Claude Code or Cursor) and ask it to summarise the code, rename obfuscated identifiers, or look for a specific behaviour, mentioning that the `-cfr` and `-vineflower` directories contain the same classes from different decompilers.
3. For stubborn methods, point it at the `-krakatau` directory, whose disassembly is exactly what the JVM sees and does not depend on any decompiler heuristics.

Because every input is processed in one shot and written to plain files, the image slots into any agent pipeline that can run a container and read a directory.

## 🔧&nbsp;Included tools

| Tool | Version | Role |
|---|---|---|
| [CFR](https://www.benf.org/other/cfr/) | 0.152 | Decompiler, strong on modern Java language features |
| [Vineflower](https://vineflower.org/) | 1.12.0 | Decompiler, actively maintained fork of JetBrains' Fernflower with Kotlin support |
| [Procyon](https://github.com/mstrobel/procyon) | 0.6.0 | Decompiler, from the Debian package |
| [jadx](https://github.com/skylot/jadx) | 1.5.6 | Decompiler for APK/DEX and JARs, with deobfuscation |
| [Krakatau](https://github.com/Storyyeller/Krakatau) | v2 (git) | Robust disassembler for obfuscated or malformed class files |
| [dex2jar](https://github.com/ThexXTURBOXx/dex2jar) | 2.4.38 | DEX to JAR conversion so the JVM engines can read APKs |
| [astyle](https://astyle.sourceforge.net/) | Debian | Uniform formatting of all output |

For background on these tools, see the [related blog post](https://eiken.dev/blog/2021/02/how-to-break-your-jar-in-2021-decompilation-guide-for-jars-and-apks/).

## 🔒&nbsp;Security

Decompilers parse untrusted input, so the image is built to limit what a malicious file can reach:

- Runs as an unprivileged user, and the input volumes can be mounted read-only.
- Every tool is pinned to a specific release and fetched from its upstream GitHub release page.
- Images are built for both architectures on GitHub Actions with SBOM and SLSA provenance attached, and the manifest is signed with [cosign](https://github.com/sigstore/cosign) (keyless):

  ```bash
  cosign verify ghcr.io/eikendev/java-decompiler:latest \
  	--certificate-identity-regexp 'https://github.com/eikendev/java-decompiler/' \
  	--certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```
- The image is rebuilt weekly so Debian security updates land without a code change.

Tagged releases are available as `ghcr.io/eikendev/java-decompiler:<version>` next to `latest`.

## 🛠️&nbsp;Development

```bash
make build            # build the image locally with Podman (RUNTIME=docker for Docker)
make test             # build and run the smoke test
make check            # static checks (shellcheck)
```

Decompiler versions are build arguments at the top of the `Dockerfile`.
Renovate opens pull requests for new decompiler releases, base images, and GitHub Actions.
