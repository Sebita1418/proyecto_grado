import '../models/incident_report_draft.dart';
import '../models/road_incident_report.dart';

class RouteIncidentProximity {
  const RouteIncidentProximity(this.report, this.distanceMeters);
  final RoadIncidentReport report;
  final double distanceMeters;
}

/// Snapshot of geometric proximity, not proof of an obstruction or delay.
class RouteIncidentAnalysis {
  RouteIncidentAnalysis({
    required this.routeId,
    required this.evaluatedAt,
    required List<RouteIncidentProximity> incidents,
  }) : incidents = List.unmodifiable(incidents);

  final String routeId;
  final DateTime evaluatedAt;
  final List<RouteIncidentProximity> incidents;
  int get total => incidents.length;
  Map<IncidentType, int> get categories => Map.unmodifiable({
    for (final type in IncidentType.values)
      if (incidents.any((item) => item.report.type == type))
        type: incidents.where((item) => item.report.type == type).length,
  });
  bool get hasRoadClosure => categories.containsKey(IncidentType.roadClosed);
  String get summary => total == 0
      ? 'Sin reportes activos próximos'
      : '$total ${total == 1 ? 'reporte activo próximo' : 'reportes activos próximos'}'
            ' · ${categories.entries.map((e) => '${e.key.label}: ${e.value}').join(', ')}'
            '${hasRoadClosure ? '\nCierre vial reportado próximo al recorrido' : ''}';
}
