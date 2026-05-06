import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tribunall/app.dart';
import 'package:tribunall/models/banco.dart';
import 'package:tribunall/state/app_state.dart';

const _bancoPrueba = Banco(
  cN: ['interrumpir al juez con una carcajada'],
  cI: ['confesar un crush delante de todos'],
  cP: ['describir una fantasia prohibida'],
  sN: ['hacer una reverencia dramática'],
  sI: ['enviar un emoji comprometedor'],
  sP: ['dar un beso apasionado'],
);

Widget _buildTestApp({bool esPremium = false}) {
  return TribunalAppScope(
    appState: AppState(
      banco: _bancoPrueba,
      esPremiumInicial: esPremium,
      enableMonetization: false,
    ),
    child: const ElTribunalApp(),
  );
}

void main() {
  testWidgets('permite agregar acusados e iniciar un juicio', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildTestApp());

    expect(find.text('EL TRIBUNAL'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);

    await tester.tap(find.textContaining('INICIAR JUICIO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SE LE ACUSA DE...'), findsOneWidget);
    expect(find.text('interrumpir al juez con una carcajada'), findsOneWidget);
  });

  testWidgets('premium desbloquea modo atrevido sin anuncio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(esPremium: true));

    await tester.tap(find.text('ATREVIDO'));
    await tester.pump();

    expect(find.text('🌙  INICIAR JUICIO ATREVIDO'), findsOneWidget);
    expect(find.text('🌙 Modo Atrevido'), findsNothing);
  });

  testWidgets('modo picante muestra estado no configurado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.text('PICANTE'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'La compra premium aún no está configurada. Cuando esté lista, se activará aquí.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'PROXIMAMENTE'), findsOneWidget);
  });
}
