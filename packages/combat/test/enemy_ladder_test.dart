import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Die Gegnerreihe aus Issue #36.
///
/// **Warum die Werte gerechnet und nicht getippt sind.** Eine Tabelle mit
/// dreissig Zeilen laesst sich nicht "stetig steigend" halten, ohne dass
/// es jemand nachrechnet. Diese Datei rechnet nach -- und haette bei einer
/// Tabelle nichts zu pruefen ausser Tippfehlern.
void main() {
  group('Die Reihe hat dreissig Sprossen', () {
    test('genau dreissig, und jede hat einen Namen', () {
      expect(Enemies.ladder, hasLength(30));
      expect(Enemies.rungs, 30);

      for (final gegner in Enemies.ladder) {
        expect(gegner.name.trim(), isNotEmpty);
      }
    });

    test('jede Id kommt nur einmal vor', () {
      final ids = Enemies.ladder.map((e) => e.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('die Namen sind ohne Umlaute, wie das ganze Package', () {
      for (final gegner in Enemies.ladder) {
        expect(
          RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(gegner.name),
          isTrue,
          reason: gegner.name,
        );
      }
    });

    test('atRung zaehlt ab eins und laeuft nicht ueber', () {
      expect(Enemies.atRung(1).id, Enemies.wegelagerer.id);
      expect(Enemies.atRung(30).id, Enemies.spitze.id);

      // Ausserhalb wird geklemmt statt geworfen: Ein Spielstand mit einer
      // unsinnigen Sprosse darf hoechstens den falschen Gegner zeigen.
      expect(Enemies.atRung(0).id, Enemies.wegelagerer.id);
      expect(Enemies.atRung(99).id, Enemies.spitze.id);
    });
  });

  group('Die Schwierigkeit steigt stetig', () {
    test('kein Wert faellt von einer Sprosse zur naechsten', () {
      for (var i = 1; i < Enemies.ladder.length; i++) {
        final vorher = Enemies.ladder[i - 1];
        final jetzt = Enemies.ladder[i];
        final wo = 'Sprosse ${i + 1} (${jetzt.name})';

        expect(jetzt.maxHp, greaterThanOrEqualTo(vorher.maxHp), reason: wo);
        expect(jetzt.attack, greaterThanOrEqualTo(vorher.attack), reason: wo);
        expect(jetzt.defense, greaterThanOrEqualTo(vorher.defense), reason: wo);
        expect(
          jetzt.utilityChance,
          greaterThanOrEqualTo(vorher.utilityChance),
          reason: wo,
        );
      }
    });

    test('und sie steigt wirklich, statt nur nicht zu fallen', () {
      final erster = Enemies.ladder.first;
      final letzter = Enemies.ladder.last;

      expect(letzter.maxHp, greaterThan(erster.maxHp * 2));
      expect(letzter.attack, greaterThan(erster.attack));
      expect(letzter.defense, greaterThan(erster.defense));
    });

    test('jeder Gegner kann zuschlagen', () {
      // Ein Gegner ohne Angriffszug waere ein Kampf, der nie endet --
      // dieselbe Sorte Fehler wie der Heal-Lock aus `gotchas.md`.
      for (final gegner in Enemies.ladder) {
        expect(gegner.loadout, isNotEmpty, reason: gegner.name);
        expect(
          gegner.loadout.any((m) => m.power > 0),
          isTrue,
          reason: gegner.name,
        );
      }
    });
  });

  group('Die drei alten Gegner sind Stuetzstellen geblieben', () {
    // Ihre Werte sind in ADR-0009 gemessen worden. Sie zu ueberschreiben
    // haette die einzigen belastbaren Zahlen des Projekts entwertet -- die
    // Reihe waechst deshalb *zwischen* ihnen.
    test('unveraendert und an ihrem Platz', () {
      expect(Enemies.atRung(1), same(Enemies.wegelagerer));
      expect(Enemies.atRung(6), same(Enemies.soeldner));
      expect(Enemies.atRung(20), same(Enemies.bergwaechter));
    });

    test('byId findet sie weiterhin', () {
      expect(Enemies.byId('wegelagerer'), isNotNull);
      expect(Enemies.byId('soeldner'), isNotNull);
      expect(Enemies.byId('bergwaechter'), isNotNull);
      expect(Enemies.byId('gibt-es-nicht'), isNull);
    });
  });
}
