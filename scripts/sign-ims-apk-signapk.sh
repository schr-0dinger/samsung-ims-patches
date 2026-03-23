#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 || $# -gt 6 ]]; then
  echo "usage: $0 <input-unsigned.apk> <output-signed.apk> <signapk.jar> <platform.x509.pem> <platform.pk8> [zipalign-bin]" >&2
  exit 1
fi

IN_APK="$1"
OUT_APK="$2"
SIGNAPK_JAR="$3"
PLATFORM_PEM="$4"
PLATFORM_PK8="$5"
ZIPALIGN_BIN="${6:-zipalign}"
ALIGNED="${OUT_APK%.apk}.aligned.apk"

"$ZIPALIGN_BIN" -f 4 "$IN_APK" "$ALIGNED"
java -jar "$SIGNAPK_JAR" "$PLATFORM_PEM" "$PLATFORM_PK8" "$ALIGNED" "$OUT_APK"
sha256sum "$OUT_APK"
