#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <input-apk-or-jar> <dex-entry> <output-dir>" >&2
  exit 1
fi

INFILE="$1"
DEX_ENTRY="$2"
OUTDIR="$3"
TMPDEX="$OUTDIR/classes.dex"

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"
unzip -p "$INFILE" "$DEX_ENTRY" > "$TMPDEX"
baksmali d "$TMPDEX" -o "$OUTDIR/smali"

echo "Wrote smali to $OUTDIR/smali"
