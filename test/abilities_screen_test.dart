import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'gear_helpers.dart';
import 'test_view.dart';

/// Der Fähigkeiten-Bildschirm (ADR-0049).
///
/// **Die Plätze standen bis zum 25.09. im Charakter**, und die Tests
/// dazu in `character_test.dart`. Sie sind hierher gewandert und um das
/// erweitert, was es dort nicht gab: den ganzen Katalog, die grauen
/// Einträge und das Blatt mit den Werten.
void main() {
  const habitId = 'habit-drei-aufgaben';
  const tag = Day(2026, 8, 17);

  /// Ein Fortschritt, in dem jeder Knoten mit Fähigkeit bestanden ist.
  ///
  /// **Seit ADR-0019 hängt jede wählbare Fähigkeit an einem Knoten.**
  /// Ohne Theoriefortschritt gäbe es nichts, was in einen freien Platz
  /// passt — diese Tests wollen aber die Plätze prüfen, nicht das
  /// Freischalten.
  TheoryProgress mitKnoten() {
    var progress = const TheoryProgress.empty();
    for (final ability in AbilityCatalog.choosable) {
      if (ability.source case FromTheory(:final nodeId)) {
        final lesson = theoryGraph.nodeById(nodeId)!.lesson;
        progress = progress.submit(lesson, <int?>[
          for (final q in lesson.questions) q.correctIndex,
        ]).progress;
      }
    }
    return progress;
  }

  SaveData aufLevel(int level, {Loadout? loadout, ChosenAbilities? abilities}) {
    final theory = mitKnoten();
    // Bestandene Seiten bringen selbst Erfahrung mit — sonst läge das
    // Level über dem gewünschten und es wären mehr Plätze offen.
    final noetig = LevelCurve.totalXpFor(level) - theory.totalXp;
    var tracker = const HabitTracker.empty().activate(habitId);
    var day = tag;
    while (tracker.totalXp < noetig) {
      tracker = tracker.check(habitId, day).tracker;
      day = day.next;
    }
    return SaveData(
      theory: theory,
      habits: tracker,
      loadout: loadout ?? const Loadout.empty(),
      abilities: abilities ?? const ChosenAbilities.empty(),
    );
  }

  Widget appMit(SaveData saved) {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(tag),
      ],
      child: const MaterialApp(home: AbilitiesScreen()),
    );
  }

  group('Die vier Plätze', () {
    testWidgets('auf Level 1 ist nur der Waffenplatz offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      // Drei gesperrte Plätze nennen ihre Stufe, statt zu fehlen.
      expect(find.text('ab Level 3'), findsOneWidget);
      expect(find.text('ab Level 6'), findsOneWidget);
      expect(find.text('ab Level 10'), findsOneWidget);
    });

    testWidgets('ohne Waffe trägt Platz 1 trotzdem etwas', (tester) async {
      // Der wichtigste Fall: Auf Level 1 ist Platz 1 der einzige offene.
      // Wäre er leer, hätte ein frischer Charakter keinen einzigen Zug.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final rueckfall = PitWeapons.byMoveId(AbilityCatalog.fallbackMoveId)!;
      expect(find.text(rueckfall.name), findsOneWidget);
    });

    testWidgets('Platz 1 zeigt die Fähigkeit der Waffe, nicht die Waffe', (
      tester,
    ) async {
      useTallView(tester);
      final klinge = GearCatalog.all.firstWhere(
        (i) => i.slot == GearSlot.waffe,
      );
      final loadout = const Loadout.empty().buy(
        angebot(klinge.id),
        availableGold: klinge.price,
      );

      await tester.pumpWidget(appMit(aufLevel(1, loadout: loadout)));

      final move = PitWeapons.byMoveId(AbilityCatalog.weaponMoves[klinge.id]!)!;
      expect(find.text(move.name), findsWidgets);
      expect(find.text(klinge.name), findsNothing);
    });

    testWidgets('auf Level 3 geht der zweite Platz auf', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      expect(find.text('ab Level 3'), findsNothing);
      expect(find.text('ab Level 6'), findsOneWidget);
      expect(find.text('leer'), findsOneWidget);
      expect(find.textContaining('Ein Platz ist noch frei'), findsOneWidget);
    });

    testWidgets('auf Level 10 sind alle vier offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      expect(find.textContaining('ab Level'), findsNothing);
      expect(find.text('leer'), findsNWidgets(AbilitySlots.total - 1));
      expect(find.textContaining('3 Plätze sind noch frei'), findsOneWidget);
    });

    testWidgets('ein gesperrter Platz lässt sich nicht antippen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('ab Level 3'));
      await tester.pumpAndSettle();

      expect(find.text('Auf welchen Platz?'), findsNothing);
    });

    testWidgets('ein leerer Platz sagt, wo etwas herkommt', (tester) async {
      // **Er ist antippbar, aber er wählt nicht.** Das Blatt mit den
      // Werten ist der Weg, und wer oben tippt, soll das erfahren
      // statt auf einen toten Knopf zu treffen.
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      await tester.tap(find.text('leer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unten eine Fähigkeit antippen'),
        findsOneWidget,
      );
    });

    testWidgets('der Waffenplatz zeigt seine Werte, legt aber nichts an', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      final rueckfall = PitWeapons.byMoveId(AbilityCatalog.fallbackMoveId)!;
      await tester.tap(find.text(rueckfall.name));
      await tester.pumpAndSettle();

      expect(find.text('Grundangriff — schlägt von selbst'), findsOneWidget);
      expect(find.text('Auf welchen Platz?'), findsNothing);
      expect(
        find.textContaining('Kommt von der getragenen Waffe'),
        findsOneWidget,
      );
    });
  });

  group('Der Katalog darunter', () {
    testWidgets('jede wählbare Fähigkeit steht da, auch die gesperrten', (
      tester,
    ) async {
      // **Das ist der Grund für den Bildschirm.** Im Charakter zeigte
      // das Auswahlblatt nur das Freigeschaltete — neunzehn Fähigkeiten,
      // von denen ein frischer Charakter keine einzige sah.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      for (final ability in AbilityCatalog.choosable) {
        final pit = PitAbilities.byId(ability.moveId)!;
        await tester.scrollUntilVisible(
          find.text(pit.name),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(pit.name), findsOneWidget, reason: pit.name);
      }
    });

    testWidgets('die Überschriften zählen mit, was offen ist', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      // Ohne jeden Fortschritt ist nichts freigeschaltet.
      expect(
        find.textContaining(
          '0 von ${AbilityCatalog.choosable.length} freigeschaltet',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mit Fortschritt zählt die Zeile mehr', (tester) async {
      // **Die Zahl wird nicht nachgerechnet, sondern abgelesen.** Was
      // offen ist, entscheidet [unlockedAbilitiesProvider] und sonst
      // nichts (`gotchas.md`, eine Frage, eine Stelle) — eine zweite
      // Rechnung im Test hätte irgendwann eine andere Antwort. Beim
      // ersten Anlauf hatte sie das schon: Auf Level 10 kommen zu den
      // elf Knoten-Fähigkeiten noch die aus Errungenschaften dazu.
      final saved = aufLevel(10);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(saved),
          todayProvider.overrideWithValue(tag),
        ],
      );
      addTearDown(container.dispose);
      final erwartet = container.read(unlockedAbilitiesProvider).length;

      useTallView(tester);
      await tester.pumpWidget(appMit(saved));

      expect(erwartet, greaterThan(0));
      expect(
        find.textContaining(
          '$erwartet von ${AbilityCatalog.choosable.length} freigeschaltet',
        ),
        findsOneWidget,
      );
    });
  });

  group('Das Blatt mit den Werten', () {
    /// Tippt die Fähigkeit im Raster an und wartet auf das Blatt.
    Future<void> oeffne(WidgetTester tester, PitAbility pit) async {
      // **`.last` ist der Eintrag im Raster.** Liegt die Fähigkeit schon
      // auf einem Platz, steht ihr Name zweimal da — und
      // `scrollUntilVisible` braucht genau einen.
      await tester.scrollUntilVisible(
        find.text(pit.name).last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(pit.name).last);
      await tester.pumpAndSettle();
    }

    testWidgets('nennt Mana, Abklingzeit, Art und Wirkung', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      await oeffne(tester, PitAbilities.funkenstoss);

      expect(find.text('Mana'), findsOneWidget);
      expect(find.text('${PitAbilities.funkenstoss.manaCost}'), findsOneWidget);
      expect(find.text('Abklingzeit'), findsOneWidget);
      expect(find.text('1,5 s'), findsOneWidget);
      expect(find.text('Art'), findsOneWidget);
      expect(find.text(PitKind.angriff.label), findsOneWidget);
      expect(find.text('Schaden'), findsOneWidget);
      expect(find.text(PitAbilities.funkenstoss.description), findsOneWidget);
    });

    testWidgets('auch eine gesperrte erklärt sich vollständig', (tester) async {
      // **Der ausdrückliche Wunsch**, und dieselbe Hausregel wie beim
      // gesperrten Stück im Laden: Ein Ziel, das man nicht sieht, ist
      // keins.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await oeffne(tester, PitAbilities.sternenfall);

      expect(find.text('Mana'), findsOneWidget);
      expect(find.text('Abklingzeit'), findsOneWidget);
      expect(find.text('Schaden'), findsOneWidget);
      expect(find.text(PitAbilities.sternenfall.description), findsOneWidget);
      // Die Bedingung steht als Bedingung da, nicht als „freigeschaltet".
      final sternenfall = AbilityCatalog.byMoveId(PitAbilities.sternenfall.id)!;
      expect(find.text(sternenfall.requirement), findsOneWidget);
      expect(find.textContaining('Freigeschaltet:'), findsNothing);
      // Auf Level 1 gibt es noch gar keinen freien Platz — das Blatt
      // sagt das, statt drei tote Knöpfe zu zeigen.
      expect(
        find.textContaining('Noch kein freier Platz offen'),
        findsOneWidget,
      );
    });

    testWidgets('eine gesperrte lässt sich nicht anlegen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      await oeffne(tester, PitAbilities.sternenfall);

      final knopf = tester.widget<InkWell>(
        find.ancestor(of: find.text('Platz 2'), matching: find.byType(InkWell)),
      );
      expect(knopf.onTap, isNull);
    });

    testWidgets('anlegen über den Platz-Knopf', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      await oeffne(tester, PitAbilities.funkenstoss);
      await tester.tap(find.text('Platz 2'));
      await tester.pumpAndSettle();

      // Der Platz trägt jetzt ihren Namen — im Raster steht er ein
      // zweites Mal.
      expect(find.text(PitAbilities.funkenstoss.name), findsNWidgets(2));
      expect(find.text('leer'), findsNWidgets(AbilitySlots.total - 2));
    });

    testWidgets('der Knopf sagt vorher, was er überschreibt', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(
          aufLevel(
            10,
            abilities: const ChosenAbilities.empty().withAt(
              0,
              PitAbilities.bluetentau.id,
            ),
          ),
        ),
      );

      await oeffne(tester, PitAbilities.funkenstoss);

      // Unter „Platz 2" steht, wer dort liegt.
      expect(find.text(PitAbilities.bluetentau.name), findsWidgets);
      expect(find.text('Platz 2'), findsOneWidget);
      expect(find.text('Platz 3'), findsOneWidget);
      // **Platz 4 wird nicht angeboten**, obwohl er offen ist:
      // `ChosenAbilities` hält keine Lücken, der Knopf würde auf Platz 3
      // landen.
      expect(find.text('Platz 4'), findsNothing);
    });

    testWidgets('räumen macht den Platz wieder leer', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(
          aufLevel(
            3,
            abilities: const ChosenAbilities.empty().withAt(
              0,
              PitAbilities.bluetentau.id,
            ),
          ),
        ),
      );

      await oeffne(tester, PitAbilities.bluetentau);
      await tester.tap(find.text('Platz räumen'));
      await tester.pumpAndSettle();

      expect(find.text('leer'), findsOneWidget);
    });
  });

  group('Was gewählt ist, geht in den Kampf', () {
    testWidgets('nur die offenen Plätze', (tester) async {
      // Der eigentliche Zweck der Verkabelung: Was gewählt ist, wirkt
      // sich aus — aber nur so weit, wie Plätze offen sind (ADR-0016).
      useTallView(tester);
      final saved = aufLevel(
        3,
        abilities: const ChosenAbilities.empty()
            .withAt(0, PitAbilities.funkenstoss.id)
            .withAt(1, PitAbilities.bluetentau.id),
      );

      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(saved),
          todayProvider.overrideWithValue(tag),
        ],
      );
      addTearDown(container.dispose);

      final moves = container.read(activeMovesProvider);

      // Level 3: Waffenplatz plus genau ein freier.
      expect(moves, hasLength(2));
      expect(moves.last, PitAbilities.funkenstoss.id);
    });
  });
}
