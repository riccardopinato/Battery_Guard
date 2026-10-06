# Release Gate

## Automated source/build gates
- Flutter analyze: required
- unit tests: required
- Web Preview build: required
- Free split APK + universal APK + AAB: required
- Premium Test split APK + universal APK: required for INTERNAL QA
- immutable artifact SHA evidence: required
- INTERNAL APKs must use the persistent signing identity
- every INTERNAL APK must pass certificate fingerprint verification
- production release workflow must refuse missing dedicated production signing secrets
- non-production Free builds must use Google Test Ads
- production live ads require both `ADMOB_USE_LIVE_ADS=true` and a configured `ADMOB_BANNER_ID`

## Persistent signing / update QA
Expected INTERNAL certificate SHA-256:
`CB:6C:7D:05:C3:43:0F:34:31:F3:22:82:48:E2:14:C6:4B:0B:50:EA:E1:6D:8C:D1:0F:63:5C:32:AF:3D:E2:91`

Before update compatibility can be CERTIFIED:
- install a persistent-signed APK N;
- create real local data/settings;
- install APK N+1 with a higher versionCode without uninstalling;
- verify update succeeds;
- verify local data/settings survive;
- verify package remains `com.riccardopinato.batteryguard`;
- verify signing certificate SHA-256 is unchanged.

The first transition from an older ephemeral debug-signed APK may require one uninstall/reinstall. That is only migration to the persistent baseline, not update certification.

## AdMob adaptive physical QA
Before production rollout verify on real devices:
- small phone portrait;
- large phone portrait;
- landscape if supported;
- gesture navigation;
- three-button navigation where available;
- light/dark mode;
- no overlap with app controls;
- no banner inside/over the NavigationBar;
- no accidental-click-risk layout;
- no-fill/failure leaves the app fully usable;
- Pro entitlement removes the placement;
- UMP consent and Privacy Options work as configured.

## External gates still required before PRODUCTION RELEASED
1. Add dedicated Android PRODUCTION signing secrets:
   - ANDROID_PRODUCTION_KEYSTORE_BASE64
   - ANDROID_PRODUCTION_KEYSTORE_PASSWORD
   - ANDROID_PRODUCTION_KEY_ALIAS
   - ANDROID_PRODUCTION_KEY_PASSWORD
2. Configure Google Play product `battery_guard_pro_lifetime`.
3. Configure production AdMob IDs in GitHub secrets:
   - ADMOB_APP_ID
   - ADMOB_BANNER_ID
4. Complete/review the Google consent message configuration for EEA/UK where applicable.
5. Upload candidate AAB to Play Internal Testing.
6. Verify purchase + restore and verify that Pro removes all ad placements with Play test account.
   - Before production, add a trusted purchase-verification strategy (server-side or equivalent trusted verifier) rather than treating an unverified purchase event as final entitlement evidence.
7. Complete PHYSICAL_ACCEPTANCE_MATRIX.md on real devices, including the AdMob adaptive checks above.
8. Verify foreground-service specialUse declaration in Play Console.
9. Publish privacy policy at a public URL and add support contact.
10. Reconcile final Data Safety and Google Mobile Ads disclosures form with exact production AAB.

Until these external gates pass, the strongest valid verdict is **NOT CERTIFIED / BLOCKED FOR PRODUCTION**, even if CI is green.
