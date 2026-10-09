# Monetization — v1.8.0

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
- Device Capability Map and telemetry provenance/confidence;
- session validity/reason codes and OEM charge-limit detection;
- session summary with basic charging metrics;
- Charge Doctor Basic with one charger/cable setup;
- qualitative Speed / Stability / Thermal / Overall evaluation;
- relevant charging anomalies;
- qualitative Battery Stress level;
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
- 30-day Insights;
- full charging curves (SoC / power / temperature / current) and deterministic phase analysis;
- multiple charger/cable setup profiles;
- numeric Speed / Stability / Thermal / Overall score breakdown;
- personal-baseline details;
- charger/cable ranking and historical trends;
- numeric Battery Stress score and exposure breakdown.

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


## Purchase entitlement integrity — v1.1.7
- INTERNAL sideload local-Pro unlock remains compile-time gated and is never enabled in the AAB/production workflow.
- Android production clients reconcile cached ownership with Google Play current purchases when the store query succeeds.
- A transient Play error returns an unknown state and does not revoke a previously cached entitlement.
- A successful Play ownership query that no longer reports the lifetime product clears the local cached entitlement.
- Client-side purchase data is NOT considered trusted anti-fraud verification.
- Production rollout remains blocked until purchase tokens are verified by a trusted backend / Google Play Developer API workflow, including refund/revocation handling.


## Intelligence Foundation monetization rule
**Free protects and explains data quality. Pro unlocks deeper analysis.**

Never paywall:
- safety alerts;
- monitoring reliability;
- telemetry availability/provenance;
- Device Capability Map;
- session validity/reason codes;
- OEM/adaptive charging-limit detection.

Premium in MAXI STEP A:
- full charging-curve visualization;
- curve phase analysis.

Curve samples are collected locally for both Free and Pro so upgrading later does not discard prior history. Free users do not receive the full curve visualization/analysis until entitlement is active.


## Charging Intelligence monetization rule — v1.5
Free must remain useful for protection and diagnosis:
- one charger/cable setup;
- unlimited controlled tests on that accessible setup;
- qualitative score bands;
- anomalies;
- qualitative stress level.

Pro monetizes depth, comparison and optimization:
- multiple setup profiles;
- numeric score values;
- baseline deltas;
- ranking;
- trends;
- detailed stress exposure.

Refund/revocation never deletes extra setup data. Extra setup profiles become inaccessible for new Free tests but remain stored locally so re-entitlement restores access without data loss.

## Battery Intelligence v1.7 tier boundary

**Free protects**
- health summary when evidence is sufficient;
- Android-reported health status separated from estimated health;
- standard ETA.

**Pro explains and optimizes**
- confidence score, uncertainty, trend and outlier inspector;
- Smart ETA from personal history;
- Idle Drain Sentinel.

Premium gating stays centralized through `FeatureCatalog`; data collection and user-owned local evidence are not deleted when Pro is unavailable.

## Device Intelligence / Charge Protection tier boundary — v1.8

**Free remains complete for protection basics**
- lower/upper threshold alerts;
- foreground monitoring and reliability diagnostics;
- OEM/adaptive charging-pause evidence already observed by Battery Guard;
- manual nominal-capacity entry and Health summary.

**Pro adds optimization depth**
- live detected-device battery-spec lookup with source/confidence;
- one-tap adoption of verified-enough stock capacity into Health Lab;
- Charge Protection target workflow 70–100%;
- OEM/system battery-protection guidance;
- live charge-stop readback verification.

Premium never converts an unsupported capability into a claimed capability. A phone with no controllable/system charging limit gets the truthful alert-only path.

