# Changelog

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
