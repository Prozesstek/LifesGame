import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

/// Die Startseite rollt nicht, nur die Zettel in „Heute“ (19.11.2026).
void main() {
  const heute = Day(2026, 8, 21);

  Future<void> zeige(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var tracker = const HabitTracker.empty();
    for (final t in HabitCatalog.all) {
      tracker = tracker.activate(t.id);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
          todayProvider.overrideWithValue(heute),
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Wie viele Rollflächen zwischen „Heute“ und der Seite liegen.
  int rollendUeberHeute(WidgetTester tester) {
    return find
        .ancestor(
          of: find.byType(TodayCard),
          matching: find.byType(SingleChildScrollView),
        )
        .evaluate()
        .length;
  }

  testWidgets('am Handy rollt nur die Liste in „Heute“', (tester) async {
    await zeige(tester, const Size(390, 844));

    expect(find.byKey(TodayCard.listeKey), findsOneWidget);
    expect(rollendUeberHeute(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auf einem sehr kleinen Handy rollt doch die Seite', (
    tester,
  ) async {
    await zeige(tester, const Size(360, 600));

    expect(rollendUeberHeute(tester), 1);
    expect(tester.takeException(), isNull);
  });
}
