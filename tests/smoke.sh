#!/usr/bin/env bash
#
# Smoke test: decompile a small JAR that ships inside the image with every
# engine and check that each engine produced output.
#
# Usage: tests/smoke.sh <image> [docker|podman]

set -euo pipefail

image="${1:?usage: $0 <image> [docker|podman]}"
runtime="${2:-docker}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/infiles" "$work/libfiles" "$work/outfiles"

# dex2jar ships a tiny JAR; use it as the fixture so no JDK is needed here.
"$runtime" run --rm --entrypoint sh "$image" -c 'cat /opt/dex2jar/lib/d2j-base-cmd-*.jar' >"$work/infiles/sample.jar"
test -s "$work/infiles/sample.jar"

user_flag=(--user "$(id -u):$(id -g)")
[[ "$runtime" == podman ]] && user_flag=(--userns=keep-id)

set +e
"$runtime" run --rm "${user_flag[@]}" \
	-v "$work/infiles:/infiles:Z,ro" \
	-v "$work/libfiles:/libfiles:Z,ro" \
	-v "$work/outfiles:/outfiles:Z,rw" \
	"$image"
status=$?
set -e

echo "exit status: $status"
ls -la "$work/outfiles"

fail=0
for engine in cfr vineflower procyon jadx; do
	n="$(find "$work/outfiles/sample.jar-$engine" -type f -name '*.java' | wc -l)"
	echo "$engine: $n .java files"
	(( n > 0 )) || { echo "FAIL: $engine produced no .java files"; cat "$work/outfiles/sample.jar-$engine.log" || true; fail=1; }
done
n="$(find "$work/outfiles/sample.jar-krakatau" -type f -name '*.j' | wc -l)"
echo "krakatau: $n .j files"
(( n > 0 )) || { echo "FAIL: krakatau produced no .j files"; cat "$work/outfiles/sample.jar-krakatau.log" || true; fail=1; }

(( status == 0 )) || fail=1
exit $fail
