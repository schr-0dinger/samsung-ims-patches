# Stage Guide

## Stage 00: Historical Bootstrap

Use this to understand the earlier Samsung IMS-to-AOSP strategy that inspired the later work.
It is a reference stage, not the main patch ladder for every modern port.

## Stage 01: `imsmanager.jar`

Apply this first if the framework never surfaces sane Samsung IMS capability/profile behavior.

## Stage 02: `imsservice.apk` AOSP Safety

Apply this when `imsservice` crashes, misreports framework registration state, or trips Samsung-specific helper paths on AOSP.

## Stage 03: Registration And Switches

Apply this when IMS boots but still refuses to register, keeps the wrong service switch state, or stalls in carrier-governor logic.

## Stage 04: Framework Bridge And Outgoing Calls

Apply this when backend registration is present but Android still does not route calls over IMS.

## Stage 05: Incoming Call Experiments

Apply these only after outgoing IMS routing is already healthy.
They intentionally stay separate because MT-call handling is easy to regress.

## Stage 06: Optional RCS Relaxations

These are not required for baseline VoLTE bring-up. Keep them optional.
