# Stage 00: Historical Bootstrap Reference

This stage preserves the earlier `android_samsung_imsservice` style of Samsung IMS bootstrapping for AOSP.

Why keep it:
- it explains the original compat mindset
- it shows how Samsung IMS was first coerced into AOSP-compatible shapes
- it remains useful as a reference when porting across devices

Why not treat it as the whole answer:
- later ports still needed additional registration, capability, signing, and call-path work
- the bootstrap alone is usually not enough for a stable modern port

Reference patch:
- `patches/0001-upstream-bootstrap-from-android_samsung_imsservice.patch`
