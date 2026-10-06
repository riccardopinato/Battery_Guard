# Google Play Data Safety — Draft

This file is a preparation aid. The final declaration must be verified against the exact production AAB and Play Console wording.

## Developer-collected data
- Battery telemetry: not collected by developer.
- Charging history: not collected by developer.
- Charge Doctor test data: not collected by developer.
- Account data: no Battery Guard account.
- Analytics: none.
- Advertising identifiers: none.

## Sharing
Battery Guard does not share battery/charging data with third parties.

## Purchase handling
The optional Battery Guard Pro lifetime purchase uses Google Play Billing. Purchase processing is performed by Google Play. Only entitlement state needed for unlocking Pro is handled by the app.

## Storage
Battery Guard app data is local-only. Android Auto Backup is disabled.

## Security / deletion
The user can clear local history and controlled-test results in-app and can remove all application data by uninstalling/clearing app storage.

Status: DRAFT — must be reconciled with Play Console and the exact production dependencies before submission.
