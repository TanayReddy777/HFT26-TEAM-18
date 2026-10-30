// Simple ResQ MVP Backend Server
// Built with pure Node.js (Zero external dependencies required)

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

// In-Memory Simple MVP State
let state = {
  isEmergency: false,
  emergencyReason: '',
  emergencyTime: null,
  batteryLevel: 85,
  inDangerZone: false,
  meetingPoint: 'Camp Alpha (Near Lake Bridge)',
  friends: [
    { id: 1, name: 'Ravi', distance: '45 meters away', battery: '82%', status: 'Safe', isBuddy: true, rssi: -58, hops: 'Direct BLE', lastSeen: '3s ago' },
    { id: 2, name: 'Priya', distance: '115 meters away', battery: '38%', status: 'Far from group', isBuddy: false, rssi: -81, hops: 'Direct BLE', lastSeen: '12s ago' },
    { id: 3, name: 'Anil', distance: '190 meters away', battery: '91%', status: 'Safe', isBuddy: false, rssi: -89, hops: '1-Hop via Ravi', lastSeen: '5s ago' }
  ],
  messages: [
    {
      id: 1,
      sender: 'Ravi',
      priority: 'P1',
      text: 'వంతెన దగ్గర ఉన్నాము, సహాయం కావాలి.',
      translation: 'We are near the bridge, need help.',
      time: '2 mins ago',
      hops: '1 Hop',
      status: 'Delivered (ACK 2/2)'
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

  // 3. POST /api/sos (Trigger Emergency SOS with instant audio & vibration broadcast)
  if (pathname === '/api/sos' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      state.isEmergency = true;
      state.emergencyReason = data.reason || 'User pressed the Emergency SOS button';
      state.emergencyTime = new Date().toLocaleTimeString();

      const senderName = data.sender || 'Mesh Node';
      // Add emergency message to chat
      const alertMsg = {
        id: Date.now(),
        sender: senderName,
        priority: 'P0',
        text: '🚨 EMERGENCY SOS: ' + state.emergencyReason,
        translation: '🚨 అత్యవసర సహాయం కోరబడింది',
        time: 'Just now',
        hops: 'Flooded (All Mesh)',
        status: 'Delivered (ACK All Peers)'
      };
      state.messages.push(alertMsg);

      // Instant Push to all connected phones!
      broadcastEvent('SOS_TRIGGERED', {
        reason: state.emergencyReason,
        time: state.emergencyTime,
        sender: senderName,
        alertMsg
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'Emergency SOS activated and sent to all friends.', state }));
    });
    return;
  }

  // 4. POST /api/safe (Clear Emergency / I am Safe)
  if (pathname === '/api/safe' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let data = {};
      try { data = JSON.parse(body); } catch (_) {}

      state.isEmergency = false;
      state.emergencyReason = '';
      state.emergencyTime = null;

      const safeMsg = {
        id: Date.now(),
        sender: data.sender || 'You',
        priority: 'P3',
        text: '✅ I am safe now. The emergency alert is resolved.',
        translation: '✅ నేను ఇప్పుడు సురక్షితంగా ఉన్నాను.',
        time: 'Just now',
        hops: 'Direct',
        status: 'Delivered'
      };
      state.messages.push(safeMsg);

      broadcastEvent('SOS_CLEARED', { state, safeMsg });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'Marked as safe. Group alert cancelled.', state }));
    });
    return;
  }

  // 4. POST /api/message (Send simple chat message with translation)
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
      const msg = {
        id: Date.now(),
        sender: data.sender || 'You',
        priority: priority,
        recipient: data.recipient || 'Broadcast (All Nodes)',
        text: text,
        translation: autoTranslate(text),
        time: 'Just now',
        hops: priority === 'P0' ? 'Flooded (All Mesh)' : (data.hops || '1 Hop'),
        status: 'Delivered (ACK 2/2)'
      };

      state.messages.push(msg);

      // If message is P0 or trauma, flag emergency status
      if (priority === 'P0') {
        state.isEmergency = true;
        state.emergencyReason = text;
        state.emergencyTime = new Date().toLocaleTimeString();
      }

      broadcastEvent('NEW_MESSAGE', { msg, isEmergency: state.isEmergency });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: msg, isEmergency: state.isEmergency }));
    });
    return;
  }

  // 5. POST /api/battery (Change battery level to test warnings)
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

  // 6. POST /api/meeting-point (Update meeting location)
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

  // 7. POST /api/scan (Simulate discovering and pinging nearby nodes)
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
  console.log(` ResQ Simple MVP Server running on:`);
  console.log(` 👉 Localhost:       http://localhost:${PORT}/`);
  console.log(` 👉 Phone on Wi-Fi:  http://172.34.12.124:${PORT}/`);
  console.log(`===============================================`);
});
