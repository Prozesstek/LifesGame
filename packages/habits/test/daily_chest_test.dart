import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Tagestruhe (ADR-0044): Wer heute alles erledigt, öffnet eine Truhe,
/// deren Inhalt aus dem Datum gewürfelt ist.
void main() {
  const heute = Day(2026, 9, 23);

  CustomHabit eigene(String id) {
    return CustomHabit(
      id: id,
      name: id,
      stat: HabitStat.staerke,
      difficulty: HabitDifficulty.mittel,
      priority: HabitPriority.normal,
    );
  }

  HabitTracker zweiLaufende() {
    return const HabitTracker.empty()
        .addCustom(eigene('a'), slots: 5)
        .addCustom(eigene('b'), slots: 5)
        .activate('a')
        .activate('b');
  }

  HabitTracker allesErledigt(Day tag) {
    return zweiLaufende().check('a', tag).tracker.check('b', tag).tracker;
  }

  /// Der erste Tag ab [ab], dessen Truhe [stufe] ist.
  Day tagMit(ChestTier stufe, {Day ab = heute}) {
    var tag = ab;
    for (var i = 0; i < 5000; i++) {
      if (DailyChest.forDay(tag).tier == stufe) return tag;
      tag = tag.next;
    }
    throw StateError('keine $stufe in 5000 Tagen');
  }

  group('Der Inhalt', () {
    test('derselbe Tag gibt dieselbe Truhe', () {
      final a = DailyChest.forDay(heute);
      final b = DailyChest.forDay(const Day(2026, 9, 23));
      expect(a.tier, b.tier);
      expect(a.gold, b.gold);
      expect(a.freezes, b.freezes);
    });

    test('Gold liegt in der Spanne der Stufe, Eis nur in der Eis-Truhe', () {
      var tag = heute;
      for (var i = 0; i < 2000; i++) {
        final truhe = DailyChest.forDay(tag);
        final stufe = truhe.tier;
        expect(truhe.gold, inInclusiveRange(stufe.goldMin, stufe.goldMax));
        expect(truhe.freezes, truhe.tier.freezes);
        tag = tag.next;
      }
    });

    test('über viele Tage kommen die Stufen so oft, wie sie sollen', () {
      const tage = 20000;
      final gezaehlt = <ChestTier, int>{};
      var gold = 0;
      var tag = const Day(2020, 1, 1);
      for (var i = 0; i < tage; i++) {
        final truhe = DailyChest.forDay(tag);
        gezaehlt[truhe.tier] = (gezaehlt[truhe.tier] ?? 0) + 1;
        gold += truhe.gold;
        tag = tag.next;
      }
      final gewicht = ChestTier.values.fold<int>(0, (s, t) => s + t.weight);
      for (final stufe in ChestTier.values) {
        expect(
          (gezaehlt[stufe] ?? 0) / tage,
          closeTo(stufe.weight / gewicht, 0.015),
          reason: stufe.name,
        );
      }
      // Der Laden ist auf 25 Gold am Tag aus Gewohnheiten ausgelegt. Die
      // Truhe legt knapp die Hälfte dazu — nicht mehr.
      expect(gold / tage, inInclusiveRange(8, 14));
    });
  });

  group('Öffnen', () {
    test('erst wenn heute alles erledigt ist', () {
      final halb = zweiLaufende().check('a', heute).tracker;
      expect(halb.canOpenChest(heute), isFalse);
      expect(halb.openChest(heute).content, isNull);

      expect(allesErledigt(heute).canOpenChest(heute), isTrue);
    });

    test('einmal je Tag', () {
      final offen = allesErledigt(heute).openChest(heute);
      expect(offen.content, isNotNull);
      expect(offen.tracker.hasOpenedChest(heute), isTrue);
      expect(offen.tracker.canOpenChest(heute), isFalse);
      expect(offen.tracker.openChest(heute).content, isNull);
    });

    test('ihr Gold zählt zum Gold der Gewohnheiten', () {
      final vorher = allesErledigt(heute);
      final offen = vorher.openChest(heute);
      expect(
        offen.tracker.totalGold,
        vorher.totalGold + offen.content!.gold,
      );
      expect(offen.tracker.chestGold, offen.content!.gold);
    });

    test('ein Häkchen zurückzunehmen nimmt die Truhe nicht zurück', () {
      final offen = allesErledigt(heute).openChest(heute).tracker;
      final zurueck = offen.uncheck('b', heute);
      expect(zurueck.hasOpenedChest(heute), isTrue);
      expect(zurueck.chestGold, offen.chestGold);
      expect(zurueck.canOpenChest(heute), isFalse);
    });

    test('ohne laufende Gewohnheit gibt es keine Truhe', () {
      expect(const HabitTracker.empty().canOpenChest(heute), isFalse);
    });
  });

  group('Das Streak-Eis kommt aus der Truhe', () {
    test('eine Eis-Truhe legt ein Eis in den Vorrat', () {
      final tag = tagMit(ChestTier.eis);
      final vorher = allesErledigt(tag);
      final nachher = vorher.openChest(tag).tracker;

      expect(nachher.freezesLeft, vorher.freezesLeft + 1);
    });

    test('ohne Truhe bleibt es beim einen Eis zum Start', () {
      expect(
        const HabitTracker.empty().freezesLeft,
        StreakFreeze.lifetimeStock,
      );
    });
  });

  group('Speichern', () {
    test('geöffnete Truhen überleben den Neustart', () {
      final offen = allesErledigt(heute).openChest(heute).tracker;
      final gelesen = HabitTracker.fromJson(offen.toJson());

      expect(gelesen.hasOpenedChest(heute), isTrue);
      expect(gelesen.chestGold, offen.chestGold);
    });

    test('ein Stand ohne Truhe schreibt keinen Abschnitt', () {
      expect(zweiLaufende().toJson().containsKey('chests'), isFalse);
    });

    test('Unlesbares wird übersprungen, nicht geworfen', () {
      final json = allesErledigt(heute).openChest(heute).tracker.toJson()
        ..['chests'] = <Object?>['kein-tag', 7, heute.toString()];
      final gelesen = HabitTracker.fromJson(json);

      expect(gelesen.hasOpenedChest(heute), isTrue);
      expect(gelesen.openedChests, hasLength(1));
    });
  });
}
