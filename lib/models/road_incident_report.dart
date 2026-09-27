import 'package:latlong2/latlong.dart';

import 'incident_report_draft.dart';

class RoadIncidentReport {
  const RoadIncidentReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.coordinates,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.description,
  });
  final String id, userId, status;
  final IncidentType type;
  final LatLng coordinates;
  final String? description;
  final DateTime createdAt, expiresAt;

  bool isActiveAt(DateTime now) => status == 'activo' && expiresAt.isAfter(now);

  static bool validCoordinates(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  factory RoadIncidentReport.fromMap(Map<String, dynamic> map) {
    final latitude = (map['latitud'] as num).toDouble();
    final longitude = (map['longitud'] as num).toDouble();
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw const FormatException('Coordenadas inválidas');
    }
    final point = LatLng(latitude, longitude);
    return RoadIncidentReport(
      id: map['id'] as String,
      userId: map['usuario_id'] as String,
      type: IncidentType.fromDatabase(map['tipo']),
      coordinates: point,
      description: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String).toUtc(),
      expiresAt: DateTime.parse(map['expira_en'] as String).toUtc(),
      status: map['estado'] as String,
    );
  }
}
