# Battery Guard

Battery Guard è una utility Android Flutter/Dart local-first per monitorare ricarica, temperatura e comportamento della batteria senza account, backend o telemetria remota.

## Stato

Versione sorgente: **1.1.7+19 — Production & Runtime Hardening**

Evidence attuale:
- IMPLEMENTED
- persistent INTERNAL signing configured in CI
- Free + Premium Test artifacts generated from the same source SHA/signing identity
- STATICALLY CHECKED: required by CI
- TESTED: required by CI
- Billing dependency hardened to current 3.3.x / Android adapter 0.5.x
- PR CI runs without signing secrets; signed INTERNAL artifacts are main-only and ARM64-first
- telemetry availability propagated through History, sessions and widget
- PHYSICAL UPDATE VERIFIED: **PENDING**
- STORE READY: **NO — external production gates pending**

Non considerare una build verde equivalente a validazione fisica del foreground service, delle notifiche, del layout pubblicitario o dell'aggiornamento in-place su device reale.

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
- AdMob Free con UMP/Privacy Options e Large Anchored Adaptive Banner, separato dalla NavigationBar;
- Test Ads obbligatori nelle build INTERNAL/QA;
- nuova icona launcher adaptive con variante themed/monochrome Android 13+;
- APK INTERNAL firmati con identità persistente verificata via fingerprint SHA-256;
- build Premium Test compile-time separata dalla logica Play production;
- notifiche native localizzate secondo lingua app/sistema;
- Battery Health Lab con stima robusta, outlier filtering e confidence basata anche sulla copertura SoC;
- diagnostica di servizio, permessi e notification channel;
- gestione sessioni interrotte/non affidabili;
- storage locale bounded.

Battery Guard **non interrompe fisicamente la ricarica** e non inventa una percentuale di battery health.

## Privacy

Android Auto Backup resta disabilitato per mantenere coerente la promessa local-only. Dati e configurazioni restano sul dispositivo salvo azioni future esplicite dell'utente.

AdMob non riceve la telemetria batteria come input di targeting. Dove richiesto, UMP viene completato prima che Battery Guard possa richiedere annunci e le Privacy Options restano riapribili quando richiesto dal framework Google.

## Build e signing

Toolchain CI fissata a Flutter 3.47.5.

La lane INTERNAL usa i secret `ANDROID_KEYSTORE_*` come keystore persistente, rifiuta fingerprint diversi da quello atteso e produce Free + Premium Test firmati con la stessa identity. La Free usa esclusivamente Test Ads.

La lane PRODUCTION usa secret separati `ANDROID_PRODUCTION_*` e richiede configurazione AdMob reale. La Web Preview usa dati simulati e non certifica capability native.

Vedi `PRODUCT_BIBLE.md`, `ROADMAP.md`, `CHANGELOG.md`, `MONETIZATION.md`, `RELEASE_GATE.md` e la documentazione Play/Privacy.
