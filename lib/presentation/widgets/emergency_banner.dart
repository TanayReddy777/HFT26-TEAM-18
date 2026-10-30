import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/incident_snapshot.dart';
import '../../core/constants/priorities.dart';

class EmergencyBanner extends StatelessWidget {
  final List<IncidentSnapshot> activeIncidents;
  final VoidCallback onTapViewAll;

  const EmergencyBanner({
    super.key,
    required this.activeIncidents,
    required this.onTapViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activeIncidents.isEmpty) {
      return const SizedBox.shrink();
    }

    // Select the highest priority active incident
    final topIncident = activeIncidents.firstWhere(
      (inc) => inc.severity == Priority.p0Critical,
      orElse: () => activeIncidents.first,
    );

    final isP0 = topIncident.severity == Priority.p0Critical;
    final bannerColor = isP0 ? ResQTheme.sosRed : ResQTheme.warningOrange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isP0 ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: bannerColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      topIncident.type,
                      style: TextStyle(
                        color: bannerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bannerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rev ${topIncident.incidentRevision}',
                        style: TextStyle(color: bannerColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Origin: ${topIncident.sourceUserId.substring(0, 8)} • Status: ${topIncident.confirmationStatus.name}',
                  style: const TextStyle(color: ResQTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTapViewAll,
            child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
