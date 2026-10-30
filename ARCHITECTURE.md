# ResQ System Architecture & Protocol Specification

## 1. Component Ownership Matrix

| Subsystem | Owner | Authoritative Responsibilities |
|---|---|---|
| **Feature 1** | `MeshEngine` | Discovery, approved peer connections, radio transport, framing/reassembly, application-level store-and-forward mesh forwarding, hop accounting, and connectivity observations. |
| **Feature 2** | `ProximityCalculator`, `MeetingPointManager`, `FallDetectionStateMachine` | Group distance, conservative horizontal accuracy uncertainty, meeting-point revisions, local boundary decisions, contact-loss triggers, and motion fall evidence. |
| **Feature 3** | `LocalTranslator`, `LanguageManager`, `ExtractiveSummarizer` | Local language detection, receiver-side translation, language-pack management, and derived extractive summaries without delaying structured SOS. |
| **Feature 4** | `BatteryMonitor`, `RiskZoneEvaluator` | Actual battery state, power policies, local offline circular hazard zones, latched discharge episode alerts, and RED zone safety check triggers. |
| **Feature 5** | `IncidentCoordinator`, `PriorityClassifier`, `DeliveryTracker` | Deterministic priority classification, incident lifecycle state, durable outgoing outbox scheduler, recipient receipts, retries, and optional cloud synchronization. |
| **Shared Infrastructure** | `SessionCoordinator`, `LocationCoordinator`, `SafetyCheckCoordinator`, `LocalDatabase` | Offline session identity, trusted membership, location acquisition, consent, safety-prompt arbitration, and durable persistence. |

---

## 2. Canonical JSON Payloads & Contract Schemas

### 2.1 Canonical Envelope
Carries immutable signed application payloads across multi-hop mesh relays:
```json
{
  "schemaVersion": 1,
  "messageId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "sessionId": "SESSION_1730342400000",
  "originId": "NODE_ALPHA_01",
  "intendedRecipients": ["NODE_BRAVO_02", "NODE_CHARLIE_03"],
  "messageKind": "incident",
  "originalOccurrenceTime": 1730342410000,
  "expiryPolicy": {
    "ttlMillis": 3600000,
    "expiresAtMs": 1730346010000
  },
  "signedPayload": "{\"incidentId\":\"INC-101\",\"incidentRevision\":1,\"type\":\"CONFIRMED_SOS\",\"severity\":0}",
  "signature": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "hopCount": 1,
  "maxHops": 5,
  "relayPath": ["NODE_ALPHA_01", "NODE_BRAVO_02"]
}
```

### 2.2 Location Update
Carried within payload for periodic proximity tracking:
```json
{
  "senderTrackingRunId": "RUN_902",
  "sequenceNumber": 142,
  "latitude": 16.50621,
  "longitude": 80.64805,
  "accuracyMeters": 12.5,
  "recordedAt": 1730342420000,
  "fixAgeMillisAtSend": 450,
  "speed": 1.2,
  "bearing": 182.4
}
```

### 2.3 Meeting Point Update (with Tombstone Removal)
```json
{
  "pointId": "POINT_CAMP_ALPHA",
  "sessionRevision": 3,
  "action": "remove",
  "creatorId": "NODE_LEADER_01",
  "updatedBy": "NODE_LEADER_01",
  "createdAt": 1730338000000,
  "updatedAt": 1730342500000
}
```

### 2.4 Incident Snapshot
```json
{
  "incidentId": "INC_FALL_8829",
  "incidentRevision": 1,
  "sourceModule": "FallDetectionStateMachine",
  "sourceUserId": "NODE_ALPHA_01",
  "relatedUserId": null,
  "type": "POSSIBLE_FALL",
  "status": "active",
  "severity": 1,
  "confirmationStatus": "unconfirmed",
  "occurredAt": 1730342510000,
  "updatedAt": 1730342510000,
  "explicitSos": false,
  "locationContext": {
    "latitude": 16.5071,
    "longitude": 80.6492,
    "accuracyMeters": 14.0,
    "recordedAt": 1730342505000,
    "isHistorical": false
  },
  "batteryContext": 42.0,
  "zoneContext": "Clear"
}
```

### 2.5 Exact Revision Receipt
```json
{
  "schemaVersion": 1,
  "messageId": "REC_9921_CHARLIE",
  "sessionId": "SESSION_1730342400000",
  "referencedId": "INC_FALL_8829",
  "exactRevision": 1,
  "memberId": "NODE_CHARLIE_03",
  "receiptType": "stored",
  "receiptTime": 1730342515000
}
```

---

## 3. State Machines & Transition Models

### 3.1 Experimental Fall Detection State Machine
```
   [MONITORING]
        │
        │ Free-fall (< 0.5 G)
        ▼
   [FREE FALL DETECTED]
        │
        │ Sharp Impact (> 2.5 G within 1000ms)
        ▼
   [IMPACT DETECTED]
        │
        │ Low Movement (|totalG - 1G| < 0.25G)
        ▼
   [POST-IMPACT STILLNESS]
        │
        │ Sustained stillness >= 2500ms
        ▼
   [FALL TRIGGERED]
        │
        ├─ Submit POSSIBLE_FALL / UNCONFIRMED (Rev 1)
        ├─ Local Prompt: "Possible fall detected. Are you okay?" (30s)
        │
        ├─► User taps "I AM SAFE" ────► Publish Rev 2: USER_CONFIRMED_SAFE
        ├─► User taps "NEED HELP" ────► Publish Rev 2: CONFIRMED_SOS (P0)
        └─► Countdown Expires ────────► Publish Rev 2: NO_RESPONSE (UNCONFIRMED)
```

### 3.2 Battery Threshold Latches & Power Bands
```
 b > 30%        : NORMAL (GPS 10s interval, mesh duty cycle 15s)
 15% <= b <= 30%: POWER_OPTIMIZATION
 10% <= b < 15% : LOW_POWER_PREPARATION
 5% <= b < 10%  : LOW_POWER_ALERT (Latched once per discharge episode)
 b < 5%         : CRITICAL_POWER (Distinct incident emitted)
 
 Reset Condition: Charging brings battery >= 20% (Hysteresis latch reset)
 Mandatory Red Zone Trigger: If b < 10% inside verified RED Hazard Zone -> Shared Safety Check
```

---

## 4. Platform Support Matrix

| Capability | Android Implementation | iOS Status & Adaptation |
|---|---|---|
| **BLE Radio Transport** | Native Bluetooth Low Energy GATT (`flutter_blue_plus`) | Supported via CoreBluetooth; background scan limits apply. |
| **High-Bandwidth P2P** | Google Play Services Nearby Connections | Apple Multipeer Connectivity (Note: Apple MPC does not interoperate with Android Nearby). |
| **On-Device Translation** | Google ML Kit Native (`google_mlkit_translation`) | Supported via ML Kit iOS pod. Pre-download required. |
| **Sensors & Fall State** | Android Accelerometer/Gyro (`sensors_plus`) | Supported via CoreMotion framework. |
| **Background Continuity**| `ResQForegroundService` with notification | Background Tasks Framework (`BGAppRefreshTask`); OS limits CPU dwell. |
