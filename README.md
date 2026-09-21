# Battery Guard

Flutter Android utility per monitorare batteria, temperatura e ricarica con avvisi persistenti anche a schermo spento.

## Stato
Versione: 0.1.0+1
Package: `com.riccardopinato.batteryguard`

## Funzioni incluse
- Dashboard con livello batteria, temperatura, tensione, corrente/potenza stimata e salute Android.
- Soglia di avviso selezionabile: 80 / 85 / 90 / 100%.
- Avviso carica completa.
- Avviso temperatura elevata con soglia configurabile.
- Avviso cavo scollegato.
- Modalità notte con notifiche silenziose.
- Foreground service Android per monitoraggio a schermo spento.
- Riavvio monitoraggio dopo boot/aggiornamento se l'utente lo aveva attivato.
- Storico locale di campioni e avvisi.
- Nessun account, cloud o telemetria.

## Nota tecnica
L'interfaccia e la logica applicativa sono Flutter/Dart. Il progetto include il minimo bridge Android/Kotlin necessario per leggere le API batteria avanzate e mantenere gli avvisi affidabili in background.

Battery Guard avvisa l'utente ma non interrompe fisicamente la ricarica.
