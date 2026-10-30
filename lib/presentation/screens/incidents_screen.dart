import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants/priorities.dart';
import '../../core/contracts/incident_service.dart';
import '../../core/contracts/session_provider.dart';
import '../../core/models/incident_snapshot.dart';

class IncidentsScreen extends StatefulWidget {
  final IncidentService incidentService;
  final SessionProvider sessionProvider;

  const IncidentsScreen({
    super.key,
    required this.incidentService,
    required this.sessionProvider,
  });

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Lifecycle & Tracking'),
      ),
      body: StreamBuilder<List<IncidentSnapshot>>(
        stream: widget.incidentService.incidentsStream,
        initialData: widget.incidentService.activeIncidents,
        builder: (context, snapshot) {
          final incidents = snapshot.data ?? [];

          if (incidents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 64, color: ResQTheme.safeGreen),
                  SizedBox(height: 16),
                  Text(
                    'No active emergency incidents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All monitored peers safe or within normal limits.',
                    style: TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              final isP0 = incident.severity == Priority.p0Critical;
              final accentColor = isP0 ? ResQTheme.sosRed : ResQTheme.warningOrange;

              final receipts = widget.incidentService.getReceiptsForIncident(
                incident.incidentId,
                incident.incidentRevision,
              );

              final totalMembers = widget.sessionProvider.authorizedMembers.length;
              final ackedCount = receipts.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  incident.severity.label,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                incident.type,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ResQTheme.surfaceBorder,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Revision ${incident.incidentRevision}',
                              style: const TextStyle(fontSize: 11, color: ResQTheme.meshCyan),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Origin Node: ${incident.sourceUserId.substring(0, 8)} • Module: ${incident.sourceModule}',
                        style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        'Confirmation: ${incident.confirmationStatus.name} • Status: ${incident.status.name}',
                        style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                      ),
                      if (incident.locationContext != null)
                        Text(
                          'Location: ${incident.locationContext!.latitude.toStringAsFixed(5)}, ${incident.locationContext!.longitude.toStringAsFixed(5)} (±${incident.locationContext!.accuracyMeters.toStringAsFixed(0)}m)',
                          style: const TextStyle(color: ResQTheme.meshCyan, fontSize: 12),
                        ),
                      const Divider(height: 20),

                      // Exact Revision Delivery Accounting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exact Receipts: $ackedCount / ${totalMembers > 1 ? totalMembers - 1 : 1} acknowledged',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ackedCount > 0 ? 'DELIVERED TO MESH' : 'QUEUED IN OUTBOX',
                            style: TextStyle(
                              fontSize: 11,
                              color: ackedCount > 0 ? ResQTheme.safeGreen : Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: const Text('Acknowledge'),
                              onPressed: () async {
                                await widget.incidentService.acknowledgeIncident(
                                  incident.incidentId,
                                  incident.incidentRevision,
                                );
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exact-revision receipt recorded!')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                              label: const Text('Volunteer Help'),
                              style: ElevatedButton.styleFrom(backgroundColor: ResQTheme.safeGreen),
                              onPressed: () async {
                                await widget.incidentService.volunteerHelp(
                                  incident.incidentId,
                                  incident.incidentRevision,
                                );
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Help volunteered for this incident!')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
