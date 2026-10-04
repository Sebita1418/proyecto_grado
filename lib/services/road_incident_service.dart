import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident_report_draft.dart';
import '../models/road_incident_report.dart';

class RoadIncidentService {
  RoadIncidentService({SupabaseClient? client}) : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;
  static const table = 'reportes_viales';

  Future<RoadIncidentReport> createReport(IncidentReportDraft draft) async {
    final point = draft.coordinates;
    if (draft.type == null ||
        point == null ||
        !RoadIncidentReport.validCoordinates(point) ||
        (draft.description?.runes.length ?? 0) > 200) {
      throw const FormatException('Reporte inválido');
    }
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Se requiere una sesión autenticada');
    final row = await _client
        .from(table)
        .insert({
          'usuario_id': user.id,
          'tipo': draft.type!.databaseValue,
          'latitud': point.latitude,
          'longitud': point.longitude,
          'descripcion': draft.description?.trim().isEmpty == true
              ? null
              : draft.description?.trim(),
        })
        .select()
        .single()
        .timeout(const Duration(seconds: 20));
    return RoadIncidentReport.fromMap(row);
  }

  Future<List<RoadIncidentReport>> fetchActiveReports() async {
    // RLS uses the server clock to exclude expired rows, even for direct REST calls.
    final rows = await _client
        .from(table)
        .select()
        .eq('estado', 'activo')
        .order('creado_en', ascending: false)
        .limit(100)
        .timeout(const Duration(seconds: 20));
    final reports = <RoadIncidentReport>[];
    for (final row in rows) {
      try {
        final report = RoadIncidentReport.fromMap(row);
        if (report.isActiveAt(DateTime.now().toUtc())) reports.add(report);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return reports;
  }

  /// Events only invalidate the small active list; GPS never queries Supabase.
  Stream<void> watchChanges() {
    late StreamController<void> events;
    RealtimeChannel? channel;
    var connectedOnce = false;
    var cancelled = false;
    events = StreamController<void>(
      onListen: () {
        try {
          channel = _client
              .channel('road-reports-${identityHashCode(events)}')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: table,
                callback: (_) {
                  if (!cancelled) events.add(null);
                },
              )
              .subscribe((status, error) {
                if (cancelled) return;
                if (status == RealtimeSubscribeStatus.subscribed) {
                  if (connectedOnce) events.add(null);
                  connectedOnce = true;
                } else if (status == RealtimeSubscribeStatus.channelError ||
                    status == RealtimeSubscribeStatus.timedOut) {
                  events.addError(StateError('Realtime no disponible'));
                }
              });
        } catch (error) {
          events.addError(error);
        }
      },
      onCancel: () async {
        cancelled = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return events.stream;
  }
}
