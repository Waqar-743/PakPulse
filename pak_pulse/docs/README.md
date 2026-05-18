# PAK·PULSE — Crisis Intelligence & Response Orchestrator

> Submission for **Google Antigravity Hackathon — Challenge 3: CIRO**
> Built in Flutter for Android + iOS.

PAK·PULSE turns raw crisis signals (in English, Urdu, or Roman Urdu) into coordinated government responses in under 60 seconds. The system is purpose-built for Pakistan's three recurring urban crises: **urban flooding**, **extreme heatwaves**, and **road-blocking protests**.

---

## The 4-Agent Pipeline

Every raw signal flows through a strict 4-stage agent pipeline. Each step is fully traceable in the **Agent Trace** screen.

```
Signal ─► Detection ─► Severity ─► Action
  ↓          ↓            ↓          ↓
 lang     cluster        RSI    3 prioritized
sector   is_new?      casualty  agency actions
crisis   confidence    risk
```

| Agent | Color | Responsibility | Tools |
|---|---|---|---|
| **Signal** | `#4D9FFF` | Parse raw text (EN/UR/Roman UR), extract sector, language, crisis hint | `normalize_text`, `geocode_sector` |
| **Detection** | `#B84DFF` | New-crisis vs existing-cluster decision (3-signal / 2-hour rule, 3× weight for PMD/NDMA) | `get_recent_signals`, `get_active_crises` |
| **Severity** | `#FF8A3D` | Compute severity tier + RSI (0–100), produce EN+UR summaries | `get_weather_overlay`, `get_population_density`, `count_signals_by_source` |
| **Action** | `#FF3B5C` | Generate 3 prioritized actions, call tools to mint real ticket IDs | `create_rescue_ticket`, `compute_reroute`, `draft_sms_alert` |

---

## How Antigravity Is Used

- **Specification-driven build** — the entire app is built phase-by-phase from a single instruction document (`PakPulse_Agent_Instructions.docx`). Each phase has a hard completion checklist. The build is reproducible from spec → code.
- **Multi-agent reasoning** — four independent agents with distinct system prompts, tools, and JSON output schemas. They are coordinated by an `Orchestrator` that yields a `Stream<OrchestratorEvent>` so the UI can render each transition live.
- **Traceability** — every agent produces an `AgentStep` with `inputSummary`, `outputSummary`, `reasoning`, `toolsUsed`, `durationMs`, and a `usedMockFallback` flag. The Agent Trace screen renders these in real time with handoff line animations.

---

## APIs / Tools (Simulated for Demo)

All tools return realistic-looking responses without hitting any network. This is intentional: the demo must work in airplane mode.

| Tool | Returns | Notes |
|---|---|---|
| `GeocodingTool.resolveSector` | `LatLng?` | Backed by a hard-coded `IslamabadSectors` map (G-5…G-15, F-5…F-11, I-8…I-14, Blue Area, Faizabad, Saddar, Murree Road, etc.) |
| `TicketTool.createRescueTicket` | `{ticket_id: 'R1122-IB-XXXX', units_dispatched, eta_minutes, ...}` | Rescue 1122 Islamabad |
| `TicketTool.createItpTicket` | `{ticket_id: 'ITP-XXXX', officers_assigned, alternate_route, ...}` | Islamabad Traffic Police |
| `TicketTool.createNdmaTicket` | `{ticket_id: 'NDMA-XX-XXXX', broadcast_channels, ...}` | NDMA Emergency Ops |
| `RerouteTool.computeReroute` | `{blocked_route, alternate_route, alternate_polyline, time_added, ...}` | Hardcoded G-10 and Faizabad routes use real Islamabad road names |
| `AlertTool.draftSms` | `{message_en, message_ur, recipient_count_estimate, channel, ...}` | Bilingual EN + Urdu Nastaliq messages |

The real LLM client (`lib/data/services/llm_client.dart`) is wired to Anthropic's `/v1/messages` endpoint and will use it if `LLM_API_KEY` is set in `.env` and `DEMO_MODE=false`. On any error/timeout it silently falls back to the mock responses.

---

## Running

```bash
flutter pub get
flutter run                       # uses DEMO_MODE=true from .env by default
```

For the live-LLM mode, set in `.env`:
```
LLM_API_KEY=sk-ant-...
DEMO_MODE=false
```

Then `flutter run`. If the network fails or the key is invalid, the app silently falls back to mock — never crashes.

---

## Project Layout

```
lib/
├─ agents/                 # 4 agents + orchestrator + 4 tools
│  ├─ tools/
│  ├─ agent_base.dart
│  ├─ signal_agent.dart
│  ├─ detection_agent.dart
│  ├─ severity_agent.dart
│  ├─ action_agent.dart
│  ├─ orchestrator.dart
│  └─ orchestrator_providers.dart
├─ core/                   # theme, constants, utils
├─ data/                   # models, mocks, services (llm_client)
├─ features/               # 9 screens + architecture easter egg
├─ widgets/                # atoms, molecules, organisms
├─ providers.dart          # Riverpod state
├─ router.dart             # GoRouter with SharedAxisTransition
└─ main.dart
```

See `docs/AGENT_TRACE_EXAMPLE.md` for a full captured pipeline trace, and `docs/DEMO_SCRIPT.md` for the 5-minute demo flow.
