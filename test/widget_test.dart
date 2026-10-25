import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linky/screens/linky_page_manager_screen.dart';

void main() {
  testWidgets('Linky page manager renders its creator controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LinkyPageManagerScreen()));
    await tester.pump();

    expect(find.byType(LinkyPageManagerScreen), findsOneWidget);
    expect(find.text('Ajouter un lien'), findsOneWidget);
  });
}
