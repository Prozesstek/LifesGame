import 'package:identity/identity.dart';
import 'package:test/test.dart';

/// Prueft den Titelkatalog als Inhalt, so wie `catalog_test.dart` den Laden
/// und `content_test.dart` die Lektionen prueft. Wer einen Titel ergaenzt,
/// bekommt hier automatisch Rueckmeldung.
void main() {
  group('Der Katalog ist in sich stimmig', () {
    test('es gibt ueberhaupt Titel', () {
      expect(TitleCatalog.all, isNotEmpty);
    });

    test('jede Id kommt nur einmal vor', () {
      final ids = TitleCatalog.all.map((title) => title.id).toSet();

      expect(ids.length, TitleCatalog.all.length);
    });

    test('jeder Wortlaut kommt nur einmal vor', () {
      final labels = TitleCatalog.all.map((title) => title.label).toSet();

      expect(labels.length, TitleCatalog.all.length);
    });

    test('jeder Titel hat Wortlaut und lesbare Bedingung', () {
      for (final title in TitleCatalog.all) {
        expect(title.label.trim(), isNotEmpty, reason: title.id);
        expect(title.requirement.trim(), isNotEmpty, reason: title.id);
      }
    });

    test('jeder Titel stellt mindestens eine Bedingung', () {
      // Ein Titel ohne Bedingung waere von Anfang an da -- und damit kein
      // verdienter Titel mehr, sondern eine Auswahl (ADR-0013).
      for (final title in TitleCatalog.all) {
        final sum =
            title.requiredStreak + title.requiredLessons + title.requiredChecks;
        expect(sum, greaterThan(0), reason: title.id);
      }
    });

    test('byId findet jeden Titel und sonst nichts', () {
      for (final title in TitleCatalog.all) {
        expect(TitleCatalog.byId(title.id), same(title));
      }
      expect(TitleCatalog.byId('gibtsnicht'), isNull);
      expect(TitleCatalog.byId(null), isNull);
    });
  });

  group('Verdienen', () {
    test('ein frischer Charakter traegt keinen Titel', () {
      expect(TitleCatalog.earnedBy(const TitleStats.empty()), isEmpty);
    });

    test('genau auf der Schwelle zaehlt als verdient', () {
      for (final title in TitleCatalog.all) {
        final exact = TitleStats(
          longestStreak: title.requiredStreak,
          passedLessons: title.requiredLessons,
          totalChecks: title.requiredChecks,
        );

        expect(title.isEarnedBy(exact), isTrue, reason: title.id);
      }
    });

    test('einer unter der Schwelle reicht nicht', () {
      for (final title in TitleCatalog.all) {
        final justUnder = TitleStats(
          longestStreak: title.requiredStreak - 1,
          passedLessons: title.requiredLessons - 1,
          totalChecks: title.requiredChecks - 1,
        );

        expect(title.isEarnedBy(justUnder), isFalse, reason: title.id);
      }
    });

    test('wer alles erreicht hat, traegt jeden Titel', () {
      const alles = TitleStats(
        longestStreak: 999,
        passedLessons: 999,
        totalChecks: 9999,
      );

      expect(TitleCatalog.earnedBy(alles).length, TitleCatalog.all.length);
    });

    test('mehr Fortschritt nimmt nie einen Titel weg', () {
      // Monotonie: Sie ist der Grund, warum longestStreak und nicht die
      // laufende Streak hereingereicht wird.
      const wenig = TitleStats(
        longestStreak: 30,
        passedLessons: 5,
        totalChecks: 50,
      );
      const mehr = TitleStats(
        longestStreak: 60,
        passedLessons: 12,
        totalChecks: 200,
      );

      final vorher = TitleCatalog.earnedBy(wenig).map((t) => t.id).toSet();
      final nachher = TitleCatalog.earnedBy(mehr).map((t) => t.id).toSet();

      expect(nachher.containsAll(vorher), isTrue);
    });

    test('isEarned prueft Wahl und Bedingung zusammen', () {
      const stats = TitleStats(longestStreak: 3);

      expect(TitleCatalog.isEarned('entschlossen', stats), isTrue);
      expect(TitleCatalog.isEarned('bestaendig', stats), isFalse);
      expect(TitleCatalog.isEarned(null, stats), isFalse);
    });
  });

  group('Abstand zum Ziel', () {
    test('ein verdienter Titel hat keinen Abstand mehr', () {
      const stats = TitleStats(longestStreak: 30);
      final title = TitleCatalog.byId('entschlossen')!;

      expect(title.missingFor(stats), 0);
    });

    test('der Abstand ist die groesste offene Luecke', () {
      const stats = TitleStats(longestStreak: 18);
      final title = TitleCatalog.byId('bestaendig')!;

      expect(title.missingFor(stats), 12);
    });
  });
}
