import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/widgets/info_blatt.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Datenschutz, Gesundheitshinweis und Lizenzen müssen im Charakter
/// erreichbar sein — der Play Store verlangt sie, ein Test hält den Weg.
void main() {
  Widget app() {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(const SaveData.empty()),
        todayProvider.overrideWithValue(const Day(2026, 11, 10)),
      ],
      child: const MaterialApp(home: CharacterScreen()),
    );
  }

  Future<void> blattOeffnen(WidgetTester tester) async {
    useTallView(tester);
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('info-knopf')));
    await tester.pumpAndSettle();
  }

  testWidgets('der Knopf oben öffnet ein Blatt mit drei Zeilen', (
    tester,
  ) async {
    await blattOeffnen(tester);

    expect(find.byKey(const Key('info-datenschutz')), findsOneWidget);
    expect(find.byKey(const Key('info-gesundheit')), findsOneWidget);
    expect(find.byKey(const Key('info-lizenzen')), findsOneWidget);
  });

  testWidgets('Datenschutz nennt die Adresse der ganzen Erklärung', (
    tester,
  ) async {
    await blattOeffnen(tester);

    await tester.tap(find.byKey(const Key('info-datenschutz')));
    await tester.pumpAndSettle();

    expect(find.textContaining(datenschutzAdresse), findsOneWidget);
    expect(find.textContaining('keine personenbezogenen Daten'), findsOne);
  });

  testWidgets('Gesundheit sagt, dass es keine Beratung ersetzt', (
    tester,
  ) async {
    await blattOeffnen(tester);

    await tester.tap(find.byKey(const Key('info-gesundheit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ersetzen keine ärztliche'), findsOneWidget);
  });

  testWidgets('Lizenzen öffnet die Lizenzseite von Flutter', (tester) async {
    await blattOeffnen(tester);

    await tester.tap(find.byKey(const Key('info-lizenzen')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
