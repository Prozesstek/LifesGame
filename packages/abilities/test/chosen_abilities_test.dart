import 'package:abilities/abilities.dart';
import 'package:test/test.dart';

/// Prueft die gewaehlte Zusammenstellung -- vor allem die Faelle, in denen
/// der Spieler umstellt statt neu zu waehlen.
void main() {
  group('Waehlen und umstellen', () {
    test('ein frischer Stand ist leer', () {
      expect(const ChosenAbilities.empty().isEmpty, isTrue);
      expect(const ChosenAbilities.empty().at(0), isNull);
    });

    test('eine Faehigkeit landet auf ihrem Platz', () {
      final chosen = const ChosenAbilities.empty().withAt(0, 'funkenstoss');

      expect(chosen.at(0), 'funkenstoss');
      expect(chosen.length, 1);
    });

    test('ein uebersprungener Platz erzeugt kein Loch', () {
      // Auf Slot 3 legen, obwohl Slot 2 leer ist: Die Liste darf danach
      // nicht zwei Arten kennen, "leer" zu sagen.
      final chosen = const ChosenAbilities.empty().withAt(2, 'funkenstoss');

      expect(chosen.moveIds, <String>['funkenstoss']);
    });

    test('dieselbe Faehigkeit liegt nie zweimal', () {
      // Sonst haette der Spieler zwei gleiche Knoepfe im Kampf -- eine
      // Wahl, die keine ist.
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'funkenstoss');
      chosen = chosen.withAt(1, 'steinhaut');
      chosen = chosen.withAt(1, 'funkenstoss');

      expect(chosen.moveIds, <String>['funkenstoss']);
    });

    test('einen Platz raeumen laesst die uebrigen stehen', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'funkenstoss');
      chosen = chosen.withAt(1, 'steinhaut');

      expect(chosen.clearedAt(0).moveIds, <String>['steinhaut']);
    });

    test('einen Platz raeumen, den es nicht gibt, aendert nichts', () {
      final chosen = const ChosenAbilities.empty().withAt(0, 'funkenstoss');

      expect(chosen.clearedAt(5).moveIds, <String>['funkenstoss']);
    });

    test('whereAllowed streicht, was nicht mehr erlaubt ist', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'funkenstoss');
      chosen = chosen.withAt(1, 'steinhaut');

      final gefiltert = chosen.whereAllowed((id) => id == 'funkenstoss');

      expect(gefiltert.moveIds, <String>['funkenstoss']);
      // Der Spielstand selbst bleibt unberuehrt.
      expect(chosen.moveIds, <String>['funkenstoss', 'steinhaut']);
    });
  });

  group('Speichern und laden', () {
    test('was geschrieben wird, kommt zurueck', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'funkenstoss');
      chosen = chosen.withAt(1, 'aurastrom');

      final gelesen = ChosenAbilities.fromJson(chosen.toJson());

      expect(gelesen.moveIds, chosen.moveIds);
    });

    test('Muell ergibt eine leere Wahl statt einer Ausnahme', () {
      expect(
        ChosenAbilities.fromJson(<String, Object?>{'moves': 42}).isEmpty,
        isTrue,
      );
      expect(
        ChosenAbilities.fromJson(<String, Object?>{}).isEmpty,
        isTrue,
      );
    });

    test('unlesbare Eintraege werden uebersprungen, lesbare nicht', () {
      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': <Object?>['funkenstoss', 42, null, '', 'aurastrom'],
      });

      expect(gelesen.moveIds, <String>['funkenstoss', 'aurastrom']);
    });

    test('Doppelte beim Laden fallen weg', () {
      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': <Object?>['funkenstoss', 'funkenstoss'],
      });

      expect(gelesen.moveIds, <String>['funkenstoss']);
    });
  });

  /// Der gemeldete Fehler: Ein Platz war belegt, im Kampf kam nichts an.
  ///
  /// Nach ADR-0022 fielen Kraftschlag, Zehrung, Sammeln und Atemzug aus
  /// dem Katalog. Wer einen davon liegen hatte, sah ihn weiter auf seinem
  /// Platz -- und ging mit einem Move weniger in den Kampf, ohne Meldung.
  group('Reste aus einer frueheren Fassung (ADR-0024)', () {
    // **Die Beispiel-Id ist bewusst erfunden.** Hier stand bis ADR-0033
    // `heavy_attack` -- und der ist mit ADR-0033 in den Katalog
    // zurueckgekehrt. Damit bewies der Test das Gegenteil dessen, was er
    // meinte. Genau dieser Fall steht in `gotchas.md`: In Tests keine Ids
    // als Beispiel benutzen, die zufaellig gerade existieren.
    test('eine Id, die es nicht mehr gibt, faellt beim Laden heraus', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      expect(AbilityCatalog.byMoveId(fremd), isNull);

      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': <Object?>[fremd, 'steinhaut', 'sandsturm'],
      });

      expect(gelesen.moveIds, <String>['steinhaut', 'sandsturm']);
    });

    test('die vier aus ADR-0017 sind seit ADR-0033 wieder waehlbar', () {
      // ADR-0024 hatte ihre Rueckkehr verworfen; ADR-0033 hat sie
      // gewaehlt, als Belohnung je eines Meilensteins. Der Mechanismus
      // von ADR-0024 -- Unbekanntes faellt beim Laden heraus -- gilt
      // unveraendert weiter und wird im Test darueber geprueft.
      for (final alt in <String>[
        'heavy_attack',
        'poison_strike',
        'mend',
        'breath',
      ]) {
        final faehigkeit = AbilityCatalog.byMoveId(alt);
        expect(faehigkeit, isNotNull, reason: alt);
        expect(faehigkeit!.source, isA<FromAchievement>(), reason: alt);
        expect(
          ChosenAbilities.fromJson(<String, Object?>{
            'moves': <Object?>[alt],
          }).moveIds,
          <String>[alt],
        );
      }
    });

    test('ein Waffenmove gehoert nicht auf einen freien Platz', () {
      // Waffenmoves kommen aus der Ausruestung, nicht aus einer Wahl
      // (ADR-0013). Auf einem freien Platz waeren sie derselbe blinde
      // Passagier.
      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': <Object?>['sword_strike', 'basic_attack', 'funkenstoss'],
      });

      expect(gelesen.moveIds, <String>['funkenstoss']);
    });

    test('alles Waehlbare ueberlebt das Laden', () {
      // Die Gegenprobe: Das Aufraeumen darf nichts Gueltiges wegnehmen.
      final alle = <String>[for (final a in AbilityCatalog.choosable) a.moveId];

      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': alle,
      });

      expect(gelesen.moveIds, alle);
    });
  });
}
