import 'package:flutter/material.dart';

import '../controllers/road_incident_controller.dart';
import '../models/road_incident_report.dart';

/// Reads the Home controller; opening this sheet creates no subscriptions.
class RoadIncidentReportsSheet extends StatelessWidget {
  const RoadIncidentReportsSheet({
    super.key,
    required this.controller,
    required this.onCreate,
  });

  final RoadIncidentController controller;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Reportes de la vía',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar reportes',
                  onPressed: controller.loading ? null : controller.refresh,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Cerrar reportes',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (controller.loading)
            const LinearProgressIndicator(semanticsLabel: 'Cargando reportes'),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Text(controller.error!),
              ),
            ),
          Flexible(
            child: controller.reports.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      controller.loading
                          ? 'Buscando novedades de la vía…'
                          : controller.ready
                          ? 'No hay reportes activos disponibles.'
                          : 'Los reportes no están disponibles. Puedes reintentar o preparar un borrador.',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.reports.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = controller.reports[index];
                      return ListTile(
                        leading: Icon(report.type.icon),
                        title: Text(report.type.label),
                        subtitle: Text(
                          report.description?.isNotEmpty == true
                              ? report.description!
                              : 'Reporte activo · Ver ubicación y detalles',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pop<RoadIncidentReport>(context, report),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Reportar novedad'),
            ),
          ),
        ],
      ),
    ),
  );
}
