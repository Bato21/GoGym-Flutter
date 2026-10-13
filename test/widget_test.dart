import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_gym/main.dart';

void main() {
  testWidgets('Las tabs navegan entre páginas', (WidgetTester tester) async {
    await tester.pumpWidget(const GoGymApp());

    expect(find.text('Inicio: en construcción'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
  });
}
