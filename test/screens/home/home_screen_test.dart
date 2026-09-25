import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/screens/nearby/nearby_places_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/screens/perfil/perfil_screen.dart';

class FakeLocationService extends LocationService {
  FakeLocationService(this.result);
  final LocationResult result;
  @override
  Future<LocationResult> locate() async => result;
}

void main() {
  Future<void> profileHome(
    WidgetTester tester,
    Future<Perfil?> Function() loadProfile,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          locationService: FakeLocationService(
            const LocationResult(
              LocationStatus.coordinatesObtained,
              coordinates: LatLng(7.1, -73.1),
            ),
          ),
          loadProfile: loadProfile,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapProfile(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'aviso Perfil permite reintentar y usar mapa a $width con texto ampliado',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var loads = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: HomeScreen(
              locationService: FakeLocationService(
                const LocationResult(
                  LocationStatus.coordinatesObtained,
                  coordinates: LatLng(7.1, -73.1),
                ),
              ),
              loadProfile: () async {
                loads++;
                return null;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Reintentar'));
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(loads, 2);
        await tester.tap(find.byType(FloatingActionButton).first);
        await tester.pump();
        expect(find.byType(RouteMap), findsOneWidget);
        expect(find.byType(MaterialBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final throwsError in [false, true]) {
    testWidgets(
      'Perfil ${throwsError ? "fallido" : "sin datos"} permite recuperar y navegar',
      (tester) async {
        var calls = 0;
        final recovered = Completer<Perfil?>();
        await profileHome(tester, () async {
          calls++;
          if (calls > 1) return recovered.future;
          if (throwsError) throw StateError('detalle interno privado');
          return null;
        });
        expect(
          find.text(
            'No fue posible cargar tu perfil. Puedes seguir usando el mapa.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('detalle interno'), findsNothing);
        expect(find.byType(RouteMap), findsOneWidget);
        await tapProfile(tester);
        await tapProfile(tester);
        expect(find.byType(MaterialBanner), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(Drawer), findsNothing);
        expect(calls, 1);
        await tester.tap(find.text('Reintentar'));
        await tester.pump();
        expect(calls, 2);
        expect(find.text('Cargando…'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Cargando…'))
              .onPressed,
          isNull,
        );
        expect(find.byType(RouteMap), findsOneWidget);
        recovered.complete(
          Perfil(
            id: 'demo',
            nombre: 'Demo',
            correo: 'demo@example.test',
            rol: 'usuario',
            activo: true,
          ),
        );
        await tester.pump();
        expect(find.byType(MaterialBanner), findsNothing);
        await tapProfile(tester);
        expect(find.byType(PerfilScreen), findsOneWidget);
        expect(find.text('demo@example.test'), findsWidgets);
        expect(calls, 2);
      },
    );
  }

  testWidgets(
    'Perfil durante carga informa sin duplicar solicitud y permite otro reintento',
    (tester) async {
      final pending = Completer<Perfil?>();
      var calls = 0;
      await profileHome(tester, () {
        calls++;
        return pending.future;
      });
      await tapProfile(tester);
      expect(
        find.text('Cargando tu perfil. Puedes seguir usando el mapa.'),
        findsOneWidget,
      );
      expect(calls, 1);
      pending.completeError(StateError('privado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(calls, 2);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Perfil pendiente tras dispose no actualiza Home', (
    tester,
  ) async {
    final pending = Completer<Perfil?>();
    await profileHome(tester, () => pending.future);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(StateError('privado'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  Future<void> render(WidgetTester tester, LocationResult result) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          locationService: FakeLocationService(result),
          loadProfile: () async => null,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Home muestra OSM, ubicación y navegación', (tester) async {
    await render(
      tester,
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(7.1, -73.1),
      ),
    );
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byTooltip('Mi ubicación'), findsWidgets);
    expect(find.text('Hola,'), findsNothing);
    expect(find.text('¿Qué deseas consultar?'), findsNothing);
    expect(find.byTooltip('Mi ubicación'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();
    expect(find.text('Muévete mejor. Decide tu ruta.'), findsNWidgets(2));
    expect(find.text('Mapa / Inicio'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Mapa / Inicio'),
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Puntos cercanos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('sin permiso conserva mapa y origen manual', (tester) async {
    await render(tester, const LocationResult(LocationStatus.permissionDenied));
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.byTooltip('Mi ubicación'), findsOneWidget);
  });

  testWidgets('Puntos cercanos abre la pantalla y permite volver al mapa', (
    tester,
  ) async {
    await render(
      tester,
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(7.1, -73.1),
      ),
    );
    for (final useBackButton in [false, true]) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Puntos cercanos'));
      await tester.pumpAndSettle();
      expect(find.byType(NearbyPlacesScreen), findsOneWidget);
      expect(find.text('Aún no disponible'), findsOneWidget);
      if (useBackButton) {
        await tester.tap(find.byType(BackButton));
      } else {
        await tester.ensureVisible(find.text('Volver al mapa'));
        await tester.tap(find.text('Volver al mapa'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(NearbyPlacesScreen), findsNothing);
      expect(find.byType(RouteMap), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    }
  });
}
