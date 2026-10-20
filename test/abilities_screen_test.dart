import 'package:flutter/gestures.dart';
import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/character/widgets/ability_sheet.dart';
import 'package:lifes_game/ui/wackeln.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
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
/// erweitert, was es dort nicht gab: das Raster und das Blatt mit den
/// Werten. Seit Issue #138 stehen dort nur die eigenen Fähigkeiten; was
/// es sonst gibt, steht in der Sammlung (ADR-0080).
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
    // Nur die neunzehn von vor ADR-0073: Mit allen Knoten brächten die
    // bestandenen Seiten allein mehr Erfahrung als Level 3.
    for (final ability in AbilityCatalog.choosable.take(19)) {
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
      expect(
        find.bySemanticsLabel(RegExp('gesperrt, ab Level 2\$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('gesperrt, ab Level 6\$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('gesperrt, ab Level 10\$')),
        findsOneWidget,
      );
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

    testWidgets('auf Level 2 geht der zweite Platz auf (ADR-0079)', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(2)));

      expect(
        find.bySemanticsLabel(RegExp('gesperrt, ab Level 2\$')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(RegExp('gesperrt, ab Level 6\$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')),
        findsOneWidget,
      );
    });

    testWidgets('auf Level 10 sind alle vier offen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      expect(find.bySemanticsLabel(RegExp('gesperrt')), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')),
        findsNWidgets(AbilitySlots.total - 1),
      );
    });

    testWidgets('ein gesperrter Platz lässt sich nicht antippen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.bySemanticsLabel(RegExp('gesperrt, ab Level 2\$')));
      await tester.pumpAndSettle();

      expect(find.text('Auf welchen Platz?'), findsNothing);
    });

    /// Die Kacheln, die gerade wackeln, weil sie gewählt werden können.
    Finder wackelnd() => find.byWidgetPredicate((w) => w is Wackeln && w.aktiv);

    testWidgets('Platz antippen, dann eine Fähigkeit (Issue #138)', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AbilitiesScreen)),
      );
      expect(wackelnd(), findsNothing);

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')));
      await tester.pumpAndSettle();

      // Alles Eigene wackelt und lässt sich wählen.
      final eigene = container.read(unlockedAbilitiesProvider);
      expect(wackelnd(), findsNWidgets(eigene.length));

      await tester.tap(
        find.descendant(of: wackelnd().first, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();

      expect(container.read(chosenAbilitiesProvider).at(0), isNotNull);
      expect(wackelnd(), findsNothing);
    });

    testWidgets('ein zweiter Tipp auf den Platz bricht ab', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(3)));

      final platz = find.bySemanticsLabel(RegExp(r'^Platz \d, leer$'));
      await tester.tap(platz);
      await tester.pumpAndSettle();
      await tester.tap(platz);
      await tester.pumpAndSettle();

      expect(wackelnd(), findsNothing);
    });

    testWidgets('ohne eigene Fähigkeit schickt der Platz zur Sammlung', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData.empty()),
            todayProvider.overrideWithValue(tag),
            playerLevelProvider.overrideWithValue(
              LevelCurve.levelFor(LevelCurve.totalXpFor(3)),
            ),
          ],
          child: const MaterialApp(home: AbilitiesScreen()),
        ),
      );

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Sammlung'), findsOneWidget);
      expect(wackelnd(), findsNothing);
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

  group('Ziehen wie beim Deckbau (ADR-0057)', () {
    /// Hält [name] im Raster gedrückt und zieht es auf [ziel].
    Future<void> ziehe(WidgetTester tester, String name, Finder ziel) async {
      await tester.scrollUntilVisible(
        find.text(name).last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(name).last),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      // Das Hochrollen läuft ab, erst danach stehen die Plätze fest.
      await tester.pumpAndSettle();

      final platz = tester.getCenter(ziel);
      await gesture.moveTo(platz + const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(platz);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(AbilitiesScreen)));

    testWidgets('halten, ziehen, loslassen legt sie auf den Platz', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      await ziehe(
        tester,
        PitAbilities.funkenstoss.name,
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')).first,
      );

      expect(
        containerOf(tester).read(chosenAbilitiesProvider).at(0),
        PitAbilities.funkenstoss.id,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')),
        findsNWidgets(AbilitySlots.total - 2),
      );
    });

    testWidgets('ein belegter Platz wird ersetzt', (tester) async {
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

      await ziehe(
        tester,
        PitAbilities.funkenstoss.name,
        find.text(PitAbilities.bluetentau.name).first,
      );

      final chosen = containerOf(tester).read(chosenAbilitiesProvider);
      expect(chosen.at(0), PitAbilities.funkenstoss.id);
      expect(chosen.contains(PitAbilities.bluetentau.id), isFalse);
    });

    testWidgets('hinter einer Lücke nimmt kein Platz an', (tester) async {
      // **Dieselbe Grenze wie bei den Knöpfen im Blatt.**
      // `ChosenAbilities` hält keine Lücken: Auf Platz 4 bei leerem
      // Platz 2 landete die Fähigkeit in Wahrheit auf Platz 2.
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      await ziehe(
        tester,
        PitAbilities.funkenstoss.name,
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')).last,
      );

      expect(containerOf(tester).read(chosenAbilitiesProvider).isEmpty, isTrue);
    });

    testWidgets('der Waffenplatz nimmt nichts an', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      final rueckfall = PitWeapons.byMoveId(AbilityCatalog.fallbackMoveId)!;
      await ziehe(
        tester,
        PitAbilities.funkenstoss.name,
        find.text(rueckfall.name).first,
      );

      expect(containerOf(tester).read(chosenAbilitiesProvider).isEmpty, isTrue);
      expect(find.text(rueckfall.name), findsWidgets);
    });

    testWidgets('eine gesperrte steht gar nicht da', (tester) async {
      // Seit Issue #138 nur Eigenes im Raster; was fehlt, steht in der
      // Sammlung. Sternenfall braucht sechzig Tage Kette.
      useTallView(tester);
      await tester.pumpWidget(appMit(aufLevel(10)));

      expect(find.text(PitAbilities.sternenfall.name), findsNothing);
    });
  });

  group('Das Raster darunter', () {
    testWidgets('nur, was freigeschaltet ist (Issue #138)', (tester) async {
      // Bis dahin stand hier der ganze Katalog, Gesperrtes grau. Das
      // steht jetzt in der Sammlung, mit dem Hinweis, woher.
      final saved = aufLevel(10);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(saved),
          todayProvider.overrideWithValue(tag),
        ],
      );
      addTearDown(container.dispose);
      final eigene = container.read(unlockedAbilitiesProvider);

      useTallView(tester);
      await tester.pumpWidget(appMit(saved));

      expect(find.byType(Wackeln), findsNWidgets(eigene.length));
    });

    testWidgets('ein frischer Stand hat ein leeres Raster', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.byType(Wackeln), findsNothing);
    });

    testWidgets('die Überschriften zählen mit, was offen ist', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      // Ohne jeden Fortschritt ist nichts freigeschaltet.
      expect(
        find.bySemanticsLabel(
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
        find.bySemanticsLabel(
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

    /// Öffnet das Blatt einer gesperrten Fähigkeit. Im Raster steht sie
    /// seit Issue #138 nicht mehr; das Blatt kann es weiter.
    Future<void> gesperrt(
      WidgetTester tester, {
      required List<String?> freiePlaetze,
    }) async {
      final ability = AbilityCatalog.byMoveId(PitAbilities.sternenfall.id)!;
      useTallView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showAbilitySheet(
                    context,
                    karte: AbilityCard.faehigkeit(
                      ability: ability,
                      pit: PitAbilities.sternenfall,
                      unlocked: false,
                      currentFreeIndex: null,
                      attack: 10,
                    ),
                    freiePlaetze: freiePlaetze,
                  ),
                  child: const Text('los'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('los'));
      await tester.pumpAndSettle();
    }

    testWidgets('auch eine gesperrte erklärt sich vollständig', (tester) async {
      // **Der ausdrückliche Wunsch**, und dieselbe Hausregel wie beim
      // gesperrten Stück im Laden: Ein Ziel, das man nicht sieht, ist
      // keins.
      await gesperrt(tester, freiePlaetze: const <String?>[]);

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
      await gesperrt(tester, freiePlaetze: const <String?>[null]);

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
      expect(
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')),
        findsNWidgets(AbilitySlots.total - 2),
      );
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

      expect(
        find.bySemanticsLabel(RegExp(r'^Platz \d, leer$')),
        findsOneWidget,
      );
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
