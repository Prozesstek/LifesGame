import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die vier Stufen des Tages (ADR-0040) gibt es seit ADR-0072 nicht
/// mehr — aber was ein Stand damit verdient hat, zählt weiter.
void main() {
  const tag = 20718; // 22.09.2026

  /// Ein Stand, wie ihn die App bis ADR-0072 geschrieben hat.
  Map<String, Object?> alterStand() {
    return <String, Object?>{
      'defeated': 18,
      'dailies': <String, Object?>{
        '$tag': <String, Object?>{
          'picks': <int>[3, 8, 11, 17],
          'cleared': <int>[3, 17],
          'partial': <String, Object?>{
            '8': <int>[4, 1],
          },
        },
      },
    };
  }

  group('Die Dailies von damals', () {
    test('was sie gezahlt haben, zählt weiter', () {
      final stand = LadderProgress.fromJson(alterStand());
      const ohne = LadderProgress(highestDefeated: 18);

      expect(
        stand.earnedXp,
        ohne.earnedXp +
            LadderRewards.dailyXpFor(3) +
            LadderRewards.dailyXpFor(17) +
            4,
        reason: 'Zwei geschaffte Dailies und ein angefangenes.',
      );
      expect(
        stand.earnedGold,
        ohne.earnedGold +
            LadderRewards.dailyGoldFor(3) +
            LadderRewards.dailyGoldFor(17) +
            1,
      );
    });

    test('sie überleben das Speichern', () {
      final stand = LadderProgress.fromJson(alterStand());
      final wieder = LadderProgress.fromJson(stand.toJson());

      expect(wieder, stand);
      expect(wieder.earnedXp, stand.earnedXp);
      expect(wieder.earnedGold, stand.earnedGold);
    });

    test('ein Viertel des Erstsiegs, gerundet', () {
      expect(
        LadderRewards.dailyXpFor(15),
        (LadderRewards.xpFor(15) / 4).round(),
      );
      expect(
        LadderRewards.dailyGoldFor(15),
        (LadderRewards.goldFor(15) / 4).round(),
      );
    });

    test('ein erfundener Eintrag bringt kein Gold', () {
      final wieder = LadderProgress.fromJson(<String, Object?>{
        'defeated': 5,
        'dailies': <String, Object?>{
          '$tag': <String, Object?>{
            'picks': <int>[1, 2, 3, 4],
            'cleared': <int>[4, 29, 30],
          },
        },
      });
      expect(wieder.dailyClears[tag], <int>{4});
    });
  });

  group('Seit ADR-0072', () {
    test('eine geschaffte Stufe zahlt nichts mehr, an keinem Tag', () {
      final stand = LadderProgress.fromJson(alterStand());

      for (var stufe = 1; stufe <= 18; stufe++) {
        expect(stand.potFor(stufe), (xp: 0, gold: 0), reason: 'Stufe $stufe');
        final danach = stand.bookRun(
          stufe,
          won: true,
          collected: (xp: 999, gold: 999),
        );
        expect(danach.earnedXp, stand.earnedXp, reason: 'Stufe $stufe');
        expect(danach.earnedGold, stand.earnedGold, reason: 'Stufe $stufe');
      }
    });

    test('ein Sieg dort verändert die alte Historie nicht', () {
      final stand = LadderProgress.fromJson(alterStand());
      final danach = stand.bookRun(8, won: true, collected: (xp: 9, gold: 9));

      expect(danach, stand);
    });

    test('eine Niederlage auf geschaffter Stufe zählt weiter als Niederlage',
        () {
      const stand = LadderProgress(highestDefeated: 10);
      final danach = stand.bookRun(4, won: false, collected: (xp: 9, gold: 9));

      expect(danach.defeatsAt(4), 1);
      expect(danach.earnedXp, stand.earnedXp);
    });
  });
}
