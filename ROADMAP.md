# Battery Guard — Roadmap

## 0.6 — Core Reliability & Release Integrity ✅ IMPLEMENTED
- notification channel truth
- session integrity / interrupted sessions
- telemetry availability
- local-only backup policy
- pinned Flutter CI
- immutable CI artifacts
- optional persistent production signing
- Product Bible / changelog / evidence discipline

## 0.7 — Factory Compliance & Runtime QA ✅ IMPLEMENTED / PHYSICAL QA PENDING
- localization IT/EN/ES/FR/DE/PT
- system locale + manual override
- Web Preview con stato simulato
- responsive/accessibility hardening
- runtime/emulator evidence where possible
- physical acceptance matrix ready

## 0.8 — Charge Doctor ✅ IMPLEMENTED
- controlled charger/cable test
- measurement confidence
- saved test history
- A/B comparison without unsupported defect claims

## 0.9 — Store & Monetization RC ✅ IMPLEMENTED / EXTERNAL GATES PENDING
- one-time Pro architecture
- Play Billing integration
- privacy/data safety/store docs
- FGS specialUse declaration pack
- production signing gate
- internal-testing evidence gate

## 1.0 — Production Candidate ✅ SOURCE COMPLETE / EXTERNAL GATES PENDING
- no new product scope
- final regression hardening
- exact-artifact evidence
- publish only when signing + physical/device + distribution gates are satisfied

## 1.1 — Longevity & Monetization ✅ IMPLEMENTED / EXTERNAL AD + PLAY GATES PENDING
- dual lower/upper charge thresholds;
- distinct lower/upper notification sounds;
- Battery Health Lab Pro;
- AdMob Free / ad-free Pro;
- updated privacy/Data Safety/production configuration.

## 1.1.1 — Heavy Audit Hardening ✅ IMPLEMENTED
- duplicate 100% alert fix;
- adaptive temperature baseline validity;
- localized native notifications/widget/tile surfaces;
- exact notification-channel diagnostics;
- UMP privacy-options entry point;
- Health Lab robust estimator;
- dependency lockfile/reproducibility hardening.

## 1.1.2 — AdMob Adaptive & Policy-Safe Layout ✅ IMPLEMENTED / CI + DEVICE QA PENDING
- replace fixed `AdSize.banner` with Google Large Anchored Adaptive sizing;
- calculate ad width from the real safe layout width;
- move the persistent banner out of the Bottom Navigation container;
- keep NavigationBar isolated from the ad placement to reduce accidental-click risk;
- reserve the adaptive slot while an eligible ad request is loading and collapse it on failure/no-fill;
- keep UMP consent gating and Privacy Options;
- enforce Google Test Ad Unit IDs outside an explicitly configured production release;
- require `ADMOB_USE_LIVE_ADS=true` plus a real banner ID for production artifacts;
- keep Pro ad-free by not constructing the ad placement;
- retain local-only diagnostic callbacks for load/failure/impression/click without battery telemetry.


## 1.1.3 — Persistent Signing & Icon Refresh ✅ IMPLEMENTED / PHYSICAL UPDATE QA PENDING
- refined shield + battery launcher artwork;
- adaptive foreground safe-zone handling;
- Android 13+ themed monochrome icon;
- persistent INTERNAL signing required for installable CI artifacts;
- pinned INTERNAL certificate fingerprint validation;
- Free + Premium Test APKs from the same source SHA/signing identity;
- Premium Test compile-time entitlement override only for the QA artifact;
- INTERNAL and PRODUCTION signing lanes separated;
- dedicated `ANDROID_PRODUCTION_*` secrets for production;
- physical in-place update verification remains required before CERTIFIED update compatibility.


## 1.1.4 — INTERNAL Pro Unlock QA ✅ IMPLEMENTED / DEVICE QA PENDING
- sideloaded INTERNAL Free APK keeps the Pro CTA actionable when Play Billing metadata is unavailable;
- local Pro fallback is compile-time gated and excluded from AAB/production;
- production purchase/restore behavior remains Google Play Billing only;
- versionCode 16 enables in-place update testing from persistent-signed v1.1.3;
- device acceptance: tap Unlock Pro -> Pro state -> ads removed -> gated features accessible -> entitlement survives app restart.


## 1.1.5 — Production & Security Hardening ✅ IMPLEMENTED / EXTERNAL VERIFICATION PENDING
- Play Billing plugin moved to current 3.3.x / Android adapter 0.5.x;
- cached Pro entitlement reconciled against current Google Play ownership when store queries succeed;
- trusted backend purchase-token verification remains a production gate;
- keystore ignore rules hardened;
- PR workflows no longer receive signing secrets;
- production workflow restricted to main and verifies expected signing fingerprint;
- target/compile SDK pinned to API 36;
- pubspec.lock is mandatory once the CI-resolved lock is committed.

## 1.1.6 — Runtime Correctness ✅ IMPLEMENTED / PHYSICAL QA PENDING
- unreliable manifest power-event receiver removed;
- unavailable temperature is preserved through History, sessions and widget;
- Charge Doctor requires active charging;
- Charge Doctor baselines are scoped to equivalent normalized setup labels + source;
- notification quick actions localized;
- Battery Health sample persistence optimized;
- explicit Android cloud/D2D extraction exclusions added.

## 1.1.7 — Test & Evidence ✅ IMPLEMENTED / CI + PHYSICAL QA PENDING
- model regressions expanded;
- Charge Doctor grouping tests added;
- localization catalog parity test added;
- UMP privacy-options timeout hardened;
- INTERNAL artifacts changed to ARM64-first;
- Evidence Bundle records targetSdk, package, Billing adapter and local-Pro bypass state;
- production candidate records and verifies upload certificate identity;
- branch protection remains an external repository-administration gate.


## 1.2.0 — Data Truth & Capability Foundation ✅ IMPLEMENTED / DEVICE QA PENDING
- signal provenance: availability + source + confidence + timestamp;
- free Device Capability Map;
- session validity model: active / valid / partial / interrupted / excluded / uncertain;
- explainable reason codes;
- OEM/adaptive charging pause detection while still plugged in;
- legacy 1.1.x session compatibility without invented evidence.

## 1.3.0 — Charging Session Intelligence ✅ IMPLEMENTED / DEVICE QA PENDING
- adaptive bounded curve sampling;
- periodic 60 s foreground observation independent of broadcast frequency;
- curve points: SoC, power, current, voltage, temperature, charging/plugged state;
- deterministic phase analysis;
- Free session evidence and OEM-limit explanation;
- Premium full charging curve + phase analysis;
- centralized feature catalog for current MAXI STEP A Free/Premium boundaries;
- six-language localization parity;
- regression coverage for provenance, session reasons, feature access and curve analyzer.

## 1.4.0 — Charge Doctor 2.0 ✅ IMPLEMENTED / DEVICE QA PENDING
- persistent charger/cable setup profiles;
- Free: one setup + controlled tests + qualitative Speed/Stability/Thermal/Overall;
- Pro: multiple setups + numeric score breakdown;
- Stability Score from sampled power variance + repeated drops;
- Speed Score against personal baseline only;
- Thermal Score from actual observed temperature and rise;
- raw evidence persisted so formulas remain recalculable;
- legacy tests remain readable without fabricated profile evidence.

## 1.5.0 — Battery Stress & Charging Ranking ✅ IMPLEMENTED / DEVICE QA PENDING
- Battery Stress exposure engine for normal sessions + Charge Doctor tests;
- factors: high SoC, heat, very-high temperature, high voltage, high-power/heat overlap;
- explicit heuristic disclaimer: no direct degradation claim;
- Free qualitative stress + anomalies;
- Pro numeric stress breakdown;
- charger/cable ranking from user-owned reliable tests;
- per-setup Overall Score and Stress trends when enough history exists;
- centralized Free/Premium gates for profiles, scores, ranking and stress details.

## 1.6.0 — Health Lab 2.0 ✅ IMPLEMENTED / DEVICE EVIDENCE ACCUMULATION PENDING
- Android-reported health status kept separate from Battery Guard estimated capacity health;
- robust capacity estimator with smoothing, MAD-based outlier filtering and uncertainty;
- confidence score from sample count, SoC spread, precision and freshness;
- outlier inspector and smoothed capacity trend;
- Free health summary; Pro confidence/trend/outlier/thermal evidence.

## 1.7.0 — Smart ETA & Idle Drain ✅ IMPLEMENTED / DEVICE QA PENDING
- Free standard ETA from current valid charging-session evidence;
- Pro Smart ETA from current session + same-source valid history + taper evidence;
- screen interactive state captured as explicit charging-curve evidence when available;
- Idle Drain Sentinel from screen-off, unplugged intervals only;
- Idle Drain compares recent behavior with the device's own power-mode-compatible baseline;
- no per-app drain attribution and no unsupported battery-degradation claims;
- six-language UI + Web Preview simulation + regression tests.

## 1.8.0 — MAXI STEP D: Device Intelligence & Charge Protection ✅ IMPLEMENTED / PHYSICAL QA PENDING

### D1 — Localization Repair
- fixed runtime locale propagation at the MaterialApp boundary;
- device locale + persisted manual override now rebuild the complete Flutter app surface;
- six-language Device Intelligence / Charge Protection catalog added;
- physical language switching remains an acceptance scenario before CERTIFIED.

### D2 — Device Battery Profile Live
- Android identity reads manufacturer/brand/model/product/SKU without serial number or unique hardware ID;
- exact Build.MODEL can be resolved live to a marketing name through a Google-Play-derived device mapping;
- Pro live lookup retrieves stock battery capacity and available wired-charge power from a community specs provider;
- provider/source, matched device and confidence are visible;
- fuzzy/low-confidence data is never applied automatically;
- online lookup is explicit/user-triggered and never background telemetry;
- production provider admission/terms/freshness remain a release gate.

### D3 — Charge Limit Capability Matrix + OEM adapters
- user target range expanded to 70/75/80/85/90/95/100%;
- Pro Charge Protection distinguishes direct control, OEM/system setting and alert-only capability;
- Pixel, Samsung and Xiaomi/Redmi/POCO system-protection guidance/adapters added;
- no OEM is falsely marked as direct-control through unsupported Android public APIs;
- monitoring records real plugged/charging readback state;
- VERIFIED STOP requires plugged + target reached + isCharging=false;
- command/request success alone can never produce a verified badge;
- future verified direct adapters must execute command -> delayed readback before success.

### D4 — Health Lab integration
- detected stock capacity can be explicitly adopted as the Health Lab nominal/design baseline;
- existing manual value is never silently overwritten;
- source/confidence remain separate from Battery Guard's own measured capacity estimate.

### D5 — Physical Evidence & Calibration ⏳ PENDING
- validate exact 1.8.0+26 artifact on real devices;
- language switch + restart persistence;
- exact-model resolution + live stock-capacity lookup;
- OEM/system charge-limit setup and readback around selected thresholds;
- overnight foreground/background reliability;
- Health Lab / Smart ETA / Idle Drain accumulation;
- tune thresholds/formulas only from observed device evidence.

## NEXT
- complete D5 on the exact signed artifact produced by CI;
- no new product scope until MAXI STEP D physical evidence and calibration are reviewed.
