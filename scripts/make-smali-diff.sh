#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "usage: $0 <old-root> <new-root> <output.patch> <relative-path>..." >&2
  exit 1
fi

OLDROOT="$1"
NEWROOT="$2"
OUTPATCH="$3"
shift 3

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$WORKDIR/old" "$WORKDIR/new"

for rel in "$@"; do
  mkdir -p "$WORKDIR/old/$(dirname "$rel")" "$WORKDIR/new/$(dirname "$rel")"
  cp "$OLDROOT/$rel" "$WORKDIR/old/$rel"
  cp "$NEWROOT/$rel" "$WORKDIR/new/$rel"
done

(
  cd "$WORKDIR"
  diff -urN old new || true
) | sed -e 's#--- old/#--- a/#' -e 's#+++ new/#+++ b/#' > "$OUTPATCH"

echo "Wrote $OUTPATCH"
