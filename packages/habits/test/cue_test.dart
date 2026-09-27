import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Der Auslöser einer Gewohnheit und die Startvorlage
/// ([ADR-0052](../../../docs/decisions/0052-ausloeser-und-startvorlage.md)).
///
/// Die schärfste Zusage steht in der Mitte: Ein Auslöser bewegt **keine**
/// Zahl. Er ist die erste Angabe des Spielers, die nichts erzeugt — und
/// genau solche Felder wachsen später gern in die Rechnung hinein.
void main() {
  const heute = Day(2026, 9, 27);
  final vorlage = HabitCatalog.starter;

  HabitTracker mitVorlage() => const HabitTracker.empty().activate(vorlage.id);

  group('Ein Auslöser festlegen', () {
    test('ohne Festlegung gibt es keinen', () {
      expect(mitVorlage().cueFor(vorlage.id), isNull);
    });

    test('er wird gespeichert, wie er gemeint ist', () {
      final t = mitVorlage().setCue(vorlage.id, 'nach dem Zähneputzen');

      expect(t.cueFor(vorlage.id), 'nach dem Zähneputzen');
    });

    test('Leerraum wird zu einer Zeile zusammengezogen', () {
      final t = mitVorlage().setCue(vorlage.id, '  nach dem\n  Essen  ');

      expect(t.cueFor(vorlage.id), 'nach dem Essen');
    });

    test('leer oder null entfernt ihn', () {
      final mit = mitVorlage().setCue(vorlage.id, 'morgens');

      expect(mit.setCue(vorlage.id, '   ').cueFor(vorlage.id), isNull);
      expect(mit.setCue(vorlage.id, null).cueFor(vorlage.id), isNull);
    });

    test('Überlanges wird gekürzt, nicht abgelehnt', () {
      final lang = 'a' * (HabitTracker.maxCueLength + 20);
      final t = mitVorlage().setCue(vorlage.id, lang);

      expect(t.cueFor(vorlage.id)!.length, HabitTracker.maxCueLength);
    });

    test('eine unbekannte Id ändert nichts', () {
      final t = mitVorlage();

      expect(identical(t.setCue('gibt-es-nicht', 'morgens'), t), isTrue);
    });

    test('er gilt auch für eine eigene Gewohnheit', () {
      const eigene = CustomHabit(
        id: 'eigen-1',
        name: 'Zehn Liegestütze',
        stat: HabitStat.staerke,
        difficulty: HabitDifficulty.mittel,
      );
      final t = const HabitTracker.empty()
          .addCustom(eigene, slots: 1)
          .setCue('eigen-1', 'nach dem Aufstehen');

      expect(t.cueFor('eigen-1'), 'nach dem Aufstehen');
    });

    test('er überlebt das Pausieren', () {
      // Wer eine Gewohnheit stoppt und wieder aufnimmt, soll den eigenen
      // Satz nicht neu schreiben müssen — dieselbe Regel wie bei den
      // Häkchen, die beim Stoppen auch bleiben.
      final t = mitVorlage()
          .setCue(vorlage.id, 'abends')
          .deactivate(vorlage.id)
          .activate(vorlage.id);

      expect(t.cueFor(vorlage.id), 'abends');
    });
  });

  test('ein Auslöser bewegt keine Zahl', () {
    final ohne = mitVorlage().check(vorlage.id, heute).tracker;
    final mit = ohne.setCue(vorlage.id, 'nach dem Zähneputzen');

    expect(mit.totalXp, ohne.totalXp);
    expect(mit.totalGold, ohne.totalGold);
    final morgen = heute.next;
    expect(
      mit.xpForNextCheck(vorlage.id, morgen),
      ohne.xpForNextCheck(vorlage.id, morgen),
    );
  });

  group('Speichern', () {
    test('ein Auslöser kommt durch toJson und zurück', () {
      final t = mitVorlage().setCue(vorlage.id, 'nach dem Frühstück');

      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.cueFor(vorlage.id), 'nach dem Frühstück');
    });

    test('ohne Auslöser sieht der Stand aus wie vorher', () {
      expect(mitVorlage().toJson().containsKey('cues'), isFalse);
    });

    test('Unbekanntes und Kaputtes wird beim Laden übersprungen', () {
      final geladen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[vorlage.id],
        'cues': <String, Object?>{
          vorlage.id: 'morgens',
          'gibt-es-nicht': 'abends',
          HabitCatalog.all.last.id: 42,
        },
      });

      expect(geladen.cueFor(vorlage.id), 'morgens');
      expect(geladen.cueFor('gibt-es-nicht'), isNull);
      expect(geladen.cueFor(HabitCatalog.all.last.id), isNull);
    });
  });

  group('Die Startvorlage', () {
    test('steht im Katalog', () {
      expect(HabitCatalog.byId(HabitCatalog.starterId), isNotNull);
    });

    test('ist Zwei Minuten lesen — die kleinste Vorlage', () {
      expect(HabitCatalog.starter.name, 'Zwei Minuten lesen');
    });
  });
}
