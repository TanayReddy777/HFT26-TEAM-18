// ResQ Offline Emergency Messaging & Safety System - Live Interactive Engine

let currentTab = 'home';
let isMultiNodeExpanded = false;
let batteryLevel = 82;
let batteryBand = 'NORMAL';
let gpsAccuracy = 12;
let countdownTimer = null;
let remainingCountdown = 30;

// In-Memory Database
const incidents = [
  {
    id: 'INC-BOOT-01',
    rev: 1,
    type: 'MESH_NETWORK_ONLINE',
    severity: 'P3_NORMAL',
    origin: 'NODE_ALPHA_01',
    status: 'ACTIVE',
    confirmation: 'CONFIRMED',
    time: '2 mins ago',
    receipts: 2
  }
];

const receipts = [
  {
    refId: 'INC-BOOT-01',
    rev: 1,
    node: 'NODE_BRAVO_02',
    type: 'STORED',
    time: '2 mins ago',
    status: 'VERIFIED'
  },
  {
    refId: 'INC-BOOT-01',
    rev: 1,
    node: 'NODE_CHARLIE_03',
    type: 'STORED',
    time: '1 min ago',
    status: 'VERIFIED'
  }
];

// Dictionary of emergency sentences across languages for real-time translation demo
const translations = {
  en: {
    bridge: "The bridge has collapsed and three people are trapped. There is no water or food. We are requesting immediate help.",
    fall: "Possible fall impact detected by motion sensors. Awaiting peer safety check-in.",
    sos: "P0 Critical SOS: Life-threatening emergency reported. Immediate rescue requested.",
    safe: "User explicitly confirmed they are safe. Obsolete hazard warning resolved."
  },
  te: {
    bridge: "వంతెన కూలిపోయింది మరియు ముగ్గురు వ్యక్తులు చిక్కుకున్నారు. నీరు మరియు ఆహారం లేదు. మేము వెంటనే సహాయం కోరుతున్నాము.",
    fall: "కదలిక సెన్సార్ల ద్వారా సంభావ్య పతనం గుర్తించబడింది. వినియోగదారు నిర్ధారణ కోసం వేచి ఉంది.",
    sos: "P0 అత్యవసర హెచ్చరిక: ప్రాణాంతక పరిస్థితి నివేదించబడింది. తక్షణ సహాయం అవసరం.",
    safe: "వినియోగదారు తాము సురక్షితంగా ఉన్నామని స్పష్టంగా ధృవీకరించారు."
  },
  hi: {
    bridge: "पुल गिर गया है और तीन लोग फंसे हुए हैं। पानी या खाना नहीं है। हम तत्काल मदद का अनुरोध कर रहे हैं।",
    fall: "मोशन सेंसर द्वारा संभावित गिरावट का पता चला। सुरक्षा पुष्टि की प्रतीक्षा है।",
    sos: "P0 गंभीर आपातकाल: जानलेवा खतरे की सूचना। तत्काल बचाव का अनुरोध।",
    safe: "उपयोगकर्ता ने स्पष्ट रूप से पुष्टि की कि वे सुरक्षित हैं।"
  },
  ta: {
    bridge: "பாலம் இடிந்து விழுந்து மூன்று பேர் சிக்கியுள்ளனர். தண்ணீரோ உணவோ இல்லை. அவசர உதவியை கோருகிறோம்.",
    fall: "இயக்க உணரிகளால் வீழ்ச்சி கண்டறியப்பட்டது. பயனர் உறுதிப்படுத்தலுக்காக காத்திருக்கிறது.",
    sos: "P0 தீவிர அவசரநிலை: உயிருக்கு ஆபத்தான நிலை. உடனடி மீட்பு தேவை.",
    safe: "பயனர் தாங்கள் பாதுகாப்பாக இருப்பதாக உறுதிப்படுத்தியுள்ளனர்."
  },
  kn: {
    bridge: "ಸೇತುವೆ ಕುಸಿದು ಬಿದ್ದಿದ್ದು ಮೂವರು ಸಿಲುಕಿಕೊಂಡಿದ್ದಾರೆ. ನೀರು ಅಥವಾ ಆಹಾರವಿಲ್ಲ. ನಾವು ತಕ್ಷಣದ ಸಹಾಯವನ್ನು ಕೋರುತ್ತಿದ್ದೇವೆ.",
    fall: "ಚಲನೆಯ ಸಂವೇದಕಗಳಿಂದ ಸಂಭವನೀಯ ಕುಸಿತ ಪತ್ತೆಯಾಗಿದೆ.",
    sos: "P0 ತುರ್ತು ಎಚ್ಚರಿಕೆ: ಜೀವಕ್ಕೆ ಅಪಾಯದ ವರದಿ. ತಕ್ಷಣದ ರಕ್ಷಣೆ ಅಗತ್ಯವಿದೆ.",
    safe: "ಬಳಕೆದಾರರು ತಾವು ಸುರಕ್ಷಿತವಾಗಿದ್ದಾರೆ ಎಂದು ದೃಢಪಡಿಸಿದ್ದಾರೆ."
  }
};

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
  renderIncidents();
  renderReceipts();
  logSim('ResQ Offline Mesh Engine v1.0.0 ready.');
  logSim('BLE GATT & Nearby Cluster transport listening on channel BLE-01.');
});

function logSim(msg) {
  const simLog = document.getElementById('sim-log');
  const now = new Date().toTimeString().split(' ')[0];
  simLog.innerHTML = `[${now}] ${msg}<br>` + simLog.innerHTML;
}

function clearSimLog() {
  document.getElementById('sim-log').innerHTML = '';
}

// ==========================================
// Tab Switching
// ==========================================
function switchTab(tabName) {
  currentTab = tabName;
  const screens = ['home', 'group', 'chat', 'incidents', 'settings', 'simulation'];
  
  screens.forEach(s => {
    const el = document.getElementById(`screen-${s}`);
    const btn = document.getElementById(`tab-btn-${s === 'simulation' ? 'sim' : s}`);
    if (el) el.style.display = (s === tabName) ? 'flex' : 'none';
    if (btn) {
      if (s === tabName) btn.classList.add('active');
      else btn.classList.remove('active');
    }
  });

  if (tabName === 'incidents') {
    renderIncidents();
  }
}

// ==========================================
// 3-Node Multi-Hop Mesh Simulation & Animation
// ==========================================
function triggerGlobalSos() {
  const incId = 'INC-SOS-' + Math.floor(Math.random() * 900 + 100);
  const newInc = {
    id: incId,
    rev: 1,
    type: 'CONFIRMED_SOS',
    severity: 'P0_CRITICAL',
    origin: 'NODE_ALPHA_01',
    status: 'ACTIVE',
    confirmation: 'CONFIRMED_HELP',
    time: 'Just now',
    receipts: 0
  };

  incidents.unshift(newInc);
  renderIncidents();

  // Show banner
  const banner = document.getElementById('global-emergency-banner');
  banner.style.display = 'flex';
  document.getElementById('banner-title').innerText = 'P0 CRITICAL SOS BROADCASTED';
  document.getElementById('banner-desc').innerText = `Node A triggered emergency (${incId}). Stored locally and forwarded to Node B.`;

  logSim(`[P0 SOS] Stored atomically in Outbox with MessageId: ${incId}`);
  animatePacketFlow(incId);
}

function triggerNodeASos() {
  triggerGlobalSos();
}

function animatePacketFlow(messageId) {
  logSim(`Node A: Transmitting to Node B via BLE GATT (Hop 0 -> 1)...`);
  
  // Highlight Node A
  const boxA = document.getElementById('node-box-a');
  const boxB = document.getElementById('node-box-b');
  const boxC = document.getElementById('node-box-c');
  const pAB = document.getElementById('packet-ab');
  const pBC = document.getElementById('packet-bc');

  boxA.classList.add('active');

  // Step 1: Fly packet from A to B
  pAB.style.opacity = '1';
  pAB.style.left = '0%';
  pAB.style.transition = 'left 1s cubic-bezier(0.4, 0, 0.2, 1)';
  
  setTimeout(() => {
    pAB.style.left = '90%';
  }, 50);

  setTimeout(() => {
    pAB.style.opacity = '0';
    boxA.classList.remove('active');
    boxB.classList.add('active');
    logSim(`Node B: Received and verified HMAC-SHA256 signature for ${messageId}. Relaying to Node C (Hop 1 -> 2)...`);

    // Step 2: Fly packet from B to C
    pBC.style.opacity = '1';
    pBC.style.left = '0%';
    pBC.style.transition = 'left 1s cubic-bezier(0.4, 0, 0.2, 1)';
    
    setTimeout(() => {
      pBC.style.left = '90%';
    }, 50);

    setTimeout(() => {
      pBC.style.opacity = '0';
      boxB.classList.remove('active');
      boxC.classList.add('active');
      logSim(`Node C: STORED incident ${messageId}. Issuing exact-revision Receipt (STORED Rev 1) reverse path C -> B -> A.`);
      document.getElementById('node-c-receipt').innerText = 'STORED (Rev 1)';

      // Record receipts
      receipts.unshift({
        refId: messageId,
        rev: 1,
        node: 'NODE_CHARLIE_03',
        type: 'STORED',
        time: 'Just now',
        status: 'VERIFIED'
      });
      receipts.unshift({
        refId: messageId,
        rev: 1,
        node: 'NODE_BRAVO_02',
        type: 'STORED',
        time: 'Just now',
        status: 'VERIFIED'
      });

      renderReceipts();
      updatePacketInspector(messageId, 2);

      setTimeout(() => {
        boxC.classList.remove('active');
        logSim(`Node A: EXACT RECEIPT loop completed for ${messageId}! (2 of 2 members confirmed).`);
      }, 1000);

    }, 1100);

  }, 1100);
}

function updatePacketInspector(msgId, hopCount) {
  const jsonViewer = document.getElementById('packet-json-viewer');
  const envelope = {
    schemaVersion: 1,
    messageId: msgId,
    sessionId: "SESSION_1730342400000",
    originId: "NODE_ALPHA_01",
    intendedRecipients: ["NODE_CHARLIE_03"],
    messageKind: "incident",
    originalOccurrenceTime: Date.now(),
    expiryPolicy: { ttlMillis: 3600000, expiresAtMs: Date.now() + 3600000 },
    signedPayload: JSON.stringify({ incidentId: msgId, type: "CONFIRMED_SOS", severity: 0 }),
    signature: "hmac_sha256_e9a8f4c2_ok",
    hopCount: hopCount,
    maxHops: 5,
    relayPath: ["NODE_ALPHA_01", "NODE_BRAVO_02", "NODE_CHARLIE_03"]
  };
  jsonViewer.innerText = JSON.stringify(envelope, null, 2);
}

// ==========================================
// Incident Lifecycle & Receipts
// ==========================================
function renderIncidents() {
  const container = document.getElementById('incidents-container');
  if (!container) return;

  const countBadge = document.getElementById('incident-count');
  countBadge.innerText = incidents.length;

  container.innerHTML = incidents.map(inc => {
    const isP0 = inc.severity.includes('P0');
    return `
      <div class="card glass-card" style="border-left: 4px solid ${isP0 ? 'var(--color-sos)' : 'var(--color-warn)'};">
        <div class="card-header">
          <div style="display:flex; align-items:center; gap:8px;">
            <span class="badge-mesh" style="background:${isP0 ? 'rgba(239,68,68,0.2)' : 'rgba(249,115,22,0.2)'}; color:${isP0 ? 'var(--color-sos)' : 'var(--color-warn)'}">${inc.severity}</span>
            <strong style="font-size:14px;">${inc.type}</strong>
          </div>
          <span class="badge-mesh">Revision ${inc.rev}</span>
        </div>
        <div class="card-body">
          <div class="meta-row">
            <span class="meta-label">Incident ID:</span>
            <span class="meta-val font-mono">${inc.id}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Origin:</span>
            <span class="meta-val">${inc.origin}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Confirmation:</span>
            <span class="meta-val" style="color:var(--color-safe)">${inc.confirmation}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Receipts:</span>
            <span class="meta-val" style="color:var(--color-mesh)">Confirmed by 2 of 2 peers</span>
          </div>
        </div>
        <div class="action-buttons-row" style="margin-top:10px;">
          <button class="btn btn-sm btn-safe" onclick="resolveIncident('${inc.id}')">MARK RESOLVED</button>
          <button class="btn btn-sm btn-outline" onclick="volunteerForIncident('${inc.id}')">VOLUNTEER HELP</button>
        </div>
      </div>
    `;
  }).join('');
}

function renderReceipts() {
  const tbody = document.getElementById('receipt-tbody');
  if (!tbody) return;

  tbody.innerHTML = receipts.map(r => `
    <tr>
      <td>${r.refId}</td>
      <td>${r.rev}</td>
      <td>${r.node}</td>
      <td>${r.type}</td>
      <td>${r.time}</td>
      <td><span class="badge-safe">${r.status}</span></td>
    </tr>
  `).join('');
}

function resolveIncident(id) {
  const inc = incidents.find(i => i.id === id);
  if (inc) {
    inc.rev += 1;
    inc.type = 'INCIDENT_RESOLVED';
    inc.confirmation = 'USER_CONFIRMED_SAFE';
    renderIncidents();
    logSim(`Incident ${id} updated to Revision ${inc.rev}: RESOLVED. Obsolete warnings dismissed.`);
  }
}

function volunteerForIncident(id) {
  logSim(`User volunteered help for incident ${id}. Stored and emitted receipt.`);
  alert(`Help volunteered for ${id}. Notification relayed to peers.`);
}

// ==========================================
// Fall Detection State Machine Simulation
// ==========================================
function simFallTrigger() {
  logSim(`[Sensors] Free-fall (<0.5G) detected at t=0ms...`);
  setTimeout(() => {
    logSim(`[Sensors] Sharp impact (3.4G) detected at t=210ms...`);
    setTimeout(() => {
      logSim(`[Sensors] Sustained stillness (|totalG-1G| < 0.25G) confirmed for 2.5s.`);
      
      // Emit Revision 1
      const fallId = 'INC-FALL-' + Math.floor(Math.random() * 900 + 100);
      incidents.unshift({
        id: fallId,
        rev: 1,
        type: 'POSSIBLE_FALL',
        severity: 'P1_URGENT',
        origin: 'NODE_ALPHA_01',
        status: 'ACTIVE',
        confirmation: 'AWAITING_CONFIRMATION',
        time: 'Just now',
        receipts: 1
      });
      renderIncidents();

      // Launch Safety Check Dialog
      openSafetyModal(
        'Possible Fall Detected',
        'Accelerometers detected sudden impact and stillness. Are you okay?',
        fallId
      );
    }, 1000);
  }, 300);
}

function openSafetyModal(title, desc, incidentId) {
  const modal = document.getElementById('safety-modal');
  document.getElementById('modal-title').innerText = title;
  document.getElementById('modal-desc').innerText = desc;
  modal.style.display = 'flex';

  remainingCountdown = 30;
  const bar = document.getElementById('countdown-progress');
  const txt = document.getElementById('countdown-text');

  clearInterval(countdownTimer);
  countdownTimer = setInterval(() => {
    remainingCountdown--;
    const pct = (remainingCountdown / 30) * 100;
    bar.style.width = pct + '%';
    txt.innerText = `${remainingCountdown} seconds remaining`;

    if (remainingCountdown <= 0) {
      clearInterval(countdownTimer);
      handleModalResponse('timeout', incidentId);
    }
  }, 1000);
}

function handleModalResponse(resp, incId) {
  clearInterval(countdownTimer);
  document.getElementById('safety-modal').style.display = 'none';

  if (resp === 'safe') {
    logSim(`User responded "I AM SAFE". Emitting Revision 2: USER_CONFIRMED_SAFE.`);
    confirmSafety();
  } else if (resp === 'help') {
    logSim(`User tapped "NEED HELP". Escalating immediately to P0 CONFIRMED_SOS!`);
    triggerGlobalSos();
  } else if (resp === 'timeout') {
    logSim(`Safety check timed out without user response. Emitted Revision 2: NO_RESPONSE (UNCONFIRMED).`);
    triggerGlobalSos();
  } else if (resp === 'snooze') {
    logSim(`Safety check snoozed for 5 minutes. Pending status preserved.`);
    alert('Check snoozed for 5 minutes. Check remains pending.');
  }
}

function confirmSafety() {
  document.getElementById('global-emergency-banner').style.display = 'none';
  if (incidents.length > 0) {
    incidents[0].rev += 1;
    incidents[0].type = 'USER_CONFIRMED_SAFE';
    incidents[0].confirmation = 'SAFE';
    renderIncidents();
  }
  logSim(`Confirmed Safe broadcasted across mesh. Alert cancelled.`);
}

function dismissBanner() {
  document.getElementById('global-emergency-banner').style.display = 'none';
}

function acknowledgeTopIncident() {
  logSim(`Exact-revision receipt recorded for top incident.`);
  alert('Receipt STORED and acknowledged back to sender.');
}

// ==========================================
// Battery & RED Zone Testing
// ==========================================
function simBatteryDrop(level) {
  batteryLevel = level;
  document.getElementById('nav-battery-val').innerText = `${level}%`;

  const badge = document.getElementById('nav-battery-band');
  if (level > 30) {
    batteryBand = 'NORMAL';
    badge.style.color = 'var(--color-safe)';
  } else if (level >= 15) {
    batteryBand = 'POWER_OPTIMIZATION';
    badge.style.color = 'var(--color-warn)';
  } else if (level >= 10) {
    batteryBand = 'LOW_POWER_PREP';
    badge.style.color = 'var(--color-warn)';
  } else if (level >= 5) {
    batteryBand = 'LOW_POWER_ALERT';
    badge.style.color = 'var(--color-sos)';
  } else {
    batteryBand = 'CRITICAL_POWER';
    badge.style.color = 'var(--color-sos)';
  }
  badge.innerText = batteryBand;

  logSim(`Battery updated to ${level}% (Band: ${batteryBand}).`);

  if (level === 9) {
    logSim(`[Episode Latch] Battery crossed <10% inside active RED hazard zone!`);
    openSafetyModal(
      'Low Battery in RED Hazard Zone',
      'Battery is at 9% within Krishna Riverbed Flood Zone. Are you safe?'
    );
  } else if (level === 4) {
    logSim(`[Episode Latch] Battery crossed <5% Critical. Emitted CRITICAL_LOW_POWER incident.`);
  }
}

// ==========================================
// Separation & Proximity Simulation
// ==========================================
function simSeparation(meters) {
  const bStatus = document.getElementById('peer-b-status');
  const blipB = document.getElementById('blip-b');

  if (meters === 20) {
    bStatus.innerText = 'Distance: 20m (±6m) • WITHIN_CONFIGURED_RANGE';
    bStatus.parentElement.parentElement.querySelector('.peer-state').className = 'peer-state state-safe';
    bStatus.parentElement.parentElement.querySelector('.peer-state').innerText = 'SAFE';
    blipB.style.transform = 'translate(15px, -10px)';
    logSim(`Peer distance: 20m. State: WITHIN_CONFIGURED_RANGE.`);
  } else if (meters === 70) {
    bStatus.innerText = 'Distance: 70m (±12m) • SEPARATION_WARNING';
    bStatus.parentElement.parentElement.querySelector('.peer-state').className = 'peer-state';
    bStatus.parentElement.parentElement.querySelector('.peer-state').style.background = 'rgba(249,115,22,0.2)';
    bStatus.parentElement.parentElement.querySelector('.peer-state').style.color = 'var(--color-warn)';
    bStatus.parentElement.parentElement.querySelector('.peer-state').innerText = 'WARNING DISTANCE';
    blipB.style.transform = 'translate(45px, -30px)';
    logSim(`Peer distance: 70m. State: SEPARATION_WARNING.`);
  } else if (meters === 120) {
    bStatus.innerText = 'Distance: 120m (±16m) • SEPARATION_CRITICAL';
    bStatus.parentElement.parentElement.querySelector('.peer-state').className = 'peer-state state-crit';
    bStatus.parentElement.parentElement.querySelector('.peer-state').innerText = 'CRITICAL SEPARATION';
    blipB.style.transform = 'translate(80px, -50px)';
    logSim(`Peer distance: 120m. State: SEPARATION_CRITICAL (>100m threshold)!`);
  }
}

function simDegradedGps() {
  document.getElementById('nav-gps-val').innerText = 'Fix: ±85m';
  logSim(`GPS fix accuracy degraded to ±85m. Conservative uncertainty heuristic active: DISTANCE_UNCERTAIN.`);
  alert('GPS accuracy degraded to ±85m. Proximity calculator reports: DISTANCE_UNCERTAIN (No false confidence).');
}

function simThreeNodeRelay() {
  triggerGlobalSos();
}

// ==========================================
// Offline Chat & Multilingual Translation
// ==========================================
function changePreferredLanguage() {
  const lang = document.getElementById('lang-select').value;
  const transBox = document.querySelector('.translation-box');
  const transText = document.querySelector('.trans-text');
  const transHeader = document.querySelector('.trans-header span');

  if (lang === 'te') {
    transBox.style.display = 'none'; // Same language as source
  } else {
    transBox.style.display = 'block';
    transHeader.innerText = `ML Kit Local Translation (${lang.toUpperCase()}):`;
    transText.innerText = translations[lang]?.bridge || translations.en.bridge;
  }

  logSim(`Receiver preferred language switched to: ${lang.toUpperCase()}`);
}

function sendChatMessage() {
  const input = document.getElementById('chat-input');
  const text = input.value.trim();
  if (!text) return;

  const container = document.getElementById('chat-messages-container');
  const bubble = document.createElement('div');
  bubble.className = 'chat-bubble';
  bubble.style.alignSelf = 'flex-end';
  bubble.style.background = 'rgba(6, 182, 212, 0.15)';
  bubble.style.borderColor = 'rgba(6, 182, 212, 0.4)';

  bubble.innerHTML = `
    <div class="bubble-header">
      <span class="bubble-sender" style="color:var(--color-mesh)">You (Node A)</span>
      <span class="bubble-tag">Lang: Auto-Detect</span>
    </div>
    <div class="bubble-text">${text}</div>
    <div style="font-size:9px; color:var(--color-text-sub); margin-top:4px; text-align:right;">✓ Relayed via Mesh</div>
  `;

  container.appendChild(bubble);
  container.scrollTop = container.scrollHeight;
  input.value = '';

  logSim(`Message sent: "${text}". Framed and broadcasted across mesh outbox.`);
}

function handleChatKey(e) {
  if (e.key === 'Enter') sendChatMessage();
}

function toggleSummary(el) {
  const content = el.querySelector('.summary-content');
  content.style.display = content.style.display === 'none' ? 'inline' : 'none';
}

function toggleMultiNodeView() {
  const studio = document.getElementById('multi-node-studio');
  studio.scrollIntoView({ behavior: 'smooth' });
}

function updateWarningDist(val) {
  document.getElementById('lbl-warn').innerText = `${val}m`;
}
function updateCritDist(val) {
  document.getElementById('lbl-crit').innerText = `${val}m`;
}

function showQrModal() {
  alert('QR Trust Enrollment Code: RESQ-MESH://join?sid=SESSION_1730342400000&pk=pk_alpha_99182\n\nAuthorized peers scan this QR code to establish cryptographic session trust without internet.');
}

function endSession() {
  if (confirm('Are you sure you want to end this offline session? Unresolved emergency incidents will be safely preserved in local storage.')) {
    logSim('Session ended. Radio tracking stopped. Unresolved outbox records preserved.');
    alert('Session closed safely.');
  }
}

function openNewMeetingPointModal() {
  const name = prompt('Enter Meeting Point Name:', 'Rendezvous Point Bravo');
  if (name) {
    document.getElementById('mp-guidance-title').innerText = name;
    document.getElementById('home-mp-status').innerText = `${name} • 140m NE`;
    logSim(`Leader updated Meeting Point to "${name}" (Revision 4). Broadcasted to peers.`);
    alert(`Meeting Point "${name}" published to group!`);
  }
}
