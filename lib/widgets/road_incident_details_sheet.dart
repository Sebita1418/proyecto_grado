import 'package:flutter/material.dart';

import 'report_incident_sheet.dart';

class RoadIncidentDetailsSheet extends StatelessWidget {
  const RoadIncidentDetailsSheet({super.key, required this.draft});

  final IncidentReportDraft draft;

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
              Icon(
                draft.type!.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  draft.type!.label,
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
          const Text(
            'Borrador sin publicar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (draft.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(draft.description!),
          ],
          const SizedBox(height: 12),
          const Text(
            'Solo visible en esta sesión del mapa. Envío de reportes pendiente de habilitación.',
          ),
        ],
      ),
    ),
  );
}
