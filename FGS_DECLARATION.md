# Foreground Service specialUse — Play declaration pack

## Capability
Battery Guard continuously watches user-requested battery charging state while protection is enabled so it can surface threshold, high-temperature and charging-interruption alerts when the UI is not open.

## Why foreground execution is user-visible
- Monitoring is explicitly enabled/disabled by the user.
- Android displays the persistent "Battery Guard active" foreground-service notification.
- The Quick Settings tile and app settings expose the same monitoring state.
- The service stops when the user disables Battery Guard.

## Why the work cannot simply be deferred
The value of a threshold/temperature alert depends on observing the charging state close to when the condition occurs. Deferring the check until the user reopens the app defeats the core user-requested protection behavior.

## specialUse manifest property
Current subtype statement:
"Continuous battery charge and temperature monitoring with user-requested alerts"

## Suggested Play Console explanation
Battery Guard is a battery charging monitor. When the user explicitly enables protection, it runs a foreground service to receive Android battery/power events and alert the user when a chosen charge threshold or temperature condition is reached. The persistent foreground notification keeps the activity visible and gives the user a direct way to return to the app or disable monitoring.

## Review video script
1. Open Battery Guard.
2. Show Protection OFF.
3. Enable Protection.
4. Show the persistent foreground notification.
5. Open Quick Settings and show Battery Guard tile = ON.
6. Show configured target threshold.
7. Trigger/use test alert to demonstrate notification UI.
8. Disable protection from notification/tile/app.
9. Show foreground notification disappearing.

Status: PREPARED, NOT PLAY-APPROVED.
