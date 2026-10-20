import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/combat/widgets/loot_dialog.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/mentor/mentor.dart';
import 'package:lifes_game/mentor/mentor_kasten.dart';
import 'package:lifes_game/mentor/zeigefinger.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';
import 'package:theory/theory.dart';

import 'gear_helpers.dart';
import 'test_view.dart';

/// Der Mentor (ADR-0079): wer er ist, was er sagt, und dass er einen
/// neuen Spieler vom leeren Stand bis in die Grube bringt.
void main() {
  const heute = Day(2026, 10, 20);

  /// Was der Mentor gerade sagt — der Text in seinem Kasten, oder null.
  String? sagt(WidgetTester tester) {
    final kasten = find.byType(MentorKasten);
    if (kasten.evaluate().isEmpty) return null;
    return tester.widget<MentorKasten>(kasten).text;
  }

  String satz(Schritt schritt, MentorOrt ort) =>
      Mentor.satz(schritt, ort)!.text;

  group('was er sagt', () {
    test('auf der Startseite hat er zu jedem Schritt einen Satz', () {
      for (final schritt in Schritt.values) {
        expect(
          Mentor.satz(schritt, MentorOrt.start),
          isNotNull,
          reason: '$schritt',
        );
      }
    });

    test('ist der Weg gegangen, schweigt er überall', () {
      for (final ort in MentorOrt.values) {
        expect(Mentor.satz(null, ort), isNull, reason: '$ort');
      }
    });

    test('ein Satz ist kurz', () {
      // Er erklärt, aber er hält keinen Vortrag: ADR-0060 lässt ihn nur
      // als Ausnahme zu.
      for (final schritt in Schritt.values) {
        for (final ort in MentorOrt.values) {
          final text = Mentor.satz(schritt, ort)?.text;
          if (text == null) continue;
          expect(text.length, lessThan(130), reason: text);
        }
      }
      expect(Mentor.ersteBeute.length, lessThan(130));
    });

    test('am Eingang steht er oben, weil „Hinab“ unten liegt', () {
      expect(
        Mentor.satz(Schritt.grube, MentorOrt.eingang)!.lage,
        KastenLage.oben,
      );
    });
  });

  group('in der App', () {
    Future<ProviderContainer> starte(
      WidgetTester tester, {
      SaveData stand = const SaveData.empty(),
      Widget home = const HomeScreen(),
    }) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(stand),
          todayProvider.overrideWithValue(heute),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: home),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    final einHaekchen = const HabitTracker.empty()
        .activate(HabitCatalog.starterId)
        .check(HabitCatalog.starterId, heute)
        .tracker;

    /// Ein Häkchen und die erste Seite: Level 2, Funkenstoß gelernt.
    SaveData ersteSeiteGelesen() {
      final erste = theoryGraph.nodeById(theoryBasicsPath.first)!;
      final theorie = const TheoryProgress.empty().openNode(erste.id).submit(
        erste.lesson,
        <int?>[for (final q in erste.lesson.questions) q.correctIndex],
      ).progress;
      return SaveData(habits: einHaekchen, theory: theorie);
    }

    testWidgets('der erste Start: er begrüßt und zeigt auf die Frage', (
      tester,
    ) async {
      await starte(tester);

      expect(sagt(tester), satz(Schritt.gewohnheit, MentorOrt.start));
      expect(find.byKey(Zeigefinger.ringKey), findsOneWidget);
    });

    testWidgets('sein Kasten nimmt keinen Tipp an', (tester) async {
      // Er zeigt, er sperrt nicht: Was darunter liegt, bleibt erreichbar.
      await starte(tester);

      expect(find.byType(MentorKasten).hitTestable(), findsNothing);
    });

    testWidgets('nach dem ersten Häkchen schickt er in die Theorie, und dort '
        'zeigt er auf die erste Seite', (tester) async {
      await starte(tester, stand: SaveData(habits: einHaekchen));
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.start));

      await tester.tap(find.text('Theorie'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeScreen), findsOneWidget);
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.baum));
      expect(
        find.ancestor(
          of: find.byType(ContinueReadingTile),
          matching: find.byType(ZeigeRing),
        ),
        findsOneWidget,
      );
    });

    testWidgets('die erste Seite bringt jedem Funkenstoß, und auf Level 2 '
        'hat er einen Platz', (tester) async {
      final c = await starte(tester, stand: ersteSeiteGelesen());

      expect(c.read(playerLevelProvider).level, 2);
      expect(
        c.read(unlockedAbilitiesProvider).map((a) => a.moveId),
        contains('funkenstoss'),
      );
      expect(sagt(tester), satz(Schritt.faehigkeitAnlegen, MentorOrt.start));
    });

    testWidgets('auf der Startseite deckt er die untere Reihe nicht zu', (
      tester,
    ) async {
      // Er steht in der leeren Mitte und zeigt hinunter auf die
      // Fähigkeiten — oben stünde er auf Gewohnheiten und Theorie.
      await starte(tester, stand: ersteSeiteGelesen());

      final kasten = tester.getRect(find.byType(MentorKasten));
      final kreis = tester.getRect(find.text('Fähigkeiten'));
      expect(kasten.bottom, lessThan(kreis.top));
      expect(
        kasten.top,
        greaterThan(tester.getRect(find.text('Theorie')).bottom),
      );
    });

    testWidgets('bei den Fähigkeiten zeigt er auf die eine, die neu ist — '
        'und ist sie angelegt, geht es in die Grube', (tester) async {
      final c = await starte(
        tester,
        stand: ersteSeiteGelesen(),
        home: const AbilitiesScreen(),
      );

      expect(
        sagt(tester),
        satz(Schritt.faehigkeitAnlegen, MentorOrt.faehigkeiten),
      );
      expect(find.byKey(Zeigefinger.ringKey), findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.byType(ZeigeRing),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Platz 2'));
      await tester.pumpAndSettle();

      expect(c.read(chosenAbilitiesProvider).contains('funkenstoss'), isTrue);
      expect(c.read(ersterStartProvider).schritt, Schritt.grube);
      expect(find.byKey(Zeigefinger.ringKey), findsNothing);
      expect(sagt(tester), isNull, reason: 'hier gibt es nichts mehr zu tun');
    });

    testWidgets('am Eingang zeigt er auf „Hinab“', (tester) async {
      final stand = ersteSeiteGelesen();
      await starte(
        tester,
        stand: SaveData(
          habits: stand.habits,
          theory: stand.theory,
          abilities: const ChosenAbilities.empty().withAt(0, 'funkenstoss'),
        ),
        home: const LadderScreen(),
      );

      expect(sagt(tester), satz(Schritt.grube, MentorOrt.eingang));
      expect(
        find.ancestor(
          of: find.byKey(LadderScreen.hinabKey),
          matching: find.byType(ZeigeRing),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nach dem ersten Sieg schweigt er', (tester) async {
      final stand = ersteSeiteGelesen();
      await starte(
        tester,
        stand: SaveData(
          habits: stand.habits,
          theory: stand.theory,
          abilities: const ChosenAbilities.empty().withAt(0, 'funkenstoss'),
          ladder: const LadderProgress.empty().defeat(1),
        ),
      );

      expect(sagt(tester), isNull);
      expect(find.byKey(Zeigefinger.ringKey), findsNothing);
    });

    testWidgets('wer überschreibt, sieht keinen Mentor', (tester) async {
      // So sehen es die Tests der anderen Bereiche.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentorKasten), findsNothing);
    });

    testWidgets('vom leeren Stand bis zur ersten Fähigkeit', (tester) async {
      final c = await starte(tester);

      // 1. Die erste Gewohnheit, mit einem Tipp.
      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.abhaken, MentorOrt.start));

      // 2. Abhaken, auf „Heute“.
      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();
      await feiernSchliessen(tester);
      expect(c.read(habitTrackerProvider).totalChecks, 1);
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.start));

      // 3. Die erste Seite, über den Vorschlag im Baum.
      await tester.tap(find.text('Theorie'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ContinueReadingTile));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);

      final seite = theoryGraph.nodeById(theoryBasicsPath.first)!.lesson;
      await zuDenFragen(tester, seite);
      for (var i = 0; i < seite.questionCount; i++) {
        final frage = seite.questions.firstWhere(
          (q) => find.text(q.prompt).evaluate().isNotEmpty,
        );
        await tester.tap(find.text(frage.options[frage.correctIndex]));
        await tester.pumpAndSettle();
        final letzte = i == seite.questionCount - 1;
        await tester.tap(find.text(letzte ? 'Auswerten' : 'Weiter'));
        await tester.pumpAndSettle();
      }
      await feiernSchliessen(tester);

      expect(c.read(passedPagesProvider), 1);
      expect(c.read(playerLevelProvider).level, 2);
      expect(c.read(ersterStartProvider).schritt, Schritt.faehigkeitAnlegen);
    });
  });

  group('die erste Beute', () {
    Future<void> zeige(WidgetTester tester, {required bool mentor}) async {
      useTallView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showLoot(
                  context,
                  loot: angebot(GearCatalog.all.first.id),
                  headline: 'Erster Sieg auf Stufe 1',
                  mentor: mentor,
                ),
                child: const Text('los'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('los'));
      await tester.pumpAndSettle();
    }

    testWidgets('beim ersten Mal sagt er seinen letzten Satz und zeigt auf '
        '„Anlegen“', (tester) async {
      await zeige(tester, mentor: true);

      expect(sagt(tester), Mentor.ersteBeute);
      expect(
        find.ancestor(
          of: find.text('Anlegen'),
          matching: find.byType(ZeigeRing),
        ),
        findsOneWidget,
      );
    });

    testWidgets('danach ist die Beute wieder nur Beute', (tester) async {
      await zeige(tester, mentor: false);

      expect(find.byType(MentorKasten), findsNothing);
      expect(find.byType(ZeigeRing), findsNothing);
    });
  });
}
