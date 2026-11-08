import 'dart:math' as math;

import 'balance.dart';
import 'pit_ability.dart';
import 'pit_modifier.dart';
import 'pit_weapon.dart';
import 'stats.dart';

/// **Angriffsschaden und Fähigkeitsstärke** (Skalierung, 08.11.2026,
/// `docs/vorlagen/skalierung.md`): was die Werte des Helden aus einer
/// Fähigkeit machen.
///
/// Jeder Schaden des Helden ist `Angriff × power`. Statt das an jeder
/// Wirkung umzubauen, wird die Fähigkeit beim Betreten der Grube einmal
/// umgerechnet — **über dieselben Veränderungen wie ein Set**
/// ([PitModifiers]), die Welt sieht nur das Ergebnis:
///
/// `power × ((1 − fs) × AS + fs × FS) / AS`
///
/// Weil die Anteile zusammen 1 ergeben, bleibt jede Zahl, wie sie ist,
/// solange Angriffsschaden und Fähigkeitsstärke gleich sind. Der
/// Grundangriff ist keine Fähigkeit und bleibt beim Angriffsschaden.
abstract final class PitSkalierung {
  /// Die Veränderungen für [ability] bei den Werten [stats].
  static List<PitModifier> fuer(PitAbility ability, ActionStats stats) {
    final as = stats.combatAttack;
    final fs = stats.combatAbilityPower;
    final cdr = stats.combatCooldownReduction;
    return <PitModifier>[
      if (ability.fs > 0 && as > 0) ...<PitModifier>[
        ScaleDamage(factor: schadensFaktor(ability.fs, as: as, fs: fs)),
        ScaleProtection(factor: schutzFaktor(ability.fs, as: as, fs: fs)),
      ],
      // Die Ultimate hat keine Abklingzeit, die sich kürzen liesse.
      if (cdr > 0 && !ability.isUltimate) ScaleCooldown(factor: 1 - cdr),
    ];
  }

  /// Der Grundangriff: Ein Stab ([PitWeapon.fs]) schlägt mit der
  /// Fähigkeitsstärke, alles andere bleibt beim Angriffsschaden.
  static PitWeapon waffe(PitWeapon waffe, ActionStats stats) {
    if (waffe.fs <= 0) return waffe;
    return waffe.mitWucht(
      schadensFaktor(
        waffe.fs,
        as: stats.combatAttack,
        fs: stats.combatAbilityPower,
      ),
    );
  }

  /// Wie viel härter oder schwächer eine Fähigkeit mit dem Anteil [anteil]
  /// trifft als mit dem Angriff allein.
  static double schadensFaktor(
    double anteil, {
    required int as,
    required int fs,
  }) {
    if (as <= 0) return 1;
    return ((1 - anteil) * as + anteil * fs) / as;
  }

  /// Heilung und Schutz: das Verhältnis der Fähigkeitsstärke zum Angriff,
  /// gedeckelt ([ActionBalance.schutzMin] bis [ActionBalance.schutzMax]),
  /// und nur im Mass ihres Anteils. Sie bleiben ein Anteil des Lebens —
  /// sonst endet kein Lauf (`gotchas.md`).
  static double schutzFaktor(
    double anteil, {
    required int as,
    required int fs,
  }) {
    if (as <= 0) return 1;
    final verhaeltnis = (fs / as).clamp(
      ActionBalance.schutzMin,
      ActionBalance.schutzMax,
    );
    return math.pow(verhaeltnis, anteil).toDouble();
  }
}
