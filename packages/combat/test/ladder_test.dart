import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Der Fortschritt in der Gegnerreihe und was er einbringt.
///
/// **Der wichtigste Test ist der ueber die Wiederholung.** ADR-0032 nimmt
/// zurueck, dass der Kampf gar nichts gibt -- aber nur unter der
/// Bedingung, dass er es genau einmal je Gegner gibt. Faellt dieser Test,
/// ist aus einer Belohnung eine Dauerquelle geworden, und `konzept.md`
/// Abschnitt 2 gilt nicht mehr.
void main() {
  group('Ein frischer Stand steht vor Sprosse eins', () {
    test('nichts geschlagen, nichts verdient', () {
      const stand = LadderProgress.empty();

      expect(stand.highestDefeated, 0);
      expect(stand.nextRung, 1);
      expect(stand.nextEnemy.id, Enemies.wegelagerer.id);
      expect(stand.earnedXp, 0);
      expect(stand.earnedGold, 0);
      expect(stand.isComplete, isFalse);
    });
  });

  group('Ein Sieg zaehlt genau einmal', () {
    test('der erste Sieg bringt Erfahrung und Gold', () {
      final stand = const LadderProgress.empty().defeat(1);

      expect(stand.highestDefeated, 1);
      expect(stand.earnedXp, LadderRewards.xpFor(1));
      expect(stand.earnedGold, LadderRewards.goldFor(1));
    });

    test('derselbe Gegner ein zweites Mal bringt nichts', () {
      // **Das ist die Bedingung, unter der es ueberhaupt Belohnung gibt.**
      // Ohne sie liesse sich der leichteste Gegner in Dauerschleife
      // schlagen, statt Haekchen zu setzen.
      final einmal = const LadderProgress.empty().defeat(1);
      final nochmal = einmal.defeat(1);

      expect(nochmal, einmal);
      expect(nochmal.earnedXp, einmal.earnedXp);
      expect(nochmal.earnedGold, einmal.earnedGold);
    });

    test('eine Sprosse laesst sich nicht ueberspringen', () {
      // Wer Sprosse 9 meldet, ohne 8 geschlagen zu haben, hat einen
      // Fehler im Aufrufer -- nicht einen Fortschritt.
      final stand = const LadderProgress.empty().defeat(9);

      expect(stand.highestDefeated, 0);
    });

    test('und die Reihe endet oben', () {
      var stand = const LadderProgress.empty();
      for (var rung = 1; rung <= Enemies.rungs; rung++) {
        stand = stand.defeat(rung);
      }

      expect(stand.highestDefeated, Enemies.rungs);
      expect(stand.isComplete, isTrue);
      expect(stand.earnedXp, LadderRewards.lifetimeXp);
      expect(stand.earnedGold, LadderRewards.lifetimeGold);

      // Oben angekommen bleibt der letzte Gegner stehen, statt ins Leere
      // zu zeigen -- so gibt es immer einen Kampf.
      expect(stand.nextRung, Enemies.rungs);
      expect(stand.defeat(Enemies.rungs + 1), stand);
    });
  });

  group('Die Belohnung waechst mit der Sprosse', () {
    test('spaeter ist mehr wert als frueher', () {
      for (var rung = 2; rung <= Enemies.rungs; rung++) {
        expect(
          LadderRewards.xpFor(rung),
          greaterThan(LadderRewards.xpFor(rung - 1)),
        );
        expect(
          LadderRewards.goldFor(rung),
          greaterThan(LadderRewards.goldFor(rung - 1)),
        );
      }
    });

    test('und die ganze Reihe bleibt eine ueberschaubare Menge', () {
      // **Der Deckel ist der Grund, warum es Belohnung geben darf.** Er
      // steht hier als Zahl, damit ein Griff an `LadderRewards` sofort
      // sichtbar macht, wie viel das Spiel insgesamt verschenkt.
      expect(LadderRewards.lifetimeXp, 2775);
      expect(LadderRewards.lifetimeGold, 1110);
    });
  });

  group('Der Stand ueberlebt einen Neustart', () {
    test('hin und zurueck', () {
      final stand = const LadderProgress.empty().defeat(1).defeat(2);
      final gelesen = LadderProgress.fromJson(stand.toJson());

      expect(gelesen, stand);
    });

    test('Unsinn kostet hoechstens die Reihe, nie den Stand', () {
      // ADR-0010: Alle `fromJson` sind nachsichtig.
      expect(
        LadderProgress.fromJson(<String, Object?>{'defeated': 'sieben'}),
        const LadderProgress.empty(),
      );
      expect(
        LadderProgress.fromJson(<String, Object?>{}),
        const LadderProgress.empty(),
      );
      expect(
        LadderProgress.fromJson(<String, Object?>{'defeated': -3}),
        const LadderProgress.empty(),
      );
    });

    test('eine zu hohe Sprosse wird geklemmt', () {
      final gelesen = LadderProgress.fromJson(<String, Object?>{
        'defeated': 999,
      });

      expect(gelesen.highestDefeated, Enemies.rungs);
    });
  });
}
