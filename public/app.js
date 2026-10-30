/**
 * ResQ — Interactive 5-Screen Full Working Model
 * Supports: Home Dashboard, SOS Dispatch, Mesh Devices Radar, Encrypted Inbox, Safety Settings,
 * Fall Simulation Countdown, Real-Time Polling, and Mobile Responsive Mode.
 */

let appState = {
  activeScreen: 'home',
  selectedPriority: 'P0',
  currentFilter: 'all',
  fallCountdownInterval: null,
  fallSecondsLeft: 15,
  isEmergency: false,
  batteryLevel: 85,
  meetingPoint: 'Camp Alpha (Lake Bridge)',
  friends: [],
  messages: []
};

// 1. Initial Kickoff
document.addEventListener('DOMContentLoaded', () => {
  initClock();
  fetchStatus();
  setInterval(fetchStatus, 3000);
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

// 2. Navigation State Machine
function navTo(screenName) {
  appState.activeScreen = screenName;

  // Toggle View Containers
  const views = document.querySelectorAll('.screen-view');
  views.forEach(v => v.classList.remove('active'));

  const targetView = document.getElementById(`view-${screenName}`);
  if (targetView) {
    targetView.classList.add('active');
    targetView.scrollTop = 0;
  }

  // Toggle Bottom Navigation Pills
  const navButtons = document.querySelectorAll('.nav-item');
  navButtons.forEach(btn => btn.classList.remove('active'));

  const activeNavBtn = document.getElementById(`nav-btn-${screenName}`);
  if (activeNavBtn) {
    activeNavBtn.classList.add('active');
  }

  // Update Dynamic Header
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

  // Re-render specific screen content
  if (screenName === 'devices') renderDevices(appState.friends);
  if (screenName === 'inbox') renderInbox(appState.messages);
}

// 3. Status Polling & Real-Time Sync
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
  // Battery status icon
  const batteryIcon = document.getElementById('status-battery-icon');
  if (batteryIcon) {
    batteryIcon.textContent = `🔋 ${data.batteryLevel}%`;
  }
  const sosBatteryTag = document.getElementById('sos-battery-tag');
  if (sosBatteryTag) {
    sosBatteryTag.textContent = `${data.batteryLevel}%`;
  }

  // Header status pill
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

  // Telemetry cards
  const networkVal = document.getElementById('card-network-val');
  if (networkVal) networkVal.textContent = data.isEmergency ? 'Alert Broadcasting' : 'Offline Active';

  const devicesVal = document.getElementById('card-devices-val');
  const meshCountVal = document.getElementById('mesh-nodes-count');
  if (devicesVal) devicesVal.textContent = `${appState.friends.length} Devices`;
  if (meshCountVal) meshCountVal.textContent = `${appState.friends.length}`;

  // Meeting point
  const meetingTitle = document.getElementById('meeting-title-text');
  if (meetingTitle) meetingTitle.textContent = data.meetingPoint;

  // Active view updates
  if (appState.activeScreen === 'devices') renderDevices(appState.friends);
  if (appState.activeScreen === 'inbox') renderInbox(appState.messages);
}

// 4. SCREEN 1 (HOME) ACTIONS
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
      body: JSON.stringify({ reason: 'Manual Emergency SOS triggered from Home Dashboard' })
    });
    if (res.ok) {
      fetchStatus();
      showToast('🚨 P0 SOS broadcasted to 3 mesh peers!');
    }
  } catch (err) {
    showToast('Failed to connect to server');
  }
}

async function handleSafeCheckIn() {
  try {
    const res = await fetch('/api/safe', { method: 'POST' });
    if (res.ok) {
      fetchStatus();
      showToast('✅ Safety confirmed. All alerts cleared.');
    }
  } catch (err) {
    console.error(err);
  }
}

// 5. SCREEN 2 (SOS DISPATCH) ACTIONS
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
        sender: 'You'
      })
    });

    if (res.ok) {
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

// 6. SCREEN 3 (NEARBY DEVICES) ACTIONS
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
  showToast(`⚡ Ping to ${name}: 18ms latency (HMAC Ack Received)`);
}

function traceRoute(name) {
  showToast(`📍 Mesh Route: Local [You] ➔ ${name} (Hop 0 • RSSI: -58 dBm)`);
}

// 7. SCREEN 4 (INBOX) ACTIONS
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
    <div class="inbox-msg-bubble ${m.sender === 'You' ? 'you' : ''} ${m.priority === 'P0' ? 'p0-alert' : ''}">
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
      body: JSON.stringify({ text, sender: 'You', priority: 'P2' })
    });
    if (res.ok) {
      fetchStatus();
      showToast('Encrypted message delivered across mesh');
    }
  } catch (err) {
    showToast('Failed to send message');
  }
}

// 8. SCREEN 5 (SETTINGS) ACTIONS
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
    fetchStatus();
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
      fetchStatus();
      showToast(`📍 Rendezvous point updated to: "${val}" (Signed Rev 2)`);
    }
  } catch (err) {
    showToast('Failed to update meeting point');
  }
}

// 9. FALL DETECTION 15-SECOND SIMULATION
function triggerFallSimulation() {
  const dialog = document.getElementById('fall-countdown-dialog');
  if (!dialog) return;

  dialog.style.display = 'flex';
  appState.fallSecondsLeft = 15;
  const countEl = document.getElementById('fall-countdown-secs');
  if (countEl) countEl.textContent = appState.fallSecondsLeft;

  clearInterval(appState.fallCountdownInterval);
  appState.fallCountdownInterval = setInterval(() => {
    appState.fallSecondsLeft--;
    if (countEl) countEl.textContent = appState.fallSecondsLeft;

    if (appState.fallSecondsLeft <= 0) {
      clearInterval(appState.fallCountdownInterval);
      dialog.style.display = 'none';
      // Auto-escalate to SOS when timer expires!
      triggerFallSosNow();
    }
  }, 1000);
}

function cancelFallAlert() {
  clearInterval(appState.fallCountdownInterval);
  const dialog = document.getElementById('fall-countdown-dialog');
  if (dialog) dialog.style.display = 'none';
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
      body: JSON.stringify({ reason: 'Unresponsive fall detected (15s auto-escalation)' })
    });
    if (res.ok) {
      fetchStatus();
      showToast('🚨 FALL SOS ESCALATED: Emergency broadcasted across mesh!');
    }
  } catch (err) {
    console.error(err);
  }
}

// 10. Desktop / Phone Frame Toggle
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

// 11. Subtle Toast Notification
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
