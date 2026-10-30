# 🚀 CBIT Hacktoberfest '26 — Project Submission

> **Official Submission Repository for CBIT Hacktoberfest '26**  
> *Chaitanya Bharathi Institute of Technology (CBIT), Hyderabad*

---

## 📋 Team Information

| Attribute | Details |
| :--- | :--- |
| **Team Name** | **The outliers** |
| **Team Number** | `TEAM-18` (`HFT26-TEAM-18`) |
| **Registration ID** | `HFEST26-7HNY7B9P` |
| **Problem Track** | **Offline Emergency Messaging & Safety Mesh System** |
| **Domain** | `Disaster Management & Public Safety` |
| **Team Leader** | Chilkepally abhinav (abhinavchilkepally@gmail.com) |
| **Institution** | Kmit |

### 👥 Team Members

| # | Name | Email | Institution | Role |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Tanay reddy vaddula | rtanay299@gmail.com | Kmit | Lead Developer & UI/UX |
| 2 | Chilkepally abhinav | abhinavchilkepally@gmail.com | Kmit | Team Leader & Systems |
| 3 | Maram sahasra reddy | sahasramaram373@gmail.com | Kmit | Core Logic & Proximity |
| 4 | Bendram kodandarama reddy | ram711522@gmail.com | Kmit | Safety & NLP Translation |
| 5 | Vamshi Krishna vududala | vamshikrishnavududala@gmail.com | Kmit | Networking & Mesh Testing |

---

# ResQ — Offline Emergency Messaging & Safety Mesh System

[![Verification Suite](https://img.shields.io/badge/Verification%20Suite-100%25%20Passing-brightgreen)](#automated-verification-suite)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Cross--Platform%20Web-blue)](#architecture-and-framework-decisions)
[![Offline Capability](https://img.shields.io/badge/Connectivity-Zero%20Internet%20Required-orange)](#offline-mesh-communication)

**ResQ** is a production-grade, decentralized **Offline Emergency Messaging & Safety System** designed for natural disaster response, outdoor expeditions, search-and-rescue teams, and off-grid group coordination. 

Operating entirely **without cellular data, internet access, routers, or cloud servers**, ResQ turns standard mobile devices into an ad-hoc store-and-forward mesh network.

---

## The Five Core Modules

| Module | Authority | Primary Responsibility |
|---|---|---|
| **Feature 1: Mesh Communication** | `MeshEngine` | P2P discovery, BLE/Nearby transport, framing/fragmentation, application store-and-forward relay, loop prevention, hop accounting. |
| **Feature 2: Group Tracking & Safety** | `ProximityCalculator`, `MeetingPointManager`, `FallDetectionStateMachine` | Haversine distance, conservative horizontal uncertainty (`±meters`), leader-authenticated meeting points, tombstones, contact-loss prompts, and experimental 3-phase fall detection. |
| **Feature 3: On-Device NLP** | `LocalTranslator`, `LanguageManager`, `ExtractiveSummarizer` | On-device ML Kit language detection, receiver-side offline translation (English, Telugu, Hindi, Tamil, Kannada), and rule-based extractive summarization preserving negation. |
| **Feature 4: Battery & Power Safety** | `BatteryMonitor`, `RiskZoneEvaluator` | Non-overlapping battery bands, latched discharge episode alerts (<10%, <5%), offline circular RED hazard zones, and mandatory safety check coordination. |
| **Feature 5: SOS Priority & Lifecycle** | `IncidentCoordinator`, `PriorityClassifier`, `DeliveryTracker` | Deterministic priority classification (P0–P3), durable outbox scheduler, atomic persistence, exact-revision receipt tracking (`Rev X by Y of Z members`), and optional cloud sync. |

---

## System Architecture

```mermaid
graph TD
    UI[Unified Flutter Mobile UI\nHome | Group | Chat | Incidents | Settings | Demo]
    
    subgraph Coordinators
        SC[Session Coordinator\nOffline Trust & QR Enrollment]
        LC[Location Coordinator\nPower-Aware GPS Fixes]
        SCC[Safety Check Coordinator\nArbitration & Escalation]
    end

    subgraph Feature Engines
        F1[F1: Mesh Engine & Router\nStore-and-Forward | Loop Prevention]
        F2[F2: Proximity & Falls\nHaversine | Fall State Machine]
        F3[F3: Local Intelligence\nML Kit Translation | Summarizer]
        F4[F4: Battery & Risk Zones\nDischarge Latches | RED Zones]
        F5[F5: Incident Coordinator\nPriority Scheduler | Outbox]
    end

    subgraph Storage & Hardware
        DB[(Local Database\nOutbox | Incidents | Receipts | Zones)]
        BT[Android BLE GATT & Nearby Connections]
        Sensors[Accelerometer & Gyroscope]
    end

    UI --> Coordinators
    Coordinators --> Feature Engines
    Feature Engines --> DB
    F1 --> BT
    F2 --> Sensors
    F4 --> LC
    F5 --> F1
```

---

## Automated Verification Suite

ResQ includes an end-to-end verification suite testing 100% of the mathematical calculations, state machine transitions, multi-node mesh store-and-forward routing, and NLP rules:

```bash
python tools/run_verification.py
```

### Verification Results:
- [x] Haversine 1 degree lat distance (~111km)
- [x] Bearing calculation (0..360°) and cardinal heading mapping
- [x] Conservative uncertainty span (`±meters`) crossing threshold yields `DISTANCE_UNCERTAIN`
- [x] HMAC-SHA256 Envelope signature generation & tamper rejection
- [x] Packet fragmentation and reassembly integrity
- [x] Multi-Hop Mesh Relay: Phone A sends SOS $\rightarrow$ Phone B relays $\rightarrow$ Phone C stores & generates exact `STORED` receipt $\rightarrow$ Phone B relays receipt back to Phone A (loop completed without direct A-C link)
- [x] Experimental Fall Detection: Free-fall (<0.5G) $\rightarrow$ Impact (>2.5G) $\rightarrow$ Stillness (2.5s) $\rightarrow$ Emits `POSSIBLE_FALL` Rev 1
- [x] Non-overlapping battery bands: Normal (>30%), Power Optimization (15–30%), Low Power Prep (10–15%), Low Power Alert (5–10%), Critical (<5%)
- [x] Discharge episode latches: crossing <10% emits alert once per episode
- [x] Deterministic Priority: Explicit SOS is authoritative P0; life-threat keywords without negation = P0; keywords with negation = P3
- [x] Leader Meeting Point Authority: non-leader rejected; leader creates Rev 1; atomic removal tombstone Rev 2
- [x] Multilingual extractive summarizer selects critical sentences and preserves negation tokens (`not`, `లేదు`, `नहीं`)

---

## Setup & Running Instructions

### Prerequisites
- Android Studio / VS Code
- Node.js (v16+)
- Python 3 (for test harness)
- Android Physical Devices (Android 8.0+ / API 26+)

### 1. Clone & Branch
```bash
git clone https://github.com/cbitosc/HFT26-TEAM-18.git
cd HFT26-TEAM-18
git checkout integration/resq-system
```

### 2. Run Verification Test Suite (100% Passing)
```bash
python tools/run_verification.py
```

### 3. Run Live Interactive 5-Screen System & Simulator
```bash
node server.js
```
- Open on laptop: `http://localhost:3000/`
- Open on phone (Wi-Fi): `http://172.34.12.124:3000/`

---

## Offline Readiness & Language Packs
Before deploying into an area without cellular or internet connectivity:
1. Open the **Settings** screen in ResQ.
2. Select your desired language packs (**Telugu**, **Hindi**, **Tamil**, or **Kannada**).
3. Tap **Download**. Google ML Kit will download and cache the native on-device translation model weights.
4. Once downloaded, complete translation operates with **zero internet connection**.

---

## Hackathon Handoff & Testing Guides
- [Architecture & Contract Schemas](ARCHITECTURE.md)
- [Two-Phone & Three-Node Physical Testing Protocol](TESTING_GUIDE.md)
- [Two-Minute Demo Presentation Script](DEMO_SCRIPT.md)
