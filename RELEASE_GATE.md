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
3. Configure production AdMob IDs in GitHub secrets:
   - ADMOB_APP_ID
   - ADMOB_BANNER_ID
4. Complete/review the Google consent message configuration for EEA/UK where applicable.
5. Upload candidate AAB to Play Internal Testing.
6. Verify purchase + restore and verify that Pro removes all ad placements with Play test account.
7. Complete PHYSICAL_ACCEPTANCE_MATRIX.md on real devices.
8. Verify foreground-service specialUse declaration in Play Console.
9. Publish privacy policy at a public URL and add support contact.
10. Reconcile final Data Safety and Google Mobile Ads disclosures form with exact production AAB.

Until these external gates pass, the strongest valid verdict is **NOT CERTIFIED / BLOCKED FOR PRODUCTION**, even if CI is green.
