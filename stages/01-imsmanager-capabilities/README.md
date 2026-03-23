# Stage 01: `imsmanager.jar` Capability And Profile Fixes

This stage patches the Samsung `imsmanager.jar` side first.

Focus:
- capability exposure
- emergency/profile extension behavior
- profile parsing that later affects framework-visible IMS behavior

When to use it:
- framework sees Samsung IMS but capability/profile behavior is obviously wrong
- you need a minimal jar-side patch before digging into `imsservice.apk`
