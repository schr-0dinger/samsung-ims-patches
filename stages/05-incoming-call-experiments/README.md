# Stage 05: Incoming Call Experiments

Incoming-call handling is easy to regress, especially on dual-SIM devices.

This stage is intentionally isolated from the outgoing-call ladder.

Focus:
- incoming-call `PendingIntent` flow
- MT-call dispatch path
- duplicate-slot and wrong-phone-instance handling

Apply only after outgoing IMS calling is already healthy.
