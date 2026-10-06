# Battery Guard 1.0 — Certification Status

Source version: **1.0.0+11**

## Source scope
The v1 product scope is frozen. No additional feature work is required before distribution testing.

## Automated gates
These must be supplied by the final main-branch CI run for the exact v1 source SHA:
- flutter gen-l10n
- flutter analyze
- flutter test
- Flutter Web Preview build
- Android split APK build
- universal APK build
- AAB build
- immutable SHA-bound artifact bundle

## External gates
The following cannot be truthfully certified by repository CI alone:
- production signing key configured;
- Google Play product `battery_guard_pro_lifetime` active;
- Play Internal Testing installation/update;
- real purchase and restore using a Play test account;
- Samsung physical acceptance matrix;
- Xiaomi/Redmi/Poco physical acceptance matrix;
- real foreground-service persistence/reboot/OEM behavior;
- real notification-channel delivery behavior;
- Google Play `specialUse` review/declaration;
- public privacy-policy URL and support contact;
- final Data Safety reconciliation.

## Current valid verdict
Until the external gates above are completed:

**SOURCE COMPLETE / CI-CERTIFIABLE, NOT CERTIFIED FOR PRODUCTION.**

Do not relabel this state as STORE READY or PRODUCTION RELEASED from a green CI run alone.
