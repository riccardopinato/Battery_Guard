# Release Gate — Battery Guard 1.8.0

## Automated source/build gates
- Flutter gen-l10n: required
- Flutter analyze: required
- Flutter tests: required
- localization catalog parity: required
- Intelligence Foundation provenance/session/curve regression tests: required
- Charging Intelligence setup/score/ranking/stress regression tests: required
- Device Intelligence model/config/capability truth regression tests: required
- Device Intelligence localization catalog parity: required
- Web Preview build: required
- PR Android ARM64 debug compile: required
- committed pubspec.lock + --enforce-lockfile: required for signed/main and production builds
- INTERNAL Free ARM64 APK: required
- INTERNAL Premium Test ARM64 APK: required
- Free AAB without local-Pro test bypass: required
- immutable SHA evidence: required
- INTERNAL APK certificate fingerprint verification: required
- package ID and targetSdk extracted from the exact APK: required
- non-production Free ads use Google Test IDs
- local Pro sideload bypass is INTERNAL APK only
- production live ads require explicit live-ad define + configured production IDs

## Repository administration gate
Before CERTIFIED:
- main must be protected by repository rules/branch protection;
- merges to main must require the deterministic CI status;
- direct bypasses should be restricted to explicit emergency administration.

This connector cannot administer branch protection, so this remains an external repository setting.

## Persistent INTERNAL signing
Expected INTERNAL SHA-256:
`CB:6C:7D:05:C3:43:0F:34:31:F3:22:82:48:E2:14:C6:4B:0B:50:EA:E1:6D:8C:D1:0F:63:5C:32:AF:3D:E2:91`

Update compatibility requires:
- same package ID `com.riccardopinato.batteryguard`;
- same INTERNAL certificate;
- higher versionCode;
- N -> N+1 physical install without uninstall;
- local data/settings preserved.

## Production signing gate
Required secrets:
- ANDROID_PRODUCTION_KEYSTORE_BASE64
- ANDROID_PRODUCTION_KEYSTORE_PASSWORD
- ANDROID_PRODUCTION_KEY_ALIAS
- ANDROID_PRODUCTION_KEY_PASSWORD
- ANDROID_PRODUCTION_CERT_SHA256
- ADMOB_APP_ID
- ADMOB_BANNER_ID

Production workflow:
- must run from `main`;
- uses environment `production`;
- verifies keystore fingerprint before build;
- verifies the exact APK with apksigner;
- verifies AAB JAR signature and signer fingerprint;
- records source SHA, package ID, targetSdk and Billing adapter in evidence;
- never enables INTERNAL Pro bypass.

## Google Play Billing gate
Client reconciliation is IMPLEMENTED.
Trusted purchase verification is NOT IMPLEMENTED.

Before rollout:
- verify purchaseToken on a trusted backend with Google Play Developer API;
- grant only PURCHASED state;
- acknowledge correctly;
- process refund/revocation/voided purchase lifecycle;
- test purchase, restore, pending, refund and revocation in Internal Testing.

## Runtime / physical gates
Run PHYSICAL_ACCEPTANCE_MATRIX.md against the exact artifact SHA on at least:
- one Samsung device;
- one Xiaomi/Redmi/Poco-class device.

Mandatory scenarios include:
- clean install/onboarding;
- notification permission denied/granted;
- disabled notification channels;
- screen-off FGS;
- recents removal;
- reboot recovery;
- OEM/battery-optimization restrictions;
- low/high/full/temperature/unplug alerts;
- night-mode silent route;
- widget and Quick Settings;
- unavailable telemetry rendering;
- interrupted session recovery;
- Capability Map/provenance truth;
- OEM/adaptive charge-limit detection;
- normal-unplug vs OEM-pause distinction;
- bounded screen-off charging-curve collection;
- Free/Premium curve feature-gate behavior;
- legacy 1.1.x session compatibility;
- Charge Doctor active-charging enforcement and setup grouping;
- Free single-setup gate and Pro multiple-setup access;
- setup persistence across restart/update;
- personal baseline isolation by profileId;
- Stability Score response to power variance/drop patterns;
- Thermal Score with available/unavailable telemetry;
- Battery Stress qualitative Free vs numeric Pro;
- charger/cable ranking and trend behavior;
- refund/revocation keeps profile data but blocks extra Free setup use;
- Battery Health plausibility;
- runtime locale switch + persisted locale after restart;
- Android model identity matches Settings/About-device model identity where exposed;
- Pro live battery-spec lookup returns either a source-attributed plausible match or a truthful no-match/error;
- stock battery capacity is never auto-applied to Health Lab;
- charge-protection target accepts 70/75/80/85/90/95/100%;
- OEM/system charge-protection guidance is correct for the tested device/software;
- at/above target while still charging never shows VERIFIED STOP;
- at/above target + still plugged + Android not charging is NOT sufficient by itself;
- VERIFIED STOP requires a recent observed charging -> not-charging transition on the same target/plug session;
- an OEM adapter must support the selected target or the flow remains alert-only;
- any future direct-control adapter must prove real command dispatch -> delayed readback transition;
- AdMob/UMP/privacy choices;
- Pro buy/restore/refund/revocation;
- signed in-place update with data preservation.

## Store / policy gates
- Play product `battery_guard_pro_lifetime` configured;
- real AdMob IDs configured;
- UMP message reviewed for applicable regions;
- candidate AAB uploaded to Play Internal Testing;
- FGS specialUse declaration accepted;
- public privacy policy + support contact;
- final Data Safety reconciled against exact AAB.

## Current verdict
**IMPLEMENTED + SOURCE HARDENED, NOT CERTIFIED / BLOCKED FOR PRODUCTION** until external repository, backend, Play and physical-device gates pass.
