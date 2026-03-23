# Samsung IMS Patches

A fresh, tutorial-style repository for bringing Samsung IMS components onto AOSP and custom ROMs.

This repo is intentionally centered on Samsung IMS itself:
- `imsservice.apk`
- `imsmanager.jar`
- Samsung-to-AOSP compat glue
- registration and call-routing patches
- staged patch files you can study and apply from raw stock artifacts

It is not a device tree, vendor tree, or full ROM port.
Device-specific packaging, SELinux, init, and product integration belong in the target DT/VT.

## What This Repo Tries To Be

This is a walkthrough, not a dump.

The stages are organized the way the work usually unfolds on a real port:
1. understand the original upstream Samsung IMS bootstrap work
2. patch `imsmanager.jar`
3. make `imsservice.apk` safer on AOSP
4. unlock registration and switch state
5. fix framework bridging and outgoing IMS calls
6. layer incoming-call experiments separately
7. keep optional RCS/TAPI relaxations clearly marked as optional

## Stage Ladder

- `stages/00-historical-bootstrap/`
  Historical upstream bootstrap reference based on `android_samsung_imsservice`.
- `stages/01-imsmanager-capabilities/`
  Early `imsmanager.jar` capability/profile fixes.
- `stages/02-imsservice-aosp-safety/`
  Samsung helper and framework-state fixes that make `imsservice` survive on AOSP.
- `stages/03-registration-and-switches/`
  Registration, DM switch, and carrier-governor changes.
- `stages/04-framework-bridge-and-outgoing-calls/`
  Compat MMTEL bridge, radio-tech callbacks, and outgoing-call routing.
- `stages/05-incoming-call-experiments/`
  Later incoming-call and MT-call path experiments.
- `stages/06-optional-rcs-relaxations/`
  Non-core optional deltas kept out of the main ladder.

## Start Here

- [APPLYING_PATCHES.md](/home/schr-0dinger/Samsung/samsung-ims-patches/docs/APPLYING_PATCHES.md)
- [BUILD_FROM_STOCK.md](/home/schr-0dinger/Samsung/samsung-ims-patches/docs/BUILD_FROM_STOCK.md)
- [COMPONENTS.md](/home/schr-0dinger/Samsung/samsung-ims-patches/docs/COMPONENTS.md)
- [STAGE_GUIDE.md](/home/schr-0dinger/Samsung/samsung-ims-patches/docs/STAGE_GUIDE.md)
- [artifacts/example-hashes.csv](/home/schr-0dinger/Samsung/samsung-ims-patches/artifacts/example-hashes.csv)

## Scope Boundary

Keep these outside this repo:
- device-tree patches
- vendor makefile changes
- board SELinux policy changes
- encryption / fstab bring-up
- generic ROM QA notes

Those belong in the ROM trees that consume these IMS artifacts.
