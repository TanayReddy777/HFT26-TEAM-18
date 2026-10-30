# ResQ — 2-Minute Hackathon Demo Script

**Total Duration**: 120 Seconds  
**Format**: Live Multi-Phone Walkthrough & Simulation

---

### [00:00 - 00:20] The Problem & Offline Reality
- **Visual**: Two phones held up, both in **Airplane Mode** (Cellular Data OFF, Wi-Fi OFF, Bluetooth ON).
- **Pitch**:
  > *"In earthquakes, floods, mountain expeditions, or remote terrain, cellular networks and the cloud are the first things to collapse. Yet, rescue operations cannot wait for internet access.*  
  > *Meet **ResQ**: a zero-cloud, decentralized emergency messaging and safety mesh system that operates on standard mobile phones using peer-to-peer radio."*

---

### [00:20 - 00:45] Feature 1 & 5: Mesh Store-and-Forward & P0 SOS
- **Visual**: Phone A triggers the prominent red **EMERGENCY SOS** button.
- **Pitch**:
  > *"When an emergency occurs, Phone A signs and persists an immutable P0 packet locally. Even though Phone A has no direct radio connection to Phone C, Phone B automatically acts as a store-and-forward mesh relay.*  
  > *Phone C receives the alert with zero manual acceptance buttons, validates the cryptographic signature, and issues an exact-revision receipt back to Phone A. We have full delivery confirmation with zero internet."*

---

### [00:45 - 01:10] Feature 2: Proximity, Uncertainty & Fall Detection
- **Visual**: Show Group Screen with peer distance and uncertainty (`70m ±15m`), followed by a simulated fall impact.
- **Pitch**:
  > *"ResQ doesn't just guess GPS coordinates. We calculate conservative horizontal accuracy intervals—if GPS uncertainty crosses our 50m warning limit, we report 'Distance Uncertain' rather than false confidence.*  
  > *Furthermore, our 3-phase fall detection state machine monitors free-fall, sharp impact, and post-impact stillness. When triggered, it publishes Revision 1 'Awaiting Confirmation' while asking the user locally if they are safe. When the user taps 'I AM SAFE', Revision 2 updates all peers and cancels the alert."*

---

### [01:10 - 01:35] Feature 3 & 4: On-Device NLP & RED Zone Battery Latches
- **Visual**: Show incoming Telugu emergency message translating locally into English, followed by battery indicator showing 9% in RED zone.
- **Pitch**:
  > *"Language barriers can be fatal during rescue. ResQ embeds Google ML Kit on-device translation for English, Telugu, Hindi, Tamil, and Kannada. Original text is preserved permanently, with rule-based extractive summaries that guarantee critical numbers, injuries, and negation words like 'not' are never lost.*  
  > *On the power side, battery discharge is divided into non-overlapping bands. Crossing 10% inside a circular RED hazard zone triggers a mandatory safety check, escalating to confirmed SOS if unanswered."*

---

### [01:35 - 02:00] Verification & Summary
- **Visual**: Show terminal output of `tools/run_verification.py` with 100% checks passing.
- **Pitch**:
  > *"ResQ is not a mockup or a web demo. It is a complete, architecturally sound system with a 100% passing verification harness covering multi-hop mesh routing, mathematical Haversine uncertainty, state machines, and cryptographic integrity.*  
  > *ResQ is offline safety, engineered for when it matters most. Thank you!"*
