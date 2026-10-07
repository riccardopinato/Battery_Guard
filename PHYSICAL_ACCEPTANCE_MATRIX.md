# Physical Acceptance Matrix

The matrix must be executed against the exact candidate artifact SHA. CI/emulator evidence is not a substitute for these rows.

| Scenario | Samsung device | Xiaomi/Redmi/Poco device | Required evidence | Status |
|---|---|---|---|---|
| Clean install + onboarding | — | — | screen recording / notes | NOT RUN |
| Notification permission denied then granted | — | — | visible state change | NOT RUN |
| Alert channel manually disabled | — | — | reliability detects blocked channel | NOT RUN |
| Protection ON, screen off | — | — | FGS remains active | NOT RUN |
| Remove app from recents | — | — | monitoring behavior | NOT RUN |
| Reboot with protection enabled | — | — | service/tile/widget state | NOT RUN |
| Battery optimization restricted/unrestricted | — | — | diagnostic behavior | NOT RUN |
| Target alert | — | — | real notification delivery | NOT RUN |
| Night-mode silent alert | — | — | visible but silent | NOT RUN |
| Cable unplug alert | — | — | real notification delivery | NOT RUN |
| Interrupted charging session after process death | — | — | history marked interrupted/uncertain | NOT RUN |
| Widget controls | — | — | target/toggle/refresh | NOT RUN |
| Quick Settings Tile | — | — | synchronized ON/OFF | NOT RUN |
| Charge Doctor 5-minute test | — | — | stored result/confidence | NOT RUN |
| Lower threshold alert | — | — | dedicated low-limit sound + one-shot hysteresis | NOT RUN |
| Upper threshold alert | — | — | dedicated high-limit sound + one-shot hysteresis | NOT RUN |
| Notification-channel sound customization | — | — | low/high channels visible independently | NOT RUN |
| Battery Health Lab | — | — | charge counter/cycles/estimate correctly unavailable or plausible | NOT RUN |
| AdMob consent + banner Free | — | — | consent flow + banner only when allowed | NOT RUN |
| Pro purchase Internal Testing | — | — | buy + restore + all ads disappear | NOT RUN |
| Pro refund/revocation reconciliation | — | — | cached Pro clears after successful Play ownership query | NOT RUN |
| INTERNAL signed update N→N+1 | — | — | installs without uninstall + data/settings preserved | NOT RUN |
| Temperature unavailable | — | — | Home/History/session/widget never show fake 0.0 °C | NOT RUN |
| Charge Doctor while plugged but not charging | — | — | test start blocked with localized message | NOT RUN |
| Charge Doctor setup grouping | — | — | different named charger/cable setups do not share baseline | NOT RUN |

## Pass rule
No v1 production rollout until all core rows pass on at least one Samsung and one Xiaomi/Redmi/Poco-class device, or an explicit documented exception is accepted.

Status: BLOCKED — physical devices / Play Internal Testing evidence not available in CI.
