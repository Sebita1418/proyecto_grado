import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/navigation_header.dart';

void main() {
  testWidgets('NavigationHeader muestra título, subtítulo e icono', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationHeader(onMenuPressed: () {}, onProfilePressed: () {}),
        ),
      ),
    );

    expect(find.text('Transporte Inteligente'), findsOneWidget);
    expect(find.text('Muévete mejor. Decide tu ruta.'), findsOneWidget);
    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('NavigationHeader ejecuta callbacks de menú y perfil', (
    tester,
  ) async {
    var menuTapped = false;
    var profileTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NavigationHeader(
            onMenuPressed: () => menuTapped = true,
            onProfilePressed: () => profileTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Abrir menú de navegación'));
    await tester.pump();
    expect(menuTapped, isTrue);

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pump();
    expect(profileTapped, isTrue);
  });

  testWidgets(
    'NavigationHeader permite título, subtítulo y avatar personalizados',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationHeader(
              title: 'Movilidad Urbana',
              subtitle: 'Rutas y tránsito',
              userAvatar: const CircleAvatar(child: Text('U')),
              onMenuPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Movilidad Urbana'), findsOneWidget);
      expect(find.text('Rutas y tránsito'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'NavigationHeader es responsive y accesible a ${width.toInt()} px con texto 1.5x',
      (tester) async {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: NavigationHeader(
                onMenuPressed: () {},
                onProfilePressed: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Transporte Inteligente'), findsOneWidget);
        expect(find.byTooltip('Abrir menú de navegación'), findsOneWidget);
        expect(find.byTooltip('Perfil'), findsOneWidget);

        semantics.dispose();
      },
    );
  }
}
