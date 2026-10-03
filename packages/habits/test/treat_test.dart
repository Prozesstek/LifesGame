import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Belohnung danach — das Versuchungsbündel
/// ([ADR-0066](../../../docs/decisions/0066-versuchungsbuendel.md)).
///
/// Wie beim Auslöser steht die schärfste Zusage in der Mitte: Sie bewegt
/// **keine** Zahl. Die App gibt die Belohnung nicht, sie erinnert daran.
void main() {
  const heute = Day(2026, 10, 3);
  final vorlage = HabitCatalog.starter;
  final andere = HabitCatalog.all.firstWhere((h) => h.id != vorlage.id);

  HabitTracker mitVorlage() => const HabitTracker.empty().activate(vorlage.id);

  group('Eine Belohnung festlegen', () {
    test('ohne Festlegung gibt es keine', () {
      expect(mitVorlage().treatFor(vorlage.id), isNull);
    });

    test('sie wird gespeichert, auf eine Zeile gebracht', () {
      final t = mitVorlage().setTreat(vorlage.id, '  ein\n  Kaffee ');

      expect(t.treatFor(vorlage.id), 'ein Kaffee');
    });

    test('leer oder null entfernt sie', () {
      final mit = mitVorlage().setTreat(vorlage.id, 'Kaffee');

      expect(mit.setTreat(vorlage.id, '  ').treatFor(vorlage.id), isNull);
      expect(mit.setTreat(vorlage.id, null).treatFor(vorlage.id), isNull);
    });

    test('Überlanges wird gekürzt, nicht abgelehnt', () {
      final lang = 'a' * (HabitTracker.maxCueLength + 20);
      final t = mitVorlage().setTreat(vorlage.id, lang);

      expect(t.treatFor(vorlage.id)!.length, HabitTracker.maxCueLength);
    });

    test('eine unbekannte Id ändert nichts', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      final t = mitVorlage();

      expect(identical(t.setTreat(fremd, 'Kaffee'), t), isTrue);
    });

    test('sie überlebt das Pausieren', () {
      final t = mitVorlage()
          .setTreat(vorlage.id, 'Kaffee')
          .deactivate(vorlage.id, today: heute)
          .activate(vorlage.id, today: heute);

      expect(t.treatFor(vorlage.id), 'Kaffee');
    });
  });

  group('Neben dem Auslöser', () {
    test('ein Satz und eine Belohnung stehen nebeneinander', () {
      final t = mitVorlage()
          .setCue(vorlage.id, 'nach dem Frühstück')
          .setTreat(vorlage.id, 'Kaffee');

      expect(t.cueFor(vorlage.id), 'nach dem Frühstück');
      expect(t.treatFor(vorlage.id), 'Kaffee');
    });

    test('ein Anker ersetzt den Satz, die Belohnung bleibt', () {
      final t = mitVorlage()
          .activate(andere.id)
          .setCue(vorlage.id, 'morgens')
          .setTreat(vorlage.id, 'Kaffee')
          .setAnchor(vorlage.id, andere.id);

      expect(t.anchorFor(vorlage.id), andere.id);
      expect(t.cueFor(vorlage.id), isNull);
      expect(t.treatFor(vorlage.id), 'Kaffee');
    });

    test('den Auslöser ändern lässt die Belohnung stehen', () {
      final t = mitVorlage()
          .setTreat(vorlage.id, 'Kaffee')
          .setCue(vorlage.id, 'abends')
          .setCue(vorlage.id, null);

      expect(t.treatFor(vorlage.id), 'Kaffee');
    });
  });

  test('eine Belohnung bewegt keine Zahl', () {
    final ohne = mitVorlage().check(vorlage.id, heute).tracker;
    final mit = ohne.setTreat(vorlage.id, 'Kaffee');

    expect(mit.totalXp, ohne.totalXp);
    expect(mit.totalGold, ohne.totalGold);
    expect(
      mit.currentStreak(vorlage.id, heute),
      ohne.currentStreak(vorlage.id, heute),
    );
    final morgen = heute.next;
    expect(
      mit.xpForNextCheck(vorlage.id, morgen),
      ohne.xpForNextCheck(vorlage.id, morgen),
    );
  });

  group('Speichern', () {
    test('eine Belohnung kommt durch toJson und zurück', () {
      final t = mitVorlage().setTreat(vorlage.id, 'eine Folge');

      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.treatFor(vorlage.id), 'eine Folge');
    });

    test('ohne Belohnung sieht der Stand aus wie vorher', () {
      expect(mitVorlage().toJson().containsKey('treats'), isFalse);
    });

    test('Unbekanntes und Kaputtes wird beim Laden übersprungen', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      final geladen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[vorlage.id],
        'treats': <String, Object?>{
          vorlage.id: 'Kaffee',
          fremd: 'Tee',
          andere.id: 42,
        },
      });

      expect(geladen.treatFor(vorlage.id), 'Kaffee');
      expect(geladen.treatFor(fremd), isNull);
      expect(geladen.treatFor(andere.id), isNull);
    });
  });
}
