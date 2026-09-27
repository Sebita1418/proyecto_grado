import 'package:flutter/material.dart';

import 'report_incident_sheet.dart';
import '../models/road_incident_report.dart';

class RoadIncidentDetailsSheet extends StatelessWidget {
  const RoadIncidentDetailsSheet({super.key, this.draft, this.report})
    : assert((draft == null) != (report == null));

  final IncidentReportDraft? draft;
  final RoadIncidentReport? report;
  IncidentType get type => report?.type ?? draft!.type!;
  String? get description => report?.description ?? draft?.description;
  String get createdLabel {
    final date = report!.createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Publicado el ${two(date.day)}/${two(date.month)}/${date.year} a las ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(type.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar detalle',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report == null
                ? 'Borrador sin publicar'
                : 'Reporte publicado · Activo',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(description!),
          ],
          const SizedBox(height: 12),
          Text(
            report == null
                ? 'Solo visible en esta sesión del mapa. Envío de reportes pendiente de habilitación.'
                : createdLabel,
          ),
        ],
      ),
    ),
  );
}
