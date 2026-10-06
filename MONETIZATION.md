# Monetization — v1.1.2

Product ID: `battery_guard_pro_lifetime`

Type: Google Play non-consumable / one-time purchase.

## Free
- complete dual-threshold battery protection;
- lower-limit "charge now" alert;
- upper-limit "unplug now" alert;
- separate Android notification channels/sounds for the two limits;
- temperature / full / cable alerts;
- foreground monitoring;
- widget + Quick Settings;
- charging history;
- 7-day Insights;
- Google AdMob **Large Anchored Adaptive Banner** after consent where required.

## AdMob placement contract
- the persistent Free banner uses the real safe layout width and Google adaptive height;
- the ad lives in a dedicated slot at the top of the main content area;
- the Bottom Navigation contains navigation only and is not shared with the ad;
- no overlay over content or controls;
- failed/no-fill requests collapse the ad slot;
- development, debug, QA and normal CI use Google's Test Ad Unit IDs;
- live ads require a release build plus `ADMOB_USE_LIVE_ADS=true` and a non-empty `ADMOB_BANNER_ID`;
- no interstitial, rewarded or native placement is enabled by default in v1.1.2.

## Pro Lifetime
- removes Battery Guard advertising permanently;
- Battery Health Lab with estimated capacity/health, cycle count where exposed, trend and thermal profile;
- Charge Doctor controlled tests and personal comparison;
- 30-day Insights.

## Principles
- no subscription;
- core battery protection is never paywalled;
- price comes from Google Play ProductDetails, never hardcoded;
- restore purchases remains available;
- Pro ad removal uses the same `battery_guard_pro_lifetime` entitlement;
- Pro users do not construct/request the banner placement;
- ads never receive Battery Guard battery telemetry as targeting input;
- advertising must adapt to Battery Guard UX, never the opposite.

## External production configuration
Create/activate `battery_guard_pro_lifetime` in Play Console and configure real AdMob App ID + Banner Unit ID before production release. The production workflow is the only canonical path that opts into live banner ads.
