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

## NEXT — MAXI STEP B: Charging Intelligence
Target: v1.4 + v1.5
- Charge Doctor 2.0;
- charger/cable profiles;
- Stability Score;
- Speed / Stability / Thermal / Overall score separation;
- personal baseline and charger ranking;
- Battery Stress Engine;
- Free qualitative summary vs Premium detailed score/breakdown/trends.
