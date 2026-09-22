import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die vier Stufen des Tages (ADR-0040).
void main() {
  const tag = 20718; // 22.09.2026

  group('Welche vier', () {
    test('vier verschiedene, alle schon geschafft, aufsteigend', () {
      for (var hoechste = 4; hoechste <= PitStage.count; hoechste++) {
        for (var t = tag; t < tag + 30; t++) {
          final heute = PitDailies.forDay(t, hoechste);
          expect(heute, hasLength(4), reason: '$hoechste, $t');
          expect(heute.toSet(), hasLength(4), reason: '$hoechste, $t');
          expect(heute.first, greaterThanOrEqualTo(1));
          expect(heute.last, lessThanOrEqualTo(hoechste));
          expect(heute, orderedEquals(List<int>.of(heute)..sort()));
        }
      }
    });

    test('eine leichte und eine von ganz oben', () {
      const hoechste = 30;
      for (var t = tag; t < tag + 60; t++) {
        final heute = PitDailies.forDay(t, hoechste);
        expect(heute.first, lessThanOrEqualTo(9), reason: '$t: $heute');
        expect(heute.last, greaterThanOrEqualTo(21), reason: '$t: $heute');
      }
    });

    test('derselbe Tag gibt dieselben vier — für beide Spieler', () {
      expect(PitDailies.forDay(tag, 20), PitDailies.forDay(tag, 20));
    });

    test('sie wechseln von Tag zu Tag', () {
      final woche = <String>{
        for (var t = tag; t < tag + 7; t++) PitDailies.forDay(t, 30).join(','),
      };
      expect(woche.length, greaterThan(4));
    });

    test('wer weniger als vier geschafft hat, bekommt alle', () {
      expect(PitDailies.forDay(tag, 0), isEmpty);
      expect(PitDailies.forDay(tag, 2), <int>[1, 2]);
    });
  });

  group('Was sie einbringen', () {
    test('ein Viertel des Erstsiegs, gerundet', () {
      final erstsieg = LadderRewards.xpFor(15);
      expect(LadderRewards.dailyXpFor(15), (erstsieg / 4).round());
      expect(
        LadderRewards.dailyGoldFor(15),
        (LadderRewards.goldFor(15) / 4).round(),
      );
    });

    test('einmal je Stufe und Tag', () {
      const stand = LadderProgress(highestDefeated: 20);
      final heute = stand.dailiesOn(tag);
      final einmal = stand.claimDaily(tag, heute.first);
      final zweimal = einmal.claimDaily(tag, heute.first);

      final daily = LadderRewards.dailyXpFor(heute.first);
      expect(einmal.earnedXp, stand.earnedXp + daily);
      expect(zweimal.earnedXp, einmal.earnedXp);
    });

    test('am nächsten Tag zahlt dieselbe Stufe wieder', () {
      var stand = const LadderProgress(highestDefeated: 3);
      stand = stand.claimDaily(tag, 2).claimDaily(tag + 1, 2);
      expect(
        stand.earnedGold,
        const LadderProgress(highestDefeated: 3).earnedGold +
            2 * LadderRewards.dailyGoldFor(2),
      );
    });

    test('eine Stufe, die heute kein Daily ist, zahlt nichts', () {
      const stand = LadderProgress(highestDefeated: 30);
      final heute = stand.dailiesOn(tag);
      final andere = List<int>.generate(30, (i) => i + 1)
          .firstWhere((s) => !heute.contains(s));
      expect(stand.claimDaily(tag, andere).earnedXp, stand.earnedXp);
    });

    test('vier Dailies bringen weniger als die Stufe selbst beim ersten Mal',
        () {
      // Die Grössenordnung aus ADR-0040: ein Tag Dailies ist kein Ersatz
      // für einen Tag Gewohnheiten, und erst recht nicht für die Reihe.
      expect(
        LadderRewards.maxDailyXpPerDay,
        lessThanOrEqualTo(LadderRewards.xpFor(PitStage.count)),
      );
      expect(
        LadderRewards.maxDailyGoldPerDay,
        lessThanOrEqualTo(LadderRewards.goldFor(PitStage.count)),
      );
    });
  });

  group('Eingefroren', () {
    test('wer mittags eine neue Stufe schafft, behält seine vier', () {
      var stand = const LadderProgress(highestDefeated: 12);
      stand = stand.withDailiesFrozen(tag);
      final morgens = stand.dailiesOn(tag);

      for (var s = 13; s <= 20; s++) {
        stand = stand.defeat(s);
      }
      expect(stand.dailiesOn(tag), morgens);
      // Ohne Einfrieren wären es jetzt andere.
      expect(PitDailies.forDay(tag, 20), isNot(morgens));
    });

    test('überlebt einen Neustart', () {
      const vorher = LadderProgress(highestDefeated: 18);
      final stand = vorher
          .withDailiesFrozen(tag)
          .claimDaily(tag, vorher.dailiesOn(tag).last);
      final wieder = LadderProgress.fromJson(stand.toJson());

      expect(wieder, stand);
      expect(wieder.earnedXp, stand.earnedXp);
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
}
