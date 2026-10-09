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
| Capability Map / provenance | — | — | availability/source/confidence reflect actual device telemetry | NOT RUN |
| OEM/adaptive charge limit | — | — | remain plugged at device limit >= 8 min; detected as protection/pause, not broken session | NOT RUN |
| Normal unplug vs OEM pause | — | — | ordinary unplug is not classified as charge-limit phase | NOT RUN |
| Charging curve screen-off | — | — | bounded points continue while FGS is active and screen is off | NOT RUN |
| Charging curve bound | — | — | long session remains bounded; no unbounded storage growth | NOT RUN |
| Free session evidence | — | — | validity/reasons/OEM limit remain visible without Pro | NOT RUN |
| Premium curve gate | — | — | Free sees lock; Pro sees full curve and phases | NOT RUN |
| Legacy 1.1.x history migration | — | — | old sessions remain readable without fabricated curve/reason data | NOT RUN |
| Signed update 1.1.7 -> 1.3.0 | — | — | update installs in place and preserves settings/history | NOT RUN |
| Signed update 1.3.0 -> 1.5.0 | — | — | update installs in place and preserves curves/tests/settings | NOT RUN |
| Free Charge Doctor Basic | — | — | create one setup, run tests, see qualitative bands/anomalies | NOT RUN |
| Free second setup gate | — | — | second setup creation/use is blocked without deleting data | NOT RUN |
| Pro multiple setup profiles | — | — | create/edit/use multiple charger+cable combinations | NOT RUN |
| Setup persistence | — | — | profiles survive process death/reboot/update | NOT RUN |
| Personal baseline isolation | — | — | tests from another profile never affect Speed baseline | NOT RUN |
| Stability Score physical variance | — | — | unstable power pattern scores lower than stable pattern | NOT RUN |
| Thermal Score unavailable data | — | — | no fake numeric thermal score when temperature is unavailable | NOT RUN |
| Battery Stress Free | — | — | qualitative level visible without numeric breakdown | NOT RUN |
| Battery Stress Pro | — | — | numeric score/exposure breakdown visible and plausible | NOT RUN |
| Charger/cable ranking | — | — | ranking only compares user's reliable saved tests | NOT RUN |
| Refund/revocation profiles | — | — | extra profiles remain stored but Free cannot start tests with them | NOT RUN |
| D1 manual language switch | — | — | EN/IT/ES/FR/DE/PT change the whole app immediately, not only Home | NOT RUN |
| D1 locale persistence | — | — | selected language survives process restart; System returns to device locale | NOT RUN |
| D2 exact Android identity | — | — | manufacturer/model shown by Battery Guard matches Android device information | NOT RUN |
| D2 live model resolution | — | — | model code resolves to correct commercial model when provider coverage exists | NOT RUN |
| D2 live stock battery specs | — | — | returned mAh is plausible, source/confidence visible; wrong/no match fails safely | NOT RUN |
| D4 Health Lab adoption | — | — | stock capacity changes nominal baseline only after explicit tap | NOT RUN |
| D3 target range | — | — | 70/75/80/85/90/95/100 persist and monitoring remains active when protection is enabled | NOT RUN |
| D3 OEM/system capability | — | — | Samsung/Xiaomi path is presented as system-setting capability, never direct control | NOT RUN |
| D3 below-target truth | — | — | plugged+charging below target reports below target, never stopped | NOT RUN |
| D3 still-charging truth | — | — | at/above target + charging=true reports still charging, never verified | NOT RUN |
| D3 static stopped snapshot | — | — | launch/restart while already plugged+not charging at target; must remain unverified/pending | NOT RUN |
| D3 unsupported custom target | — | — | choose target not exposed by OEM adapter; remains alert-only, never verified stop | NOT RUN |
| D3 verified stop readback | — | — | observe CHARGING, then at/above target observe plugged=true + charging=false within the transition window; only then VERIFIED STOP | NOT RUN |
| D3 overnight protection | — | — | leave connected overnight; verify OEM limit/readback and FGS reliability without runaway polling | NOT RUN |
| D5 Health/ETA/Idle calibration | — | — | collect exact-artifact evidence; tune only if observed evidence justifies changes | NOT RUN |

## Pass rule
No v1 production rollout until all core rows pass on at least one Samsung and one Xiaomi/Redmi/Poco-class device, or an explicit documented exception is accepted.

Status: BLOCKED — physical devices / Play Internal Testing evidence not available in CI.
