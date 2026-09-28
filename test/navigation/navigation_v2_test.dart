import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/navigation/navigation_instruction.dart';
import 'package:transporte_inteligente/navigation/navigation_instruction_presentation.dart';
import 'package:transporte_inteligente/navigation/navigation_session.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/widgets/navigation_status_card.dart';

const v2Route = RouteResult(
  origin: LatLng(0, 0),
  destination: LatLng(0, .02),
  points: [LatLng(0, 0), LatLng(0, .01), LatLng(0, .02)],
  distanceMeters: 2200,
  durationSeconds: 600,
  instructions: [
    NavigationInstruction(
      type: ManeuverType.depart,
      direction: ManeuverDirection.straight,
      position: LatLng(0, 0),
      distanceMeters: 1100,
      durationSeconds: 300,
      distanceFromStart: 0,
    ),
    NavigationInstruction(
      type: ManeuverType.turn,
      direction: ManeuverDirection.right,
      position: LatLng(0, .01),
      distanceMeters: 1100,
      durationSeconds: 300,
      distanceFromStart: 1100,
      streetName: 'Carrera 27',
    ),
    NavigationInstruction(
      type: ManeuverType.arrive,
      direction: ManeuverDirection.unknown,
      position: LatLng(0, .02),
      distanceMeters: 0,
      durationSeconds: 0,
      distanceFromStart: 2200,
    ),
  ],
);

class V2Gps extends LocationService {
  final updates = StreamController<LocationResult>.broadcast();
  @override
  Stream<LocationResult> watch() => updates.stream;
  void point(LatLng value, {DateTime? at}) => updates.add(
    LocationResult(
      LocationStatus.coordinatesObtained,
      coordinates: value,
      recordedAt: at,
    ),
  );
}

Future<void> tick() => Future<void>.delayed(Duration.zero);
const outside = LatLng(.002, .005);
RouteResult rerouted() => const RouteResult(
  origin: outside,
  destination: LatLng(0, .02),
  points: [outside, LatLng(0, .01), LatLng(0, .02)],
  distanceMeters: 1800,
  durationSeconds: 400,
  instructions: [
    NavigationInstruction(
      type: ManeuverType.arrive,
      direction: ManeuverDirection.unknown,
      position: LatLng(0, .02),
      distanceMeters: 0,
      durationSeconds: 0,
      distanceFromStart: 1800,
    ),
  ],
);

void main() {
  test('OSRM conserva alternativas y steps; desconocidos seguros; steps defectuosos no inventan guía', () async {
    Object step(String type, String modifier, double lng) => {
      'distance': 100,
      'duration': 20,
      'name': '',
      'maneuver': {
        'type': type,
        'modifier': modifier,
        'location': [lng, 0],
      },
    };
    final candidate = {
      'distance': 2200,
      'duration': 600,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [0, 0],
          [.01, 0],
          [.02, 0],
        ],
      },
      'legs': [
        {
          'steps': [
            step('depart', 'straight', 0),
            step('future', 'future', .01),
            step('arrive', '', .02),
          ],
        },
      ],
    };
    final client = MockClient((request) async {
      expect(request.url.queryParameters['steps'], 'true');
      expect(request.url.queryParameters['alternatives'], 'true');
      expect(request.url.queryParameters['geometries'], 'geojson');
      return http.Response(
        jsonEncode({
          'code': 'Ok',
          'routes': [candidate, candidate],
        }),
        200,
      );
    });
    final service = OsrmRoutingService(client: client);
    final results = await service.routeAlternatives(
      origin: v2Route.origin,
      destination: v2Route.destination,
    );
    expect(results.length, 2);
    expect(results.first.instructions.length, 3);
    expect(results.first.instructions[1].type, ManeuverType.unknown);
    expect(
      results.first.instructions[1].instructionText,
      'Sigue la ruta indicada',
    );
    expect(results.first.instructions[1].distanceFromStart, 100);
    final option = RouteOption.fromRouteResult(
      id: '1',
      mode: TransportMode.driving,
      route: results.first,
    );
    expect(option.route.instructions.length, 3);
    candidate['legs'] = [
      {
        'steps': [
          step('depart', 'straight', 0),
          {'maneuver': null},
        ],
      },
    ];
    expect(
      (await service.routeAlternatives(
        origin: v2Route.origin,
        destination: v2Route.destination,
      )).first.instructions,
      isEmpty,
    );
    client.close();
  });

  test('traducción sin calle inventada e iconos según dirección', () {
    expect(
      v2Route.instructions[1].instructionText,
      'Gira a la derecha en Carrera 27',
    );
    expect(v2Route.instructions[1].instructionIcon, Icons.turn_right);
    for (final type in ManeuverType.values) {
      for (final direction in ManeuverDirection.values) {
        final instruction = NavigationInstruction(
          type: type,
          direction: direction,
          position: const LatLng(0, 0),
          distanceMeters: 0,
          durationSeconds: 0,
          distanceFromStart: 0,
        );
        expect(instruction.instructionText, isNotEmpty);
        expect(instruction.instructionText.endsWith(' en '), isFalse);
      }
    }
    expect(v2Route.instructions.last.instructionText, 'Llegada al destino');
  });

  test('distancia decrece, supera step con tolerancia, jitter no retrocede y llegada elimina siguiente', () async {
    final gps = V2Gps();
    final session = NavigationSession(gps)..start(v2Route, 'Destino');
    gps.point(const LatLng(0, .005));
    await tick();
    expect(session.currentInstruction!.type, ManeuverType.depart);
    expect(session.nextInstruction!.type, ManeuverType.turn);
    expect(session.distanceToInstruction, closeTo(556, 5));
    gps.point(const LatLng(0, .009));
    await tick();
    expect(session.distanceToInstruction, closeTo(111, 3));
    gps.point(const LatLng(0, .01005));
    await tick();
    expect(session.nextInstruction!.type, ManeuverType.turn);
    gps.point(const LatLng(0, .0102));
    await tick();
    expect(session.nextInstruction!.type, ManeuverType.arrive);
    gps.point(const LatLng(0, .00999));
    await tick();
    expect(session.nextInstruction!.type, ManeuverType.arrive);
    gps.point(const LatLng(0, .0198));
    await tick();
    expect(session.state, NavigationState.arrived);
    expect(session.nextInstruction, isNull);
    session.dispose();
    await gps.updates.close();
  });

  test('desvío aislado no recalcula; confirmado single-flight reemplaza geometría y steps', () async {
    final gps = V2Gps();
    var calls = 0;
    final pending = Completer<RouteResult>();
    final session = NavigationSession(
      gps,
      reroute: ({required origin, required destination}) {
        calls++;
        expect(origin, outside);
        expect(destination, v2Route.destination);
        return pending.future;
      },
    )..start(v2Route, 'Destino');
    gps.point(outside);
    await tick();
    expect(calls, 0);
    gps.point(v2Route.origin);
    await tick();
    gps.point(outside);
    gps.point(outside);
    await tick();
    expect(calls, 0);
    gps.point(outside);
    await tick();
    expect(calls, 1);
    expect(session.state, NavigationState.rerouting);
    gps.point(outside);
    gps.point(outside);
    await tick();
    expect(calls, 1);
    final updated = rerouted();
    pending.complete(updated);
    await tick();
    expect(session.route, same(updated));
    expect(session.isActive, isTrue);
    expect(session.route!.instructions.length, 1);
    expect(session.remainingDistance, session.geometryDistance);
    expect(session.progress, 0);
    expect(session.notice, 'Ruta actualizada');
    session.dispose();
    expect(gps.updates.hasListener, isFalse);
    await gps.updates.close();
  });

  test(
    'error conserva ruta; cooldown controla reintento y GPS obsoleto se ignora',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      final gps = V2Gps();
      var calls = 0;
      final session = NavigationSession(
        gps,
        now: () => now,
        reroute: ({required origin, required destination}) async {
          calls++;
          throw StateError('offline');
        },
      )..start(v2Route, 'Destino');
      for (var i = 0; i < 3; i++) {
        gps.point(outside, at: now.add(Duration(seconds: i)));
      }
      await tick();
      expect(calls, 1);
      expect(session.state, NavigationState.rerouteFailed);
      expect(session.route, same(v2Route));
      gps.point(v2Route.origin, at: now);
      await tick();
      expect(session.currentPosition, outside);
      gps.point(outside);
      await tick();
      expect(calls, 1);
      now = now.add(const Duration(seconds: 31));
      gps.point(outside);
      await tick();
      expect(calls, 2);
      session.dispose();
      await gps.updates.close();
    },
  );

  for (final action in [
    'finish',
    'dispose',
    'rejoin',
    'new-session',
    'moved',
  ]) {
    test('respuesta stale tras $action no sustituye ruta', () async {
      final gps = V2Gps();
      final pending = Completer<RouteResult>();
      final session = NavigationSession(
        gps,
        reroute: ({required origin, required destination}) => pending.future,
      )..start(v2Route, 'Destino');
      gps.point(outside);
      gps.point(outside);
      gps.point(outside);
      await tick();
      if (action == 'dispose') {
        session.dispose();
      } else if (action == 'finish' || action == 'new-session') {
        session.finish();
      }
      if (action == 'new-session') session.start(v2Route, 'Nuevo destino');
      if (action == 'rejoin') {
        gps.point(v2Route.origin);
        await tick();
      }
      if (action == 'moved') {
        gps.point(const LatLng(.01, .01));
        await tick();
      }
      pending.complete(rerouted());
      await tick();
      expect(session.route, same(v2Route));
      if (action != 'dispose') session.dispose();
      await gps.updates.close();
    });
  }

  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets(
      'panel de maniobra y finalizar accesibles a $width con texto grande',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gps = V2Gps();
        final session = NavigationSession(gps)..start(v2Route, 'Destino');
        gps.point(const LatLng(0, .009));
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NavigationManeuverCard(session: session),
                        NavigationStatusCard(session: session),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Gira a la derecha en Carrera 27'), findsOneWidget);
        expect(find.text('111 m'), findsOneWidget);
        await tester.tap(find.text('Finalizar ruta'));
        await tester.pump();
        expect(session.isActive, isFalse);
        expect(tester.takeException(), isNull);
        session.dispose();
        await tester.runAsync(gps.updates.close);
      },
    );
  }
}
