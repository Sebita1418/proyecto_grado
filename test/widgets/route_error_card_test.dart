import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/route_error_card.dart';

void main() {
  Widget buildTestWidget({
    required String message,
    required VoidCallback onRetry,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RouteErrorCard(message: message, onRetry: onRetry),
      ),
    );
  }

  group('RouteErrorCard', () {
    testWidgets('muestra el título y mensaje de error', (tester) async {
      const errorMessage = 'No se pudo conectar con el servicio de rutas.';

      await tester.pumpWidget(
        buildTestWidget(message: errorMessage, onRetry: () {}),
      );

      expect(find.text('No fue posible calcular la ruta'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('muestra el botón Reintentar', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(message: 'Error al calcular la ruta.', onRetry: () {}),
      );

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('ejecuta onRetry al presionar Reintentar', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          message: 'Error al calcular la ruta.',
          onRetry: () {
            retryCalled = true;
          },
        ),
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });
}
