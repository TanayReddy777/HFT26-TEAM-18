import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../features/group_tracking/meeting_point_manager.dart';

class BearingIndicatorCard extends StatelessWidget {
  final MeetingPointGuidance guidance;

  const BearingIndicatorCard({
    super.key,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Transform.rotate(
                  angle: guidance.bearingDegrees * (pi / 180.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ResQTheme.meshCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: ResQTheme.meshCyan,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Point • ${guidance.distanceMeters.toStringAsFixed(0)}m ${guidance.cardinalDirection}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ResQTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guidance.isNearDestination
                            ? 'Near destination — Please confirm visually.'
                            : 'Bearing: ${guidance.bearingDegrees.toStringAsFixed(0)}° • Revision ${guidance.revision}',
                        style: TextStyle(
                          fontSize: 13,
                          color: guidance.isNearDestination
                              ? ResQTheme.safeGreen
                              : ResQTheme.textSecondary,
                          fontWeight: guidance.isNearDestination ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: ResQTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      guidance.disclaimer,
                      style: const TextStyle(fontSize: 11, color: ResQTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
