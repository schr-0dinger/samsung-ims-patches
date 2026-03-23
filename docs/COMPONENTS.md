# Components

## `imsservice.apk`

This is the main Samsung IMS runtime and carries most of the AOSP-compat, registration, and call-routing work.

## `imsmanager.jar`

This jar influences feature exposure and profile/capability behavior seen by the framework.
In this port, it needed small but important smali-level fixes.

## `ImsTelephonyService.apk`

This component still matters for a complete ROM port, but this repo does not ship a stable code patch for it yet.
For the A9 work, the practical focus stayed on:
- `imsservice.apk`
- `imsmanager.jar`

If you need to touch `ImsTelephonyService.apk` on a different port, treat it as a separate stage and keep the patch narrow.
