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
import 'package:lifes_game/home/widgets/erste_gewohnheit.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/mentor/mentor.dart';
import 'package:lifes_game/mentor/mentor_kasten.dart';
import 'package:lifes_game/mentor/scheinwerfer.dart';
import 'package:lifes_game/mentor/zeigefinger.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';
import 'package:lifes_game/theory/widgets/tree_view.dart';
import 'package:lifes_game/theory/widgets/talentpunkt_einfuehrung.dart';
import 'package:theory/theory.dart';

import 'gear_helpers.dart';
import 'test_view.dart';
import 'tutorial_helfer.dart';

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
          // Die Gebiete sind die Ausnahme: Sie erklärt er (Issue #183).
          if (text == null || text == Mentor.gebiete) continue;
          // Seit ADR-0095 ein paar Wörter: Licht und Punkt zeigen den Weg.
          expect(text.split(' ').length, lessThanOrEqualTo(8), reason: text);
        }
      }
      expect(Mentor.ersteBeute.split(' ').length, lessThanOrEqualTo(12));
      expect(Mentor.gebiete.split(' ').length, lessThanOrEqualTo(12));
    });
  });

  group('in der App', () {
    Future<ProviderContainer> starte(
      WidgetTester tester, {
      SaveData stand = const SaveData.empty(),
      Widget home = const HomeScreen(),
      bool hinweisWeg = false,
    }) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(stand),
          todayProvider.overrideWithValue(heute),
          if (hinweisWeg) hinweisGesehen,
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
      // Erst: wo die Gewohnheiten wohnen; ein Tipp irgendwohin weiter.
      expect(sagt(tester), satz(Schritt.gewohnheitenZeigen, MentorOrt.start));
      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.start));

      await tester.tap(find.byKey(HubCircle.keyFor('Theorie')));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeScreen), findsOneWidget);
      // Erst der Talentpunkt, groß in der Mitte; ein Tipp schickt ihn hoch.
      expect(sagt(tester), satz(Schritt.talentpunkt, MentorOrt.baum));
      expect(find.byKey(TalentpunktEinfuehrung.punktKey), findsOneWidget);
      expect(find.byType(ContinueReadingTile), findsNothing);
      await tester.tapAt(const Offset(200, 600));
      await tester.pumpAndSettle();
      expect(find.byKey(TalentpunktEinfuehrung.punktKey), findsNothing);
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.baum));
      // Die ganze Wahl im Licht, ohne gelben Punkt (07.11.2026).
      expect(find.byKey(Zeigefinger.ringKey), findsNothing);
      expect(find.byType(ScheinwerferLicht), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(ContinueReadingTile),
          matching: find.byType(ZeigeRing),
        ),
        findsWidgets,
      );
    });

    testWidgets('die erste Frage: der Mentor, zwei Vorschläge und das Eigene, '
        'je eine Zeile', (tester) async {
      await starte(tester);

      expect(ErsteGewohnheitKarte.vorschlaege, hasLength(2));
      final zeilen = <Rect>[
        // Erst der Mentor, dann die Zeilen (Issue #183).
        tester.getRect(find.byType(MentorKasten)),
        for (final v in ErsteGewohnheitKarte.vorschlaege)
          tester.getRect(find.text(v.name)),
        tester.getRect(find.byKey(ErsteGewohnheitKarte.eigenesKey)),
      ];
      for (var i = 1; i < zeilen.length; i++) {
        expect(zeilen[i].top, greaterThan(zeilen[i - 1].bottom), reason: '$i');
      }
      // Mittig: Die Frage steht nicht oben am Rand — Mentor und Karte
      // rücken zusammen in die Mitte.
      final karte = tester
          .getRect(find.byType(ErsteGewohnheitKarte))
          .expandToInclude(tester.getRect(find.byType(MentorKasten)));
      final mitte =
          tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
      expect((karte.center.dy - mitte).abs(), lessThan(120));
    });

    testWidgets('in der Theorie zuerst drei Seiten, der Baum auf Wunsch', (
      tester,
    ) async {
      await starte(
        tester,
        stand: SaveData(habits: einHaekchen),
        home: const SkillTreeScreen(),
        hinweisWeg: true,
      );

      expect(find.byType(ContinueReadingTile), findsNWidgets(3));
      expect(find.byType(TreeView), findsNothing);

      await tester.tap(find.byKey(SkillTreeScreen.erkundenKey));
      await tester.pumpAndSettle();

      expect(find.byType(TreeView), findsWidgets);
      expect(find.byKey(SkillTreeScreen.erkundenKey), findsNothing);
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
      final kreis = tester.getRect(find.byKey(HubCircle.keyFor('Fähigkeiten')));
      expect(kasten.bottom, lessThan(kreis.top));
      expect(
        kasten.top,
        greaterThan(
          tester.getRect(find.byKey(HubCircle.keyFor('Theorie'))).bottom,
        ),
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
      // Dann zeigt er auf der Startseite, wo die Fähigkeiten liegen.
      expect(c.read(ersterStartProvider).schritt, Schritt.faehigkeitenZeigen);
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
        hinweisWeg: true,
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

    testWidgets('nach dem ersten Sieg erklärt er die Gebiete, ganz oben '
        '(Issue #183)', (tester) async {
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

      expect(sagt(tester), Mentor.gebiete);
      // Er steht über „Heute“, nicht darunter.
      expect(
        tester.getRect(find.byType(MentorKasten)).bottom,
        lessThan(tester.getRect(find.byType(TodayCard)).top),
      );
    });

    testWidgets('mit der zweiten Gewohnheit schweigt er', (tester) async {
      final stand = ersteSeiteGelesen();
      final zweite = HabitCatalog.all
          .firstWhere((v) => v.id != HabitCatalog.starterId)
          .id;
      await starte(
        tester,
        stand: SaveData(
          habits: stand.habits.activate(zweite),
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
      expect(sagt(tester), satz(Schritt.gewohnheitenZeigen, MentorOrt.start));

      // 3. Wo die Gewohnheiten wohnen — ein Tipp irgendwohin.
      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.ersteSeite, MentorOrt.start));

      // 4. Die erste Seite, über den Vorschlag im Baum — erst der
      // Talentpunkt, ein Tipp schickt ihn an seinen Platz.
      await tester.tap(find.byKey(HubCircle.keyFor('Theorie')));
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.talentpunkt, MentorOrt.baum));
      await tester.tapAt(const Offset(200, 600));
      await tester.pumpAndSettle();
      // Der erste Vorschlag ist der des Mentors.
      await tester.tap(find.byType(ContinueReadingTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);

      final seite = theoryGraph.nodeById(theoryBasicsPath.first)!.lesson;
      await zuDenFragen(tester, seite);
      for (var i = 0; i < seite.questionCount; i++) {
        final frage = seite.questions.firstWhere(
          (q) => find.text(q.prompt).evaluate().isNotEmpty,
        );
        await waehle(tester, frage.options[frage.correctIndex]);
        final letzte = i == seite.questionCount - 1;
        await tester.tap(find.text(letzte ? 'Auswerten' : 'Weiter'));
        await tester.pumpAndSettle();
      }
      await feiernSchliessen(tester);

      expect(c.read(passedPagesProvider), 1);
      expect(c.read(playerLevelProvider).level, 2);
      // **Im Tutorial legt das Spiel Funkenstoß selbst an** (07.11.2026),
      // dann zeigt der Mentor, wo die Fähigkeiten liegen.
      expect(c.read(chosenAbilitiesProvider).contains('funkenstoss'), isTrue);
      expect(c.read(ersterStartProvider).schritt, Schritt.faehigkeitenZeigen);
      // Ein Tipp irgendwohin, und es geht in den Dungeon.
      // Zurück aus Seite und Baum auf die Startseite.
      Navigator.of(tester.element(find.byType(LessonScreen))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(SkillTreeScreen))).pop();
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.faehigkeitenZeigen, MentorOrt.start));
      await tester.tapAt(const Offset(200, 700));
      await tester.pumpAndSettle();
      expect(sagt(tester), satz(Schritt.grube, MentorOrt.start));
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
