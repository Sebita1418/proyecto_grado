import 'package:flutter/material.dart';

import '../controllers/road_incident_controller.dart';
import '../models/road_incident_report.dart';
import '../models/incident_report_draft.dart';

/// Reads the Home controller; opening this sheet creates no subscriptions.
class RoadIncidentReportsSheet extends StatefulWidget {
  const RoadIncidentReportsSheet({
    super.key,
    required this.controller,
    required this.onCreate,
  });

  final RoadIncidentController controller;
  final VoidCallback onCreate;

  @override
  State<RoadIncidentReportsSheet> createState() =>
      _RoadIncidentReportsSheetState();
}

class _RoadIncidentReportsSheetState extends State<RoadIncidentReportsSheet> {
  IncidentType? _type;
  RoadIncidentController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final reports =
            controller.reports
                .where((report) => _type == null || report.type == _type)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
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
              const LinearProgressIndicator(
                semanticsLabel: 'Cargando reportes',
              ),
            if (controller.reports.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Todos (${controller.reports.length})'),
                      selected: _type == null,
                      onSelected: (_) => setState(() => _type = null),
                    ),
                    for (final type in IncidentType.values)
                      if (type == _type ||
                          controller.reports.any(
                            (report) => report.type == type,
                          ))
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            avatar: Icon(type.icon, size: 18),
                            label: Text(type.label),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                        ),
                  ],
                ),
              ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(controller.error!),
                ),
              ),
            Flexible(
              child: reports.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.error == null
                                ? Icons.explore_outlined
                                : Icons.cloud_off_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.loading
                                ? 'Buscando novedades de la vía…'
                                : _type != null && controller.reports.isNotEmpty
                                ? 'No hay reportes de esta categoría.'
                                : controller.ready
                                ? 'No hay reportes activos disponibles.'
                                : 'Los reportes no están disponibles. Puedes reintentar o preparar un borrador.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (controller.ready && !controller.loading)
                            const Text(
                              'Las nuevas novedades aparecerán aquí cuando estén disponibles.',
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              report.type.icon,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          title: Text(report.type.label),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (report.description?.trim().isNotEmpty == true)
                                Text(
                                  report.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _dateLabel(context, report),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Text('Ver en el mapa'),
                            ],
                          ),
                          trailing: const Icon(Icons.map_outlined),
                          onTap: () => Navigator.pop<RoadIncidentReport>(
                            context,
                            report,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: widget.onCreate,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Reportar novedad'),
              ),
            ),
          ],
        );
      },
    ),
  );

  String _dateLabel(BuildContext context, RoadIncidentReport report) {
    final date = report.createdAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatCompactDate(date)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }
}
