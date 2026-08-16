# Stage 09: ISIM Gate And Remaining AOSP Compatibility

Stage 08 got registration to complete, but only when the IMS service was
restarted by hand after boot. This stage finds why, and clears the remaining
Samsung API references that had not yet been hit.

**Verified on Jio (405862), SM-A920F, QASSA Android 10:** three consecutive cold
boots, no `pm clear`, no `kill -9`, registered unaided at 84 s / 85 s / 98 s
uptime. Zero FATALs, zero `NoClassDefFoundError`.

## Patch 1 - the reason registration never started by itself

`SimManager.isSimAvailable()` gates every register task on:

```
mSimState == LOADED && (mIsimLoaded || !hasIsim())
```

`mIsimLoaded` is only ever set from the `android.intent.action.ISIM_LOADED`
broadcast. That intent is a Samsung telephony addition - **AOSP never sends it
on a cold boot.** The SIM in this device reports `ril.hasisim=1,0`, so slot 0
has an ISIM, the second clause is false forever, and the method returns false
permanently. It is polled every 10 seconds:

```
I SimManager: mSimState:LOADED, mIsimLoaded:false, hasIsim():true
I SimManager: mSimState:LOADED, mIsimLoaded:false, hasIsim():true
...
```

No `RegisterTask` is ever built, so nothing reaches `tryRegister`, and the log
simply stops after the SIM loads:

```
0x1000000D:0,LOADED,RJIL_IN,1
0x10010000:0,UPD MNO:false
0x30000009:0,0->13            <- LTE attached
0x13000012:0,MN:true,WN:false
<nothing>
```

The fix drops the ISIM clause - a `LOADED` SIM is available. ISIM
authentication is unaffected: it is done on demand through the modem
(`REQ ISIM AUTH` in the trace, answered in ~1 s) and never reads this flag.

This is also why `kill -9` appeared to be a magic trigger. It is not a trigger
at all - the restarted receiver simply picks the broadcast up, because by then
the SIM has long since loaded. `am force-stop` does not restart the service, so
it never had the same effect.

## Patch 1 (cont.) - remaining Samsung API references

A reference sweep of both artifacts, rather than waiting for each crash, found
what was left. `SemCscFeature` (130 refs) and `SemFloatingFeature` (42 refs)
already had stub classes bundled. The rest:

| Reference | Where | Fix |
|---|---|---|
| `SemEmergencyManager` | `ImsUtil`, `RegistrationManagerBase`, `SmsServiceModule` | stub class, `isEmergencyMode`/`checkModeType` return false |
| `android.os.SemHqmManager` | `RcsHqmAgent`, `SmsServiceModule` | both `sendHWParamToHQM` methods return false |
| `UserHandle.SEM_CURRENT` | `GeolocationController` (7 sites) | `UserHandle.CURRENT` |
| `ToneGenerator.semSetVolume(F)` | `ResipMediaHandler$RingBackToneHandler` | `stopTone()` |

Notes on two of these:

- **HQM** is Samsung's Hardware Quality Monitor telemetry. `getSystemService("HqmManagerService")`
  returns null on AOSP, and the `check-cast` to the missing type throws
  `NoClassDefFoundError` - which the method's `NullPointerException` and
  `ClassCastException` handlers do **not** catch. Reached from RCS capability
  exchange, so it is live code, not a dead path.
- **`semSetVolume`** is on the outgoing-call ringback mute path. Volume is
  otherwise only applied through the `ToneGenerator` constructor and unmute
  rebuilds the generator, so `stopTone()` is the equivalent behaviour.

`com/samsung/android/ims/*` (`SemImsRegistration`, `SemImsRegistrationError`,
`ISemImsService$Stub`, `ISemImsRegistrationListener`) is deliberately **left
alone**. `ImsServiceStub` only reaches it via:

```smali
sget v2, Landroid/os/Build$VERSION;->SEM_INT:I
const/16 v3, 0xa9c
if-lt v2, v3, :cond_1a7
invoke-static {...}, ...SemImsServiceStub;->makeSemImsService(...)
:catch_1a8   # NoSuchFieldError
```

`SEM_INT` does not exist on AOSP, so the `NoSuchFieldError` is caught and
`SemImsServiceStub` is never loaded. Stubbing a Parcelable AIDL surface would
have been real risk for no gain.

## Patch 2 - imsmanager.jar

One reference remained in the jar, `TelephonyManagerExt.isRoaming()`:

```smali
- invoke-static {v0}, Landroid/os/SemSystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;
+ invoke-static {v0}, Landroid/os/SystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;
```

After this the jar has **zero** Samsung-only references. Remember the split
from stage 08: `imsmanager.jar` is on the framework classpath and cannot see
classes bundled in the APK, so stubs added to the APK never help the jar.

## Corrections to stage 08

Two things recorded there as open were wrong:

- "`Feature` resets to 0 on every reboot, `pm clear` needed each boot" - it
  does not. `imsswitch_0.xml` keeps `mmtel=true volte=true mmtel-video=true`
  and `imsfeature_0.xml` keeps `volte=1` across reboots. `UPD MNO:false` is the
  normal unchanged-SIM path and is harmless; the successful registration on
  14:18 also logged `UPD MNO:false` immediately before `InitialRegi`. The
  `DeviceConfigManager` `gsUpdated` guard was suspected and is **not** the bug.
- "Registration does not start by itself" - correct, but the cause was the ISIM
  gate above, not a missing trigger in `tryRegister`.

The lesson repeated from stage 08: measure the failing boot instead of reasoning
from the code path that looks suspicious. Both wrong hypotheses above were
plausible from reading smali alone.

## Applying

Patch the smali, reassemble both artifacts, re-sign the APK with the platform
key, then install as in stage 08 - including clearing the jar's dalvik-cache
entry, which still matters.
