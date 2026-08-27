import 'package:combat/combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/battle/floating_text.dart';

/// Die Zahlen über den Kämpfern.
///
/// Geprüft wird die **Zuordnung**, nicht das Bild: welche Quelle welche
/// Farbe bekommt und wer Funken trägt. Ob es auf einem Handy gut aussieht,
/// beantwortet kein Widget-Test — dafür muss man hinsehen.
void main() {
  group('Schaden ist rot, Heilung grün', () {
    test('die beiden Grundfarben sind klar unterscheidbar', () {
      // Rot heisst: deutlich mehr Rot als Grün. Grün umgekehrt. Das ist
      // die Aussage, auf die es ankommt — nicht der genaue Farbwert.
      expect(DamageColors.hit.r, greaterThan(DamageColors.hit.g));
      expect(DamageColors.heal.g, greaterThan(DamageColors.heal.r));
    });

    test('ein geblockter Schlag ist weder rot noch grün', () {
      expect(DamageColors.blocked, isNot(DamageColors.hit));
      expect(DamageColors.blocked, isNot(DamageColors.heal));
    });
  });

  group('Jede Schadensquelle hat ihre eigene Farbe', () {
    test('Gift ist lila, Sandsturm gelb, Lava rot', () {
      final gift = DamageColors.forSource('poison');
      final sand = DamageColors.forSource('sandstorm');
      final lava = DamageColors.forSource('lava');

      // Lila: viel Blau, wenig Grün.
      expect(gift.b, greaterThan(gift.g));
      // Sandgelb: Rot und Grün hoch, Blau deutlich niedriger.
      expect(sand.b, lessThan(sand.g));
      expect(sand.r, greaterThan(sand.b));
      // Lava: rot.
      expect(lava.r, greaterThan(lava.g));
    });

    test('keine zwei Quellen teilen sich eine Farbe', () {
      final quellen = <String>[
        'poison',
        'poison_bog',
        'burn',
        'frost',
        'sandstorm',
        'lava',
      ];
      final farben = <int>{
        for (final id in quellen) DamageColors.forSource(id).toARGB32(),
      };

      expect(farben, hasLength(quellen.length));
    });

    test('jede Umgebung des Spiels hat eine eigene Farbe bekommen', () {
      // Die Naht: `package:combat` kennt vier Umgebungen. Kommt eine
      // fünfte dazu, fällt sie hier auf, statt still in Treffer-Rot zu
      // erscheinen.
      for (final environment in Environments.all) {
        expect(
          DamageColors.forSource(environment.id),
          isNot(DamageColors.hit),
          reason: '${environment.name} hat keine eigene Farbe.',
        );
      }
    });

    test('was niemand eingetragen hat, bleibt sichtbar', () {
      expect(DamageColors.forSource('gibt-es-nicht'), DamageColors.hit);
    });

    test('nur das Lavafeld trägt Funken', () {
      expect(DamageColors.sparklesFor('lava'), isTrue);
      expect(DamageColors.sparklesFor('poison'), isFalse);
      expect(DamageColors.sparklesFor('sandstorm'), isFalse);
    });
  });

  group('Was ein Event über dem Kopf anzeigt', () {
    test('ein Treffer zeigt die Zahl in Rot', () {
      final readout = damageReadoutFor(
        const DamageDealt(target: Side.enemy, amount: 17, timedHitFactor: 1),
      );

      expect(readout, isNotNull);
      expect(readout!.text, '17');
      expect(readout.color, DamageColors.hit);
      expect(readout.target, Side.enemy);
    });

    test('ein perfekter Treffer steht grösser da', () {
      final normal = damageReadoutFor(
        const DamageDealt(target: Side.enemy, amount: 17, timedHitFactor: 1),
      );
      final perfekt = damageReadoutFor(
        const DamageDealt(target: Side.enemy, amount: 17, timedHitFactor: 1.2),
      );

      expect(perfekt!.fontSize, greaterThan(normal!.fontSize));
    });

    test('Heilung zeigt ein Plus in Grün', () {
      final readout = damageReadoutFor(
        const Healed(target: Side.player, amount: 20),
      );

      expect(readout!.text, '+20');
      expect(readout.color, DamageColors.heal);
    });

    test('ein ganz geblockter Schlag sagt „Geblockt"', () {
      final readout = damageReadoutFor(
        const DamageAbsorbed(target: Side.player, amount: 9, complete: true),
      );

      expect(readout!.text, 'Geblockt');
      expect(readout.color, DamageColors.blocked);
    });

    test('ein teilweise geblockter zeigt nur die Zahl, die durchkommt', () {
      // Das Absorb-Event schweigt; gleich darauf kommt das DamageDealt
      // mit dem Rest, und das trägt die Zahl.
      final geblockt = damageReadoutFor(
        const DamageAbsorbed(target: Side.player, amount: 4, complete: false),
      );
      final durch = damageReadoutFor(
        const DamageDealt(target: Side.player, amount: 9, timedHitFactor: 1),
      );

      expect(geblockt, isNull);
      expect(durch!.text, '9');
    });

    test('Gift zeigt seine Zahl in seiner Farbe', () {
      final readout = damageReadoutFor(
        const StatusTicked(target: Side.enemy, statusId: 'poison', damage: 3),
      );

      expect(readout!.text, '3');
      expect(readout.color, DamageColors.forSource('poison'));
      expect(readout.color, isNot(DamageColors.hit));
      expect(readout.sparkle, isFalse);
    });

    test('das Lavafeld bekommt Funken', () {
      final readout = damageReadoutFor(
        const StatusTicked(target: Side.enemy, statusId: 'lava', damage: 6),
      );

      expect(readout!.sparkle, isTrue);
    });

    test('ein Effekt ohne Schaden zeigt nichts', () {
      // Nicht jeder Tick kostet HP — ein Schild tickt auch.
      expect(
        damageReadoutFor(
          const StatusTicked(target: Side.enemy, statusId: 'shield', damage: 0),
        ),
        isNull,
      );
    });

    test('Ereignisse ohne Zahl zeigen nichts', () {
      expect(damageReadoutFor(const RoundStarted(2)), isNull);
      expect(damageReadoutFor(const ShieldBroke(Side.player)), isNull);
      expect(
        damageReadoutFor(
          const EnergyChanged(side: Side.player, delta: 3, current: 3),
        ),
        isNull,
      );
    });
  });
}
