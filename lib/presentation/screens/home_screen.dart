import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants/priorities.dart';
import '../../core/contracts/session_provider.dart';
import '../../core/contracts/incident_service.dart';
import '../../core/contracts/location_provider.dart';
import '../../core/contracts/power_policy_provider.dart';
import '../../core/constants/event_codes.dart';
import '../widgets/emergency_banner.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatelessWidget {
  final SessionProvider sessionProvider;
  final IncidentService incidentService;
  final LocationProvider locationProvider;
  final PowerPolicyProvider powerProvider;
  final VoidCallback onNavigateToIncidents;
  final VoidCallback onNavigateToDemo;

  const HomeScreen({
    super.key,
    required this.sessionProvider,
    required this.incidentService,
    required this.locationProvider,
    required this.powerProvider,
    required this.onNavigateToIncidents,
    required this.onNavigateToDemo,
  });

  @override
  Widget build(BuildContext context) {
    final powerState = powerProvider.currentPowerState;
    final latestFix = locationProvider.latestFix;
    final activeIncidents = incidentService.activeIncidents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ResQ • Emergency Mesh', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_rounded, color: ResQTheme.meshCyan),
            tooltip: 'Interactive Demo Mode',
            onPressed: onNavigateToDemo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Telemetry Bar
          StatusIndicatorBar(
            powerState: powerState,
            gpsAccuracy: latestFix?.accuracyMeters,
            connectedPeersCount: sessionProvider.authorizedMembers.length > 1
                ? sessionProvider.authorizedMembers.length - 1
                : 0,
            cloudStatus: 'Offline / Mesh',
          ),

          // Active Emergency Banner
          EmergencyBanner(
            activeIncidents: activeIncidents,
            onTapViewAll: onNavigateToIncidents,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Prominent P0 SOS Trigger Button
                Center(
                  child: GestureDetector(
                    onTap: () => _triggerManualSos(context),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ResQTheme.sosRed,
                        boxShadow: [
                          BoxShadow(
                            color: ResQTheme.sosRed.withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos_rounded, size: 56, color: Colors.white),
                            SizedBox(height: 6),
                            Text(
                              'EMERGENCY SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Tap to broadcast P0',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Session Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mesh Session State',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ResQTheme.safeGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sessionProvider.currentSessionId.isNotEmpty ? 'ACTIVE' : 'READY',
                                style: const TextStyle(
                                  color: ResQTheme.safeGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Device ID: ${sessionProvider.localNodeId.substring(0, 8)}',
                          style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          'Role: ${sessionProvider.isLeader ? 'Leader (Meeting Point Authority)' : 'Member'}',
                          style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          'Active Members: ${sessionProvider.authorizedMembers.length}',
                          style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: const Text('Enroll Peer'),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Verified QR Enrollment Active')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.power_settings_new_rounded),
                                label: const Text('End Session'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ResQTheme.sosRed,
                                ),
                                onPressed: () async {
                                  await sessionProvider.endSession();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Session ended. Unresolved incidents preserved.')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _triggerManualSos(BuildContext context) async {
    await incidentService.submitIncident(
      sourceModule: 'ManualTrigger',
      eventCode: EventCodes.confirmedSos,
      severity: Priority.p0Critical,
      explicitSos: true,
      reason: 'User triggered explicit SOS button from home screen',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: ResQTheme.sosRed,
        content: Text('P0 Explicit SOS broadcasted across offline mesh!'),
      ),
    );
  }
}
