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

## Monetization v1

Free keeps all core monitoring/protection behavior, including the lower/upper charge window and their distinct alerts. Free can display consent-gated AdMob banners. Pro is a one-time Google Play purchase that removes ads and unlocks Battery Health Lab, Charge Doctor and 30-day Insights. No subscription.

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

Ogni misura deve avere disponibilità esplicita. Una sessione può essere:
- active
- completed
- interrupted
- uncertain

Solo le sessioni completed affidabili alimentano Insights e baseline adattive.

## Release truth

La Evidence Ladder canonica è:
IMPLEMENTED -> STATICALLY CHECKED -> TESTED -> CI GREEN -> ARTIFACT BUILT -> TRUSTED RUNTIME VERIFIED -> PHYSICAL DEVICE VERIFIED -> DISTRIBUTION VERIFIED -> STORE READY -> PRODUCTION RELEASED.

Nessun livello implica automaticamente il successivo.
