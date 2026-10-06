# Release Gate

## Automated source/build gates
- Flutter analyze: required
- unit tests: required
- Web Preview build: required
- split APK + AAB: required
- immutable artifact SHA evidence: required
- production release workflow must refuse missing signing secrets

## External gates still required before PRODUCTION RELEASED
1. Add persistent Android production signing secrets:
   - ANDROID_KEYSTORE_BASE64
   - ANDROID_KEYSTORE_PASSWORD
   - ANDROID_KEY_ALIAS
   - ANDROID_KEY_PASSWORD
2. Configure Google Play product `battery_guard_pro_lifetime`.
3. Upload candidate AAB to Play Internal Testing.
4. Verify purchase + restore with Play test account.
5. Complete PHYSICAL_ACCEPTANCE_MATRIX.md on real devices.
6. Verify foreground-service specialUse declaration in Play Console.
7. Publish privacy policy at a public URL and add support contact.
8. Reconcile final Data Safety form with exact production AAB.

Until these external gates pass, the strongest valid verdict is **NOT CERTIFIED / BLOCKED FOR PRODUCTION**, even if CI is green.
