# Changelog

## 1.1.4
- fixed the disabled "Unlock Pro" action in sideloaded INTERNAL Free APKs;
- added a compile-time local Pro fallback only when `BATTERY_GUARD_ALLOW_LOCAL_PRO_TEST=true`;
- INTERNAL APKs can unlock the cached local Pro entitlement when Google Play Billing/product metadata is unavailable;
- production and AAB builds do not receive the local unlock flag and still require real Google Play Billing;
- kept the forced-Premium QA artifact separate from the Free purchase-flow test;
- bumped versionCode to 16 so v1.1.4 can update the persistent-signed v1.1.3 baseline in place;
- aligned the Settings version label to 1.1.4.

## 1.1.3
- refreshed the launcher icon with the approved shield + charged battery artwork;
- moved the visual into the adaptive foreground safe zone and added Android 13+ monochrome/themed support;
- introduced persistent INTERNAL signing for installable QA APKs;
- pinned and verified the INTERNAL certificate SHA-256 fingerprint;
- separated INTERNAL and PRODUCTION signing lanes;
- production releases now require dedicated `ANDROID_PRODUCTION_*` secrets;
- added a compile-time Premium Test entitlement override without changing Play production behavior;
- CI now builds Free and Premium Test APKs from the same source SHA and signing identity;
- preserved Free and Premium symbol files in the Evidence Bundle;
- kept analyze/test/Web checks available even when PR signing secrets are unavailable;
- hardened the final PR after automated review: release signing no longer blocks debug/sync, adaptive icon safe-zone handling is corrected, and Free symbols survive the Premium rebuild;
- bumped source version to 1.1.3+15.

## 1.1.2
- replaced fixed-size `AdSize.banner` with Google Large Anchored Adaptive banner sizing based on the actual available layout width;
- moved the persistent Free banner out of the Bottom Navigation container and into a dedicated top content slot;
- isolated NavigationBar from advertising to reduce accidental-click risk and removed the previous banner/navigation sandwich;
- adaptive slot reserves the Google-computed height while loading and collapses after load failure/no-fill;
- added local diagnostic callbacks for banner load, failure, impression and click without sending Battery Guard telemetry;
- updated Google Test Banner IDs and forced test ads outside an explicitly configured production release;
- production artifacts now require an explicit `ADMOB_USE_LIVE_ADS=true` opt-in in addition to the real banner ID;
- preserved UMP consent gating, Privacy Options and Pro ad-free behavior;
- bumped source version to 1.1.2+14.

## 1.1.1
- fixed duplicate 100% notifications when the upper target itself is 100%;
- localized native/background notification channels, alert titles and alert messages;
- localized battery status/health/charging-source labels in Flutter UI;
- notification reliability now respects disabled low-limit alerts and night-mode quiet channel health;
- added a visible Google UMP privacy-options entry point when required and consent-change ad reload;
- improved AdMob initialization retry behavior;
- hardened Battery Health Lab: discharging-only samples, robust outlier filtering, SoC-spread confidence and health capped at 100%;
- fixed adaptive temperature baseline so it requires actual historical temperature samples;
- added explicit network permissions for the ad-supported Free build;
- CI artifact now exports the generated dependency lockfile for reproducibility hardening.

## 1.1.0
- added configurable lower battery threshold (default 20%) in addition to the upper charging threshold;
- added separate Android notification channels/sounds for "charge now" and "unplug now";
- added dedicated sound-test actions in Settings;
- added Android charge-counter and cycle-count telemetry when exposed by the OEM;
- added Pro Battery Health Lab with estimated full capacity, estimated health percentage, confidence, cycle count, capacity trend and thermal profile;
- health percentage is explicitly labelled as an estimate, never an official OEM value;
- added Google AdMob banner advertising to Free;
- added Google consent flow before requesting ads where required;
- existing Pro lifetime entitlement now removes ads and includes Health Lab;
- production workflow now requires real AdMob identifiers in addition to production signing.

## 1.0.0
- feature freeze: no new product scope after 0.9;
- final source version aligned to 1.0.0+11;
- remaining Settings strings migrated to localization resources;
- production-release workflow, privacy/store/FGS documentation and physical acceptance matrix retained as mandatory external gates;
- v1 source can become PRODUCTION RELEASED only after production signing, Play Internal Testing, purchase/restore, physical-device matrix and Play policy checks pass.

## 0.9.0
- added Google Play Billing architecture for the non-consumable `battery_guard_pro_lifetime`;
- cached offline Pro entitlement with purchase/restore synchronization;
- free core remains fully functional;
- Pro gates Charge Doctor and 30-day Insights;
- store price is read from Google Play ProductDetails, never hardcoded;
- added privacy, Data Safety, foreground-service declaration, Play listing and monetization drafts;
- added physical acceptance matrix and explicit production release gate;
- added production release workflow that refuses missing signing secrets and immutable-release overwrite.

## 0.8.0
- added Charge Doctor controlled charger/cable tests;
- local persistent history for up to 50 controlled tests;
- power/current/voltage/temperature sampling while the test is open;
- low/medium/high measurement confidence based on duration and sample count;
- personal comparison only against reliable tests using the same source;
- wording explicitly avoids declaring a cable defective from telemetry alone;
- Charge Doctor available in Android and simulated Web Preview.

## 0.7.0
- Flutter localization infrastructure for EN/IT/ES/FR/DE/PT;
- system-language default with persistent manual override;
- browser-safe simulated Web Preview;
- GitHub Pages preview branch generated from the same source SHA;
- navigation, onboarding, Home, History, Insights and Settings migrated to localized strings;
- Web Preview explicitly labels native Android telemetry as simulated.

## 0.6.0
- notification reliability now checks app-wide notifications and individual channels;
- alert cooldown is recorded only after a deliverable notification succeeds;
- adaptive alert one-shot state is committed only after successful delivery;
- foreground-service health no longer treats old battery events as a heartbeat;
- Smart Charging adds lastObservedAt and session quality;
- interrupted sessions are excluded from adaptive/Insight baselines;
- battery current/power/temperature/voltage expose availability flags;
- unavailable telemetry is no longer rendered as a real zero value;
- Android Auto Backup disabled for strict local-only behavior;
- CI Flutter version pinned and release assets no longer overwritten on every main push;
- optional production signing contract added without storing secrets in source.
