import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/widgets/achievement_unlock_sheet.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/tages_flamme.dart';
import 'package:lifes_game/habits/widgets/tages_flamme_feier.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Merkt sich, was gespielt werden sollte, statt es zu spielen.
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

/// **Die große Flamme in der Mitte** (28.10.2026): Das erste Häkchen des
/// Tages lässt die Tageskette groß einen Tag höher ticken.
///
/// Keine Zahl ändert sich — geprüft wird, was die Einblendung zeigt und
/// dass die Feiern danach auf sie warten.
void main() {
  // Ein Sonntag: Die Woche davor liegt ganz hinter uns.
  const heute = Day(2026, 10, 18);

  // Drei Vorlagen ohne Timer: Ein Tipp hakt sie ab.
  final drei = HabitCatalog.all
      .where((t) => t.id != HabitCatalog.starter.id)
      .take(3)
      .toList(growable: false);

  HabitTracker mitDreien() {
    var tracker = const HabitTracker.empty();
    for (final vorlage in drei) {
      tracker = tracker.activate(vorlage.id);
    }
    return tracker;
  }

  // Gestern war schon etwas abgehakt: Die Kette steht bei 1, und die
  // Errungenschaft des ersten Häkchens liegt zurück.
  HabitTracker mitGestern() =>
      mitDreien().check(drei.first.id, heute.previous).tracker;

  group('TagesFlamme', () {
    test('nur das erste Häkchen des Tages zündet', () {
      final vorher = mitGestern();
      final erstes = vorher.check(drei[1].id, heute).tracker;
      final zweites = erstes.check(drei[2].id, heute).tracker;

      final flamme = TagesFlamme.aus(
        vorher: vorher,
        nachher: erstes,
        heute: heute,
      );
      expect(flamme, isNotNull);
      expect(flamme!.vorher, 1);
      expect(flamme.nachher, 2);
      expect(flamme.rollt, isTrue);

      expect(
        TagesFlamme.aus(vorher: erstes, nachher: zweites, heute: heute),
        isNull,
      );
    });

    test('am allerersten Tag springt die Eins auf, statt zu rollen', () {
      final vorher = mitDreien();
      final flamme = TagesFlamme.aus(
        vorher: vorher,
        nachher: vorher.check(drei.first.id, heute).tracker,
        heute: heute,
      );
      expect(flamme!.vorher, 0);
      expect(flamme.nachher, 1);
      expect(flamme.rollt, isFalse);
    });

    test('die Woche: was brennt, was das Eis trug, was noch kommt', () {
      // Ein Mittwoch. Montag abgehakt, Dienstag mit Eis gedeckt.
      const mittwoch = Day(2026, 10, 21);
      final montag = mittwoch.previous.previous;
      final tracker = HabitTracker(
        activeIds: <String>[drei.first.id],
        checks: <String, Set<Day>>{
          drei.first.id: <Day>{montag, mittwoch},
        },
        frozenDays: <Day>{mittwoch.previous},
      );

      expect(TagesFlamme.wocheVon(tracker, mittwoch), <FlammenTag>[
        FlammenTag.brennt,
        FlammenTag.eis,
        FlammenTag.heute,
        FlammenTag.kommt,
        FlammenTag.kommt,
        FlammenTag.kommt,
        FlammenTag.kommt,
      ]);
    });

    test('am Sonntag liegt die ganze Woche zurück', () {
      final woche = TagesFlamme.wocheVon(mitGestern(), heute);
      expect(woche.last, FlammenTag.heute);
      expect(woche[5], FlammenTag.brennt, reason: 'Samstag, gestern');
      expect(woche.take(5), everyElement(FlammenTag.leer));
    });
  });

  group('Auf der Startseite', () {
    Future<_Mitschrift> startseite(
      WidgetTester tester,
      HabitTracker tracker,
    ) async {
      useTallView(tester);
      final mitschrift = _Mitschrift();
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
          todayProvider.overrideWithValue(heute),
          soundPlayerProvider.overrideWithValue(mitschrift),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      return mitschrift;
    }

    Finder inDerKarte(Finder finder) =>
        find.descendant(of: find.byType(TodayCard), matching: finder);

    final feier = find.byKey(TagesFlammeFeier.feierKey);
    Finder inDerFlamme(String text) =>
        find.descendant(of: feier, matching: find.text(text));

    testWidgets('das erste Häkchen lässt die Zahl groß einen Tag höher '
        'ticken', (tester) async {
      final mitschrift = await startseite(tester, mitGestern());
      expect(feier, findsNothing);

      await tester.tap(inDerKarte(find.text(drei[1].name)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(feier, findsOneWidget);
      expect(inDerFlamme('1'), findsOneWidget, reason: 'erst die alte');
      expect(inDerFlamme('2'), findsNothing);
      expect(inDerFlamme('Mo'), findsOneWidget, reason: 'die Woche');

      await tester.pump(const Duration(milliseconds: 500));
      expect(inDerFlamme('1'), findsOneWidget, reason: 'sie rollt hinaus');
      expect(inDerFlamme('2'), findsOneWidget, reason: 'die neue herein');

      await tester.pump(const Duration(milliseconds: 500));
      expect(inDerFlamme('1'), findsNothing);
      expect(inDerFlamme('2'), findsOneWidget);
      expect(mitschrift.gespielt, contains(SoundEffect.ketteSteigt));

      await tester.pumpAndSettle();
      expect(feier, findsNothing, reason: 'sie blendet von selbst aus');

      // Das zweite Häkchen zündet nichts mehr.
      mitschrift.gespielt.clear();
      await tester.tap(inDerKarte(find.text(drei[2].name)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(feier, findsNothing);
      await tester.pumpAndSettle();
      expect(mitschrift.gespielt, isNot(contains(SoundEffect.ketteSteigt)));
    });

    testWidgets('ein Tipp blendet sie sofort aus und hakt nichts ab', (
      tester,
    ) async {
      await startseite(tester, mitGestern());

      await tester.tap(inDerKarte(find.text(drei[1].name)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(feier, findsOneWidget);

      // Genau dorthin, wo darunter die nächste Gewohnheit hängt.
      await tester.tapAt(tester.getCenter(inDerKarte(find.text(drei[2].name))));
      await tester.pump();
      // Ein Hauch über die Dauer: Fertig ist eine Animation erst danach.
      await tester.pump(
        TagesFlammeFeier.weg + const Duration(milliseconds: 50),
      );
      await tester.pump();
      expect(feier, findsNothing);

      final tracker = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      ).read(habitTrackerProvider);
      expect(tracker.completedOn(heute), 1, reason: 'nur das erste');
      await tester.pumpAndSettle();
    });

    testWidgets('die Errungenschaft wartet, bis die Flamme aus ist', (
      tester,
    ) async {
      // Das allererste Häkchen bringt „Erster Schritt“.
      final mitschrift = await startseite(tester, mitDreien());

      await tester.tap(inDerKarte(find.text(drei.first.name)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(feier, findsOneWidget);
      expect(inDerFlamme('1'), findsOneWidget);
      expect(find.byType(AchievementUnlockSheet), findsNothing);
      expect(mitschrift.gespielt, isNot(contains(SoundEffect.errungenschaft)));

      await tester.pumpAndSettle();
      expect(feier, findsNothing);
      expect(find.byType(AchievementUnlockSheet), findsOneWidget);
    });
  });
}
