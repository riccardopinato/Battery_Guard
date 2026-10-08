# Battery Guard — Product Bible

## Missione

Ridurre l'incertezza durante la ricarica del telefono con dati osservabili e avvisi affidabili, restando leggera, locale e trasparente.

## Promessa utente

1. mostrare solo dati che Android espone realmente;
2. distinguere dati non disponibili da valori zero;
3. avvisare alla soglia selezionata quando il percorso notifiche è realmente disponibile;
4. non dichiarare il servizio operativo senza evidenza runtime;
5. non attribuire una falsa percentuale di salute batteria;
6. non fingere di poter interrompere la ricarica;
7. conservare i dati localmente per default.

## Core

- Battery Snapshot
- Monitoring & Notification Reliability
- Smart Charging Sessions
- Adaptive Protection
- History
- Insights
- Quick Controls
- Charge Doctor controlled tests

## Charge Doctor guardrails

Charge Doctor compares observed telemetry under controlled conditions. It never labels a charger or cable as defective from one measurement. Personal comparison requires reliable prior tests using the same charging source.

## Monetization doctrine

**Free protects. Pro explains, compares and optimizes.**

Free always includes safety monitoring, reliability diagnostics, telemetry availability/provenance, Device Capability Map, session validity/reason codes and OEM/adaptive charge-limit detection.

Pro is a one-time Google Play purchase. It removes ads and unlocks advanced analysis surfaces, including full charging curves/phase analysis, Battery Health Lab, Charge Doctor advanced capabilities and extended Insights. No subscription.

## Battery Health Lab guardrails

Battery Health Lab may estimate full-charge capacity and a health percentage only when the device exposes compatible charge-counter data and the user provides/has a nominal design capacity. The value must always be labelled as an estimate, carry a confidence level and never be presented as an official OEM/Apple-equivalent state-of-health value.

## Advertising guardrails

Free ads must never receive Battery Guard battery telemetry, charging history, Health Lab data or Charge Doctor results as targeting input. Pro must remove Battery Guard ad placements.

## Non-goal v1

- AI/LLM
- social/community
- SMS automatici
- cloud/account obbligatorio
- controllo hardware della ricarica
- battery-health % inventata

## Data truth

Ogni segnale deve dichiarare:
- availability;
- source;
- confidence;
- observed timestamp.

Una sessione mantiene separati:
- lifecycle quality: active / completed / interrupted / uncertain;
- validity: active / valid / partial / interrupted / excluded / uncertain;
- reason codes spiegabili.

Una sessione vecchia senza nuova evidenza resta leggibile, ma Battery Guard non inventa curve, source o reason codes retroattivi.

Solo le sessioni con validità sufficiente alimentano Insights e baseline compatibili.

## Release truth

La Evidence Ladder canonica è:
IMPLEMENTED -> STATICALLY CHECKED -> TESTED -> CI GREEN -> ARTIFACT BUILT -> TRUSTED RUNTIME VERIFIED -> PHYSICAL DEVICE VERIFIED -> DISTRIBUTION VERIFIED -> STORE READY -> PRODUCTION RELEASED.

Nessun livello implica automaticamente il successivo.


## Charging Intelligence doctrine — v1.5

Charge Doctor is no longer an all-or-nothing Premium feature.

**FREE**
- one charger + cable setup profile;
- controlled tests;
- qualitative Speed / Stability / Thermal / Overall bands;
- safety-relevant anomalies;
- qualitative Battery Stress.

**PRO**
- multiple setup profiles;
- numeric score breakdown;
- personal baseline delta;
- charger/cable ranking;
- setup trends;
- detailed Battery Stress exposure.

Scoring rules:
- never compare against an external generic device database;
- Speed requires enough reliable tests from the same setup;
- Stability uses sampled power behavior, not average watts alone;
- Thermal uses observed temperature evidence only;
- Overall is composed only from available sub-scores;
- missing evidence stays unavailable;
- Battery Stress is an exposure heuristic, never a claim of measured chemical degradation.
