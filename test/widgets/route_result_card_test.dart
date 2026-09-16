import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('resumen se adapta a ${width.toInt()} px', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: width < 420 ? width : 420,
                child: RouteResultCard(
                  route: const RouteResult(
                    origin: LatLng(7.1, -73.1),
                    destination: LatLng(7.2, -73.2),
                    points: [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
                    distanceMeters: 9800,
                    durationSeconds: 660,
                  ),
                  originLabel: 'Tu ubicación actual',
                  destinationLabel: 'Centro Comercial Cacique',
                  onModify: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('9.8 km'), findsOneWidget);
      expect(find.text('11 min'), findsOneWidget);
    });
  }
}
