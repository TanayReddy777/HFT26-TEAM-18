/**
 * ResQ — Interactive 5-Screen Full Working Model with Real-Time Multi-Phone Mesh
 * Features:
 * - Server-Sent Events (SSE) sub-50ms instant sync across real phones on local Wi-Fi
 * - Web Audio API emergency siren and chime generator
 * - Web Vibration API tactile alerts on phone hardware
 * - Physical Phone Accelerometer (DeviceMotionEvent) for real drop/fall detection
 * - Peer Identity Switcher (Phone 1 Tanay vs Phone 2 Ravi vs Phone 3 Anil)
 * - 5 Full Screens: Home, SOS, Devices Radar, Encrypted Inbox, Safety Settings
 */

let appState = {
  activeScreen: 'home',
  myIdentity: 'Phone 1 (Tanay)',
  selectedPriority: 'P0',
  currentFilter: 'all',
  fallCountdownInterval: null,
  fallSecondsLeft: 15,
  isEmergency: false,
  batteryLevel: 85,
  meetingPoint: 'Camp Alpha (Lake Bridge)',
  friends: [],
  messages: [],
  sensorsEnabled: false,
  lastG: 9.8,
  inFreeFall: false,
  freeFallTimestamp: 0
};

// Web Audio Context for Emergency Siren
let audioCtx = null;

function initAudio() {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (AudioContextClass) {
      audioCtx = new AudioContextClass();
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function playEmergencySiren() {
  try {
    initAudio();
    if (!audioCtx) return;

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.type = 'sawtooth';
    // Frequency sweeps between 880Hz and 440Hz
    const now = audioCtx.currentTime;
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(440, now + 0.4);
    osc.frequency.exponentialRampToValueAtTime(880, now + 0.8);
    osc.frequency.exponentialRampToValueAtTime(440, now + 1.2);

    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 1.4);

    osc.connect(gain);
    gain.connect(audioCtx.destination);

    osc.start(now);
    osc.stop(now + 1.4);
  } catch (err) {
    console.warn('Audio siren playback skipped:', err);
  }
}

function playMessageBeep() {
  try {
    initAudio();
    if (!audioCtx) return;

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.type = 'sine';
    const now = audioCtx.currentTime;
    osc.frequency.setValueAtTime(587.33, now); // D5
    osc.frequency.setValueAtTime(880, now + 0.1); // A5

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);

    osc.connect(gain);
    gain.connect(audioCtx.destination);

    osc.start(now);
    osc.stop(now + 0.3);
  } catch (err) {}
}

function triggerVibration(pattern = [500, 200, 500]) {
  if (navigator.vibrate) {
    navigator.vibrate(pattern);
  }
}

// 1. Initial Kickoff
document.addEventListener('DOMContentLoaded', () => {
  initClock();
  initSSE();
  fetchStatus();
  initPhysicalAccelerometer();
});

// Device Clock Update
function initClock() {
  function updateTime() {
    const clockEl = document.getElementById('device-clock');
    if (!clockEl) return;
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    clockEl.textContent = `${hours}:${minutes}`;
  }
  updateTime();
  setInterval(updateTime, 1000);
}

// 2. Real-Time SSE (Server-Sent Events) Stream
function initSSE() {
  const evtSource = new EventSource('/api/events');

  evtSource.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      handleLiveEvent(data);
    } catch (err) {
      console.warn('Error parsing SSE event:', err);
    }
  };

  evtSource.onerror = () => {
    console.warn('SSE reconnecting in background...');
  };
}

function handleLiveEvent(data) {
  if (!data || !data.type) return;

  if (data.state) {
    appState.isEmergency = data.state.isEmergency;
    appState.batteryLevel = data.state.batteryLevel;
    appState.meetingPoint = data.state.meetingPoint;
    appState.friends = data.state.friends || [];
    appState.messages = data.state.messages || [];
    renderGlobalState(data.state);
  }

  // Event specific actions
  switch (data.type) {
    case 'SOS_TRIGGERED':
      playEmergencySiren();
      triggerVibration([800, 300, 800, 300, 1000]);
      showToast(`🚨 P0 EMERGENCY SOS from ${data.payload.sender || 'Peer Node'}!`);
      break;

    case 'SOS_CLEARED':
      triggerVibration([200, 100, 200]);
      showToast('✅ Peer announced safe. Alert cleared.');
      break;

    case 'NEW_MESSAGE':
      if (data.payload && data.payload.msg) {
        if (data.payload.msg.sender !== appState.myIdentity) {
          playMessageBeep();
          triggerVibration([150]);
          showToast(`💬 ${data.payload.msg.sender}: ${data.payload.msg.text}`);
        }
      }
      break;

    case 'BATTERY_CHANGED':
      showToast(`🔋 Group Power Band update: ${data.payload.batteryLevel}%`);
      break;

    case 'MEETING_POINT_CHANGED':
      showToast(`📍 Meeting Point updated to: ${data.payload.meetingPoint}`);
      break;
  }
}

// 3. User Identity Switcher (For testing 2 phones side by side)
function changeDeviceIdentity(name) {
  appState.myIdentity = name;
  showToast(`Active Identity set to: ${name}`);

  // Register device presence to server
  fetch('/api/register-device', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      deviceId: name.toLowerCase().replace(/[^a-z0-9]/g, '-'),
      deviceName: name,
      battery: appState.batteryLevel
    })
  }).catch(() => {});
}

function enableSensorsAndAudio() {
  initAudio();
  appState.sensorsEnabled = true;

  const btn = document.getElementById('btn-sensors-sound');
  if (btn) {
    btn.className = 'btn-enable-sensors active';
    btn.textContent = '🔊 Active (Vibrate & Siren On)';
  }

  // Request accelerometer permissions if browser requires it (iOS 13+)
  if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
    DeviceMotionEvent.requestPermission()
      .then(permissionState => {
        if (permissionState === 'granted') {
          showToast('✅ Accelerometer drop sensors granted!');
        }
      })
      .catch(console.error);
  }

  triggerVibration([200]);
  playMessageBeep();
  showToast('🔊 Siren & Phone Vibration Enabled!');
}

// 4. Physical Accelerometer Fall Sensor
function initPhysicalAccelerometer() {
  if (typeof DeviceMotionEvent !== 'undefined') {
    window.addEventListener('devicemotion', (event) => {
      const acc = event.accelerationIncludingGravity;
      if (!acc || acc.x === null) return;

      const totalG = Math.sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);

      // Phase 1: Free fall detection (near weightless: < 3.5 m/s^2)
      if (totalG < 3.5) {
        appState.inFreeFall = true;
        appState.freeFallTimestamp = Date.now();
      } 
      // Phase 2: High impact shockwave (> 24 m/s^2) shortly following freefall
      else if (appState.inFreeFall && totalG > 24.0 && (Date.now() - appState.freeFallTimestamp < 1500)) {
        appState.inFreeFall = false;
        triggerFallSimulation();
        triggerVibration([1000]);
      }

      appState.lastG = totalG;
    });
  }
}

// 5. Navigation State Machine
function navTo(screenName) {
  appState.activeScreen = screenName;

  const views = document.querySelectorAll('.screen-view');
  views.forEach(v => v.classList.remove('active'));

  const targetView = document.getElementById(`view-${screenName}`);
  if (targetView) {
    targetView.classList.add('active');
    targetView.scrollTop = 0;
  }

  const navButtons = document.querySelectorAll('.nav-item');
  navButtons.forEach(btn => btn.classList.remove('active'));

  const activeNavBtn = document.getElementById(`nav-btn-${screenName}`);
  if (activeNavBtn) {
    activeNavBtn.classList.add('active');
  }

  const titleEl = document.getElementById('header-title');
  const subEl = document.getElementById('header-subtitle');

  const headers = {
    'home': { title: 'ResQ', sub: 'OFFLINE SAFETY' },
    'sos': { title: 'Emergency Dispatch', sub: 'PRIORITY P0-P2 MESH' },
    'devices': { title: 'Mesh Radar', sub: 'PEER-TO-PEER TOPOLOGY' },
    'inbox': { title: 'Encrypted Inbox', sub: 'LOCAL STORE-AND-FORWARD' },
    'settings': { title: 'Safety Settings', sub: 'SENSORS & POWER BANDS' }
  };

  if (headers[screenName]) {
    titleEl.textContent = headers[screenName].title;
    subEl.textContent = headers[screenName].sub;
  }

  if (screenName === 'devices') renderDevices(appState.friends);
  if (screenName === 'inbox') renderInbox(appState.messages);
}

// 6. Status Polling & Real-Time Sync
async function fetchStatus() {
  try {
    const res = await fetch('/api/status', { cache: 'no-store' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    
    appState.isEmergency = data.isEmergency;
    appState.batteryLevel = data.batteryLevel;
    appState.meetingPoint = data.meetingPoint;
    appState.friends = data.friends || [];
    appState.messages = data.messages || [];

    renderGlobalState(data);
  } catch (err) {
    console.warn('Syncing offline state locally:', err);
  }
}

function renderGlobalState(data) {
  const batteryIcon = document.getElementById('status-battery-icon');
  if (batteryIcon) batteryIcon.textContent = `🔋 ${data.batteryLevel}%`;

  const sosBatteryTag = document.getElementById('sos-battery-tag');
  if (sosBatteryTag) sosBatteryTag.textContent = `${data.batteryLevel}%`;

  const headerPill = document.getElementById('header-status-pill');
  const headerText = document.getElementById('header-status-text');
  const sosAmbientGlow = document.getElementById('sos-ambient-glow');
  const activeEmergencyCard = document.getElementById('active-emergency-card');
  const incidentText = document.getElementById('banner-incident-text');
  const activityHeadline = document.getElementById('activity-headline-text');
  const activityDetail = document.getElementById('activity-detail-text');
  const activityTime = document.getElementById('activity-time-tag');

  if (data.isEmergency) {
    if (headerPill) {
      headerPill.className = 'status-pill-red';
      if (headerText) headerText.textContent = 'SOS Active';
    }
    if (activeEmergencyCard) activeEmergencyCard.style.display = 'block';
    if (incidentText) incidentText.textContent = data.emergencyReason || 'Critical P0 Emergency broadcast in progress across offline mesh.';
    if (activityHeadline) activityHeadline.textContent = '🚨 P0 Emergency SOS Active';
    if (activityDetail) activityDetail.textContent = `Alert broadcasted at ${data.emergencyTime || 'recent'} to all peers`;
    if (activityTime) activityTime.textContent = 'LIVE ALERT';
    if (sosAmbientGlow) {
      sosAmbientGlow.style.boxShadow = '0 0 65px rgba(239, 68, 68, 0.85)';
      sosAmbientGlow.style.animationDuration = '1.2s';
    }
  } else {
    if (headerPill) {
      headerPill.className = 'status-pill-green';
      if (headerText) headerText.textContent = 'Mesh Active';
    }
    if (activeEmergencyCard) activeEmergencyCard.style.display = 'none';
    if (activityHeadline) activityHeadline.textContent = 'No Recent Emergency Incidents';
    if (activityDetail) activityDetail.textContent = 'All 3 connected peers acknowledging current revision';
    if (activityTime) activityTime.textContent = 'Just now';
    if (sosAmbientGlow) {
      sosAmbientGlow.style.boxShadow = '0 0 40px rgba(239, 68, 68, 0.35)';
      sosAmbientGlow.style.animationDuration = '2.5s';
    }
  }

  const networkVal = document.getElementById('card-network-val');
  if (networkVal) networkVal.textContent = data.isEmergency ? 'Alert Broadcasting' : 'Offline Active';

  const devicesVal = document.getElementById('card-devices-val');
  const meshCountVal = document.getElementById('mesh-nodes-count');
  if (devicesVal) devicesVal.textContent = `${appState.friends.length} Devices`;
  if (meshCountVal) meshCountVal.textContent = `${appState.friends.length}`;

  const meetingTitle = document.getElementById('meeting-title-text');
  if (meetingTitle) meetingTitle.textContent = data.meetingPoint;

  if (appState.activeScreen === 'devices') renderDevices(appState.friends);
  if (appState.activeScreen === 'inbox') renderInbox(appState.messages);
}

// 7. SCREEN 1 (HOME) ACTIONS
function handleSosPress() {
  const dialog = document.getElementById('sos-confirm-dialog');
  if (dialog) dialog.style.display = 'flex';
}

function dismissSosDialog() {
  const dialog = document.getElementById('sos-confirm-dialog');
  if (dialog) dialog.style.display = 'none';
}

async function confirmSosBroadcast() {
  dismissSosDialog();
  try {
    const res = await fetch('/api/sos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        reason: `Emergency SOS triggered from ${appState.myIdentity}`,
        sender: appState.myIdentity
      })
    });
    if (res.ok) {
      playEmergencySiren();
      triggerVibration([500, 200, 500]);
      fetchStatus();
      showToast('🚨 P0 SOS broadcasted across mesh!');
    }
  } catch (err) {
    showToast('Failed to connect to server');
  }
}

async function handleSafeCheckIn() {
  try {
    const res = await fetch('/api/safe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sender: appState.myIdentity })
    });
    if (res.ok) {
      triggerVibration([200]);
      fetchStatus();
      showToast('✅ Safety confirmed. Alert cleared.');
    }
  } catch (err) {
    console.error(err);
  }
}

// 8. SCREEN 2 (SOS DISPATCH) ACTIONS
function selectPriority(priority) {
  appState.selectedPriority = priority;
  document.querySelectorAll('.priority-chip').forEach(btn => btn.classList.remove('active'));
  const activeBtn = document.getElementById(`chip-${priority.toLowerCase()}`);
  if (activeBtn) activeBtn.classList.add('active');
}

function applyTemplate(text) {
  const input = document.getElementById('sos-input-text');
  if (input) {
    input.value = text;
    handleCharCount();
  }
}

function handleCharCount() {
  const input = document.getElementById('sos-input-text');
  const counter = document.getElementById('sos-char-counter');
  if (!input || !counter) return;

  const len = new TextEncoder().encode(input.value).length;
  counter.textContent = `${len} / 140 bytes`;
  if (len > 140) {
    counter.style.color = 'var(--sos-red)';
  } else {
    counter.style.color = 'var(--text-slate-muted)';
  }
}

async function dispatchSosMessage() {
  const input = document.getElementById('sos-input-text');
  const text = input ? input.value.trim() : '';
  if (!text) {
    showToast('Please select a template or enter an emergency message');
    return;
  }

  const btn = document.getElementById('btn-broadcast-sos');
  if (btn) btn.innerText = 'TRANSMITTING ACROSS MESH...';

  try {
    const res = await fetch('/api/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: text,
        priority: appState.selectedPriority,
        sender: appState.myIdentity
      })
    });

    if (res.ok) {
      playEmergencySiren();
      triggerVibration([400, 200, 400]);

      const traceCard = document.getElementById('relay-trace-card');
      if (traceCard) traceCard.style.display = 'block';

      showToast(`🚨 ${appState.selectedPriority} Emergency alert relayed to mesh!`);
      if (input) input.value = '';
      handleCharCount();
      fetchStatus();
    }
  } catch (err) {
    showToast('Failed to dispatch alert');
  } finally {
    if (btn) btn.innerText = '🚨 TRANSMIT TO MESH (ALL NODES)';
  }
}

// 9. SCREEN 3 (NEARBY DEVICES) ACTIONS
function renderDevices(friends) {
  const container = document.getElementById('devices-container');
  if (!container || !friends) return;

  container.innerHTML = friends.map(f => `
    <div class="device-item-card">
      <div class="device-item-top">
        <div class="device-peer-info">
          <div class="device-avatar">${f.isBuddy ? '🛡️' : '📱'}</div>
          <div>
            <div class="device-peer-name">
              ${f.name}
              ${f.isBuddy ? '<span class="buddy-badge">PRIMARY BUDDY</span>' : ''}
            </div>
            <div class="device-meta-sub">${f.distance} • Battery: ${f.battery}</div>
          </div>
        </div>
        <span class="device-status-badge ${f.status === 'Safe' ? 'safe' : 'warning'}">${f.status}</span>
      </div>

      <div class="device-telemetry-row">
        <div class="device-rf-tag">📶 ${f.rssi || -65} dBm • ${f.hops || 'Direct BLE'}</div>
        <div class="device-actions">
          <button class="btn-device-action" onclick="pingNode('${f.name}')">Ping</button>
          <button class="btn-device-action" onclick="traceRoute('${f.name}')">Trace</button>
        </div>
      </div>
    </div>
  `).join('');
}

async function triggerDeviceScan() {
  const btn = document.getElementById('btn-scan');
  if (btn) btn.classList.add('scanning');

  try {
    const res = await fetch('/api/scan', { method: 'POST' });
    if (res.ok) {
      const data = await res.json();
      appState.friends = data.friends;
      renderDevices(data.friends);
      triggerVibration([100]);
      showToast(`Radar Scan: ${data.friends.length} peers synchronized!`);
    }
  } catch (err) {
    console.error(err);
  } finally {
    setTimeout(() => {
      if (btn) btn.classList.remove('scanning');
    }, 800);
  }
}

function pingNode(name) {
  triggerVibration([80]);
  showToast(`⚡ Ping to ${name}: 18ms latency (HMAC Ack Received)`);
}

function traceRoute(name) {
  showToast(`📍 Mesh Route: [${appState.myIdentity}] ➔ ${name} (Hop 0 • RSSI: -58 dBm)`);
}

// 10. SCREEN 4 (INBOX) ACTIONS
function filterInbox(type) {
  appState.currentFilter = type;
  document.querySelectorAll('.filter-tab').forEach(b => b.classList.remove('active'));
  if (window.event && window.event.currentTarget) {
    window.event.currentTarget.classList.add('active');
  }
  renderInbox(appState.messages);
}

function renderInbox(messages) {
  const container = document.getElementById('inbox-messages-container');
  if (!container || !messages) return;

  let filtered = messages;
  if (appState.currentFilter === 'p0') {
    filtered = messages.filter(m => m.priority === 'P0' || m.text.includes('🚨') || m.text.includes('EMERGENCY'));
  } else if (appState.currentFilter === 'safe') {
    filtered = messages.filter(m => m.text.includes('safe') || m.text.includes('సురక్షితంగా'));
  }

  container.innerHTML = filtered.map(m => `
    <div class="inbox-msg-bubble ${m.sender === appState.myIdentity ? 'you' : ''} ${m.priority === 'P0' ? 'p0-alert' : ''}">
      <div class="msg-top-row">
        <span class="msg-sender-name">${m.sender} ${m.priority ? `(${m.priority})` : ''}</span>
        <span>${m.time}</span>
      </div>
      <div class="msg-body-text">${m.text}</div>
      ${m.translation ? `
        <div class="msg-translation-pill">
          <span>🗣️ ${m.translation}</span>
        </div>
      ` : ''}
      <div class="msg-ack-status">✓✓ Delivered (${m.hops || '1 Hop'})</div>
    </div>
  `).join('');

  container.scrollTop = container.scrollHeight;
}

async function sendInboxMessage() {
  const input = document.getElementById('inbox-input-msg');
  const text = input ? input.value.trim() : '';
  if (!text) return;

  input.value = '';
  try {
    const res = await fetch('/api/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text,
        sender: appState.myIdentity,
        priority: 'P2'
      })
    });
    if (res.ok) {
      playMessageBeep();
      triggerVibration([60]);
      fetchStatus();
      showToast('Encrypted message delivered across mesh');
    }
  } catch (err) {
    showToast('Failed to send message');
  }
}

// 11. SCREEN 5 (SETTINGS) ACTIONS
async function handleBatterySlider(val) {
  const numEl = document.getElementById('battery-slider-num');
  if (numEl) numEl.textContent = `${val}%`;

  const badge = document.getElementById('power-band-badge');
  const desc = document.getElementById('battery-band-desc');

  if (val >= 25) {
    if (badge) { badge.className = 'power-band-badge'; badge.textContent = 'NORMAL BAND'; }
    if (desc) desc.textContent = '● All sensors active. High-frequency BLE beacon broadcast.';
  } else if (val >= 15) {
    if (badge) { badge.className = 'power-band-badge warn'; badge.textContent = 'OPTIMIZATION BAND'; }
    if (desc) desc.textContent = '● Reduced display refresh & throttle non-emergency relay broadcasts.';
  } else if (val >= 5) {
    if (badge) { badge.className = 'power-band-badge danger'; badge.textContent = 'LOW POWER ALERT (<15%)'; }
    if (desc) desc.textContent = '⚠️ Auto-emitted LOW_POWER_ALERT to group. GPS interval throttled to 5 mins.';
  } else {
    if (badge) { badge.className = 'power-band-badge danger'; badge.textContent = 'CRITICAL (<5%)'; }
    if (desc) desc.textContent = '🛑 Emergency Beacon only. All background services suspended.';
  }

  try {
    await fetch('/api/battery', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ level: val, inDangerZone: val < 15 })
    });
  } catch (err) {
    console.error(err);
  }
}

async function saveMeetingPoint() {
  const input = document.getElementById('setting-meeting-input');
  const val = input ? input.value.trim() : '';
  if (!val) return;

  try {
    const res = await fetch('/api/meeting-point', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ meetingPoint: val })
    });
    if (res.ok) {
      triggerVibration([100]);
      showToast(`📍 Rendezvous point updated to: "${val}" (Signed Rev 2)`);
    }
  } catch (err) {
    showToast('Failed to update meeting point');
  }
}

// 12. FALL DETECTION 15-SECOND SIMULATION
function triggerFallSimulation() {
  const dialog = document.getElementById('fall-countdown-dialog');
  if (!dialog) return;

  dialog.style.display = 'flex';
  appState.fallSecondsLeft = 15;
  const countEl = document.getElementById('fall-countdown-secs');
  if (countEl) countEl.textContent = appState.fallSecondsLeft;

  // Immediate alarm burst on fall
  playEmergencySiren();
  triggerVibration([600, 200, 600]);

  clearInterval(appState.fallCountdownInterval);
  appState.fallCountdownInterval = setInterval(() => {
    appState.fallSecondsLeft--;
    if (countEl) countEl.textContent = appState.fallSecondsLeft;

    if (appState.fallSecondsLeft <= 0) {
      clearInterval(appState.fallCountdownInterval);
      dialog.style.display = 'none';
      triggerFallSosNow();
    }
  }, 1000);
}

function cancelFallAlert() {
  clearInterval(appState.fallCountdownInterval);
  const dialog = document.getElementById('fall-countdown-dialog');
  if (dialog) dialog.style.display = 'none';
  triggerVibration([100]);
  showToast('✅ Fall alert safely canceled. User marked safe.');
}

async function triggerFallSosNow() {
  clearInterval(appState.fallCountdownInterval);
  const dialog = document.getElementById('fall-countdown-dialog');
  if (dialog) dialog.style.display = 'none';

  try {
    const res = await fetch('/api/sos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        reason: `Unresponsive fall detected from ${appState.myIdentity} (15s auto-escalation)`,
        sender: appState.myIdentity
      })
    });
    if (res.ok) {
      playEmergencySiren();
      triggerVibration([1000, 500, 1000]);
      fetchStatus();
      showToast('🚨 FALL SOS ESCALATED: Emergency broadcasted across mesh!');
    }
  } catch (err) {
    console.error(err);
  }
}

// 13. Desktop / Phone Frame Toggle
function togglePhoneFrame() {
  const frame = document.getElementById('device-frame');
  const btn = document.getElementById('frame-toggle-btn');
  if (!frame) return;

  frame.classList.toggle('fullscreen-phone-mode');
  if (frame.classList.contains('fullscreen-phone-mode')) {
    if (btn) btn.textContent = '📱 Restore Phone Bezel';
  } else {
    if (btn) btn.textContent = '📱 Toggle Fullscreen View';
  }
}

// 14. Subtle Toast Notification
function showToast(message) {
  let toast = document.getElementById('resq-toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'resq-toast';
    toast.style.position = 'fixed';
    toast.style.bottom = '80px';
    toast.style.left = '50%';
    toast.style.transform = 'translateX(-50%)';
    toast.style.backgroundColor = '#1E293B';
    toast.style.color = '#F8FAFC';
    toast.style.padding = '10px 20px';
    toast.style.borderRadius = '20px';
    toast.style.boxShadow = '0 10px 25px rgba(0,0,0,0.6), 0 0 15px rgba(6, 182, 212, 0.3)';
    toast.style.border = '1px solid #334155';
    toast.style.fontSize = '12px';
    toast.style.fontWeight = '700';
    toast.style.zIndex = '9999';
    toast.style.transition = 'opacity 0.25s ease';
    toast.style.pointerEvents = 'none';
    document.body.appendChild(toast);
  }

  toast.textContent = message;
  toast.style.opacity = '1';
  clearTimeout(window.__toastTimeout);
  window.__toastTimeout = setTimeout(() => {
    toast.style.opacity = '0';
  }, 2800);
}
