import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/contracts/session_provider.dart';
import '../../core/contracts/location_provider.dart';
import '../../core/location/haversine.dart';
import '../../features/group_tracking/meeting_point_manager.dart';
import '../../features/group_tracking/proximity_calculator.dart';
import '../widgets/bearing_indicator.dart';

class GroupScreen extends StatefulWidget {
  final SessionProvider sessionProvider;
  final LocationProvider locationProvider;
  final MeetingPointManager meetingPointManager;
  final ProximityCalculator proximityCalculator;

  const GroupScreen({
    super.key,
    required this.sessionProvider,
    required this.locationProvider,
    required this.meetingPointManager,
    required this.proximityCalculator,
  });

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _boundaryAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final members = widget.sessionProvider.authorizedMembers;
    final ownFix = widget.locationProvider.latestFix;
    final guidance = widget.meetingPointManager.calculateGuidance(
      ownFix?.latitude,
      ownFix?.longitude,
    );
    final meetingPoint = widget.meetingPointManager.currentMeetingPoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group & Meeting Point'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meeting Point Guidance Card
          if (guidance != null) ...[
            BearingIndicatorCard(guidance: guidance),
            const SizedBox(height: 12),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_rounded, color: ResQTheme.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meetingPoint?.isRemoval ?? true
                            ? 'No active meeting point set for this session.'
                            : 'Waiting for own GPS fix for meeting point guidance.',
                        style: const TextStyle(color: ResQTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Leader Controls (Authority Verified)
          if (widget.sessionProvider.isLeader) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Leader Point Authority',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (meetingPoint != null && !meetingPoint.isRemoval)
                          Text(
                            'Rev ${meetingPoint.sessionRevision}',
                            style: const TextStyle(
                              color: ResQTheme.meshCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_location_alt_rounded),
                            label: const Text('Set Current GPS'),
                            onPressed: ownFix == null
                                ? null
                                : () async {
                                    await widget.meetingPointManager.createOrUpdateMeetingPoint(
                                      name: 'Rendezvous Point Alpha',
                                      latitude: ownFix.latitude,
                                      longitude: ownFix.longitude,
                                      accuracyMeters: ownFix.accuracyMeters,
                                      suggestedRadius: 100.0,
                                    );
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Meeting point revision broadcasted!')),
                                    );
                                  },
                          ),
                        ),
                        if (meetingPoint != null && !meetingPoint.isRemoval) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: ResQTheme.sosRed),
                            tooltip: 'Remove Meeting Point',
                            onPressed: () async {
                              await widget.meetingPointManager.removeMeetingPoint(
                                meetingPoint.pointId,
                                meetingPoint.sessionRevision + 1,
                                widget.sessionProvider.localNodeId,
                              );
                              setState(() {});
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Boundary Alert Switch
          SwitchListTile(
            title: const Text('Local Boundary Alerts'),
            subtitle: const Text('Alert if separated beyond meeting point radius (Local warning)'),
            value: _boundaryAlertsEnabled,
            activeColor: ResQTheme.meshCyan,
            onChanged: (val) {
              setState(() {
                _boundaryAlertsEnabled = val;
              });
            },
          ),
          const SizedBox(height: 16),

          const Text(
            'Authorized Members & Distance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...members.map((member) {
            final isSelf = member.id == widget.sessionProvider.localNodeId;
            final proximity = widget.proximityCalculator.evaluatePeerProximity(
              ownFix: ownFix,
              peer: member,
            );

            Color badgeColor = ResQTheme.safeGreen;
            if (proximity.assessment.state == SeparationState.criticalSeparation) {
              badgeColor = ResQTheme.sosRed;
            } else if (proximity.assessment.state == SeparationState.warningSeparation) {
              badgeColor = ResQTheme.warningOrange;
            } else if (proximity.assessment.state == SeparationState.distanceUncertain) {
              badgeColor = Colors.purpleAccent;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelf ? ResQTheme.meshCyan : ResQTheme.surfaceBorder,
                  child: Icon(
                    isSelf ? Icons.person : Icons.person_outline,
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.displayName + (isSelf ? ' (You)' : ''),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                    if (member.isPrimaryBuddy) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'BUDDY',
                        style: TextStyle(
                          color: ResQTheme.meshCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  isSelf
                      ? 'Local Node • Fix: ±${ownFix?.accuracyMeters.toStringAsFixed(0) ?? '?'}m'
                      : proximity.assessment.description,
                  style: TextStyle(color: isSelf ? ResQTheme.textSecondary : badgeColor, fontSize: 13),
                ),
                trailing: !isSelf
                    ? IconButton(
                        icon: Icon(
                          member.isPrimaryBuddy ? Icons.favorite : Icons.favorite_border,
                          color: member.isPrimaryBuddy ? ResQTheme.sosRed : ResQTheme.textSecondary,
                        ),
                        tooltip: 'Set as Primary Buddy',
                        onPressed: () {
                          widget.sessionProvider.setPrimaryBuddy(member.id);
                          setState(() {});
                        },
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
