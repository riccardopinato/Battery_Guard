# Google Play Data Safety — Draft for v1.1.7

This is a preparation aid. The final declaration must be reconciled with the exact production AAB and the current Play Console questionnaire.

## Battery / app data
- Battery telemetry: processed locally; not sent to Battery Guard backend.
- Charging history: local.
- Charge Doctor results: local.
- Battery Health Lab capacity samples: local.
- Battery Guard account: none.

## Advertising SDK
The Free version includes Google Mobile Ads / AdMob. The final Data Safety declaration must include the data practices of the exact Google Mobile Ads SDK version bundled in the production AAB, including any device identifiers, diagnostics or advertising data required by Google's disclosure documentation.

Consent is requested where required before ad requests. When required by Google's UMP status, Settings exposes a visible privacy-options entry point so choices can be revisited. Battery telemetry is not supplied by Battery Guard as ad-targeting input.

## Pro
Pro is a non-consumable Google Play purchase. Pro removes Battery Guard ad placements. Google Play processes purchase information required to establish/restore ownership.

## Sharing
Battery Guard does not intentionally share battery history, Battery Health Lab estimates or Charge Doctor measurements with advertisers.

## Backup
Android Auto Backup is disabled. v1.1.7 also provides explicit legacy backup and Android 12+ data-extraction rules that exclude app files, databases, SharedPreferences, external app data and device-protected equivalents from cloud backup and device transfer.

Status: **DRAFT — NOT FINAL PLAY DECLARATION**.


## Purchase entitlement reconciliation
The Android client can query current Google Play ownership to reconcile the locally cached Pro entitlement. This is not a Battery Guard backend and does not replace trusted server-side purchase verification. Production rollout remains blocked until the final purchase-verification architecture and exact Play disclosure are reconciled.

## Battery Intelligence local data

Battery Intelligence adds only local diagnostic evidence:
- Health Lab capacity samples, confidence/outlier/trend evidence: local;
- screen interactive state attached to battery/charging observations: local;
- Idle Drain screen-off segments and personal baseline: local;
- Smart ETA inputs/results: computed locally from charging sessions.

Battery Guard does not send this evidence to an app backend and does not provide it to AdMob as targeting input.

## Device Intelligence live lookup — v1.8

When a Pro user explicitly taps the online device-spec lookup:
- Battery Guard reads non-unique Android make/model/product information locally;
- the Android model code may be sent to a public device-name mapping endpoint derived from the Google Play supported-device catalog;
- the resolved/non-resolved make/model query may then be sent to the selected phone-specifications provider;
- no serial number, Android ID, advertising ID, battery history, Health Lab samples or charging-session history is intentionally included in those lookup requests;
- the lookup is user-triggered, not periodic background telemetry;
- returned specs are cached only in current app state in this implementation; Health Lab persists only a capacity after explicit user adoption.

The exact production provider, its privacy/terms and the final Play Data Safety questionnaire must be re-checked before STORE READY.

## Charge Protection — v1.8

Charge-protection capability detection, target, live battery readback and verification state are processed locally. OEM/system settings are opened through Android intents where available. Battery Guard does not send charge-limit state to its own backend.

