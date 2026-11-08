import 'package:action_combat/action_combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/pit_text.dart';

/// Was das Blatt über die Skalierung sagt (`docs/vorlagen/skalierung.md`).
void main() {
  String? wert(List<PitStat> stats, String label) {
    for (final s in stats) {
      if (s.label == label) return s.value;
    }
    return null;
  }

  test('jede Fähigkeit sagt, womit sie skaliert', () {
    expect(skaliertMit(0), 'Angriffsschaden');
    expect(skaliertMit(1), 'Fähigkeitsstärke');
    expect(skaliertMit(0.4), '60 % Angriffsschaden, 40 % Fähigkeitsstärke');
  });

  test('der Schaden rechnet mit dem passenden Wert', () {
    const werte = (angriff: 100, faehigkeit: 200);
    // Funkenstoß ist ganz Magie, Kraftschlag ganz Schlag.
    final funke = pitAbilityStats(
      PitAbilities.byId('funkenstoss')!,
      werte: werte,
    );
    final schlag = pitAbilityStats(
      PitAbilities.byId('heavy_attack')!,
      werte: werte,
    );

    expect(wert(funke, 'Skaliert mit'), 'Fähigkeitsstärke');
    expect(wert(schlag, 'Skaliert mit'), 'Angriffsschaden');
    final funkePower =
        (PitAbilities.byId('funkenstoss')!.effects.first as BoltAtNearest)
            .power;
    expect(wert(funke, 'Schaden'), contains('${(200 * funkePower).round()}'));
  });

  test('ein Stab schlägt mit der Fähigkeitsstärke', () {
    final stab = pitWeaponStats(PitWeapons.funkenwurf);
    expect(wert(stab, 'Skaliert mit'), 'Fähigkeitsstärke');
    final klinge = pitWeaponStats(PitWeapons.hieb);
    expect(wert(klinge, 'Skaliert mit'), 'Angriffsschaden');
  });

  test('wer nur Mana bringt, sagt nichts über Skalierung', () {
    final aura = pitAbilityStats(PitAbilities.byId('aurastrom')!);
    expect(wert(aura, 'Skaliert mit'), isNull);
  });
}
