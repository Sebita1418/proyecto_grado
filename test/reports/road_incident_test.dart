import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transporte_inteligente/controllers/road_incident_controller.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/services/road_incident_service.dart';

Map<String, dynamic> reportRow({String id = 'report-id'}) => {
  'id': id,
  'usuario_id': 'private-user-id',
  'tipo': 'accident',
  'latitud': 7.1,
  'longitud': -73.1,
  'descripcion': 'Carril derecho',
  'estado': 'activo',
  'creado_en': DateTime.now().toUtc().toIso8601String(),
  'expira_en': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 6))
      .toIso8601String(),
};
const draft = IncidentReportDraft(
  type: IncidentType.accident,
  coordinates: LatLng(7.1, -73.1),
  description: 'Carril derecho',
);

class FakeRoadIncidents extends RoadIncidentService {
  List<RoadIncidentReport> rows = [];
  final events = StreamController<void>.broadcast();
  int fetches = 0, creates = 0;
  bool fail = false;
  Completer<RoadIncidentReport>? pendingCreate;
  Completer<List<RoadIncidentReport>>? pendingFetch;
  @override
  Future<List<RoadIncidentReport>> fetchActiveReports() async {
    fetches++;
    if (fail) throw StateError('offline');
    return pendingFetch?.future ?? rows;
  }

  @override
  Future<RoadIncidentReport> createReport(IncidentReportDraft value) async {
    creates++;
    if (fail) throw StateError('offline');
    final result = pendingCreate == null
        ? RoadIncidentReport.fromMap({
            ...reportRow(),
            'latitud': value.coordinates!.latitude,
            'longitud': value.coordinates!.longitude,
            'tipo': value.type!.databaseValue,
            'descripcion': value.description,
          })
        : await pendingCreate!.future;
    rows = [result];
    return result;
  }

  @override
  Stream<void> watchChanges() => events.stream;
}

void main() {
  test('mapping estable, desconocidos, parsing y coordenadas inválidas', () {
    expect(IncidentType.values.map((v) => v.databaseValue), [
      'accident',
      'congestion',
      'road_work',
      'road_closed',
      'hazard',
      'other',
    ]);
    for (final value in IncidentType.values) {
      expect(IncidentType.fromDatabase(value.databaseValue), value);
    }
    expect(IncidentType.fromDatabase('future-type'), IncidentType.other);
    final report = RoadIncidentReport.fromMap(reportRow());
    expect(report.coordinates, draft.coordinates);
    expect(report.createdAt.isUtc, isTrue);
    expect(report.isActiveAt(DateTime.now()), isTrue);
    expect(report.isActiveAt(report.expiresAt), isFalse);
    for (final latitude in [91.0, double.nan, double.infinity]) {
      expect(
        () => RoadIncidentReport.fromMap({...reportRow(), 'latitud': latitude}),
        throwsFormatException,
      );
    }
  });

  test('service hace INSERT autenticado sin fechas/estado y fetch limitado robusto', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.contains('/auth/')) {
          return http.Response(
            jsonEncode({
              'access_token': 'test-access-token',
              'refresh_token': 'test-refresh-token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'private-user-id',
                'aud': 'authenticated',
                'created_at': '2026-01-01T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response(
          jsonEncode(
            request.method == 'POST'
                ? reportRow()
                : [
                    reportRow(),
                    {...reportRow(), 'latitud': 100},
                    {...reportRow(), 'expira_en': '2020-01-01T00:00:00Z'},
                    {...reportRow(), 'creado_en': 'invalid'},
                    {...reportRow(), 'estado': 'cancelado'},
                  ],
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'test@example.test',
      password: 'test-only',
    );
    final service = RoadIncidentService(client: client);
    final created = await service.createReport(draft);
    expect(created.id, 'report-id');
    final insert = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(insert.keys.toSet(), {
      'usuario_id',
      'tipo',
      'latitud',
      'longitud',
      'descripcion',
    });
    expect(insert['usuario_id'], 'private-user-id');
    expect(insert['tipo'], 'accident');
    final fetched = await service.fetchActiveReports();
    expect(fetched.length, 1);
    expect(requests.last.url.queryParameters['limit'], '100');
    expect(requests.last.url.queryParameters['estado'], 'eq.activo');
    final count = requests.length;
    await expectLater(
      service.createReport(const IncidentReportDraft()),
      throwsFormatException,
    );
    expect(requests.length, count);
  });

  test('service no publica sin sesión', () async {
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    await expectLater(
      RoadIncidentService(client: client).createReport(draft),
      throwsStateError,
    );
  });

  testWidgets(
    'controller carga una vez, deduplica, refresca eventos y cancela',
    (tester) async {
      final service = FakeRoadIncidents()
        ..rows = [RoadIncidentReport.fromMap(reportRow())];
      final controller = RoadIncidentController(service);
      await controller.refresh();
      expect(service.fetches, 1);
      expect(service.events.hasListener, isTrue);
      await controller.publish(draft);
      expect(controller.reports.length, 1);
      service.rows = [
        RoadIncidentReport.fromMap(reportRow()),
        RoadIncidentReport.fromMap(reportRow()),
      ];
      service.events.add(null);
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 351));
      expect(service.fetches, 2);
      expect(controller.reports.length, 1);
      service.rows = [];
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 351));
      expect(controller.reports, isEmpty);
      service.events.addError(StateError('realtime offline'));
      await tester.pump();
      expect(controller.error, contains('vivo'));
      controller.dispose();
      expect(service.events.hasListener, isFalse);
      await tester.runAsync(service.events.close);
    },
  );

  testWidgets('controller error, doble publicación, carrera fetch y dispose', (
    tester,
  ) async {
    final service = FakeRoadIncidents()..fail = true;
    final controller = RoadIncidentController(service);
    await controller.refresh();
    expect(controller.ready, isFalse);
    expect(controller.error, isNotNull);
    await expectLater(controller.publish(draft), throwsStateError);
    service.fail = false;
    service.pendingCreate = Completer<RoadIncidentReport>();
    final publish = controller.publish(draft);
    expect(controller.publishing, isTrue);
    await expectLater(controller.publish(draft), throwsStateError);
    expect(service.creates, 2); // first failed + one pending, never a duplicate
    service.pendingFetch = Completer<List<RoadIncidentReport>>();
    final refresh = controller.refresh();
    service.pendingCreate!.complete(RoadIncidentReport.fromMap(reportRow()));
    await publish;
    final pending = service.pendingFetch!;
    service.pendingFetch = null;
    pending.complete([]);
    await refresh;
    await tester.pump();
    expect(controller.reports.single.id, 'report-id');
    service.pendingFetch = Completer<List<RoadIncidentReport>>();
    final lateFetch = controller.refresh();
    controller.dispose();
    service.pendingFetch!.complete([]);
    await lateFetch;
    expect(service.events.hasListener, isFalse);
    await tester.runAsync(service.events.close);
  });

  testWidgets('caducidad local retira marcadores sin hacer polling', (
    tester,
  ) async {
    var now = DateTime.now().toUtc();
    final service = FakeRoadIncidents()
      ..rows = [
        RoadIncidentReport.fromMap({
          ...reportRow(),
          'expira_en': now.add(const Duration(seconds: 10)).toIso8601String(),
        }),
      ];
    final controller = RoadIncidentController(service, now: () => now);
    await controller.refresh();
    expect(controller.reports.length, 1);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(controller.reports, isEmpty);
    expect(service.fetches, 1);
    controller.dispose();
    await tester.runAsync(service.events.close);
  });
}
