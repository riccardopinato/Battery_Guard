# Reuse & Provenance

Battery Guard follows the App Utility factory process.

Applied process/components:
- Master Prompt Utility Flutter v24 FULL CONSOLIDATED;
- Golden Components Index v8;
- Golden Notification Reliability — behavior adapted to Battery Guard notification channels and diagnostics;
- Golden CI / Release discipline — immutable artifact and signing concepts;
- Golden Release Reality / Physical Validation — evidence ladder and no false certification;
- Golden Localization — scheduled for 0.7.

No Golden component is marked CERTIFIED by Battery Guard merely because its concepts are reused.

## MAXI STEP C — Battery Intelligence

- originType: NEW_IMPLEMENTATION + INTERNAL_DONOR/EXTEND_EXISTING
- sourceProjectOrRepo: Battery Guard
- sourceRefOrCommit: df45b014f0fe7ac228e256343c926ad22d7f6860
- reuseScope: extend BatteryHealthStore, ChargingSessionStore, MonitoringService and existing Flutter controller/UI contracts
- externalCodeCopied: none
- newRuntimeDependencies: none
- adaptationSummary: Health Lab 2 robust estimator; screen-state evidence; deterministic Smart ETA; local Idle Drain personal baseline
- Golden/process constraints: historical MAXI STEP C baseline originally referenced v21; current governance superseded by Master Prompt v24 FULL + Golden Index v8; Release Reality; AppLab QA; AdMob Safe & Adaptive; persistent signing/update compatibility
- status: ADAPTED — verification pending CI/runtime/device evidence

## MAXI STEP D — Device Intelligence & Charge Protection

- originType: NEW_IMPLEMENTATION + EXTEND_EXISTING + OSS_REFERENCE/DATA_PROVIDER
- sourceProjectOrRepo: Battery Guard
- sourceRefOrCommit: 6534c3708daded104aadbd4d037d4e60fb5d6c3f
- reuseScope: extend existing AppController, MonitoringConfig, MonitoringService, Health Lab and localization architecture
- externalCodeCopied: none
- newRuntimeDependencies: none
- external data/reference providers:
  - bsthen/device-models — Apache-2.0; Google-Play-derived model-code -> marketing-name mapping, accessed live through CDN
  - rinehartwang1979/phone-specs-api — MIT; community phone-spec REST data, accessed live on explicit user request
- adaptationSummary:
  - MaterialApp locale repair;
  - Android non-unique device identity bridge;
  - live model resolution + stock battery-spec lookup;
  - capability-based charge-protection matrix;
  - OEM system-setting adapters/guidance;
  - command -> readback verification contract;
  - explicit Health Lab stock-capacity adoption.
- privacyNotes: no serial/Android ID/ad ID/battery history sent by Battery Guard lookup code; provider requests are user-triggered
- Golden/process constraints: Master Prompt v24 FULL; Golden Index v8; Localization; Capability/Permission/Health; Android Native Reliability; Release Reality/Physical Validation
- status: ADAPTED — CI + physical D5 evidence pending

