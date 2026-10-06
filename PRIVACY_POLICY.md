# Battery Guard — Privacy Policy

Last updated: 2026-10-06

Battery Guard is designed as a local-first battery utility.

## Battery data processed on the device
Battery Guard reads battery information exposed by Android, including charge level, charging status, temperature when available, voltage/current when available, charge counter when available, cycle count when available, charging source and power-save state.

It can store locally:
- charging history and alerts;
- charging-session statistics;
- Charge Doctor test results;
- Battery Health Lab capacity samples and nominal capacity entered by the user;
- app preferences.

Battery Guard does not upload this battery telemetry to a Battery Guard server.

## Battery Health Lab
Battery Health Lab calculates an **estimate**, not an official manufacturer battery-health percentage. The estimate depends on Android/OEM telemetry and the nominal capacity configured by the user. If the device does not expose compatible information, Battery Guard reports the data as unavailable rather than inventing a value.

## Advertising — Free version
The Free version can display Google AdMob banner advertising. Google Mobile Ads may process device/advertising information according to Google's own policies. Battery Guard requests the Google consent flow where required before requesting ads.

Battery Guard does not use battery telemetry or Charge Doctor results to target advertisements.

When Google's privacy configuration requires it, Battery Guard exposes a visible "Privacy choices" entry in Settings so the user can review or change advertising privacy choices.

## Pro
Battery Guard Pro is a one-time Google Play purchase. Pro removes Battery Guard advertising and unlocks additional features including Battery Health Lab, Charge Doctor and extended Insights.

Purchase processing is performed by Google Play. Battery Guard stores the local entitlement required to unlock Pro and can restore ownership through Google Play.

## Accounts and Battery Guard cloud
There is no Battery Guard account and no Battery Guard cloud backend in v1.1.

## Backup
Android Auto Backup is disabled for Battery Guard so local battery history is not silently copied to cloud backup by the app configuration.

## Analytics
Battery Guard does not include a separate first-party analytics or behavioural-tracking system.

## Deletion
Local history and Charge Doctor tests can be deleted from the app. Clearing application storage or uninstalling Battery Guard removes its local app data under normal Android application-data semantics.

## Contact
A public support/privacy contact and hosted privacy-policy URL must be added before Play production rollout.
