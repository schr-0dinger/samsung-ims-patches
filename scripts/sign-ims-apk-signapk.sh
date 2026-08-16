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

# signapk.jar needs libconscrypt_openjdk_jni.so, which lives next to it in the
# AOSP host output. Without java.library.path it dies in NativeCrypto.<clinit>
# with UnsatisfiedLinkError before it ever looks at the APK.
LIB_DIR="${SIGNAPK_LIB_PATH:-$(dirname "$SIGNAPK_JAR")/../lib64}"

"$ZIPALIGN_BIN" -f 4 "$IN_APK" "$ALIGNED"
java -Djava.library.path="$LIB_DIR" -jar "$SIGNAPK_JAR" \
  "$PLATFORM_PEM" "$PLATFORM_PK8" "$ALIGNED" "$OUT_APK"

# classes.dex must stay 4-byte aligned or ART maps it the slow way.
"$ZIPALIGN_BIN" -c -v 4 "$OUT_APK" | grep -E 'classes\.dex|Verification'
sha256sum "$OUT_APK"
