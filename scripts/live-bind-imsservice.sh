#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <imsservice-signed.apk>" >&2
  exit 1
fi

APK="$1"
REMOTE="/sdcard/Download/$(basename "$APK")"

adb push "$APK" "$REMOTE"
adb shell su -c "mount --bind '$REMOTE' /system/priv-app/imsservice/imsservice.apk && sha256sum /system/priv-app/imsservice/imsservice.apk"
adb shell su -c 'am force-stop com.sec.imsservice; am force-stop com.android.phone; sleep 2; pidof com.android.phone com.sec.imsservice || true'
