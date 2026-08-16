#!/usr/bin/env bash
# Reboot the device and watch for IMS registration with no manual help.
#
# This is the harness behind the stage 09 claim. The failure it catches is
# specifically "registration only happens if you restart the service by hand",
# so it must never touch the device between boot and registration - no
# `pm clear`, no `kill -9`. It also records the imsservice process age, which
# is what proves the service started once and was not restarted by a crash
# loop: if the age tracks uptime, nothing restarted it.
#
# usage: verify-cold-boot-registration.sh [label] [max-seconds]
#
# Requires adb with root (su) on the device.

set -uo pipefail

LABEL="${1:-run}"
MAX="${2:-360}"

echo "[$LABEL] rebooting"
adb reboot
sleep 5
adb wait-for-device

for _ in $(seq 1 60); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
echo "[$LABEL] boot_completed at uptime $(adb shell cat /proc/uptime | tr -d '\r' | cut -d' ' -f1)s"

start=$(date +%s)
registered=""
up=""
while [ $(( $(date +%s) - start )) -lt "$MAX" ]; do
  up=$(adb shell cat /proc/uptime 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
  proc=$(adb shell 'su -c "ps -A -o PID,ETIME,ARGS"' 2>/dev/null | grep 'com.sec.imsservice$' | tr -s ' ')
  reg=$(adb shell 'su -c "dumpsys secims"' 2>/dev/null | grep -E 'UserAgent .* State:' | tail -1 | tr -d '\r')
  fatal=$(adb shell 'su -c "logcat -b crash -d"' 2>/dev/null | grep -c FATAL)
  echo "[$LABEL] up=${up}s proc=[${proc}] fatal=${fatal} ${reg}"
  case "$reg" in
    *RegisteredState*) registered=yes; break ;;
  esac
  sleep 15
done

echo "[$LABEL] ==== RESULT ===="
if [ -n "$registered" ]; then
  echo "[$LABEL] REGISTERED UNAIDED at uptime ${up}s"
else
  echo "[$LABEL] NOT REGISTERED within ${MAX}s"
fi

echo "[$LABEL] isSimAvailable inputs:"
adb shell 'su -c "logcat -d -s SimManager"' 2>/dev/null | grep -a 'mIsimLoaded' | tail -3

echo "[$LABEL] registration trace:"
adb shell 'su -c "grep -aE \"UPD MNO|InitialRegi|REG OK\" /data/log/imscr/imscr.log.0"' 2>/dev/null | tail -10

echo "[$LABEL] NoClassDefFoundError: $(adb shell 'su -c "logcat -b crash -d"' 2>/dev/null | grep -c NoClassDefFoundError)"
