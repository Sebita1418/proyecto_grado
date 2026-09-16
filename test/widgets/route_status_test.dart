import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/route_status.dart';

void main() {
  Widget buildTestWidget(RouteStatus widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  group('RouteStatus', () {
    testWidgets('muestra el estado inicial correctamente', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(status: RouteStatusType.idle)),
      );

      expect(find.text('Consulta una ruta'), findsOneWidget);
      expect(
        find.text('Ingresa un origen y un destino para calcular tu ruta.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    });

    testWidgets('muestra el estado de carga correctamente', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(status: RouteStatusType.loading)),
      );

      expect(find.text('Calculando ruta'), findsOneWidget);
      expect(
        find.text(
          'Estamos buscando la mejor ruta disponible. Espera un momento.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra el estado de error correctamente', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const RouteStatus(status: RouteStatusType.error)),
      );

      expect(find.text('No fue posible calcular la ruta'), findsOneWidget);
      expect(
        find.text(
          'Ocurrió un problema al consultar la ruta. Inténtalo nuevamente.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('permite mostrar un mensaje personalizado', (tester) async {
      const customMessage = 'No se encontró una ruta disponible.';

      await tester.pumpWidget(
        buildTestWidget(
          const RouteStatus(
            status: RouteStatusType.error,
            message: customMessage,
          ),
        ),
      );

      expect(find.text(customMessage), findsOneWidget);
    });
  });
}
