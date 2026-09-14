import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/route_status.dart';

void main() {
  Widget buildTestWidget(RouteStatus status) {
    return MaterialApp(home: Scaffold(body: status));
  }

  group('RouteStatus', () {
    testWidgets('muestra correctamente el estado inicial', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(type: RouteStatusType.initial)),
      );

      expect(find.text('Planifica tu recorrido'), findsOneWidget);
      expect(
        find.text(
          'Ingresa un punto de origen y un destino para calcular tu ruta.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    });

    testWidgets('muestra correctamente el estado de carga', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(type: RouteStatusType.loading)),
      );

      expect(find.text('Calculando ruta'), findsOneWidget);
      expect(
        find.text('Estamos buscando la mejor ruta disponible.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra correctamente el estado de error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(type: RouteStatusType.error)),
      );

      expect(find.text('No fue posible calcular la ruta'), findsOneWidget);
      expect(
        find.text(
          'Ocurrió un problema al consultar la ruta. Intenta nuevamente.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('muestra un mensaje personalizado cuando se proporciona', (
      tester,
    ) async {
      const customMessage =
          'No se encontró una ruta disponible para este recorrido.';

      await tester.pumpWidget(
        buildTestWidget(
          const RouteStatus(
            type: RouteStatusType.error,
            message: customMessage,
          ),
        ),
      );

      expect(find.text(customMessage), findsOneWidget);
      expect(
        find.text(
          'Ocurrió un problema al consultar la ruta. Intenta nuevamente.',
        ),
        findsNothing,
      );
    });
  });
}
