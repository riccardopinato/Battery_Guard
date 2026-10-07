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
