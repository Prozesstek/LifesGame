import 'package:achievements/achievements.dart';
import 'package:test/test.dart';

/// Prüft den **Inhalt** des Katalogs, nicht den Code drumherum — dieselbe
/// Bauform wie `catalog_test.dart` in `package:gear` und
/// `content_test.dart` in `package:theory`.
///
/// Der Katalog ist eine Tabelle mit siebenundzwanzig Zeilen. Eine solche
/// Tabelle lässt sich nicht von Hand stimmig halten; ohne diesen Test
/// prüft niemand nach, ob die Zahlen aus ADR-0033 auch die Zahlen im Code
/// sind.
void main() {
  group('Aufbau', () {
    test('jede Id kommt genau einmal vor', () {
      final ids = <String>{};
      for (final a in AchievementCatalog.all) {
        expect(ids.add(a.id), isTrue, reason: 'doppelte Id: ${a.id}');
      }
    });

    test('jeder Name kommt genau einmal vor', () {
      final namen = <String>{};
      for (final a in AchievementCatalog.all) {
        expect(namen.add(a.name), isTrue, reason: 'doppelt: ${a.name}');
      }
    });

    test('19 Meilensteine und 8 Entdeckungen', () {
      expect(AchievementCatalog.milestoneCount, 19);
      expect(AchievementCatalog.discoveryCount, 8);
      expect(AchievementCatalog.all, hasLength(27));
    });

    test('jeder Bereich ist besetzt', () {
      for (final area in AchievementArea.values) {
        expect(
          AchievementCatalog.inArea(area),
          isNotEmpty,
          reason: '${area.label} ist leer',
        );
      }
    });

    test('jede Bedingung steht im Klartext da', () {
      for (final a in AchievementCatalog.all) {
        expect(a.requirement.trim(), isNotEmpty, reason: a.id);
        expect(a.target, greaterThan(0), reason: a.id);
      }
    });
  });

  group('Die zwei Arten', () {
    test('jede Entdeckung steht auf der Entdeckungsstufe', () {
      for (final a in AchievementCatalog.all.where((a) => a.isDiscovery)) {
        expect(a.tier, AchievementTier.entdeckung, reason: a.id);
      }
    });

    test('kein Meilenstein steht auf der Entdeckungsstufe', () {
      for (final a in AchievementCatalog.all.where((a) => a.isMilestone)) {
        expect(a.tier, isNot(AchievementTier.entdeckung), reason: a.id);
      }
    });

    // Der Kern von ADR-0033: Wer für ein Selbstbild bezahlt wird, lernt,
    // dass es um die Bezahlung ging. Stünde hier eines Tages Gold, wäre
    // das eine Richtungsentscheidung und kein Zahlendetail.
    test('eine Entdeckung zahlt weder Gold noch Erfahrung', () {
      for (final a in AchievementCatalog.all.where((a) => a.isDiscovery)) {
        expect(a.tier.xp, 0, reason: a.id);
        expect(a.tier.gold, 0, reason: a.id);
        expect(a.tier.fame, greaterThan(0), reason: a.id);
      }
    });

    test('jeder Meilenstein zahlt alle drei', () {
      for (final a in AchievementCatalog.all.where((a) => a.isMilestone)) {
        expect(a.tier.xp, greaterThan(0), reason: a.id);
        expect(a.tier.gold, greaterThan(0), reason: a.id);
        expect(a.tier.fame, greaterThan(0), reason: a.id);
      }
    });

    test('keine Entdeckung bringt eine Fähigkeit mit', () {
      for (final a in AchievementCatalog.all.where((a) => a.isDiscovery)) {
        expect(a.moveId, isNull, reason: a.id);
      }
    });

    test('teurere Stufe heißt mehr von allem', () {
      const stufen = <AchievementTier>[
        AchievementTier.klein,
        AchievementTier.mittel,
        AchievementTier.gross,
      ];
      for (var i = 1; i < stufen.length; i++) {
        expect(stufen[i].xp, greaterThan(stufen[i - 1].xp));
        expect(stufen[i].gold, greaterThan(stufen[i - 1].gold));
        expect(stufen[i].fame, greaterThan(stufen[i - 1].fame));
      }
    });
  });

  group('Belohnungen', () {
    // Die drei Zahlen aus ADR-0033. Sie stehen dort im Text und hier im
    // Code -- wer eine Stufe verschiebt oder einen Eintrag ergänzt, sieht
    // hier, dass der ADR nachzuziehen ist.
    test('über ein Spielerleben: 1680 Erfahrung, 560 Gold, 385 Ruhm', () {
      expect(AchievementCatalog.lifetimeXp, 1680);
      expect(AchievementCatalog.lifetimeGold, 560);
      expect(AchievementCatalog.lifetimeFame, 385);
    });

    test(
        'der Ruhm teilt sich in 265 aus Meilensteinen und 120 aus Entdeckungen',
        () {
      var meilensteine = 0;
      var entdeckungen = 0;
      for (final a in AchievementCatalog.all) {
        if (a.isMilestone) {
          meilensteine += a.tier.fame;
        } else {
          entdeckungen += a.tier.fame;
        }
      }
      expect(meilensteine, 265);
      expect(entdeckungen, 120);
    });

    // Gegenprobe zu ADR-0032: Die Reihe gibt 2775 Erfahrung. Die
    // Errungenschaften sollen daneben stehen, nicht darüber.
    test('ein leerer Stand hat nichts verdient', () {
      const leer = AchievementStats.empty();
      expect(AchievementCatalog.earnedBy(leer), isEmpty);
      expect(AchievementCatalog.xpFor(leer), 0);
      expect(AchievementCatalog.goldFor(leer), 0);
      expect(AchievementCatalog.fameFor(leer), 0);
    });
  });

  group('Titel und Fähigkeiten', () {
    test('kein Titel hängt an zwei Errungenschaften', () {
      final titel = <String>{};
      for (final a in AchievementCatalog.all) {
        final id = a.titleId;
        if (id == null) continue;
        expect(titel.add(id), isTrue, reason: 'Titel doppelt vergeben: $id');
      }
    });

    test('dreizehn Titel werden vergeben', () {
      final titel = <String>{
        for (final a in AchievementCatalog.all)
          if (a.titleId != null) a.titleId!,
      };
      expect(titel, hasLength(13));
    });

    test('keine Fähigkeit hängt an zwei Errungenschaften', () {
      final moves = <String>{};
      for (final a in AchievementCatalog.all) {
        final id = a.moveId;
        if (id == null) continue;
        expect(moves.add(id), isTrue, reason: 'Move doppelt vergeben: $id');
      }
    });

    // Die vier aus ADR-0017, zurückgeholt über ADR-0033 -- einer je
    // Bereich. Dass die Ids drüben in `package:combat` ankommen, prüft
    // `test/abilities_seam_test.dart` in der App; hier ist es ein Wort.
    test('vier Fähigkeiten, eine je Bereich', () {
      final jeBereich = <AchievementArea, int>{};
      for (final a in AchievementCatalog.all) {
        if (a.moveId == null) continue;
        jeBereich[a.area] = (jeBereich[a.area] ?? 0) + 1;
      }
      expect(jeBereich, hasLength(AchievementArea.values.length));
      for (final anzahl in jeBereich.values) {
        expect(anzahl, 1);
      }
      expect(
        <String>{
          for (final a in AchievementCatalog.all)
            if (a.moveId != null) a.moveId!,
        },
        <String>{'breath', 'poison_strike', 'heavy_attack', 'mend'},
      );
    });
  });

  group('Messen', () {
    test('der Fortschritt läuft nie über das Ziel hinaus', () {
      const viel = AchievementStats(totalChecks: 100000, longestStreak: 9999);
      for (final a in AchievementCatalog.all) {
        expect(a.progressIn(viel), lessThanOrEqualTo(a.target), reason: a.id);
      }
    });

    test('verdient heißt: nichts fehlt mehr', () {
      const stand = AchievementStats(totalChecks: 50);
      final verlaesslich = AchievementCatalog.byId('verlaesslich')!;
      expect(verlaesslich.isEarnedBy(stand), isTrue);
      expect(verlaesslich.missingFor(stand), 0);
      expect(verlaesslich.progressIn(stand), 50);
    });

    test('ein Meilenstein zeigt, wie weit es noch ist', () {
      const stand = AchievementStats(totalChecks: 38);
      final verlaesslich = AchievementCatalog.byId('verlaesslich')!;
      expect(verlaesslich.isEarnedBy(stand), isFalse);
      expect(verlaesslich.progressIn(stand), 38);
      expect(verlaesslich.missingFor(stand), 12);
    });

    test('mehr Fortschritt nimmt nie etwas weg', () {
      const wenig = AchievementStats(totalChecks: 60, longestStreak: 30);
      const viel = AchievementStats(totalChecks: 260, longestStreak: 61);

      final vorher = AchievementCatalog.earnedIdsBy(wenig);
      final nachher = AchievementCatalog.earnedIdsBy(viel);
      expect(nachher.containsAll(vorher), isTrue);
      expect(
        AchievementCatalog.fameFor(viel),
        greaterThanOrEqualTo(AchievementCatalog.fameFor(wenig)),
      );
    });

    test('eine Stufe der Häkchen löst drei Errungenschaften nacheinander aus',
        () {
      expect(
        AchievementCatalog.earnedIdsBy(const AchievementStats(totalChecks: 1)),
        contains('erster-schritt'),
      );
      expect(
        AchievementCatalog.earnedIdsBy(const AchievementStats(totalChecks: 49)),
        isNot(contains('verlaesslich')),
      );
      const zweihundert = AchievementStats(totalChecks: 200);
      expect(
        AchievementCatalog.earnedIdsBy(zweihundert),
        containsAll(<String>['erster-schritt', 'verlaesslich', 'unermuedlich']),
      );
    });

    test('Titel und Fähigkeiten kommen mit dem Stand', () {
      const stand = AchievementStats(highestRung: 10);
      expect(
        AchievementCatalog.earnedMoveIdsBy(stand),
        contains('heavy_attack'),
      );
      expect(AchievementCatalog.earnedTitleIdsBy(stand), isEmpty);

      const mitTitel = AchievementStats(longestStreak: 30);
      expect(
        AchievementCatalog.earnedTitleIdsBy(mitTitel),
        containsAll(<String>['entschlossen', 'bestaendig']),
      );
    });
  });
}
