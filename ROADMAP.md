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
