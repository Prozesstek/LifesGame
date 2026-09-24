import 'package:gear/gear.dart';
import 'package:test/test.dart';

/// Würfel, Tagesladen, Beute und Schlüssel (ADR-0048).
void main() {
  group('Die Tabelle', () {
    test('Episch erst ab seiner Stufe, Legendär erst ab seiner', () {
      for (var stufe = 0; stufe <= 30; stufe++) {
        final w = GearRolls.weightsFor(stufe);
        for (final rarity in w.keys) {
          expect(
            GearGates.isOpen(rarity, highestRung: stufe),
            isTrue,
            reason: 'Stufe $stufe würfelt $rarity',
          );
        }
      }
      expect(GearRolls.weightsFor(9).containsKey(GearRarity.epic), isFalse);
      expect(GearRolls.weightsFor(10).containsKey(GearRarity.epic), isTrue);
      expect(
        GearRolls.weightsFor(19).containsKey(GearRarity.legendary),
        isFalse,
      );
      expect(
        GearRolls.weightsFor(20).containsKey(GearRarity.legendary),
        isTrue,
      );
    });

    test('tiefer heisst seltener', () {
      int gewoehnlich(int s) => GearRolls.weightsFor(s)[GearRarity.common]!;
      int summe(int s) =>
          GearRolls.weightsFor(s).values.fold<int>(0, (a, b) => a + b);
      final flach = gewoehnlich(1) / summe(1);
      expect(flach, greaterThan(gewoehnlich(15) / summe(15)));
      expect(
        gewoehnlich(15) / summe(15),
        greaterThan(gewoehnlich(25) / summe(25)),
      );
    });
  });

  group('Ein Wurf', () {
    test('jeder Wert liegt zwischen 85 und 115 % des Katalogwerts', () {
      for (final item in GearCatalog.all) {
        final soll = item.bonus.scaled;
        for (var seed = 1; seed < 40; seed++) {
          final wurf = GearRolls.rollBonus(item, GearDice(seed));
          for (final (ist, katalog) in <(int, int)>[
            (wurf.attack, soll.attack),
            (wurf.maxHp, soll.maxHp),
            (wurf.defense, soll.defense),
            (wurf.maxEnergy, soll.maxEnergy),
          ]) {
            if (katalog == 0) {
              expect(ist, 0, reason: item.id);
              continue;
            }
            expect(ist, greaterThanOrEqualTo((katalog * 0.85).floor()));
            expect(ist, lessThanOrEqualTo((katalog * 1.15).ceil()));
          }
        }
      }
    });

    test('die Würfe streuen wirklich', () {
      final klinge = GearCatalog.byId('gear-uebungsklinge')!;
      final angriffe = <int>{
        for (var seed = 1; seed < 60; seed++)
          GearRolls.rollBonus(klinge, GearDice(seed)).attack,
      };
      expect(angriffe.length, greaterThan(3));
    });
  });

  group('Der Tagesladen', () {
    test('sechs Angebote, eins je Platz', () {
      final heute = DailyShop.offersFor(20355, highestRung: 0);
      expect(heute, hasLength(6));
      expect(
        heute.map((c) => c.item!.slot).toSet(),
        GearSlot.values.toSet(),
      );
    });

    test('derselbe Tag gibt denselben Laden, ein anderer einen anderen', () {
      String laden(int tag) => DailyShop.offersFor(tag, highestRung: 0)
          .map((c) => '${c.itemId}:${c.bonus.total}')
          .join(',');
      expect(laden(20355), laden(20355));
      final andere = <String>{for (var t = 20356; t < 20366; t++) laden(t)};
      expect(andere.contains(laden(20355)), isFalse);
    });

    test('der Preis ist der des Katalogs, egal wie gewürfelt', () {
      for (final angebot in DailyShop.offersFor(20355, highestRung: 30)) {
        expect(angebot.paid, angebot.item!.price);
      }
    });

    test('ohne Stufe 10 nie Episches, über viele Tage', () {
      for (var tag = 20000; tag < 20400; tag++) {
        for (final a in DailyShop.offersFor(tag, highestRung: 9)) {
          expect(a.item!.rarity.index, lessThan(GearRarity.epic.index));
        }
      }
    });

    test('tief genug, und Episches taucht auf', () {
      final seltenheiten = <GearRarity>{
        for (var tag = 20000; tag < 20100; tag++)
          for (final a in DailyShop.offersFor(tag, highestRung: 25))
            a.item!.rarity,
      };
      expect(seltenheiten, contains(GearRarity.epic));
      expect(seltenheiten, contains(GearRarity.legendary));
    });

    test('die Uid nennt Tag und Platz', () {
      final waffe = DailyShop.offersFor(20355, highestRung: 0).first;
      expect(waffe.uid, 'laden-20355-waffe');
    });
  });

  group('Die Beute', () {
    test('wiederholbar und eindeutig', () {
      final a = GearLoot.drop(stage: 5, dayIndex: 20355, nth: 1);
      final b = GearLoot.drop(stage: 5, dayIndex: 20355, nth: 1);
      final c = GearLoot.drop(stage: 5, dayIndex: 20355, nth: 2);
      expect(a.uid, b.uid);
      expect(a.itemId, b.itemId);
      expect(a.bonus, b.bonus);
      expect(c.uid, isNot(a.uid));
    });

    test('kostet nichts', () {
      expect(GearLoot.drop(stage: 1, dayIndex: 1, nth: 1).paid, 0);
    });

    test('flach gibt nie Episches, tief manchmal Legendäres', () {
      for (var n = 0; n < 300; n++) {
        final flach = GearLoot.drop(stage: 9, dayIndex: 20355, nth: n);
        expect(flach.item!.rarity.index, lessThan(GearRarity.epic.index));
      }
      final tief = <GearRarity>{
        for (var n = 0; n < 300; n++)
          GearLoot.drop(stage: 25, dayIndex: 20355, nth: n).item!.rarity,
      };
      expect(tief, contains(GearRarity.legendary));
    });

    test('jeder Platz kann fallen', () {
      final plaetze = <GearSlot>{
        for (var n = 0; n < 100; n++)
          GearLoot.drop(stage: 3, dayIndex: 20355, nth: n).item!.slot,
      };
      expect(plaetze, GearSlot.values.toSet());
    });
  });

  group('Die Schlüssel', () {
    test('verdient minus verbraucht, höchstens zehn', () {
      expect(GearKeys.available(earned: 0, consumed: 0), 0);
      expect(GearKeys.available(earned: 4, consumed: 1), 3);
      expect(GearKeys.available(earned: 40, consumed: 0), GearKeys.cap);
    });

    test('einsetzen nimmt einen, und der Überhang verfällt', () {
      final nachher = GearKeys.consume(earned: 40, consumed: 0);
      expect(GearKeys.available(earned: 40, consumed: nachher), 9);
      // Neue Schlüssel kommen danach wieder dazu.
      expect(GearKeys.available(earned: 43, consumed: nachher), 10);
    });

    test('ohne Schlüssel ändert Einsetzen nichts', () {
      expect(GearKeys.consume(earned: 3, consumed: 3), 3);
    });
  });
}
