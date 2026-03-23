# Build From Stock

This repo assumes you start from raw Samsung stock artifacts and work forward in stages.

## Inputs

At minimum, collect:
- `imsservice.apk`
- `imsmanager.jar`
- `ImsTelephonyService.apk`

## Tooling

Recommended tools:
- `baksmali`
- `apktool`
- `zipalign`
- `signapk.jar` or equivalent ROM signing flow
- JDK 17+

## Basic Workflow

1. Extract `classes.dex` from the stock APK/JAR.
2. Decompile with `baksmali` for patch review.
3. Apply the stage patch that matches the problem you are solving.
4. Rebuild the artifact.
5. Sign it with the platform key required by the target ROM branch.
6. Replace the artifact in a test image or bind-mount it live.
7. Validate one problem area at a time.

## Why The Stages Matter

Trying to jump straight from stock Samsung IMS to a fully customized end-state is brittle.
The staged layout helps you answer questions like:
- did `imsservice` even boot on AOSP?
- did the framework bridge bind?
- did registration complete?
- did outgoing IMS calls route correctly?
- did incoming calls regress later?

## Notes

- `ImsTelephonyService.apk` is included in the component map, but this repo does not currently export a stable smali patch for it because the main work in this port stayed focused on `imsservice.apk` and `imsmanager.jar`.
- Device-specific signing, init, manifest, permission, and SELinux work should stay in the ROM trees.
- The entries in [example-hashes.csv](/home/schr-0dinger/Samsung/samsung-ims-patches/artifacts/example-hashes.csv) are illustrative samples, not required filenames or paths.
