# ResQ Physical Device & Multi-Node Testing Protocol

This document provides exact, step-by-step procedures for evaluating ResQ under strict physical conditions without internet access.

---

## 1. Two-Phone Direct Testing Protocol

### Objective
Verify direct peer discovery, enrollment, encrypted communication, location sharing, and receipt generation.

### Setup
1. **Phones**: 2 Android smartphones (Phone A and Phone B).
2. **Network Isolation**:
   - Turn **OFF Mobile Data** on both phones.
   - Turn **OFF Wi-Fi** on both phones (or keep enabled only for Nearby High-Bandwidth mode).
   - Turn **ON Bluetooth** and **Location Services** (GPS).
   - Ensure Airplane mode is enabled with Bluetooth toggled back on to guarantee zero internet.

### Procedure
1. **Enrollment**:
   - Open ResQ on Phone A $\rightarrow$ Tap **Create Session** ("Captain Alpha").
   - Open ResQ on Phone B $\rightarrow$ Tap **Join Session** $\rightarrow$ Scan Phone A's QR Code or enter the shared session secret.
   - Verify Phone B appears in Phone A's **Group Screen** as an authorized peer.
2. **Offline Chat & Translation**:
   - On Phone A, set preferred language to Telugu (`te`).
   - On Phone B, send a message in English: `"We need medical assistance at the river."`
   - Observe Phone A: The message appears **immediately** in English. Phone A's local ML Kit translates the message into Telugu beneath the original text.
3. **Manual SOS Trigger**:
   - On Phone A, tap the prominent red **EMERGENCY SOS** button on the Home surface.
   - Observe Phone B: Phone B receives the P0 SOS alert **without requiring any per-message Accept button**.
   - Check Phone A's Incidents tab: Phone B is marked **Delivered & Stored (Exact Receipt recorded)**.

---

## 2. Three-Phone Multi-Hop Relay Protocol (A $\rightarrow$ B $\rightarrow$ C)

### Objective
Verify application-level store-and-forward relay through an intermediary node (Phone B) when no direct radio link exists between Phone A and Phone C.

```
[ Phone A ] <─── BLE Radio ───> [ Phone B (Relay) ] <─── BLE Radio ───> [ Phone C ]
     │                                                                       ▲
     └──────────────── No Direct Radio Connection ───────────────────────────┘
```

### Physical Setup
- Place **Phone B** in the center (e.g. hallway or intermediate room).
- Place **Phone A** and **Phone C** at opposite ends, separated by sufficient distance or physical obstacles so they **cannot** see or ping each other directly.
- Verify Phone A and Phone C have no direct connection in their respective peer lists.

### Procedure
1. Phone A initiates an emergency P0 SOS:
   - Phone A creates and signs the immutable payload (`hopCount = 0`).
   - Outbox scheduler submits the envelope to Phone B.
2. Phone B processes the relay:
   - Phone B validates the signature and deduplication cache.
   - Phone B automatically forwards the envelope to Phone C (`hopCount = 1`, `relayPath = [Phone A, Phone B]`).
3. Phone C receives and acknowledges:
   - Phone C stores the emergency incident.
   - Phone C automatically generates an exact-revision `Receipt` (Type: `STORED`, Rev 1) addressed to Phone A.
   - Phone C sends the receipt back to Phone B.
4. Phone B relays receipt back to Phone A:
   - Phone A receives Phone C's exact receipt.
   - Phone A updates its delivery counter: `"Revision 1 acknowledged by 2 of 2 members (Phone B, Phone C)"`.
   - **Full loop completed without direct A-C connectivity!**

---

## 3. Experimental Fall Detection Testing

> **Safety Warning**: Never put a human at physical risk to test fall detection. Use a cushioned drop or the simulated trigger.

### Soft Impact Test
1. Hold Phone A in hand at chest height over a soft mattress or cushion.
2. Drop the phone onto the soft surface from ~1 meter.
3. Keep the phone completely still on the cushion for 3 seconds.
4. Observe Phone A:
   - Phone A detects Free-fall (<0.5G) $\rightarrow$ Impact (>2.5G) $\rightarrow$ Stillness (2.5s).
   - Phone A launches the **Safety Check Dialog**: `"Possible fall detected. Are you okay? (30s remaining)"`.
   - Reachable peers (Phone B) immediately display: `"Possible fall detected for [User]. Awaiting confirmation."` (Rev 1).
5. Tap **"I AM SAFE"** on Phone A:
   - Phone A updates the incident to Revision 2 (`USER_CONFIRMED_SAFE`).
   - Phone B updates its display: `"[User] confirmed they are safe"` and dismisses the urgent warning.

---

## 4. Battery Threshold & RED Hazard Zone Testing

1. In the **Settings** screen, observe the loaded risk zones (e.g., `"Krishna Riverbed Flashflood Zone"` [RED]).
2. In **Demo Mode**, inject simulated battery discharge:
   - Set battery to **9%**.
   - Discharge episode latch activates: `LOW_POWER_ALERT` is persisted and broadcasted once.
   - Because the simulated position is inside the RED hazard zone, a mandatory Safety Check dialog triggers: `"Low battery (9%) within RED hazard zone. Are you safe?"`.
   - Tapping **"NEED HELP"** immediately escalates the incident to `CONFIRMED_SOS` (P0) with exact location coordinates.
