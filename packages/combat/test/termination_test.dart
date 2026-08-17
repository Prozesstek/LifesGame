import 'package:combat/combat.dart';
import 'package:test/test.dart';

/// Prueft die eine Eigenschaft, die keine Balance-Frage ist, sondern eine
/// Bedingung: **Ein Kampf muss enden.**
///
/// Der Anlass ist ein echter Fehler. Heilung war als Anteil der maximalen
/// HP definiert, Schaden dagegen als Vielfaches des Angriffswerts. Sobald
/// die HP-Pools schneller wuchsen als die Angriffswerte, heilte sich jede
/// Seite schneller, als die andere zuschlagen konnte. Sichtbar wurde das
/// nicht als Absturz, sondern als Unsinn in der Simulation: Siegquoten,
/// die *sanken*, wenn der Spieler staerker wurde.
///
/// Solche Fehler findet kein Beispielkampf. Sie brauchen einen Test, der
/// viele Werte-Kombinationen durchprobiert und nur eine Frage stellt.
void main() {
  group('Ein Kampf endet immer', () {
    /// Ab hier ist ein Kampf kein Kampf mehr. Grosszuegig gewaehlt: Ein
    /// knapper Kampf darf lang sein, nur nicht endlos.
    const int deckel = 300;

    /// Spielt einen Kampf, in dem beide Seiten die Standard-Policy nutzen,
    /// und gibt die Rundenzahl zurueck.
    int runden({
      required int seed,
      required Combatant player,
      required Combatant enemy,
      required TimedHit timing,
    }) {
      const policy = SimpleEnemyPolicy();
      final engine = CombatEngine(seed: seed);
      var state = CombatState.start(player: player, enemy: enemy);

      var count = 0;
      while (count < deckel && !state.isOver) {
        final move = policy.chooseMove(
          self: state.player,
          opponent: state.enemy,
          loadout: Moves.defaultLoadout,
        );
        state = engine
            .resolveRound(state, PlayerAction(move: move, timedHit: timing))
            .state;
        count++;
      }
      return count;
    }

    test('bei den Werten, die im Spiel wirklich vorkommen', () {
      // Spannweite der Charakterwerte aus `package:habits`, plus Luft nach
      // oben fuer Ausruestung.
      for (final gegner in Enemies.all) {
        for (var attack = 13; attack <= 30; attack += 1) {
          for (final maxHp in <int>[160, 200, 224, 300]) {
            final count = runden(
              seed: attack * 31 + maxHp,
              player: Combatant.fresh(
                name: 'Held',
                maxHp: maxHp,
                attack: attack,
                defense: 14,
                maxEnergy: 12,
              ),
              enemy: gegner.spawn(),
              timing: TimedHit.none,
            );
            expect(
              count,
              lessThan(deckel),
              reason: 'Kampf gegen ${gegner.name} mit $attack ATK / $maxHp HP '
                  'endet nicht',
            );
          }
        }
      }
    });

    test('auch bei absurd grossen HP-Pools geht es abwaerts', () {
      // Bei sehr grossen Pools dauert ein Kampf zu Recht lange -- HP geteilt
      // durch Schaden, daran ist nichts falsch. Eine Rundenzahl taugt hier
      // also nicht als Pruefung.
      //
      // Was in jedem Fall gelten muss, unabhaengig von der Groesse: Die
      // **Summe** beider HP-Balken sinkt. Steht sie oder steigt sie, heilt
      // sich jemand schneller, als zugeschlagen wird -- und genau das ist
      // der Heal-Lock. Diese Formulierung ist skalenfrei und deshalb die
      // richtige.
      for (final maxHp in <int>[1000, 5000, 20000]) {
        final engine = CombatEngine(seed: maxHp);
        var state = CombatState.start(
          player: Combatant.fresh(
            name: 'Held',
            maxHp: maxHp,
            attack: 20,
            defense: 14,
            maxEnergy: 12,
          ),
          enemy: Combatant.fresh(
            name: 'Riese',
            maxHp: maxHp,
            attack: 20,
            defense: 14,
            maxEnergy: 12,
          ),
        );

        int summe() => state.player.hp + state.enemy.hp;
        var vorher = summe();

        // In Fenstern von 50 Runden pruefen, nicht Runde fuer Runde: Eine
        // einzelne Heilung darf die Summe kurz anheben.
        for (var fenster = 0; fenster < 4 && !state.isOver; fenster++) {
          // Der Spieler haelt bewusst am Basisangriff fest: Der Test soll
          // die Engine pruefen, nicht das Verhalten der Policy auf
          // Spielerseite. Der Gegner heilt weiter nach Policy -- er ist die
          // Seite, die den Lock ausgeloest hat.
          for (var i = 0; i < 50 && !state.isOver; i++) {
            state = engine
                .resolveRound(
                  state,
                  const PlayerAction(move: Moves.basicAttack),
                )
                .state;
          }
          final nachher = summe();
          expect(
            nachher,
            lessThan(vorher),
            reason: 'Bei $maxHp HP je Seite sinkt die Summe der HP nicht -- '
                'jemand heilt schneller als der andere zuschlaegt',
          );
          vorher = nachher;
        }
      }
    });

    test('und bei jedem Timing-Ergebnis', () {
      // Mehr Schaden darf einen Kampf nie verlaengern. Genau das war beim
      // Heal-Lock der Fall: Frueher unter die Heilschwelle getrieben,
      // blieb der Gegner dort stehen.
      for (final timing in TimedHit.values) {
        final count = runden(
          seed: 7,
          player: Combatant.fresh(
            name: 'Held',
            maxHp: 224,
            attack: 20,
            defense: 14,
            maxEnergy: 12,
          ),
          enemy: Enemies.bergwaechter.spawn(),
          timing: timing,
        );
        expect(count, lessThan(deckel), reason: 'Timing $timing endet nicht');
      }
    });
  });
}
