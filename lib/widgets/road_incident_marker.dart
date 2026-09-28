import 'package:flutter/material.dart';

import 'report_incident_sheet.dart';

/// Shared marker for published reports and explicitly labelled draft previews.
class RoadIncidentMarker extends StatelessWidget {
  const RoadIncidentMarker({
    super.key,
    required this.type,
    required this.onTap,
    this.published = false,
    this.nearRoute = false,
  });

  final IncidentType type;
  final bool published;
  final bool nearRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = published
        ? '${type.label}: reporte publicado${nearRoute ? ', cerca de tu ruta' : ''}'
        : '${type.label}: borrador sin publicar';
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Material(
          color: colors.surface,
          elevation: 3,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.primary, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(type.icon, color: colors.primary, size: 26),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Icon(
                    nearRoute
                        ? Icons.route
                        : published
                        ? Icons.check_circle
                        : Icons.edit,
                    size: 12,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
