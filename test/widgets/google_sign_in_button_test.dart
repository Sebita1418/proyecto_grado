import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/google_sign_in_button.dart';

void main() {
  Widget buildTestWidget({
    VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GoogleSignInButton(
          onPressed: onPressed,
          enabled: enabled,
          isLoading: isLoading,
        ),
      ),
    );
  }

  testWidgets('muestra el texto Continuar con Google', (tester) async {
    await tester.pumpWidget(buildTestWidget(onPressed: () {}));

    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('ejecuta el callback al presionar el botón', (tester) async {
    var callbackCount = 0;

    await tester.pumpWidget(
      buildTestWidget(
        onPressed: () {
          callbackCount++;
        },
      ),
    );

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(callbackCount, 1);
  });

  testWidgets('no ejecuta el callback cuando está deshabilitado', (
    tester,
  ) async {
    var callbackCount = 0;

    await tester.pumpWidget(
      buildTestWidget(
        enabled: false,
        onPressed: () {
          callbackCount++;
        },
      ),
    );

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(callbackCount, 0);
  });

  testWidgets('muestra indicador y bloquea el callback mientras carga', (
    tester,
  ) async {
    var callbackCount = 0;

    await tester.pumpWidget(
      buildTestWidget(
        isLoading: true,
        onPressed: () {
          callbackCount++;
        },
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continuar con Google'), findsNothing);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(callbackCount, 0);
  });
}
