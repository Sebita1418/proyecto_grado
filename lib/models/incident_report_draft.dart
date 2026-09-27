import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Categories of road incidents and conditions for community reporting.
enum IncidentType {
  accident('accident', 'Accidente', Icons.car_crash_outlined),
  congestion('congestion', 'Congestión', Icons.traffic_outlined),
  roadWork('road_work', 'Obra en la vía', Icons.construction_outlined),
  roadClosed('road_closed', 'Vía cerrada', Icons.block_outlined),
  hazard('hazard', 'Peligro / Obstáculo', Icons.warning_amber_outlined),
  other('other', 'Otro', Icons.info_outline);

  const IncidentType(this.databaseValue, this.label, this.icon);
  final String databaseValue;
  static IncidentType fromDatabase(Object? value) => values.firstWhere(
    (type) => type.databaseValue == value,
    orElse: () => other,
  );
  final String label;
  final IconData icon;
}

/// Clean draft contract for incident reports.
///
/// Collects user input for road report publication
/// without fabricating coordinates or database records.
class IncidentReportDraft {
  const IncidentReportDraft({
    this.type,
    this.coordinates,
    this.description,
    this.manualLocation = false,
  });

  final IncidentType? type;
  final LatLng? coordinates;
  final String? description;
  final bool manualLocation;
}
