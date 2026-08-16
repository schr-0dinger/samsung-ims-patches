# Stage 08: Missing Samsung Framework Classes

The two crashes that stopped IMS registration completing on AOSP. With stage 07
(VoPS) and correct CSC in place, this stage is what makes VoLTE actually register.

**Verified on Jio (405862), SM-A920F, QASSA Android 10:**

```
[-->] REGISTER sip:ims.mnc862.mcc405.3gppnetwork.org  [CSeq: 1]
[<--] SIP/2.0 401 Unauthorized                         (IMS-AKA challenge)
[-->] REGISTER                                         [CSeq: 2]
[<--] SIP/2.0 200 OK
[-->] SUBSCRIBE tel:...  -> 200 OK
[<--] NOTIFY             -> 200 OK

UserAgent State: [RegisteredState], Profile: [RJIL VoLTE(#388)]
onRegistrationStatusChanged: registered[true], response [0], 403Forbidden Count [0]
```

Incoming calls arrive - on a VoLTE-only carrier that is only possible over a live
IMS registration.

## Patch 1 - ImsProfile.getEnableEvsCodec()

```
java.lang.NoClassDefFoundError: Lcom/samsung/android/feature/SemFloatingFeature;
  at ImsProfile.getEnableEvsCodec(ImsProfile.java:2417)
  at ImsProfile.getAudioCodec
  at ResipRegistrationManager.configureMedia
  at ResipRegistrationManager.createUserAgent
  at ResipRegistrationManager.registerInternal
  at RegistrationManagerBase.onPdnConnected
```

The IMS PDN connects, then the stack dies building the SIP user agent while
querying `SEC_FLOATING_FEATURE_COMMON_SUPPORT_EVS`. init restarts it, the PDN
comes up again, it dies again - roughly every 15 seconds, forever. Returning 0
(EVS disabled) is safe: VoLTE runs on AMR/AMR-WB.

**`ImsProfile` exists in BOTH `imsservice.apk` and `imsmanager.jar`.** The jar is
on the framework classpath and wins. Patching only the APK changes nothing - the
crash continues at an identical stack frame. Patch both.

## Patch 2 - ImsRegistration.<clinit>

```
java.lang.NoClassDefFoundError: Landroid/os/SemSystemProperties;
  at ImsRegistration.<clinit>(ImsRegistration.java:75)
  at ImsRegistration.getBuilder
  at UserAgent.buildImsRegistration
  at UserAgent$RegisteredState.onRegistered
  at UserAgent$RegisteredState.enter
```

Note the frames: this fires *inside* `RegisteredState.enter()`, so the network had
already returned `200 OK`. Registration succeeded and the stack crashed while
reporting it. The static initializer only reads `ro.product_ship` to set a
`SHIP_BUILD` flag; `android.os.SystemProperties` is a drop-in replacement and is
already used elsewhere in the same code.

## Applying

Patch the smali in both artifacts, reassemble, re-sign the APK with the platform
key (`vendor/qassa/signing/platform.{pk8,x509.pem}`), then install:

```bash
adb push imsmanager.jar /data/local/tmp/ && adb push imsservice.apk /data/local/tmp/
adb shell su -c 'mount -o rw,remount /; \
  cp /data/local/tmp/imsmanager.jar /system/framework/imsmanager.jar; \
  cp /data/local/tmp/imsservice.apk /system/priv-app/imsservice/imsservice.apk; \
  chmod 644 ...; chcon u:object_r:system_file:s0 ...; \
  rm -rf /data/dalvik-cache/*/system@framework@imsmanager.jar*'
```

Clearing the jar's dalvik-cache entry matters - ART otherwise keeps running the
old dex.

## Follow-up - all resolved in stage 09

Three things were recorded here as open. See
[stage 09](../09-isim-gate-and-aosp-compat/README.md) for the fixes.

**Registration does not start by itself after a normal boot.** Real, and fixed.
The cause was not a missing trigger: `SimManager.isSimAvailable()` gates every
register task on `mIsimLoaded`, which is only set from the Samsung-only
`android.intent.action.ISIM_LOADED` broadcast that AOSP never sends. With
`ril.hasisim=1` it stayed false forever. `kill -9` was never a trigger - the
restarted receiver just picked the broadcast up late.

**`Feature` resets to 0 on every reboot.** ~~Needs `pm clear` after each boot.~~
This was wrong. The switches persist correctly (`imsswitch_0.xml` keeps
`mmtel=true volte=true`, `imsfeature_0.xml` keeps `volte=1`), and `UPD MNO:false`
is the normal unchanged-SIM path - the successful registration documented above
logged `UPD MNO:false` seconds before `InitialRegi`. No `pm clear` is needed.

**Other `Sem*` references remain.** Real, and swept in stage 09. The list here
was also incomplete: it missed `UserHandle.SEM_CURRENT`,
`ToneGenerator.semSetVolume` and `android.os.SemHqmManager`, and it named
several classes (`SoftphoneClient`, `OmcCode`, `MessagingAppInfoReceiver`,
`RegistrationGovernorImpl`) that were already safe because `SemCscFeature` and
`SemFloatingFeature` stubs are bundled in the APK.

## Note on diagnosis

None of this was visible without root. The service restarts every ~15s, so
`dumpsys` only ever shows a freshly-initialised process - which reads as "nothing
is happening" rather than "it crashed". `adb shell am force-stop` does not restart
it; `kill -9` does. The real evidence is `/data/log/imscr/imscr.log.0` plus the
crash buffer.
