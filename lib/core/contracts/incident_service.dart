import '../models/incident_snapshot.dart';
import '../models/receipt.dart';
import '../constants/priorities.dart';

abstract class IncidentService {
  List<IncidentSnapshot> get activeIncidents;
  Stream<List<IncidentSnapshot>> get incidentsStream;

  Future<IncidentSnapshot> submitIncident({
    required String sourceModule,
    required String eventCode,
    required Priority severity,
    required bool explicitSos,
    String? relatedUserId,
    String? reason,
  });

  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required ConfirmationStatus newConfirmation,
    String? newEventCode,
  });

  Future<void> handleIncomingIncident(IncidentSnapshot incident);
  Future<void> acknowledgeIncident(String incidentId, int revision);
  Future<void> volunteerHelp(String incidentId, int revision);
  List<Receipt> getReceiptsForIncident(String incidentId, int revision);
}
