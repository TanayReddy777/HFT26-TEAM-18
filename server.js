// ResQ Production Offline Mesh Backend Server
// Built with pure Node.js (Zero external dependencies required)
// Full 10-Node Mesh Support with Originator Verification Authority

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

// 10 Decentralized Mesh Nodes across Team ResQ & Field Peers
const ALL_DEVICES = [
  { id: 1, name: 'Phone 1 (Tanay)', role: 'Team Leader', distance: '0m (Local)', battery: '85%', status: 'Safe', isBuddy: false, rssi: -30, hops: 'Origin Node', lastSeen: 'Active' },
  { id: 2, name: 'Phone 2 (Abhinav)', role: 'Field Operations', distance: '32 meters away', battery: '88%', status: 'Safe', isBuddy: true, rssi: -54, hops: 'Direct BLE', lastSeen: '2s ago' },
  { id: 3, name: 'Phone 3 (Sahasra)', role: 'Medical Lead', distance: '65 meters away', battery: '92%', status: 'Safe', isBuddy: true, rssi: -62, hops: 'Direct BLE', lastSeen: '4s ago' },
  { id: 4, name: 'Phone 4 (Ram)', role: 'Rescue Relay', distance: '110 meters away', battery: '76%', status: 'Safe', isBuddy: false, rssi: -74, hops: 'Direct BLE', lastSeen: '6s ago' },
  { id: 5, name: 'Phone 5 (Vamshi)', role: 'Network Mesh', distance: '145 meters away', battery: '81%', status: 'Safe', isBuddy: false, rssi: -79, hops: '1-Hop via Ram', lastSeen: '8s ago' },
  { id: 6, name: 'Phone 6 (Ravi)', role: 'Scout Alpha', distance: '180 meters away', battery: '69%', status: 'Safe', isBuddy: false, rssi: -83, hops: '1-Hop via Abhinav', lastSeen: '5s ago' },
  { id: 7, name: 'Phone 7 (Priya)', role: 'Camp Base', distance: '210 meters away', battery: '58%', status: 'Safe', isBuddy: false, rssi: -88, hops: '2-Hop via Ravi', lastSeen: '12s ago' },
  { id: 8, name: 'Phone 8 (Anil)', role: 'Bridge Watch', distance: '260 meters away', battery: '73%', status: 'Safe', isBuddy: false, rssi: -91, hops: '2-Hop via Sahasra', lastSeen: '7s ago' },
  { id: 9, name: 'Phone 9 (Sneha)', role: 'Perimeter Scout', distance: '310 meters away', battery: '64%', status: 'Safe', isBuddy: false, rssi: -94, hops: '3-Hop via Anil', lastSeen: '15s ago' },
  { id: 10, name: 'Phone 10 (Kiran)', role: 'Evacuation Escort', distance: '375 meters away', battery: '95%', status: 'Safe', isBuddy: false, rssi: -96, hops: '3-Hop via Sneha', lastSeen: '10s ago' }
];

// In-Memory Simple MVP State with Originator Authority Tracking
let state = {
  isEmergency: false,
  emergencyOriginator: null,   // Authoritative node that triggered the alert
  emergencyReason: '',
  emergencyTime: null,
  emergencyRevision: 0,
  emergencyAcks: [],           // Devices that have acknowledged receipt
  batteryLevel: 85,
  inDangerZone: false,
  meetingPoint: 'Camp Alpha (Near Lake Bridge)',
  friends: ALL_DEVICES,
  messages: [
    {
      id: 1,
      sender: 'Phone 6 (Ravi)',
      priority: 'P1',
      text: 'వంతెన దగ్గర ఉన్నాము, సహాయం కావాలి.',
      translation: 'We are near the bridge, need help.',
      time: '2 mins ago',
      hops: '1 Hop',
      status: 'Delivered (ACK 10/10)'
    }
  ]
};

// Simple translations dictionary for instant demo
const simpleTranslations = {
  'help': 'సహాయం (Help)',
  'i need help': 'నాకు సహాయం కావాలి (I need help)',
  'i am safe': 'నేను సురక్షితంగా ఉన్నాను (I am safe)',
  'water': 'నీరు (Water)',
  'food': 'ఆహారం (Food)',
  'bridge': 'వంతెన (Bridge)',
  'where are you': 'మీరు ఎక్కడ ఉన్నారు (Where are you)'
};

function autoTranslate(text) {
  const lower = text.toLowerCase().trim();
  for (const [key, val] of Object.entries(simpleTranslations)) {
    if (lower.includes(key)) {
      return val;
    }
  }
  // If text has Telugu characters, provide English
  if (/[\u0C00-\u0C7F]/.test(text)) {
    return 'Translated to English: Emergency message received.';
  }
  return 'Translated to Telugu: అత్యవసర సందేశం అందింది.';
}

// SSE Clients Set for sub-50ms instant multi-phone event broadcasting
const sseClients = new Set();
const registeredDevices = new Map();

function broadcastEvent(type, payload) {
  const payloadStr = JSON.stringify({ type, payload, state, timestamp: Date.now() });
  for (const client of sseClients) {
    try {
      client.write(`data: ${payloadStr}\n\n`);
    } catch (_) {
      sseClients.delete(client);
    }
  }
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // --- REST & REAL-TIME API ENDPOINTS ---

  // 0. GET /api/events (Server-Sent Events for instant multi-phone live sync)
  if (pathname === '/api/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-store',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*'
    });
    res.write(`data: ${JSON.stringify({ type: 'CONNECTED', state })}\n\n`);
    sseClients.add(res);

    req.on('close', () => {
      sseClients.delete(res);
    });
    return;
  }

  // 1. GET /api/status
  if (pathname === '/api/status' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(state));
    return;
  }

  // 2. POST /api/register-device (Track real connected phones on local Wi-Fi)
  if (pathname === '/api/register-device' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}
      
      const deviceId = data.deviceId || 'node-' + Math.floor(Math.random() * 1000);
      const deviceName = data.deviceName || 'Peer ' + deviceId;

      registeredDevices.set(deviceId, {
        id: deviceId,
        name: deviceName,
        distance: data.distance || '12 meters away',
        battery: (data.battery || 85) + '%',
        status: 'Safe',
        isBuddy: Boolean(data.isBuddy),
        rssi: data.rssi || -55,
        hops: 'Direct BLE / Wi-Fi Direct',
        lastSeen: 'Just now'
      });

      broadcastEvent('DEVICE_REGISTERED', { deviceId, deviceName });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, registered: Array.from(registeredDevices.values()) }));
    });
    return;
  }

  // 3. POST /api/sos (Trigger Emergency SOS with Originator Authority Binding)
  if (pathname === '/api/sos' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      const senderName = data.sender || 'Phone 1 (Tanay)';
      state.isEmergency = true;
      state.emergencyOriginator = senderName; // BIND ORIGINATOR AUTHORITY
      state.emergencyRevision = (state.emergencyRevision || 0) + 1;
      state.emergencyReason = data.reason || 'User pressed the Emergency SOS button';
      state.emergencyTime = new Date().toLocaleTimeString();
      state.emergencyAcks = [senderName]; // Originator auto-acknowledged

      // Update peer status in list
      state.friends.forEach(f => {
        if (f.name === senderName) {
          f.status = '🚨 SOS ACTIVE';
        }
      });

      const alertMsg = {
        id: Date.now(),
        sender: senderName,
        priority: 'P0',
        text: `🚨 [EMERGENCY SOS - REV ${state.emergencyRevision}] ${state.emergencyReason}. Sole resolution authority: ${senderName}`,
        translation: '🚨 [అత్యవసర సహాయం] తక్షణ సహాయం కోరబడింది.',
        time: 'Just now',
        hops: 'Flooded (10-Node Mesh)',
        status: `Broadcasted (Originator: ${senderName})`
      };
      state.messages.push(alertMsg);

      // Instant Push to all 10 devices!
      broadcastEvent('SOS_TRIGGERED', {
        reason: state.emergencyReason,
        time: state.emergencyTime,
        sender: senderName,
        originator: senderName,
        revision: state.emergencyRevision,
        acks: state.emergencyAcks,
        alertMsg
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        message: `Emergency SOS broadcasted across 10-node mesh. Originator authority locked to ${senderName}.`,
        originator: senderName,
        revision: state.emergencyRevision,
        state
      }));
    });
    return;
  }

  // 4. POST /api/safe (Clear Emergency / Resolve - STRICT ORIGINATOR AUTHORITY)
  if (pathname === '/api/safe' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      const caller = data.sender || 'Unknown Node';

      // 🔐 STRICT ORIGINATOR AUTHORITY RULE:
      // Only the device that sent the alert has the authority to verify resolution!
      if (state.isEmergency && state.emergencyOriginator && caller !== state.emergencyOriginator) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: 'UNAUTHORIZED_RESOLUTION_ATTEMPT',
          originator: state.emergencyOriginator,
          caller: caller,
          message: `ACCESS DENIED: Authority to verify resolution rests exclusively with originator "${state.emergencyOriginator}". Recipient device "${caller}" cannot resolve this alert on their behalf.`
        }));
        return;
      }

      // If authorized (caller is the originator):
      const previousOriginator = state.emergencyOriginator || caller;
      state.isEmergency = false;
      state.emergencyRevision = (state.emergencyRevision || 0) + 1;
      state.emergencyOriginator = null;
      state.emergencyReason = '';
      state.emergencyTime = null;
      state.emergencyAcks = [];

      // Reset all peer statuses back to Safe
      state.friends.forEach(f => { f.status = 'Safe'; });

      const safeMsg = {
        id: Date.now(),
        sender: caller,
        priority: 'P3',
        text: `✅ [ISSUE RESOLVED - REV ${state.emergencyRevision}] Originator (${caller}) verified situation is safe. Mesh emergency cancelled.`,
        translation: '✅ [పరిష్కరించబడింది] అత్యవసర పరిస్థితి పరిష్కరించబడింది.',
        time: 'Just now',
        hops: 'Direct BLE',
        status: 'Delivered (ACK 10/10 Nodes)'
      };
      state.messages.push(safeMsg);

      broadcastEvent('SOS_CLEARED', {
        state,
        safeMsg,
        originator: previousOriginator,
        resolvedBy: caller,
        revision: state.emergencyRevision
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        message: `Marked as safe. Emergency resolved by authorized originator ${caller}. Broadcasted to all 10 devices.`,
        resolvedBy: caller,
        revision: state.emergencyRevision,
        state
      }));
    });
    return;
  }

  // 5. POST /api/ack (Recipient Devices Acknowledge Receipt across 10-node mesh)
  if (pathname === '/api/ack' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      const ackDevice = data.sender || 'Unknown Node';
      if (!state.emergencyAcks) state.emergencyAcks = [];
      if (!state.emergencyAcks.includes(ackDevice)) {
        state.emergencyAcks.push(ackDevice);
      }

      const ackMsg = {
        id: Date.now(),
        sender: ackDevice,
        priority: 'P2',
        text: `🤝 [ACK - REV ${state.emergencyRevision}] ${ackDevice} acknowledged ${state.emergencyOriginator}'s SOS (${state.emergencyAcks.length}/10 Nodes)`,
        translation: '🤝 రసీదు నమోదు చేయబడింది.',
        time: 'Just now',
        hops: '1-Hop Mesh',
        status: `Acknowledged (${state.emergencyAcks.length}/10)`
      };
      state.messages.push(ackMsg);

      broadcastEvent('SOS_ACKNOWLEDGED', {
        device: ackDevice,
        originator: state.emergencyOriginator,
        acksCount: state.emergencyAcks.length,
        totalNodes: state.friends.length,
        state
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        device: ackDevice,
        originator: state.emergencyOriginator,
        acksCount: state.emergencyAcks.length,
        totalNodes: state.friends.length,
        state
      }));
    });
    return;
  }

  // 6. POST /api/message (Send simple chat message with translation)
  if (pathname === '/api/message' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      const text = data.text || '';
      if (!text) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Text is required' }));
        return;
      }

      const priority = data.priority || 'P2';
      const senderName = data.sender || 'Phone 1 (Tanay)';
      const msg = {
        id: Date.now(),
        sender: senderName,
        priority: priority,
        recipient: data.recipient || 'Broadcast (All 10 Nodes)',
        text: text,
        translation: autoTranslate(text),
        time: 'Just now',
        hops: priority === 'P0' ? 'Flooded (All 10 Nodes)' : (data.hops || '1 Hop'),
        status: 'Delivered (ACK 10/10)'
      };

      state.messages.push(msg);

      // If message is P0 or trauma, flag emergency status with originator authority
      if (priority === 'P0') {
        state.isEmergency = true;
        state.emergencyOriginator = senderName;
        state.emergencyRevision = (state.emergencyRevision || 0) + 1;
        state.emergencyReason = text;
        state.emergencyTime = new Date().toLocaleTimeString();
        state.emergencyAcks = [senderName];
        state.friends.forEach(f => {
          if (f.name === senderName) {
            f.status = '🚨 SOS ACTIVE';
          }
        });
      }

      broadcastEvent('NEW_MESSAGE', { msg, isEmergency: state.isEmergency, originator: state.emergencyOriginator });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: msg, isEmergency: state.isEmergency }));
    });
    return;
  }

  // 7. POST /api/battery (Change battery level to test warnings)
  if (pathname === '/api/battery' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}
      
      const level = Number(data.level) || 85;
      state.batteryLevel = level;
      state.inDangerZone = Boolean(data.inDangerZone);

      broadcastEvent('BATTERY_CHANGED', { batteryLevel: state.batteryLevel, inDangerZone: state.inDangerZone });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, batteryLevel: state.batteryLevel, inDangerZone: state.inDangerZone }));
    });
    return;
  }

  // 8. POST /api/meeting-point (Update meeting location)
  if (pathname === '/api/meeting-point' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}
      
      if (data.meetingPoint) {
        state.meetingPoint = data.meetingPoint;
      }

      broadcastEvent('MEETING_POINT_CHANGED', { meetingPoint: state.meetingPoint });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, meetingPoint: state.meetingPoint }));
    });
    return;
  }

  // 9. POST /api/scan (Simulate discovering and pinging nearby nodes across 10-node mesh)
  if (pathname === '/api/scan' && req.method === 'POST') {
    // Dynamic RSSI slight variance simulating living RF environment
    state.friends.forEach(f => {
      const delta = Math.floor(Math.random() * 9) - 4;
      f.rssi = Math.min(-45, Math.max(-95, (f.rssi || -70) + delta));
      f.lastSeen = '1s ago';
    });

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      success: true,
      nodesCount: state.friends.length,
      friends: state.friends,
      scannedAt: new Date().toLocaleTimeString()
    }));
    return;
  }

  // --- SERVE STATIC FRONTEND FILES ---
  let filePath = path.join(PUBLIC_DIR, pathname === '/' ? 'index.html' : pathname);
  const ext = path.extname(filePath).toLowerCase();

  const contentTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml'
  };

  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('File not found');
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Server error: ' + err.code);
      }
    } else {
      res.writeHead(200, {
        'Content-Type': contentTypes[ext] || 'application/octet-stream',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0',
        'Pragma': 'no-cache',
        'Expires': '0'
      });
      res.end(content);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(` ResQ 10-Node Mesh Server with Originator Authority`);
  console.log(` 👉 Localhost:       http://localhost:${PORT}/`);
  console.log(` 👉 Phone on Wi-Fi:  http://172.34.12.124:${PORT}/`);
  console.log(` 👉 Active Nodes:    10 Decentralized Devices`);
  console.log(`===============================================`);
});
