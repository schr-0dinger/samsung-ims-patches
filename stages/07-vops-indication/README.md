# Stage 07: VoPS Indication

Fixes an off-by-one that left `PdnController` believing the network's VoPS state
was unknown, so it never brought up the IMS PDN and registration could not start.

## Symptom

```
dumpsys secims
  PdnController State: phoneId: 0 ... mVopsIndication: UNKNOWN
  IMS SIP messages history:            (empty)
dumpsys telephony.registry / logcat
  ims:[state=IDLE,enabled=false]       (IMS apnContext never enabled)
  pcscf=[]                             (no P-CSCF on any bearer)
```

The framework side looks healthy the whole time: the modem reports
`LteVopsSupportInfo mVopsSupport = 2 (SUPPORTED)`, `useImsForCall=true` and
`imsPhone.isVolteEnabled()=true`. Only the Samsung stack disagrees, and the dex
carries both outcomes as strings - `"VoPS Supported. Registration over IMS pdn."`
versus `"by VoPS policy: remove all service"`.

## Cause

`ServiceStateExt` resolves its constants by reflecting into
`android.telephony.ServiceState`. Those fields are Samsung additions, so on AOSP
every lookup throws `NoSuchFieldException` and the **defaults** apply:

```smali
LTE_IMS_VOICE_AVAIL_UNKNOWN     = getIntField("...UNKNOWN", 1)      -> 1
LTE_IMS_VOICE_AVAIL_SUPPORT     = getIntField("...SUPPORT", 2)      -> 2
LTE_IMS_VOICE_AVAIL_NOT_SUPPORT = getIntField("...NOT_SUPPORT", 3)  -> 3
```

`ServiceStateWrapper.getLteImsVoiceAvail()` had already been stubbed to return a
constant, but it returned `1` - which on AOSP is **UNKNOWN**, not "supported".
`VoPsIndication.translateVops(1)` therefore yielded `UNKNOWN`, and the PDN
controller refused to bring up the IMS bearer.

The value required is `2`.

## Patch

One instruction:

```smali
.method public getLteImsVoiceAvail()I
-   const/4 v0, 0x1
+   const/4 v0, 0x2
    return v0
.end method
```

## Verified

`mVopsIndication` flips `UNKNOWN` -> `SUPPORTED` on the SIM slot (the empty slot
correctly stays `UNKNOWN`), and it survives a full airplane-mode cycle.

## Clear the IMS databases after changing CSC

The stack caches its service switches in the `com.sec.imsservice` /`com.sec.ims`
databases and does not re-read them once written. A device that first booted
without CSC stores `mmtel=0`, and `VolteServiceModule.updateFeature()` then logs
`Update Feature [... Feature: 0]` forever - no features, so nothing to register -
even after CSC is fixed. `DmConfigHelper.getImsSwitchValue()` returning 1 does not
help, because the second half of the gate is `readSwitch("mmtel", default=true)`,
and `readSwitch` only falls back to the default when *nothing* is stored.

```bash
adb shell pm clear com.sec.imsservice
adb shell pm clear com.sec.ims
adb reboot
```

Verified: `Feature: 0` -> non-zero after clearing and rebooting. Do this after any
CSC change, or the new profile is ignored.

## Not sufficient on its own

With VoPS correct and every `PdnController` precondition satisfied
(`mDataConnectionState: true`, `mEmergencyOnly: false`), the IMS apnContext is
*still* `enabled=false` and no SIP REGISTER is sent. There is at least one more
gate between "preconditions met" and "request the IMS PDN". Next places to look:

- `RegistrationGovernorImpl` / `RegistrationGovernorRjil` decision path
- `ImsServiceSwitchBase` / `ImsServiceSwitchEur` switch state (stage 03 touches these)
- whether the framework ever drives `turnOnIms` / `changeEnabledCapabilities`
  into `com.sec.internal.google.GoogleImsServiceAdapter` - no such log lines appear

## Caveat

This hardcodes "supported" rather than reading the real value. That is accurate
on a VoPS network (Jio reports `mVopsSupport=2`), but on a network without VoPS
the stack will now attempt IMS anyway. The correct long-term form reads
`ServiceState.getNetworkRegistrationInfo(DOMAIN_PS, TRANSPORT_WWAN)`
`.getDataSpecificInfo().getLteVopsSupportInfo()` and maps it onto the same
constants. Worth doing before this ships publicly - a wrong VoPS assumption is
what wedged calls on a CSFB carrier previously.
