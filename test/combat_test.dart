import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/combat/combat_controller.dart';
import 'package:lifes_game/combat/combat_screen.dart';
import 'package:lifes_game/combat/widgets/timing_bar.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

void main() {
  _tippflaeche();

  group('CombatController', () {
    test('startet mit vollem Leben und leerem Log', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session = container.read(combatControllerProvider);
      expect(session.state.player.hp, session.state.player.maxHp);
      expect(session.state.isOver, isFalse);
      expect(session.log, isEmpty);
    });

    test('ein Kampf hat immer mindestens den Waffenmove', () {
      // Slot 1 gehört der Waffe und ist nie leer (ADR-0017). Ohne diesen
      // Test bleibt ein leeres Moveset unbemerkt: Der Bildschirm zeigt
      // dann einfach keine Knöpfe, ohne Fehlermeldung.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(combatControllerProvider).moves, isNotEmpty);
    });

    test('restart behält das Moveset — der Kampf bleibt bedienbar', () {
      // Der Fehler, den dieser Test verhindert: `CombatSession.moves` hat
      // einen leeren Standardwert. `restart()` baute die Sitzung neu, ohne
      // ihn zu setzen — und weil die Gegnerwahl `restart()` aufruft, war
      // jeder über den Startbildschirm begonnene Kampf ohne einen einzigen
      // Knopf. Sichtbar war das nur im Bild, nicht als Fehler.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      controller.restart();

      final session = container.read(combatControllerProvider);
      expect(session.moves, isNotEmpty);
      expect(session.moves, container.read(activeMovesProvider));
    });

    test('restart liest das Moveset neu ein', () {
      // Innerhalb eines Kampfes friert das Moveset ein, zwischen zwei
      // Kämpfen nicht: Ein neuer Kampf soll die Fähigkeiten von jetzt
      // verwenden (ADR-0017).
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      controller.restart();

      expect(
        container.read(combatControllerProvider).moves,
        container.read(activeMovesProvider),
      );
    });

    test('eine Runde verändert den Zustand und liefert Events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      final events = controller.playRound(Moves.basicAttack, TimedHit.perfect);

      expect(events, isNotEmpty);
      expect(events.whereType<DamageDealt>(), isNotEmpty);
      expect(
        container.read(combatControllerProvider).state.enemy.hp,
        lessThan(Enemies.all.first.maxHp),
      );
    });

    test('restart setzt den Kampf vollständig zurück', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      controller
        ..playRound(Moves.basicAttack, TimedHit.none)
        ..appendLog(<String>['irgendwas'])
        ..restart();

      final session = container.read(combatControllerProvider);
      expect(session.state.enemy.hp, session.state.enemy.maxHp);
      expect(session.log, isEmpty);
      expect(session.state.round, 1);
    });

    test('nach Kampfende werden keine Züge mehr angenommen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      // Lange genug prügeln, bis eine Seite fällt.
      for (var i = 0; i < 200; i++) {
        if (container.read(combatControllerProvider).state.isOver) break;
        controller.playRound(Moves.basicAttack, TimedHit.perfect);
      }

      expect(container.read(combatControllerProvider).state.isOver, isTrue);
      expect(controller.playRound(Moves.basicAttack, TimedHit.none), isEmpty);
    });
  });

  group('CombatScreen', () {
    Future<void> pumpScreen(WidgetTester tester, {SaveData? saved}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (saved != null) savedGameProvider.overrideWithValue(saved),
          ],
          child: const MaterialApp(home: CombatScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('ein frischer Charakter hat genau den Waffen-Move', (
      tester,
    ) async {
      // Seit ADR-0016/0017 ist auf Level 1 nur Slot 1 offen, und der
      // gehoert der Waffe. Vier Knoepfe waeren eine Behauptung, die der
      // Charakterbildschirm nicht deckt.
      await pumpScreen(tester);

      expect(find.text(Moves.basicAttack.name), findsOneWidget);
      expect(find.text(Moves.heavyAttack.name), findsNothing);
      expect(find.text(Moves.mend.name), findsNothing);
    });

    testWidgets('ohne Waffe greift der Rueckfall', (tester) async {
      // Slot 1 darf nie leer sein -- sonst haette ein frischer Charakter
      // keinen einzigen Knopf.
      await pumpScreen(tester, saved: const SaveData.empty());

      expect(
        find.text(Moves.byId(AbilityCatalog.fallbackMoveId)!.name),
        findsOneWidget,
      );
    });

    testWidgets('Moves ohne genug Energie sind deaktiviert', (tester) async {
      // Ein Charakter mit offenem zweitem Slot und einem teuren Move
      // darauf: Zu Beginn hat er 0 Energie, also ist nur der Waffen-Move
      // bezahlbar.
      await pumpScreen(tester, saved: _mitSlot2(Moves.heavyAttack.id));

      final heavy = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(Moves.heavyAttack.name),
          matching: find.byType(FilledButton),
        ),
      );
      expect(heavy.onPressed, isNull);

      final basic = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(Moves.basicAttack.name),
          matching: find.byType(FilledButton),
        ),
      );
      expect(basic.onPressed, isNotNull);
    });

    testWidgets('eine nicht gewaehlte Faehigkeit taucht nicht auf', (
      tester,
    ) async {
      await pumpScreen(tester, saved: _mitSlot2(Moves.heavyAttack.id));

      expect(find.text(Moves.heavyAttack.name), findsOneWidget);
      expect(find.text(Moves.mend.name), findsNothing);
    });
  });

  group('Gegnerwahl', () {
    test('beginnt beim leichtesten Gegner', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedEnemyProvider).id, Enemies.all.first.id);
      expect(
        container.read(combatControllerProvider).state.enemy.name,
        Enemies.all.first.name,
      );
    });

    test('ein anderer Gegner gilt ab dem nächsten Kampf', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedEnemyProvider.notifier)
          .select(Enemies.bergwaechter);
      container.read(combatControllerProvider.notifier).restart();

      final gegner = container.read(combatControllerProvider).state.enemy;
      expect(gegner.name, Enemies.bergwaechter.name);
      expect(gegner.maxHp, Enemies.bergwaechter.maxHp);
    });

    test('die Gegner werden nach oben hin härter', () {
      // Die Reihenfolge ist kein Zufall: Der Bildschirm zeigt sie so an,
      // und die Einschätzung darunter setzt sie voraus.
      for (var i = 1; i < Enemies.all.length; i++) {
        final leichter = Enemies.all[i - 1];
        final schwerer = Enemies.all[i];
        expect(schwerer.maxHp, greaterThan(leichter.maxHp));
        expect(
          schwerer.attack + schwerer.defense,
          greaterThanOrEqualTo(leichter.attack + leichter.defense),
        );
      }
    });
  });

  group('EnemyPickerScreen', () {
    testWidgets('zeigt alle Gegner mit einer Einschaetzung', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: EnemyPickerScreen())),
      );
      await tester.pumpAndSettle();

      for (final gegner in Enemies.all) {
        expect(find.text(gegner.name), findsOneWidget, reason: gegner.name);
      }
      // Ein frischer Charakter schafft den ersten knapp und die anderen
      // nicht -- genau das soll der Bildschirm vorher sagen.
      expect(find.text('wird knapp'), findsOneWidget);
      expect(find.text('vermutlich noch zu stark'), findsNWidgets(2));
    });
  });
}

/// Ein Stand, der Level 3 erreicht hat (zweiter Slot offen) und [moveId]
/// darauf gelegt hat.
///
/// Erfahrung kommt aus Haekchen -- gerechnet wird sie in
/// `package:progression`, hier wird nur genug davon erzeugt.
SaveData _mitSlot2(String moveId) {
  const habitId = 'habit-drei-aufgaben';
  const start = Day(2026, 8, 17);

  // **Seit ADR-0019 haengt jede waehlbare Faehigkeit an einem Knoten.**
  // Ein Move im Slot allein reicht nicht mehr -- er wird beim
  // Zusammenstellen geprueft, und ohne bestandene Seite faellt er
  // heraus. Deshalb steht hier auch der Theoriefortschritt.
  final node = theoryGraph.nodes.firstWhere((n) => n.unlocksAbility == moveId);
  final theory = const TheoryProgress.empty().submit(node.lesson, <int?>[
    for (final q in node.lesson.questions) q.correctIndex,
  ]).progress;

  final noetig = LevelCurve.totalXpFor(3) - theory.totalXp;

  var tracker = const HabitTracker.empty().activate(habitId);
  var day = start;
  while (tracker.totalXp < noetig) {
    tracker = tracker.check(habitId, day).tracker;
    day = day.next;
  }

  return SaveData(
    theory: theory,
    habits: tracker,
    abilities: const ChosenAbilities.empty().withAt(0, moveId),
  );
}

/// Der Tipp im Zeitfenster zählt überall im Kampfbereich.
///
/// Auf einem Handy trifft man eine 34 Pixel hohe Leiste im Eifer nicht
/// zuverlässig. Die Fläche liegt deshalb über dem ganzen Körper — aber
/// **nicht** über der AppBar, sonst käme man aus dem Kampf nicht mehr
/// heraus, ohne vorher zu tippen.
void _tippflaeche() {
  group('Tippen im Zeitfenster', () {
    Future<void> starteZeitfenster(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CombatScreen())),
      );
      await tester.pump();

      // Der Waffenmove richtet Schaden an und öffnet damit das Fenster.
      await tester.tap(find.text(Moves.basicAttack.name));
      await tester.pump();
    }

    testWidgets('ein Tipp auf die Kämpfer löst aus', (tester) async {
      await starteZeitfenster(tester);
      expect(find.byType(TimingBar), findsOneWidget);

      // Weit weg von der Leiste: oben im Bild, wo die Figuren stehen.
      await tester.tapAt(const Offset(200, 260));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Fenster zu, es wurde eine Runde gespielt.
      expect(find.byType(TimingBar), findsNothing);
    });

    testWidgets('ein Tipp auf die Leiste löst weiterhin aus', (tester) async {
      await starteZeitfenster(tester);

      await tester.tap(find.byType(TimingBar));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(TimingBar), findsNothing);
    });

    testWidgets('die AppBar bleibt frei', (tester) async {
      // Die Fläche darf die AppBar nicht verdecken. Läge sie darüber, wäre
      // ein begonnener Zug eine Falle: Der Zurück-Pfeil sitzt dort, und man
      // käme aus dem Kampf nicht mehr heraus, ohne vorher zu tippen.
      await starteZeitfenster(tester);

      await tester.tapAt(tester.getCenter(find.byType(AppBar)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Nichts ausgelöst — das Zeitfenster läuft weiter.
      expect(find.byType(TimingBar), findsOneWidget);
    });
  });
}
