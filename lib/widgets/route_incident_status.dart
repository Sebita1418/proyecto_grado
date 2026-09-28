import 'package:flutter/material.dart';

import '../mobility/route_incident_analysis.dart';
import 'road_incident_details_sheet.dart';

class RouteIncidentStatus extends StatelessWidget {
  const RouteIncidentStatus({super.key, this.analysis});
  final RouteIncidentAnalysis? analysis;

  void _showReports(BuildContext context) {
    final snapshot = analysis!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Reportes próximos a esta alternativa · proximidad geométrica, no bloqueo confirmado',
              ),
            ),
            for (final item in snapshot.incidents)
              ListTile(
                leading: Icon(item.report.type.icon),
                title: Text(item.report.type.label),
                subtitle: Text(
                  'Aproximadamente ${item.distanceMeters.round()} m del recorrido',
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    maxHeight: MediaQuery.sizeOf(context).height * .8,
                  ),
                  builder: (_) => RoadIncidentDetailsSheet(report: item.report),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: InkWell(
      onTap: analysis != null && analysis!.total > 0
          ? () => _showReports(context)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            analysis?.hasRoadClosure == true
                ? Icons.block_outlined
                : Icons.info_outline,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              analysis?.summary ?? 'Reportes no disponibles; comparación por duración y distancia.',
            ),
          ),
        ],
      ),
    ),
  );
}
