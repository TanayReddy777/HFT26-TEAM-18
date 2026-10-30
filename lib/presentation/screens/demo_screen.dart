import 'package:flutter/material.dart';
import '../../app/theme.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final List<String> _simLog = [];
  int _activeStep = 0;

  void _addLog(String msg) {
    setState(() {
      _simLog.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Multi-Node Simulator'),
        backgroundColor: Colors.purple.shade900,
      ),
      body: Column(
        children: [
          // Mandatory Demo Banner
          Container(
            width: double.infinity,
            color: Colors.amber.shade800,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  'DEMO — SIMULATED DATA (Isolated Environment)',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Guided Multi-Node Scenarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 1. Separation Progression
                _buildScenarioCard(
                  title: '1. Separation Distance Progression',
                  subtitle: 'Simulates Phone A moving from 20m -> 70m (Warning) -> 120m (Critical)',
                  icon: Icons.social_distance_rounded,
                  color: ResQTheme.warningOrange,
                  actions: [
                    TextButton(
                      child: const Text('20m (Within Range)'),
                      onPressed: () => _addLog('Peer distance: 20m. State: WITHIN_CONFIGURED_RANGE'),
                    ),
                    TextButton(
                      child: const Text('70m (Warning)'),
                      onPressed: () => _addLog('Peer distance: 70m (±15m). State: SEPARATION_WARNING'),
                    ),
                    TextButton(
                      child: const Text('120m (Critical)'),
                      onPressed: () => _addLog('Peer distance: 120m (±20m). State: SEPARATION_CRITICAL'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Poor GPS Fix & Uncertainty
                _buildScenarioCard(
                  title: '2. Poor GPS Accuracy Handling',
                  subtitle: 'Simulates degraded GPS uncertainty (±85m). Conservative heuristic activates.',
                  icon: Icons.gps_not_fixed_rounded,
                  color: Colors.purpleAccent,
                  actions: [
                    TextButton(
                      child: const Text('Inject ±85m Fix'),
                      onPressed: () => _addLog('GPS fix accuracy degraded to ±85m. Separation evaluated as: DISTANCE_UNCERTAIN (No false confidence).'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Fall Detection State Machine
                _buildScenarioCard(
                  title: '3. Fall Detection & Revisions',
                  subtitle: 'Simulates Free-fall (<0.5G) -> Impact (>2.5G) -> Stillness (2.5s)',
                  icon: Icons.personal_injury_rounded,
                  color: ResQTheme.sosRed,
                  actions: [
                    TextButton(
                      child: const Text('Simulate Fall Impact'),
                      onPressed: () => _addLog('Sensors: Impact 3.2G detected -> Stillness confirmed -> Emitted POSSIBLE_FALL Rev 1 (Awaiting Confirmation).'),
                    ),
                    TextButton(
                      child: const Text('User Safe'),
                      onPressed: () => _addLog('User responded "I AM SAFE" -> Published Rev 2: USER_CONFIRMED_SAFE. Obsolete warning cancelled.'),
                    ),
                    TextButton(
                      child: const Text('Timeout'),
                      onPressed: () => _addLog('Countdown expired without response -> Published Rev 2: NO_RESPONSE (UNCONFIRMED).'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Battery Discharge in RED Zone
                _buildScenarioCard(
                  title: '4. Battery Discharge in RED Zone',
                  subtitle: 'Simulates battery drop from 11% -> 9% (Alert) -> 4% (Critical) inside RED zone.',
                  icon: Icons.battery_alert_rounded,
                  color: ResQTheme.sosRed,
                  actions: [
                    TextButton(
                      child: const Text('11% Normal'),
                      onPressed: () => _addLog('Battery: 11%. Band: LOW_POWER_PREPARATION.'),
                    ),
                    TextButton(
                      child: const Text('9% in RED Zone'),
                      onPressed: () => _addLog('Battery: 9% (Discharge episode latched). User inside "RED Zone Alpha" -> Mandatory Safety Check Requested!'),
                    ),
                    TextButton(
                      child: const Text('4% Critical'),
                      onPressed: () => _addLog('Battery: 4%. Band: CRITICAL_POWER. Distinct CRITICAL_LOW_POWER incident emitted.'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. 3-Node Multi-Hop Mesh Relay
                _buildScenarioCard(
                  title: '5. Three-Node Mesh Relay (A -> B -> C)',
                  subtitle: 'Phone A has NO direct connection to C. Phone B relays the emergency SOS packet.',
                  icon: Icons.alt_route_rounded,
                  color: ResQTheme.meshCyan,
                  actions: [
                    TextButton(
                      child: const Text('Run A -> B -> C Relay'),
                      onPressed: () {
                        _addLog('Node A: Created P0 SOS (MessageId: 8f4a1). Forwarded to Node B (Hop 0).');
                        _addLog('Node B: Received from A, verified signature. Relayed to Node C (Hop 1).');
                        _addLog('Node C: Stored P0 SOS. Emitted Receipt STORED Rev 1 via reverse route B -> A.');
                        _addLog('Node A: Received exact-revision receipt for Node C! Full loop completed without direct A-C radio link.');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Simulation Event Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  height: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ResQTheme.surfaceBorder),
                  ),
                  child: _simLog.isEmpty
                      ? const Center(
                          child: Text(
                            'Click any simulation action above to trigger events...',
                            style: TextStyle(color: ResQTheme.textSecondary, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _simLog.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _simLog[i],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: ResQTheme.meshCyan,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
