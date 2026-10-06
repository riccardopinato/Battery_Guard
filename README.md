# Battery Guard

Battery Guard è una utility Android Flutter/Dart local-first per monitorare ricarica, temperatura e comportamento della batteria senza account, backend o telemetria remota.

## Stato

Versione sorgente: **1.1.1+13 — Audit hardening**

Evidence attuale:
- IMPLEMENTED
- STATICALLY CHECKED: required by final CI
- TESTED: required by final CI
- PHYSICAL DEVICE VERIFIED: **NO**
- STORE READY: **NO — external gates pending**

Non considerare una build verde equivalente a validazione fisica del foreground service o della consegna notifiche.

## Funzioni

- finestra di ricarica con limite inferiore e superiore;
- due canali/suoni distinti: "metti in carica" e "scollega il caricatore";
- temperatura batteria;
- corrente, tensione e potenza quando esposte dal dispositivo;
- foreground monitoring Android;
- avvisi soglia, temperatura, 100%, cavo scollegato;
- modalità notte;
- Smart Charging con sessioni, velocità, ETA e baseline personale;
- Insights 7/30 giorni;
- widget Home;
- Quick Settings Tile;
- Charge Doctor con test controllati, confidence model e confronto personale A/B;
- Battery Guard Pro lifetime: rimozione pubblicità + Battery Health Lab + Charge Doctor + Insights 30 giorni;
- AdMob banner nel piano Free con UMP/Privacy Options, configurazione test in CI e ID reali obbligatori per la release production;
- notifiche native localizzate secondo lingua app/sistema;
- Battery Health Lab con stima robusta, outlier filtering e confidence basata anche sulla copertura SoC;
- diagnostica di servizio, permessi e notification channel;
- gestione sessioni interrotte/non affidabili;
- storage locale bounded.

Battery Guard **non interrompe fisicamente la ricarica** e non inventa una percentuale di battery health.

## Privacy

La v0.7 mantiene disabilitato Android Auto Backup per mantenere coerente la promessa local-only. Dati e configurazioni restano sul dispositivo salvo azioni future esplicite dell'utente.

## Build

Toolchain CI fissata a Flutter 3.47.5. La Web Preview usa dati simulati e non certifica le capability native. Le build CI senza credenziali di produzione usano signing di test e **non sono store-ready**. La firma di produzione è supportata tramite secret GitHub dedicati, non conservati nel repository.

Vedi `PRODUCT_BIBLE.md`, `ROADMAP.md`, `CHANGELOG.md`, `RELEASE_GATE.md` e la documentazione Play/Privacy.
