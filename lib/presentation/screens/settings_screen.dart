import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../features/intelligence/language_manager.dart';
import '../../features/group_tracking/proximity_calculator.dart';
import '../../core/storage/local_database.dart';

class SettingsScreen extends StatefulWidget {
  final LanguageManager languageManager;
  final ProximityCalculator proximityCalculator;
  final LocalDatabase database;

  const SettingsScreen({
    super.key,
    required this.languageManager,
    required this.proximityCalculator,
    required this.database,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _fallDetectionEnabled = true;

  @override
  Widget build(BuildContext context) {
    final packs = widget.languageManager.getAllPacks();
    final zones = widget.database.getAllRiskZones();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Offline Readiness'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline Language Packs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.downloading_rounded, color: ResQTheme.meshCyan),
                      SizedBox(width: 8),
                      Text(
                        'Offline Translation Packs',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Download your preferred language packs before entering an area without internet connectivity.',
                    style: TextStyle(color: ResQTheme.textSecondary, fontSize: 12),
                  ),
                  const Divider(height: 20),
                  ...packs.map((pack) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(pack.name),
                      subtitle: Text(
                        pack.isDownloaded ? 'Downloaded & Ready' : 'Not downloaded (Requires Internet)',
                        style: TextStyle(
                          fontSize: 11,
                          color: pack.isDownloaded ? ResQTheme.safeGreen : ResQTheme.textSecondary,
                        ),
                      ),
                      trailing: pack.isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (pack.isDownloaded
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: ResQTheme.sosRed, size: 20),
                                  onPressed: () async {
                                    await widget.languageManager.deletePack(pack.code);
                                    setState(() {});
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download_rounded, color: ResQTheme.meshCyan, size: 20),
                                  onPressed: () async {
                                    await widget.languageManager.downloadPack(pack.code);
                                    setState(() {});
                                  },
                                )),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Proximity & Separation Thresholds
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.social_distance_rounded, color: ResQTheme.warningOrange),
                      SizedBox(width: 8),
                      Text(
                        'Separation Alert Thresholds',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Warning Distance: ${widget.proximityCalculator.warningDistance.toStringAsFixed(0)}m'),
                  Slider(
                    value: widget.proximityCalculator.warningDistance,
                    min: 20,
                    max: 80,
                    divisions: 6,
                    activeColor: ResQTheme.warningOrange,
                    onChanged: (val) {
                      setState(() {
                        widget.proximityCalculator.updateThresholds(
                          val,
                          widget.proximityCalculator.criticalDistance,
                        );
                      });
                    },
                  ),
                  Text('Critical Distance: ${widget.proximityCalculator.criticalDistance.toStringAsFixed(0)}m'),
                  Slider(
                    value: widget.proximityCalculator.criticalDistance,
                    min: 90,
                    max: 200,
                    divisions: 11,
                    activeColor: ResQTheme.sosRed,
                    onChanged: (val) {
                      setState(() {
                        widget.proximityCalculator.updateThresholds(
                          widget.proximityCalculator.warningDistance,
                          val,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Motion & Fall Detection
          Card(
            child: SwitchListTile(
              title: const Text('Experimental Fall Detection'),
              subtitle: const Text('Uses accelerometer for impact and stillness detection. Subject to phone drop false positives.'),
              value: _fallDetectionEnabled,
              activeColor: ResQTheme.meshCyan,
              onChanged: (val) {
                setState(() {
                  _fallDetectionEnabled = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Offline Risk Zones List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: ResQTheme.safeGreen),
                      SizedBox(width: 8),
                      Text(
                        'Local Offline Risk Zones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Circular geofenced hazard areas stored locally. Low battery in RED zones triggers mandatory safety checks.',
                    style: TextStyle(color: ResQTheme.textSecondary, fontSize: 12),
                  ),
                  const Divider(height: 20),
                  ...zones.map((zone) {
                    Color zoneColor = ResQTheme.safeGreen;
                    if (zone.riskLevel.name == 'red') zoneColor = ResQTheme.sosRed;
                    if (zone.riskLevel.name == 'orange') zoneColor = ResQTheme.warningOrange;
                    if (zone.riskLevel.name == 'yellow') zoneColor = Colors.amber;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle, color: zoneColor, size: 14),
                      title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Radius: ${zone.radiusMeters.toStringAsFixed(0)}m • ${zone.sourceProvenance}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        zone.riskLevel.name.toUpperCase(),
                        style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
