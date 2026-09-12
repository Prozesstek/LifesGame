import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_card.dart';
import 'package:lifes_game/achievements/achievements_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Der Errungenschaftsbildschirm.
///
/// **Die eine Regel, die dieser Test bewacht:** Eine unverdiente
/// Entdeckung verrät weder ihren Namen noch ihre Bedingung. Stünde sie
/// eines Tages lesbar da, wäre das keine Textänderung, sondern das Ende
/// der halben Entscheidung aus ADR-0033 — dieser Test zwingt sie ans
/// Licht.
void main() {
  /// Ein Stand mit [tage] Häkchen am Stück auf einer Vorlage.
  SaveData mitStreak(int tage) {
    var tracker = const HabitTracker.empty();
    final template = HabitCatalog.all.first;
    tracker = tracker.activate(template.id);
    var day = const Day(2026, 1, 1);
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(template.id, day).tracker;
      day = day.next;
    }
    return SaveData(habits: tracker);
  }

  Widget appMit(SaveData saved, {Widget screen = const AchievementsScreen()}) {
    return ProviderScope(
      overrides: [savedGameProvider.overrideWithValue(saved)],
      child: MaterialApp(home: screen),
    );
  }

  group('Meilensteine zeigen ihren Abstand', () {
    testWidgets('ein offener nennt Bedingung und Fortschritt', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(1)));
      await tester.pumpAndSettle();

      // „der Verlässliche" braucht 50 Häkchen; bei einem steht 1 / 50.
      expect(find.text('der Verlässliche'), findsOneWidget);
      expect(find.text('1 / 50'), findsOneWidget);
    });

    testWidgets('ein verdienter zeigt, was er eingebracht hat', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));
      await tester.pumpAndSettle();

      expect(find.text('der Entschlossene'), findsOneWidget);
      // Erfahrung, Gold und der Titel stehen da — der Abstand nicht mehr.
      expect(find.textContaining('Titel „der Entschlossene"'), findsOneWidget);
    });

    testWidgets('ein frischer Stand hat nichts verdient und sagt es', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));
      await tester.pumpAndSettle();

      expect(find.text('0 Ruhm'), findsOneWidget);
      expect(find.text('0 / 27'), findsOneWidget);
    });
  });

  group('Entdeckungen verraten sich nicht', () {
    testWidgets('eine unverdiente steht als ??? da', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));
      await tester.pumpAndSettle();

      // Drei Entdeckungen liegen im Bereich „Gewohnheiten".
      expect(find.text('???'), findsNWidgets(3));
      expect(find.text('Noch nicht entdeckt'), findsNWidgets(3));
    });

    testWidgets('weder Name noch Bedingung stehen irgendwo', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));
      await tester.pumpAndSettle();

      for (final entdeckung in AchievementCatalog.inArea(
        AchievementArea.gewohnheiten,
      ).where((a) => a.isDiscovery)) {
        expect(
          find.text(entdeckung.name),
          findsNothing,
          reason: '${entdeckung.id} verrät seinen Namen.',
        );
        expect(
          find.text(entdeckung.requirement),
          findsNothing,
          reason: '${entdeckung.id} verrät seine Bedingung.',
        );
      }
    });

    testWidgets('eine verdiente steht mit Namen da', (tester) async {
      useTallView(tester);
      // 21 Tage am Stück auf **einer** Gewohnheit reichen für den
      // Entschlossenen und den Beständigen nicht, für den Mönch auch
      // nicht — der braucht drei Häkchen am Tag. Zum Prüfen genügt eine
      // Entdeckung, die an der Kette hängt.
      await tester.pumpWidget(appMit(mitStreak(30)));
      await tester.pumpAndSettle();

      expect(find.text('der Beständige'), findsOneWidget);
      // Der Mönch bleibt verborgen: ein Häkchen am Tag ist zu wenig.
      expect(find.text('der Mönch'), findsNothing);
    });
  });

  group('Die vier Reiter', () {
    testWidgets('jeder Bereich ist erreichbar und zählt mit', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));
      await tester.pumpAndSettle();

      // **Die Reiterleiste schiebt sich waagerecht**, wie im Laden: Vier
      // Reiter mit Zählstand passen auf 560 Pixel nicht nebeneinander,
      // und ein abgeschnittenes Wort wäre schlimmer als einer, den man
      // heranschiebt. Was nicht sichtbar ist, baut die `ListView` gar
      // nicht — der Test muss also wirklich schieben.
      final leiste = find.byType(Scrollable).first;
      for (final area in AchievementArea.values) {
        await tester.dragUntilVisible(
          find.text(area.label),
          leiste,
          const Offset(-80, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text(area.label), findsOneWidget);
      }

      // Gewohnheiten: zwei von elf bei drei Tagen Kette.
      expect(find.text('2/11'), findsOneWidget);

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.text('Erster Sieg'), findsOneWidget);
      expect(find.text('der Verlässliche'), findsNothing);
    });
  });

  group('Der Weg dorthin', () {
    testWidgets('die Karte führt zum Bildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(mitStreak(3), screen: const Scaffold(body: AchievementsCard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Errungenschaften'), findsOneWidget);
      expect(find.textContaining('von 27'), findsOneWidget);

      await tester.tap(find.byType(AchievementsCard));
      await tester.pumpAndSettle();

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });
}
