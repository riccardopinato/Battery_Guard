# Changelog

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
