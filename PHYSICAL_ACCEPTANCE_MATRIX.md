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
| Pro purchase Internal Testing | — | — | buy + restore | NOT RUN |

## Pass rule
No v1 production rollout until all core rows pass on at least one Samsung and one Xiaomi/Redmi/Poco-class device, or an explicit documented exception is accepted.

Status: BLOCKED — physical devices / Play Internal Testing evidence not available in CI.
