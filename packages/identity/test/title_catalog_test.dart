import 'package:identity/identity.dart';
import 'package:test/test.dart';

/// Prueft den Titelkatalog als Inhalt, so wie `catalog_test.dart` den Laden
/// und `content_test.dart` die Lektionen prueft. Wer einen Titel ergaenzt,
/// bekommt hier automatisch Rueckmeldung.
///
/// **Was dieser Test seit ADR-0033 nicht mehr prueft: die Bedingungen.**
/// Sie stehen nicht mehr hier, sondern in `package:achievements` — samt
/// den Tests dazu. Dass jede vergebene Titel-Id in diesem Katalog ankommt,
/// prueft `test/achievements_seam_test.dart` in der App; keines der beiden
/// Packages kann das allein.
void main() {
  group('Der Katalog ist in sich stimmig', () {
    test('es gibt ueberhaupt Titel', () {
      expect(TitleCatalog.all, isNotEmpty);
    });

    test('dreizehn Titel: sieben aus Meilensteinen, sechs aus Entdeckungen',
        () {
      expect(TitleCatalog.all, hasLength(13));
    });

    test('jede Id kommt nur einmal vor', () {
      final ids = TitleCatalog.all.map((title) => title.id).toSet();

      expect(ids.length, TitleCatalog.all.length);
    });

    test('jeder Wortlaut kommt nur einmal vor', () {
      final labels = TitleCatalog.all.map((title) => title.label).toSet();

      expect(labels.length, TitleCatalog.all.length);
    });

    test('jeder Titel hat einen Wortlaut', () {
      for (final title in TitleCatalog.all) {
        expect(title.label.trim(), isNotEmpty, reason: title.id);
        expect(title.id.trim(), isNotEmpty);
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

  group('Verdiente Titel nachschlagen', () {
    test('ein frischer Charakter traegt keinen Titel', () {
      expect(TitleCatalog.forIds(const <String>{}), isEmpty);
    });

    test('forIds gibt die Titel in Katalogreihenfolge zurueck', () {
      final ids = <String>{'belesen', 'entschlossen'};
      final titel = TitleCatalog.forIds(ids);

      expect(titel.map((t) => t.id), <String>['entschlossen', 'belesen']);
    });

    test('eine unbekannte Id kostet nichts', () {
      final titel = TitleCatalog.forIds(<String>{'entschlossen', 'gibtsnicht'});

      expect(titel, hasLength(1));
      expect(titel.single.id, 'entschlossen');
    });

    test('wer alles verdient hat, traegt jeden Titel', () {
      final alle = <String>{for (final t in TitleCatalog.all) t.id};

      expect(TitleCatalog.forIds(alle).length, TitleCatalog.all.length);
    });

    test('isEarned prueft Wahl und Bedingung zusammen', () {
      const verdient = <String>{'entschlossen'};

      expect(TitleCatalog.isEarned('entschlossen', verdient), isTrue);
      expect(TitleCatalog.isEarned('bestaendig', verdient), isFalse);
      expect(TitleCatalog.isEarned(null, verdient), isFalse);
      // Eine Id, die der Katalog nicht kennt, gilt nie als verdient --
      // auch dann nicht, wenn sie in der Menge steht.
      const fremd = <String>{'gibtsnicht'};
      expect(TitleCatalog.isEarned('gibtsnicht', fremd), isFalse);
    });
  });
}
