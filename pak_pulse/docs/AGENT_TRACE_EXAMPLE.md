# Agent Trace Example — Live Pipeline Run

**Input signal:** `G-10 mein pani bhar gaya, gaariyan phans gayi hain, madad chahiye`
**Mode:** `DEMO_MODE=true` (mock fallback active — every step tagged `[demo]`)
**Total pipeline time:** ~2.6s

---

## STEP 1 — Signal Agent (342 ms) `[demo]`

**Input**
```
Raw signal: "G-10 mein pani bhar gaya, gaariyan phans gayi hain, madad chahiye"
```

**Output**
```json
{
  "language": "roman_ur",
  "sector": "G-10",
  "lat_hint": 33.69,
  "lng_hint": 73.0228,
  "crisis_hint": "flood",
  "severity_hint": "high",
  "extracted_entities": ["water/flood", "vehicle", "help_request", "sector_G10"],
  "confidence": 0.88,
  "reasoning": "Signal processed in DEMO_MODE. Language detected from keyword analysis. Sector resolved from IslamabadSectors lookup. Crisis type inferred from domain vocabulary."
}
```

**Tools used:** `normalize_text`, `geocode_sector`

---

## STEP 2 — Detection Agent (518 ms) `[demo]`

**Input**
```
9 signals from G-10 in last 2 hours
```

**Output**
```json
{
  "is_new_crisis": true,
  "crisis_type": "flood",
  "cluster_id": "demo-cluster-1747500000000",
  "signal_count_in_cluster": 10,
  "confidence": 0.85,
  "reasoning": "Cluster threshold met: 3+ signals from same sector within 2-hour window. DEMO_MODE active — using mock clustering logic."
}
```

**Tools used:** `get_recent_signals`, `get_active_crises`

→ Handoff line draws from Detection to Severity (600ms morph)

---

## STEP 3 — Severity Agent (724 ms) `[demo]`

**Input**
```
Crisis: flood @ G-10 | 10 signals | weighted source mix
```

**Output**
```json
{
  "severity": "high",
  "rsi_score": 74,
  "affected_radius_meters": 1000,
  "casualty_risk": "moderate",
  "summary_en": "Crisis detected and assessed in DEMO_MODE. Risk score calculated using signal count and source weighting.",
  "summary_ur": "بحران کا پتہ لگایا گیا ہے اور خطرے کی سطح کا اندازہ لگایا گیا ہے۔",
  "reasoning": "RSI computed: base 40 + source multipliers + Pakistan context factors. DEMO_MODE active."
}
```

**Tools used:** `get_weather_overlay`, `get_population_density`, `count_signals_by_source`

→ Note the `summary_ur` is real Urdu script (Nastaliq) — never transliterated.

---

## STEP 4 — Action Agent (891 ms) `[demo]`

**Input**
```
HIGH flood @ G-10 | RSI 74
```

**Output** — 3 prioritized actions
```json
{
  "actions": [
    {
      "priority": 1,
      "type": "dispatch_rescue",
      "title": "Deploy Rescue 1122 — G-10",
      "target_agency": "Rescue 1122 Islamabad",
      "payload": {"sector": "G-10", "units": 2},
      "estimated_impact": "Life safety response within 12 minutes."
    },
    {
      "priority": 2,
      "type": "traffic_reroute",
      "title": "Activate Alternate Route — G-10",
      "target_agency": "Islamabad Traffic Police (ITP)",
      "payload": {"blocked": "G-10", "alternate": "Service Road Eastern"}
    },
    {
      "priority": 3,
      "type": "citizen_alert_sms",
      "title": "Emergency SMS Alert — G-10 Residents",
      "target_agency": "NDMA Emergency Communication Cell",
      "payload": {"sector": "G-10", "recipients": 45000}
    }
  ],
  "reasoning": "Three-tier response: life safety first, traffic management second, public communication third."
}
```

After the LLM returns, the Action Agent **calls the appropriate tool for each action**, producing real-looking ticket IDs:

- `TicketTool.createRescueTicket` → `R1122-IB-4471`
- `RerouteTool.computeReroute` + `TicketTool.createItpTicket` → `ITP-2240`
- `AlertTool.draftSms` + `TicketTool.createNdmaTicket` → `NDMA-FL-0337`

**Tools used:** `create_rescue_ticket`, `compute_reroute`, `draft_sms_alert`

---

## Pipeline Complete

A new `Crisis` object is constructed from the four agent outputs and added to `crisisListProvider`. The home map updates with a new pulsing marker. The **VIEW CRISIS** and **EXECUTE ACTIONS** buttons appear at the bottom of the trace screen.

Every step above is replayable in-app:
1. Open the home screen
2. Tap the `+ SIGNAL` FAB
3. Paste any of the demo signal texts
4. Tap **RUN PIPELINE** — the agent trace screen will animate the full sequence live.
