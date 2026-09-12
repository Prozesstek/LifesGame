import 'package:identity/identity.dart';
import 'package:test/test.dart';

void main() {
  group('Identity Name', () {
    test('ohne Eingabe steht der Platzhalter', () {
      const identity = Identity.empty();

      expect(identity.hasName, isFalse);
      expect(identity.displayName, 'Namenlos');
    });

    test('Leerraum am Rand faellt weg', () {
      final identity = const Identity.empty().withName('  Frederik  ');

      expect(identity.name, 'Frederik');
    });

    test('zu lange Namen werden gekuerzt', () {
      final long = 'x' * (Identity.maxNameLength + 10);
      final identity = const Identity.empty().withName(long);

      expect(identity.name.length, Identity.maxNameLength);
    });

    test('ein Name aus nur Leerraum zaehlt als kein Name', () {
      final identity = const Identity.empty().withName('   ');

      expect(identity.hasName, isFalse);
      expect(identity.displayName, 'Namenlos');
    });

    test('der Titel ueberlebt eine Namensaenderung', () {
      final identity =
          const Identity.empty().withTitle('entschlossen').withName('Brett');

      expect(identity.chosenTitleId, 'entschlossen');
      expect(identity.name, 'Brett');
    });
  });

  group('Identity Titel', () {
    // Was verdient ist, kommt seit ADR-0033 aus `package:achievements`
    // herein -- hier als schlichte Menge von Ids.
    const earned = <String>{'entschlossen', 'bestaendig'};

    test('ohne Wahl steht nur der Name', () {
      final identity = const Identity.empty().withName('Frederik');

      expect(identity.titleFor(earned), isNull);
      expect(identity.displayLine(earned), 'Frederik');
    });

    test('ein verdienter Titel steht neben dem Namen', () {
      final identity =
          const Identity.empty().withName('Frederik').withTitle('bestaendig');

      expect(identity.displayLine(earned), 'Frederik, der Beständige');
    });

    test('ein nicht verdienter Titel wird nicht getragen', () {
      final identity =
          const Identity.empty().withName('Frederik').withTitle('unbeirrbar');

      expect(identity.titleFor(earned), isNull);
      expect(identity.displayLine(earned), 'Frederik');
    });

    test('ein unbekannter Titel wird still ignoriert', () {
      final identity = const Identity.empty().withTitle('gibtsnicht');

      expect(identity.titleFor(earned), isNull);
    });

    test('ein verdienter Titel bleibt, wenn die Kette reisst', () {
      // Die Bedingung haengt an der laengsten je gelaufenen Kette, nicht
      // an der laufenden (ADR-0014, Punkt 2 -- gilt weiter). Hier zeigt
      // sich das daran, dass die Menge der verdienten Ids nur waechst.
      final identity = const Identity.empty().withTitle('bestaendig');
      const spaeter = <String>{'entschlossen', 'bestaendig', 'unermuedlich'};

      expect(identity.titleFor(spaeter)?.id, 'bestaendig');
    });

    test('Titel ablegen ist moeglich', () {
      final identity =
          const Identity.empty().withTitle('bestaendig').withTitle(null);

      expect(identity.chosenTitleId, isNull);
      expect(identity.titleFor(earned), isNull);
    });
  });

  group('Identity Speichern', () {
    test('Hin und zurueck aendert nichts', () {
      final before =
          const Identity.empty().withName('Frederik').withTitle('bestaendig');
      final after = Identity.fromJson(before.toJson());

      expect(after.name, before.name);
      expect(after.chosenTitleId, before.chosenTitleId);
    });

    test('ein leerer Stand liest sich als leere Identitaet', () {
      final identity = Identity.fromJson(const <String, Object?>{});

      expect(identity.hasName, isFalse);
      expect(identity.chosenTitleId, isNull);
    });

    test('Unsinn im Stand wirft nicht', () {
      final identity = Identity.fromJson(const <String, Object?>{
        'name': 42,
        'title': <String>['kein', 'string'],
      });

      expect(identity.hasName, isFalse);
      expect(identity.chosenTitleId, isNull);
    });
  });
}
