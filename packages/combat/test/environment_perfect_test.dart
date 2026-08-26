import 'package:combat/combat.dart';
import 'package:test/test.dart';

import 'test_fixtures.dart';

/// Legt [move] mit dem angegebenen Timing und gibt die Events zurueck.
List<CombatEvent> lege(Move move, TimedHit timing, {int attack = 16}) {
  final engine = engineWith();
  final step = engine.resolveRound(
    CombatState.start(
      player: hero(maxHp: 500, attack: attack, energy: 10, maxEnergy: 10),
      enemy: dummy(maxHp: 500, attack: 10),
    ),
    PlayerAction(move: move, timedHit: timing),
  );
  return step.events;
}

int gelegteRunden(List<CombatEvent> events) {
  return events.whereType<EnvironmentSet>().single.turns;
}

void main() {
  group('Perfekt gelegt haelt eine Runde laenger', () {
    test('Frostnebel: drei Runden, perfekt vier', () {
      expect(gelegteRunden(lege(AbilityMoves.frostnebel, TimedHit.none)), 3);
      expect(gelegteRunden(lege(AbilityMoves.frostnebel, TimedHit.perfect)), 4);
    });

    test('ein guter Treffer reicht nicht', () {
      expect(gelegteRunden(lege(AbilityMoves.frostnebel, TimedHit.good)), 3);
    });

    test('Sandsturm, Giftmoor und Vulkanbruch ebenso', () {
      int perfekt(Move move) => gelegteRunden(lege(move, TimedHit.perfect));

      expect(perfekt(AbilityMoves.sandsturm), 4);
      expect(perfekt(AbilityMoves.giftmoor), 5);
      expect(perfekt(AbilityMoves.vulkanbruch), 4);
    });

    test('Zeitdehnung haelt drei Runden statt zwei', () {
      final events = lege(AbilityMoves.zeitdehnung, TimedHit.perfect);
      final gesetzt = events
          .whereType<StatusApplied>()
          .where((e) => e.statusId == 'time_dilation')
          .last;

      expect(gesetzt.turns, 3);
    });
  });

  group('Die Bonusrunde haengt hinten an, nicht vorn', () {
    test('Giftmoor faengt auch perfekt gelegt bei vollem Schaden an', () {
      // 5 HP je Runde bei Angriff 16, steigend um 2. Rechnete die Engine
      // die verstrichenen Runden gegen die Katalogdauer statt gegen die
      // tatsaechliche, kaeme hier eine Runde *vor* dem Anfang heraus --
      // und damit 3 statt 5 Schaden.
      final events = lege(AbilityMoves.giftmoor, TimedHit.perfect);
      final tick = events
          .whereType<StatusTicked>()
          .where((e) => e.statusId == 'poison_bog')
          .single;

      expect(tick.damage, 5);
    });

    test('ohne Bonusrunde gilt dieselbe Zahl', () {
      final events = lege(AbilityMoves.giftmoor, TimedHit.none);
      final tick = events
          .whereType<StatusTicked>()
          .where((e) => e.statusId == 'poison_bog')
          .single;

      expect(tick.damage, 5);
    });
  });

  group('Wer eine Perfect-Wirkung hat, hat ein Zeitfenster', () {
    test('alle fuenfzehn Faehigkeiten werden getippt', () {
      for (final move in AbilityMoves.all) {
        expect(
          move.hasTimingWindow,
          isTrue,
          reason: '${move.name} haette keine Leiste bekommen.',
        );
      }
    });

    test('Sammeln und Atemzug nicht -- sie haben nichts zu gewinnen', () {
      expect(Moves.mend.hasTimingWindow, isFalse);
      expect(Moves.breath.hasTimingWindow, isFalse);
    });

    test('die acht ohne Schaden waeren vorher uebersprungen worden', () {
      final ohneSchaden =
          AbilityMoves.all.where((m) => !m.dealsDamage).toList();

      expect(ohneSchaden, hasLength(8));
      expect(ohneSchaden.every((m) => m.hasTimingWindow), isTrue);
    });
  });
}
