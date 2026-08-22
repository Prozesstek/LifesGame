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
      final chosen = const ChosenAbilities.empty().withAt(0, 'mend');

      expect(chosen.at(0), 'mend');
      expect(chosen.length, 1);
    });

    test('ein uebersprungener Platz erzeugt kein Loch', () {
      // Auf Slot 3 legen, obwohl Slot 2 leer ist: Die Liste darf danach
      // nicht zwei Arten kennen, "leer" zu sagen.
      final chosen = const ChosenAbilities.empty().withAt(2, 'mend');

      expect(chosen.moveIds, <String>['mend']);
    });

    test('dieselbe Faehigkeit liegt nie zweimal', () {
      // Sonst haette der Spieler zwei gleiche Knoepfe im Kampf -- eine
      // Wahl, die keine ist.
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'mend');
      chosen = chosen.withAt(1, 'heavy_attack');
      chosen = chosen.withAt(1, 'mend');

      expect(chosen.moveIds, <String>['mend']);
    });

    test('einen Platz raeumen laesst die uebrigen stehen', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'mend');
      chosen = chosen.withAt(1, 'heavy_attack');

      expect(chosen.clearedAt(0).moveIds, <String>['heavy_attack']);
    });

    test('einen Platz raeumen, den es nicht gibt, aendert nichts', () {
      final chosen = const ChosenAbilities.empty().withAt(0, 'mend');

      expect(chosen.clearedAt(5).moveIds, <String>['mend']);
    });

    test('whereAllowed streicht, was nicht mehr erlaubt ist', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'mend');
      chosen = chosen.withAt(1, 'heavy_attack');

      final gefiltert = chosen.whereAllowed((id) => id == 'mend');

      expect(gefiltert.moveIds, <String>['mend']);
      // Der Spielstand selbst bleibt unberuehrt.
      expect(chosen.moveIds, <String>['mend', 'heavy_attack']);
    });
  });

  group('Speichern und laden', () {
    test('was geschrieben wird, kommt zurueck', () {
      var chosen = const ChosenAbilities.empty();
      chosen = chosen.withAt(0, 'mend');
      chosen = chosen.withAt(1, 'breath');

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
        'moves': <Object?>['mend', 42, null, '', 'breath'],
      });

      expect(gelesen.moveIds, <String>['mend', 'breath']);
    });

    test('Doppelte beim Laden fallen weg', () {
      final gelesen = ChosenAbilities.fromJson(<String, Object?>{
        'moves': <Object?>['mend', 'mend'],
      });

      expect(gelesen.moveIds, <String>['mend']);
    });
  });
}
