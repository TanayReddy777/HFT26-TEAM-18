import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../core/contracts/mesh_transport.dart';
import '../core/contracts/session_provider.dart';
import '../core/contracts/location_provider.dart';
import '../core/contracts/power_policy_provider.dart';
import '../core/contracts/incident_service.dart';
import '../core/contracts/safety_check_coordinator.dart';
import '../core/models/risk_zone.dart';
import '../core/session/session_coordinator.dart';
import '../core/location/location_coordinator.dart';
import '../core/storage/local_database.dart';
import '../core/safety_checks/safety_check_coordinator_impl.dart';
import '../features/mesh/mesh_engine.dart';
import '../features/group_tracking/meeting_point_manager.dart';
import '../features/group_tracking/proximity_calculator.dart';
import '../features/group_tracking/fall_detection_state_machine.dart';
import '../features/intelligence/language_manager.dart';
import '../features/intelligence/local_translator.dart';
import '../features/power_safety/risk_zone_evaluator.dart';
import '../features/power_safety/battery_monitor.dart';
import '../features/sos/incident_coordinator.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/group_screen.dart';
import '../presentation/screens/chat_screen.dart';
import '../presentation/screens/incidents_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/demo_screen.dart';
import '../presentation/widgets/safety_check_modal.dart';
import '../testing/fakes/fake_mesh_transport.dart';
import '../testing/fakes/multi_node_simulation_network.dart';

class ResQApp extends StatefulWidget {
  const ResQApp({super.key});

  @override
  State<ResQApp> createState() => _ResQAppState();
}

class _ResQAppState extends State<ResQApp> {
  int _currentIndex = 0;

  // Single shared database and infrastructure instances
  late final LocalDatabase _database;
  late final SessionCoordinator _sessionCoordinator;
  late final LocationCoordinator _locationCoordinator;
  late final MeshEngine _meshEngine;
  late final IncidentCoordinator _incidentCoordinator;
  late final SafetyCheckCoordinatorImpl _safetyCoordinator;
  late final MeetingPointManager _meetingPointManager;
  late final ProximityCalculator _proximityCalculator;
  late final FallDetectionStateMachine _fallStateMachine;
  late final LanguageManager _languageManager;
  late final LocalTranslator _translator;
  late final RiskZoneEvaluator _riskZoneEvaluator;
  late final BatteryMonitor _batteryMonitor;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _database = LocalDatabase();

    // Seed default offline risk zones
    await _database.saveRiskZone(const RiskZone(
      id: 'ZONE_RED_RIVER',
      name: 'Krishna Riverbed Flashflood Zone',
      centerLatitude: 16.5062,
      centerLongitude: 80.6480,
      radiusMeters: 450.0,
      riskLevel: RiskLevel.red,
      description: 'Active flashflood inundation alert',
      sourceProvenance: 'NDRF Disaster Geofence Dataset',
    ));

    await _database.saveRiskZone(const RiskZone(
      id: 'ZONE_ORANGE_LANDSLIDE',
      name: 'Ghat Pass Cliffside',
      centerLatitude: 16.5180,
      centerLongitude: 80.6620,
      radiusMeters: 300.0,
      riskLevel: RiskLevel.orange,
      description: 'Rockfall and landslide hazard path',
      sourceProvenance: 'Offline Topo Map Layer',
    ));

    _sessionCoordinator = SessionCoordinator();
    await _sessionCoordinator.createSession(
      displayName: 'Captain ResQ',
      groupSecret: 'resq_hackathon_demo_key',
    );

    _locationCoordinator = LocationCoordinator();

    // Default simulation/test harness transport
    final simNetwork = MultiNodeSimulationNetwork();
    final transport = FakeMeshTransport(
      nodeId: _sessionCoordinator.localNodeId,
      network: simNetwork,
    );

    _meshEngine = MeshEngine(
      localNodeId: _sessionCoordinator.localNodeId,
      sessionId: _sessionCoordinator.currentSessionId,
      sharedSecret: _sessionCoordinator.sharedGroupSecret,
      transport: transport,
      database: _database,
    );
    await _meshEngine.initialize();

    _incidentCoordinator = IncidentCoordinator(
      database: _database,
      sessionProvider: _sessionCoordinator,
      locationProvider: _locationCoordinator,
      meshEngine: _meshEngine,
    );

    _safetyCoordinator = SafetyCheckCoordinatorImpl(
      incidentService: _incidentCoordinator,
    );

    _meetingPointManager = MeetingPointManager(
      database: _database,
      localNodeId: _sessionCoordinator.localNodeId,
      isLeaderCheck: () => _sessionCoordinator.isLeader,
    );

    _proximityCalculator = ProximityCalculator(
      warningDistance: 50.0,
      criticalDistance: 100.0,
    );

    _fallStateMachine = FallDetectionStateMachine(
      safetyCoordinator: _safetyCoordinator,
      incidentService: _incidentCoordinator,
      localUserId: _sessionCoordinator.localNodeId,
    );

    _languageManager = LanguageManager();
    _translator = LocalTranslator(languageManager: _languageManager);

    _riskZoneEvaluator = RiskZoneEvaluator(database: _database);

    _batteryMonitor = BatteryMonitor(
      incidentService: _incidentCoordinator,
      locationProvider: _locationCoordinator,
      safetyCoordinator: _safetyCoordinator,
      riskZoneEvaluator: _riskZoneEvaluator,
    );
    await _batteryMonitor.initialize();

    // Enroll a sample authorized offline peer
    _sessionCoordinator.enrollPeer(
      memberId: 'PEER_ANIL',
      displayName: 'Anil Kumar',
      publicKey: 'pk_anil_998',
      isLeader: false,
    );

    // Listen for Safety Check Requests
    _safetyCoordinator.activeCheckStream.listen((check) {
      if (check != null && mounted) {
        _showSafetyCheckDialog(check);
      }
    });

    setState(() {
      _isInitialized = true;
    });
  }

  void _showSafetyCheckDialog(SafetyCheckRequest request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SafetyCheckDialog(
        request: request,
        onResponse: (response) {
          Navigator.of(ctx).pop();
          _safetyCoordinator.respondToCheck(request.id, response);
        },
        onSnooze: (seconds) {
          Navigator.of(ctx).pop();
          _safetyCoordinator.snoozeCheck(request.id, seconds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        theme: ResQTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final screens = [
      HomeScreen(
        sessionProvider: _sessionCoordinator,
        incidentService: _incidentCoordinator,
        locationProvider: _locationCoordinator,
        powerProvider: _batteryMonitor,
        onNavigateToIncidents: () => setState(() => _currentIndex = 3),
        onNavigateToDemo: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DemoScreen()),
        ),
      ),
      GroupScreen(
        sessionProvider: _sessionCoordinator,
        locationProvider: _locationCoordinator,
        meetingPointManager: _meetingPointManager,
        proximityCalculator: _proximityCalculator,
      ),
      ChatScreen(
        sessionProvider: _sessionCoordinator,
        intelligenceService: _translator,
      ),
      IncidentsScreen(
        incidentService: _incidentCoordinator,
        sessionProvider: _sessionCoordinator,
      ),
      SettingsScreen(
        languageManager: _languageManager,
        proximityCalculator: _proximityCalculator,
        database: _database,
      ),
    ];

    return MaterialApp(
      title: 'ResQ Emergency Mesh',
      debugShowCheckedModeBanner: false,
      theme: ResQTheme.darkTheme,
      home: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: ResQTheme.surfaceCard,
          indicatorColor: ResQTheme.meshCyan.withOpacity(0.2),
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_rounded),
              label: 'Group',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_rounded),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Incidents',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
