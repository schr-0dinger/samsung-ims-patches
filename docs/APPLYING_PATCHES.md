# Applying Patches

This repo is meant to be followed as a ladder, not consumed as one giant diff.

## Recommended Order

1. start from raw Samsung stock artifacts
2. decompile the target component
3. apply the stage patch that matches your current blocker
4. rebuild and sign
5. test only that stage's expected outcome
6. move to the next stage only after the previous one is stable

## Typical Per-Stage Workflow

For an APK such as `imsservice.apk`:
1. extract `classes.dex`
2. decompile with `baksmali`
3. apply the stage patch against the decompiled smali tree
4. rebuild the APK
5. sign with the platform key expected by the target ROM
6. replace the artifact in a test image or bind-mount it live
7. verify the specific behavior that stage is supposed to unlock

For a JAR such as `imsmanager.jar`:
1. extract `classes.dex`
2. decompile with `baksmali`
3. apply the patch
4. rebuild the JAR
5. repack into the target ROM tree
6. reboot and verify framework-visible behavior

## Helper Scripts

- [extract-dex-smali.sh](/home/schr-0dinger/Samsung/samsung-ims-patches/scripts/extract-dex-smali.sh)
  Extracts `classes.dex` and decompiles it with `baksmali`.
- [make-smali-diff.sh](/home/schr-0dinger/Samsung/samsung-ims-patches/scripts/make-smali-diff.sh)
  Creates a text diff between two decompiled smali trees.
- [sign-ims-apk-signapk.sh](/home/schr-0dinger/Samsung/samsung-ims-patches/scripts/sign-ims-apk-signapk.sh)
  Example signing flow for APK rebuilds.
- [live-bind-imsservice.sh](/home/schr-0dinger/Samsung/samsung-ims-patches/scripts/live-bind-imsservice.sh)
  Example live bind-mount workflow for rapid device-side testing.

## Expected Milestones

- after Stage 01:
  capability and profile exposure are less broken
- after Stage 02:
  `imsservice` survives better on AOSP
- after Stage 03:
  IMS registration and switch state start behaving sensibly
- after Stage 04:
  the framework bridge is strong enough for outgoing IMS call routing
- after Stage 05:
  incoming-call behavior can be experimented on in isolation

## Keep The Boundary Clean

This repo stops at Samsung IMS artifacts and their immediate bridge behavior.
If you need to change:
- device makefiles
- init scripts
- SELinux policy
- framework overlays
- proprietary packaging

do that in the actual ROM trees, not here.
