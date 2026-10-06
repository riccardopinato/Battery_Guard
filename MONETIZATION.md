# Monetization — v1.1

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
- Google AdMob banner advertising after consent where required.

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
- ads never receive Battery Guard battery telemetry as targeting input.

## External production configuration
Create/activate `battery_guard_pro_lifetime` in Play Console and configure real AdMob App ID + Banner Unit ID before production release.
