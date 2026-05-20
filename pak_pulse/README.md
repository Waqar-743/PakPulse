<p align="center">
  <img src="Pak-Pulse-ICON.png" width="130" alt="PAK·PULSE"/>
</p>

<h1 align="center">PAK·PULSE</h1>
<p align="center"><b>Crisis Intelligence & Response Orchestrator for Pakistan</b></p>
<p align="center">
  <i>Real-time multi-agent AI that detects, classifies, and coordinates disaster response — built for Pakistani communities, powered by live data.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart" />
  <img src="https://img.shields.io/badge/AI-Multi--Agent_Pipeline-blueviolet" />
  <img src="https://img.shields.io/badge/Hackathon-2026-FF4B4B" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" />
</p>

---

## The Problem We Are Solving

Pakistan is one of the most disaster-prone countries on Earth. Every year, millions of citizens face floods, earthquakes, heatwaves, and civil emergencies with **no unified, intelligent response layer**. Information is fragmented across news tickers, WhatsApp forwards, and government bulletins that arrive hours too late. First responders act on gut feel. Communities are left guessing.

**PAK·PULSE changes that.**

---

## What Is PAK·PULSE?

PAK·PULSE is a mobile-first crisis intelligence platform that runs a **live multi-agent AI pipeline** directly on your phone. The moment a disaster signal comes in — from weather APIs, social feeds, or GDACS satellite alerts — four specialized AI agents wake up, confer, and produce a classified, severity-scored crisis with a recommended action plan in seconds.

Think of it as a **crisis command centre that fits in your pocket** — built specifically for Pakistan's geography, cities, and emergency ecosystem.

---

## Hackathon Context

> This app was built as a hackathon submission, demonstrating how AI agent orchestration can be applied to real-world humanitarian challenges in Pakistan.

**Challenge statement:** Design a technology solution that improves disaster preparedness and emergency response for communities in Pakistan.

**Our answer:** A multi-agent AI pipeline that ingests live signals from multiple data sources, detects emerging crises, scores their severity, and dispatches structured response actions — all in real time, all on a mobile device.

**What makes it stand out:**
- Four AI agents working in concert, each with a distinct role
- Live data integration (weather, maps, emergency feeds)
- Location-aware — auto-detects your Pakistani city and tailors all alerts
- Built to scale from a single user to city-wide emergency operations

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        PAK·PULSE APP                            │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Home    │  │  Signal  │  │  Crisis  │  │    Action     │  │
│  │Dashboard │  │  Inbox   │  │  Detail  │  │   Console     │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬────────┘  │
│       │              │             │                │            │
│  ─────┴──────────────┴─────────────┴────────────────┴────────── │
│                     Flutter UI Layer (Riverpod)                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│              ┌──────────── ORCHESTRATOR ───────────┐            │
│              │         (Pipeline Controller)        │            │
│              │                                      │            │
│     ┌────────▼────────┐            ┌────────────────▼────────┐  │
│     │  SIGNAL AGENT   │            │   DETECTION AGENT       │  │
│     │  Parses raw     │────────────▶  Identifies crisis type  │  │
│     │  input signals  │            │  from signal history     │  │
│     └─────────────────┘            └───────────┬─────────────┘  │
│                                                │                │
│     ┌───────────────────────────────────────────▼─────────────┐  │
│     │                  SEVERITY AGENT                         │  │
│     │     Scores impact: Low / Medium / High / Critical       │  │
│     └───────────────────────────────┬─────────────────────────┘  │
│                                     │                            │
│     ┌───────────────────────────────▼─────────────────────────┐  │
│     │                   ACTION AGENT                          │  │
│     │  Generates structured response plan with tools:         │  │
│     │  🚨 alert_tool  📍 geocoding_tool                       │  │
│     │  🔀 reroute_tool  🎫 ticket_tool                        │  │
│     └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent Pipeline — Step by Step

```
Raw Signal Received
        │
        ▼
┌───────────────┐
│ SIGNAL AGENT  │  → Parses text/metadata, extracts location,
│               │    event type, and confidence score
└───────┬───────┘
        │
        ▼
┌─────────────────┐
│ DETECTION AGENT │  → Cross-references with active crises
│                 │    & recent signal history; decides if
│                 │    this is a new event or an existing one
└────────┬────────┘
         │
         ▼
┌────────────────┐
│ SEVERITY AGENT │  → Scores severity (1–10) using weather
│                │    data, population density, crisis type
│                │    and geospatial risk factors
└───────┬────────┘
        │
        ▼
┌───────────────┐
│ ACTION AGENT  │  → Fires tools to create alerts, compute
│               │    safe evacuation routes, dispatch tickets
│               │    to relevant emergency departments
└───────┬───────┘
        │
        ▼
┌───────────────────────────────┐
│  Crisis object saved to state │
│  UI updates in real-time      │
│  User notified via app        │
└───────────────────────────────┘
```

---

## Live Data Sources

| Source | Data | Key needed | Used For |
|---|---|---|---|
| **Google Gemini** | LLM reasoning (`gemini-2.5-flash`) | Yes (free tier) | Powers the 4-agent pipeline; mock fallback on error |
| **Open-Meteo** | Current + next-day temperature, rainfall, humidity | No | Live conditions + heatwave/flood forecast |
| **OpenStreetMap** | Map tiles (CartoDB Voyager) via `flutter_map` | No | Crisis map, zones, routes, markers |
| **GDACS** | Global disaster alerts | No | Live regional flood / disaster feed |
| **TomTom Traffic** | Real road incidents, closures, jams | Yes (free tier) | Live road status near a crisis |

---

## Feature Breakdown

### Home Dashboard
- Live crisis card feed with severity color-coding
- Real-time signal counter updating every 8 seconds
- City-aware weather overlay

### Signal Inbox
- Streaming feed of incoming crisis signals
- Each signal shows source, confidence, and timestamp
- One-tap to run the full agent pipeline on any signal

### Crisis Detail
- Interactive OpenStreetMap (`flutter_map`) — crisis zone polygon, pulsing epicentre
- Alternate safe route (green polyline) + emergency-service markers
- Live atmospheric conditions + next-day heatwave/flood forecast (Open-Meteo)
- Live Road Status — real road incidents/closures from TomTom Traffic
- Agent Reasoning trace — the full 4-agent pipeline for this crisis

### Action Console
- Structured action plan generated by the Action Agent
- Each action item links to a tool call (alert, reroute, ticket)
- Real-time execution status per action

### Agent Trace
- Transparent view of every agent step in the pipeline
- Input/output log for Signal → Detection → Severity → Action
- Built for judges and developers to inspect AI reasoning

### Onboarding
- First-launch GPS permission request
- Auto-detects user's Pakistani city
- Manual city search fallback (100+ cities supported)
- Stored in SharedPreferences, never asked again

### Settings
- Change city at any time
- App theme and preferences

---

## Tech Stack

```
Frontend          Flutter 3.x + Dart 3.3+
State Management  Flutter Riverpod 2.x
Navigation        go_router 14.x
Maps              flutter_map + OpenStreetMap (no key)
AI Reasoning      Google Gemini (gemini-2.5-flash)
Location          geolocator
Animations        flutter_animate + Lottie + shimmer
Networking        Dio + http
Local Storage     shared_preferences
Fonts             Google Fonts
AI Pipeline       Custom multi-agent orchestrator (Dart)
Environment       flutter_dotenv
```

---

## Project Structure

```
lib/
├── main.dart               # App entry point
├── app.dart                # Root widget + theme
├── router.dart             # go_router route definitions
├── providers.dart          # Global Riverpod providers
│
├── agents/                 # AI Agent Pipeline
│   ├── orchestrator.dart   # Pipeline controller (stream-based)
│   ├── signal_agent.dart   # Parses raw signals
│   ├── detection_agent.dart# Crisis detection & deduplication
│   ├── severity_agent.dart # Impact scoring
│   ├── action_agent.dart   # Response plan generation
│   └── tools/              # Agent tool implementations
│       ├── alert_tool.dart
│       ├── geocoding_tool.dart
│       ├── reroute_tool.dart
│       └── ticket_tool.dart
│
├── core/
│   ├── constants/          # Crisis types, Pakistan cities
│   ├── theme/              # App-wide light theme
│   └── utils/              # Helpers
│
├── data/
│   ├── models/             # Crisis, Signal, Action, LiveConditions
│   ├── services/           # LiveConditionsService, LocationService, LLM client
│   ├── mock/               # Demo data for hackathon presentation
│   └── repositories/       # Data access layer
│
├── features/
│   ├── home/               # Dashboard screen
│   ├── signal_inbox/       # Signal feed
│   ├── crisis_detail/      # Map + detail view
│   ├── action_console/     # Action plan UI
│   ├── agent_trace/        # Pipeline transparency
│   ├── onboarding/         # City/GPS setup
│   ├── settings/           # User preferences
│   ├── history/            # Past crisis log
│   └── shell/              # Persistent navigation shell
│
└── widgets/                # Shared UI components
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.3.0`
- Android Studio or VS Code with Flutter extension
- An Android device or emulator (API 21+)
- A free Google Gemini API key ([aistudio.google.com](https://aistudio.google.com/apikey))
- A free TomTom API key ([developer.tomtom.com](https://developer.tomtom.com)) — optional, for live road data

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/your-username/pak-pulse.git
cd pak-pulse/pak_pulse

# 2. Install dependencies
flutter pub get

# 3. Configure your environment file (.env)
# Set these keys:
#   GEMINI_API_KEY=your_key_here     # required for live AI reasoning
#   TOMTOM_API_KEY=your_key_here     # optional — live road incidents
#   DEMO_MODE=false                  # false = live Gemini, true = offline mock
# Open-Meteo, OpenStreetMap and GDACS need no key.

# 4. Run on connected device
flutter run --release
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Hackathon Demo Flow

1. Launch app → onboarding asks for city (try **Islamabad**)
2. Home screen shows active crisis cards with live severity scores
3. Tap **Signal Inbox** → see incoming signals streaming in real-time
4. Tap any signal → run the **full 4-agent pipeline** and watch it execute
5. Open **Crisis Detail** → see the live Google Map with crisis zone + safe route
6. Open **Agent Trace** → inspect every AI reasoning step transparently
7. Open **Action Console** → review the structured emergency response plan

---

## Why Pakistan Needs This

- Pakistan ranks among the top 10 countries most vulnerable to climate change
- The 2022 floods affected **33 million people** and killed over 1,700
- Emergency response coordination remains siloed and slow
- PAK·PULSE is a step toward a unified, AI-assisted national crisis layer

---

## Contributing

Pull requests are welcome. For major changes, open an issue first.

---

## License

MIT License — see `LICENSE` for details.

---

<p align="center">Built with ❤️ for Pakistan · Hackathon 2026</p>
