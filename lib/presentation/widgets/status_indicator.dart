import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/power_state.dart';

class StatusIndicatorBar extends StatelessWidget {
  final PowerState powerState;
  final double? gpsAccuracy;
  final int connectedPeersCount;
  final String cloudStatus;

  const StatusIndicatorBar({
    super.key,
    required this.powerState,
    this.gpsAccuracy,
    required this.connectedPeersCount,
    required this.cloudStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ResQTheme.surfaceCard,
        border: const Border(bottom: BorderSide(color: ResQTheme.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Battery
          Row(
            children: [
              Icon(
                powerState.isCharging
                    ? Icons.battery_charging_full_rounded
                    : (powerState.percentage < 15
                        ? Icons.battery_alert_rounded
                        : Icons.battery_std_rounded),
                color: powerState.percentage < 15 ? ResQTheme.sosRed : ResQTheme.safeGreen,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${powerState.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // GPS Accuracy
          Row(
            children: [
              Icon(
                gpsAccuracy != null ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                color: gpsAccuracy != null && gpsAccuracy! <= 20
                    ? ResQTheme.safeGreen
                    : ResQTheme.warningOrange,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                gpsAccuracy != null ? '±${gpsAccuracy!.toStringAsFixed(0)}m' : 'No GPS Fix',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Mesh Peers
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: ResQTheme.meshCyan, size: 18),
              const SizedBox(width: 4),
              Text(
                '$connectedPeersCount Peers',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Cloud Sync (Offline vs Synced)
          Row(
            children: [
              Icon(
                cloudStatus == 'Unconfigured' || cloudStatus == 'Offline'
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
                color: ResQTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                cloudStatus,
                style: const TextStyle(fontSize: 11, color: ResQTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
