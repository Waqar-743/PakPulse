# PAK·PULSE — 5-Minute Demo Script

> Use this when recording the hackathon submission video. Total target: **3–5 minutes**. Keep cuts tight.

---

## 0:00 – 0:18 — HOOK

> "Pakistan loses lives every year to crises that take hours to coordinate.
> 2015 Karachi heatwave — 1,200 dead in three days.
> Islamabad G-10 — flooded every monsoon.
> Faizabad — blocked weekly.
> The signals are everywhere. Nobody connects them fast enough."

**On-screen:** Splash logo → home map. Three pulsing crisis markers appear one by one (red flood, orange heat, violet protest).

---

## 0:18 – 0:45 — THE SYSTEM

> "Pak-Pulse is Pakistan's first AI-powered crisis intelligence and response orchestrator.
> Four agents turn raw signals — in Urdu, Roman Urdu, or English — into executed government responses in under 60 seconds."

**On-screen:** Scroll the Signal Inbox showing live signals in three languages. Pause on an Urdu Nastaliq card and a Roman Urdu card to make the multilingual point.

---

## 0:45 – 2:10 — LIVE PIPELINE (the money shot)

> "Watch live."

**Action:** Tap `+ SIGNAL`. Type or paste:
```
G-10 mein pani bhar gaya, gaariyan phans gayi
```
Tap **RUN PIPELINE**.

> "Signal Agent — G-10, Roman Urdu, flood.
> Detection Agent — nine matching signals, new cluster.
> Severity Agent — RSI 87, Critical.
> Action Agent — three coordinated responses."

**On-screen:** Agent Trace screen. Each card glows its agent color while thinking, then completes with a green check. The handoff lines animate from 0→100% as each agent finishes. The PIPELINE elapsed-time counter in the header ticks up.

---

## 2:10 – 3:00 — ACTIONS EXECUTE

> "Now watch the actions execute — not just plan."

**Action:** Tap **EXECUTE ACTIONS** at the bottom of the trace screen.

> "Rescue 1122 ticket R1122-IB-4472 created. Traffic rerouted through Service Road Eastern. Bilingual SMS drafted for 45,000 residents."

**On-screen:** Action Console. Tap **EXECUTE** on each card in order:
1. **Dispatch** — character-by-character API response streams into the dark code box, ending with a green ticket ID.
2. **Reroute** — same typewriter response, plus the before/after mini map: old red path fades out, new green path draws itself.
3. **SMS Alert** — bilingual EN + Urdu message body shown.

---

## 3:00 – 3:45 — OTHER CRISES

> "Same system, two more crises.
> Jacobabad heatwave — NDMA deployed, cooling centers opened.
> Faizabad blockage — ITP deployed, 9th Avenue route activated."

**On-screen:** Back to home. Tap the **Jacobabad** marker → Crisis Detail (Overview tab → Signals tab). Quick cut. Back. Tap **Faizabad** marker → same flow.

---

## 3:45 – 4:30 — AGENT TRACE / TRACEABILITY

> "Every decision is traceable. Every tool call logged. This is not a chatbot — it's a structured multi-agent workflow with verifiable outputs."

**On-screen:** From a crisis detail, tap **AGENT TRACE**. Slowly scroll through the four cards. Tap one to expand: show INPUT, REASONING, TOOLS USED chips, and the raw JSON box. Highlight the `[demo]` badge to be transparent about mock fallback.

---

## 4:30 – 5:00 — CLOSE

> "Pak-Pulse. Crisis intelligence in 60 seconds. In Urdu or English.
> Signal do. Baqi hum sambhal lenge."

**On-screen:** Onboarding page 3 — the large Nastaliq line:
> سگنل دو، باقی ہم سنبھال لیں گے

Fade to splash logo.

---

## Pre-Demo Checklist

Before hitting record, in **Settings**:
- [ ] **Demo Mode** ON
- [ ] **Auto-play demo sequence** OFF (you're driving manually)
- [ ] **Playback speed** 1x
- [ ] **Reset Demo Data** tapped so the action console shows pending tickets
- [ ] Device on **airplane mode** to prove robustness

If you want a hands-free walk-through instead, flip **Auto-play** ON — three demo signals will fire 8 seconds apart and the third will take you straight to the agent trace.

---

## Easter Egg

In Settings, tap the **SETTINGS** title 5 times within 3 seconds → opens the **ARCHITECTURE** screen showing the 4-agent diagram, the tech stack, and the challenge name. Useful if a judge asks "what's the architecture?".
