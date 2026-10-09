import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/report_location_picker.dart';

import 'route_flow_test.dart'
    show ControlledRouting, ForbiddenGeocoding, firstRoute, tapLabel;
import 'address_flow_test.dart' show EmptyAddressSuggestions;
import 'report_location_flow_test.dart' show DeniedLocation;

void main() {
  for (final width in [390.0, 768.0]) {
    testWidgets('selección manual actualiza marcadores y OSRM a $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final routing = ControlledRouting();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            initiallyCollapsed: false,
            locationService: DeniedLocation(),
            loadProfile: () async => Perfil(
              id: 'test',
              nombre: 'Ana',
              correo: 'ana@example.test',
              rol: 'usuario',
              activo: true,
            ),
            geocodingService: ForbiddenGeocoding(),
            placeSuggestionService: EmptyAddressSuggestions(),
            routingService: routing,
          ),
        ),
      );
      await tester.pumpAndSettle();
      const origin = LatLng(7.11, -73.12);
      const destination = LatLng(7.12, -73.13);
      for (final isOrigin in [true, false]) {
        final label = isOrigin
            ? 'Elegir origen en el mapa'
            : 'Elegir destino en el mapa';
        await tapLabel(tester, label);
        expect(find.byType(ReportLocationPicker), findsOneWidget);
        final pickerMap = tester.widget<FlutterMap>(
          find.byType(FlutterMap).last,
        );
        final coordinates = isOrigin ? origin : destination;
        pickerMap.options.onTap!(
          const TapPosition(Offset.zero, Offset.zero),
          coordinates,
        );
        await tester.pump();
        expect(
          tester
              .widget<RouteMap>(find.byType(RouteMap).last)
              .markers
              .single
              .point,
          coordinates,
        );
        await tapLabel(tester, 'Confirmar ubicación');
        final homeMap = tester.widget<RouteMap>(find.byType(RouteMap));
        expect(
          homeMap.overlayMarkers.any((marker) => marker.point == coordinates),
          isTrue,
        );
      }
      await tapLabel(tester, 'Analizar rutas');
      expect(routing.calls, 1);
      expect(routing.lastOrigin, origin);
      expect(routing.lastDestination, destination);
      routing.pending.complete([firstRoute]);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
}
