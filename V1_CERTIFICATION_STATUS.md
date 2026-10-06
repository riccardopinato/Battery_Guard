# Battery Guard 1.1 — Certification Status

Source target: **1.1.0+12**

## Scope
v1.1 adds:
- dual lower/upper battery thresholds;
- distinct lower/upper Android notification sounds;
- Battery Health Lab Pro;
- AdMob banners in Free;
- Pro lifetime ad removal.

## Automated gates required on the exact source SHA
- flutter gen-l10n
- flutter analyze
- flutter test
- Flutter Web Preview build
- Android split APK build
- universal APK build
- AAB build
- immutable SHA-bound artifact bundle

## External gates still required
- production Android signing secrets;
- real AdMob App ID / Banner Unit ID;
- Google consent configuration review;
- Google Play product `battery_guard_pro_lifetime`;
- Play Internal Testing install/update;
- real purchase + restore + ad-removal verification;
- Samsung and Xiaomi/Redmi/Poco physical acceptance rows;
- real foreground-service and notification-channel sound behavior;
- Battery Health Lab plausibility checks on devices exposing and not exposing charge-counter/cycle data;
- Play `specialUse` declaration;
- hosted privacy policy + support contact;
- final Data Safety reconciliation including Google Mobile Ads SDK.

## Valid verdict
Until the external gates pass:

**SOURCE IMPLEMENTED / CI-CERTIFIABLE, NOT CERTIFIED FOR PRODUCTION.**
