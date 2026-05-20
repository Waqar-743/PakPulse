<p align="center">
  <img src="Pak-Pulse-ICON.png" width="150" alt="PAK·PULSE app icon"/>
</p>

<h1 align="center">PAK·PULSE</h1>

<p align="center">
  <b>When a road gets blocked in Islamabad, six AI agents argue about it before your neighbour even tweets.</b>
</p>

<p align="center">
  <i>A citizen-first crisis intelligence app for Pakistan — live signals in, verified alerts out.</i>
</p>

<p align="center">
  <a href="https://github.com/Waqar-743/PakPulse/releases/latest"><img src="https://img.shields.io/github/v/release/Waqar-743/PakPulse?label=APK&color=3DDC84&logo=android"/></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart"/>
  <img src="https://img.shields.io/badge/AI-6--Agent_Pipeline-blueviolet"/>
  <img src="https://img.shields.io/badge/RAG-Gemini-FF6F00"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android"/>
</p>

<p align="center">
  <a href="https://github.com/Waqar-743/PakPulse/releases/latest/download/pak-pulse-v1.1.0.apk"><b>⬇ Download the latest APK</b></a>
</p>

---

## The Story

It's a Tuesday afternoon in G-10. Somebody on Margalla Road posts on X that the chowk is blocked. Three minutes later a citizen forwards the same thing on WhatsApp. Five minutes later a PMD weather alert quietly pings about rain in Zone 3. Twenty minutes later traffic on Faizabad doubles back.

Right now, those four facts live in four different places. Your phone doesn't connect them. Rescue 1122 doesn't connect them. Your cousin sitting in F-7 has no idea any of this is happening until he drives into it.

**PAK·PULSE connects them.** As reports come in, they cluster by sector and by what's being reported. The moment two or more citizens describe the same thing in the same place, six AI agents wake up, cross-check the cluster against TomTom's live traffic feed and GDACS's regional disaster feed, score the confidence, and — only if the evidence holds — drop a verified alert on the map and ping every PAK·PULSE user within 25 km.

That's the whole pitch. Citizens report; agents verify; the city sees it before it spreads.

---

## What It Actually Does

| | |
|---|---|
| **Crowd-clustered intake** | Signals from Twitter, citizen reports, PMD, NDMA, and traffic cameras get grouped by sector + crisis type within a 2-hour window. Official sources (PMD/NDMA) count 3× weight. |
| **6-agent verification chain** | `Signal → Detection → Verification → FactCheck → Severity → Action`. Verification pulls live TomTom + GDACS evidence. FactCheck is a hard gate — unverified clusters never reach the map. |
| **Real-time notifications** | Verified crisis within 25 km of your stored city → dismissible banner on Home with a one-tap email share. No backend, no Firebase, no card. |
| **Grounded chatbot ("Ask")** | RAG over active and historical crisis records. Replies in English, Urdu, or Roman-Urdu. Cites the records it used. Won't invent locations, casualties, or times. |
| **Live maps** | OpenStreetMap tiles, crisis polygons, alternate routes, emergency-service markers. |
| **Bilingual everywhere** | English + Urdu signal parsing, Roman-Urdu fallback. Built for how Pakistanis actually type. |

---

## Why The Pipeline Has Six Agents

A single LLM call deciding "is this real?" gets it wrong in two ways: it hallucinates corroboration that doesn't exist, and it can't be audited. Splitting the work makes each step inspectable and each failure recoverable.

```
   ┌─────────────┐    ┌─────────────┐    ┌──────────────┐
   │  SIGNAL     │    │  DETECTION  │    │ VERIFICATION │
   │             │    │             │    │              │
   │ normalize   │───▶│ cluster +   │───▶│ TomTom +     │
   │ parse text  │    │ dedup vs.   │    │ GDACS evid.  │
   │ extract loc │    │ active map  │    │ (no LLM)     │
   └─────────────┘    └─────────────┘    └──────┬───────┘
                                                │
                ┌───────────────────────────────┘
                ▼
       ┌──────────────┐    ┌─────────────┐    ┌────────────┐
       │ FACT-CHECK   │    │  SEVERITY   │    │  ACTION    │
       │              │    │             │    │            │
       │ confidence + │───▶│ RSI score + │───▶│ alerts +   │
       │ go / no-go   │    │ summary EN+ │    │ reroute +  │
       │ HARD GATE    │    │ UR          │    │ tickets    │
       └──────────────┘    └─────────────┘    └────────────┘
```

The hard gate is the point. If FactCheck says no, severity and action never run, and the crisis never lands on the map. Citizens see "watching" not "confirmed." That's how trust survives a noisy news cycle.

---

## Data Sources

| Source | What it gives us | Key needed | Free tier |
|---|---|---|---|
| **Google Gemini** (`gemini-2.5-flash`) | LLM reasoning for Signal / Detection / FactCheck / Severity / Action / Chat | Yes | 1k req/day |
| **TomTom Traffic Incidents** | Live road closures, jams, accidents — the "official" corroboration for road-blockage clusters | Yes | 2.5k req/day |
| **GDACS** (UN + EC) | Regional floods, cyclones, alerts — the "official" corroboration for flood clusters | No | Unlimited |
| **Open-Meteo** | Weather + heat forecast for the user's city | No | Unlimited |
| **OpenStreetMap** (CartoDB Voyager) | Map tiles via `flutter_map` | No | Unlimited |

---

## Tech Stack

```
Frontend          Flutter 3.x · Dart 3.3+
State             Riverpod 2.x (StateNotifier + StreamProvider)
Navigation        go_router 14
LLM               Google Gemini (gemini-2.5-flash) via Dio
Maps              flutter_map + OSM/CartoDB tiles (no key)
Location          geolocator
Animations        flutter_animate · Lottie · shimmer
Storage           shared_preferences
Env               flutter_dotenv (bundled as asset)
Agents            Custom multi-agent orchestrator (pure Dart, stream-based)
```

---

## Project Structure

```
lib/
├── main.dart                          # bootstrap
├── app.dart                           # MaterialApp.router + theme
├── router.dart                        # go_router routes
├── providers.dart                     # signal & crisis state
│
├── agents/
│   ├── orchestrator.dart              # 6-stage stream pipeline
│   ├── orchestrator_providers.dart    # clusterer + auto-verifier providers
│   ├── signal_clusterer.dart          # sector × type × window grouping
│   ├── signal_agent.dart              # parse raw text → normalized
│   ├── detection_agent.dart           # new vs. existing crisis
│   ├── verification_agent.dart        # TomTom + GDACS cross-check (no LLM)
│   ├── fact_check_agent.dart          # confidence score + hard gate
│   ├── severity_agent.dart            # RSI + bilingual summary
│   ├── action_agent.dart              # alert / reroute / ticket plan
│   └── tools/                         # geocoding, reroute, alert, ticket
│
├── data/
│   ├── models/                        # crisis, signal, road_incident, disaster_news…
│   ├── services/                      # llm_client, traffic, disaster_news, notification…
│   └── mock/                          # seeds for offline DEMO_MODE
│
├── features/
│   ├── onboarding/                    # GPS / city picker
│   ├── home/                          # dashboard + verified-alert banner + Ask FAB
│   ├── chat/                          # RAG chatbot screen
│   ├── crisis_detail/                 # map + live traffic + agent trace
│   ├── agent_trace/                   # transparent 6-step reasoning log
│   ├── architecture/                  # in-app diagram of the pipeline
│   ├── history/                       # past crises
│   ├── signal_inbox/ · action_console/ · settings/ · splash/ · shell/
│
└── widgets/                           # atoms / molecules / organisms
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>= 3.3.0`
- Android Studio or VS Code (Flutter extension)
- An Android 7+ device or emulator
- A free Gemini key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
- *(Optional)* A free TomTom key from [developer.tomtom.com](https://developer.tomtom.com) — road-blockage verification falls back to citizen-only weighting without it

### Run it

```bash
git clone https://github.com/Waqar-743/PakPulse.git
cd PakPulse/pak_pulse

# Configure secrets — pak_pulse/.env (gitignored)
#   GEMINI_API_KEY=AIza...
#   TOMTOM_API_KEY=...
#   DEMO_MODE=false           # true = fully offline mock pipeline

flutter pub get
flutter run --release
```

### Build a release APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

> On Windows machines with a tight C: drive, redirect Gradle off C: first:
> ```powershell
> $env:GRADLE_USER_HOME = 'D:\gradle-home'
> $env:TMP = 'D:\build-temp'; $env:TEMP = 'D:\build-temp'
> ```

### Try the latest APK without building

[**Download `pak-pulse-v1.1.0.apk` from the latest release →**](https://github.com/Waqar-743/PakPulse/releases/latest)

Enable "Install from unknown sources" on your Android, open the APK, install. Grant location on first launch.

---

## How To Demo It

1. Launch → onboarding asks for your city. Pick **Islamabad**.
2. On the Home screen, leave the signal simulator running. Within ~16 seconds two same-sector signals will accumulate.
3. Watch the agent rail at the bottom of the screen light up: **S → D → V → FC → Sv → A**.
4. If FactCheck verifies (live mode with TomTom corroboration this happens fast), a new crisis pin lands on the map and a banner appears.
5. Tap the **Ask** FAB → ask "Is G-10 safe right now?" The chatbot retrieves the verified crisis and answers grounded in it.
6. Tap a crisis → open the Agent Trace screen → inspect every input / output / reasoning step the agents produced.

---

## Security Note On The Release APK

The published APK at `releases/latest` bundles `.env` as a Flutter asset — that's how `flutter_dotenv` works. Anyone who decompiles the APK can read the embedded `GEMINI_API_KEY` and `TOMTOM_API_KEY`. For a demo build, fine. **For wider public distribution: rotate both keys after publishing**, or move them server-side behind a thin proxy. This is a known trade-off of shipping client-side keys with `flutter_dotenv`, not a project-specific bug.

---

## Why Pakistan Needs Something Like This

- Pakistan ranks in the top 10 most climate-vulnerable countries on the [Global Climate Risk Index](https://www.germanwatch.org/en/cri).
- The 2022 floods affected **33 million people** and killed over 1,700.
- Crisis information today is scattered across Twitter, WhatsApp, PMD bulletins, ICT Police tweets, and Rescue 1122 hotlines — none of which talk to each other.
- A unified, citizen-first verification layer doesn't fix that overnight. But it gives one shared source of truth that's auditable, bilingual, and lives in everyone's pocket.

---

## Roadmap

- Push notifications via FCM (currently in-app only; needs Firebase Blaze plan)
- Server-side proxy so API keys can leave the APK
- Embeddings-based retrieval for the chatbot once the crisis corpus exceeds ~200 records (currently keyword + sector + recency)
- Twitter / X ingestion via official API once budget permits
- Karachi, Lahore, Peshawar sector dictionaries (Islamabad / Rawalpindi are fully covered today)

---

## Contributing

PRs welcome. Open an issue first for anything bigger than a typo. If you're adding a new agent or a new data source, keep the orchestrator's stream contract intact — `OrchestratorEvent` shape is what the UI's agent timeline depends on.

---

## License

MIT — see `LICENSE`.

---

<p align="center">
  <i>Built in Islamabad. For everyone who's ever taken a wrong turn into a road that nobody told them was blocked.</i>
</p>
