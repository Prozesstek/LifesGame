import 'dart:math';

import 'combatant.dart';
import 'environment.dart';
import 'move.dart';
import 'status.dart';

/// Entscheidet, welchen Move der Gegner waehlt.
///
/// Als Interface ausgelegt, damit Tests eine feste Wahl vorgeben koennen und
/// Gegnertypen sich spaeter im Verhalten unterscheiden, ohne die Engine
/// anzufassen.
///
/// Die vier zusaetzlichen Angaben sind alle optional, damit ein Test eine
/// Policy mit drei Zeilen bauen kann. Wer sie weglaesst, bekommt das alte
/// Verhalten: immer der staerkste bezahlbare Angriff.
abstract interface class EnemyPolicy {
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,

    /// Auf welcher Seite die Policy gerade steuert.
    ///
    /// Standard ist [Side.enemy], weil das ihr Zweck ist. Die
    /// Balance-Simulation leiht sie sich fuer den Spieler und gibt die
    /// Seite dann ausdruecklich an -- ohne sie liesse sich nicht
    /// unterscheiden, ob eine liegende Umgebung die eigene ist.
    Side side,

    /// Die Umgebung, die gerade liegt.
    Environment? environment,

    /// Der Zufallsgeber der Engine. Nur ueber ihn bleibt ein Kampf bei
    /// gleichem Seed reproduzierbar.
    Random? random,

    /// Wie oft dieser Gegner etwas anderes tut als zuzuschlagen.
    double utilityChance,
  });
}

/// Zweckmaessige Standard-KI: heilt in Not, schlaegt hart wenn moeglich,
/// vergiftet wenn es sich lohnt, sonst Basisangriff.
///
/// Bewusst simpel und **zustandslos**. Interessante Gegner entstehen im
/// Konzept ueber Stats, Move-Sets und Timing-Muster, nicht ueber schlaue
/// Suche. Zustandslos ist dabei kein Detail, sondern die Voraussetzung
/// dafuer, dass ein Kampf bei gleichem Seed reproduzierbar bleibt.
class SimpleEnemyPolicy implements EnemyPolicy {
  const SimpleEnemyPolicy({this.healBelowHpRatio = 0.3});

  /// Unterhalb dieses HP-Anteils wird Heilung bevorzugt -- aber nur, wenn
  /// kein Schild mehr steht.
  ///
  /// Die Schild-Bedingung ist der Grund, warum Kaempfe ueberhaupt enden.
  /// Ohne sie heilt sich ein angeschlagener Gegner jede zweite Runde und
  /// damit schneller, als ein Spieler zuschlagen kann: In der Simulation
  /// sank die Siegquote, *weil* der Spieler mehr Schaden machte -- mehr
  /// Schaden trieb den Gegner nur frueher in den Dauerheilmodus (siehe
  /// `docs/context/gotchas.md`). Da "Sammeln" immer auch einen Schild
  /// setzt und der zwei Runden haelt, begrenzt diese eine Bedingung die
  /// Heilrate auf etwa jede dritte Runde -- ohne dass die Policy sich
  /// etwas merken muss.
  final double healBelowHpRatio;

  /// Ab diesem HP-Anteil ist Heilen als *Utility-Zug* verschwendet.
  ///
  /// Die Notheilung oben hat ihre eigene, viel tiefere Schwelle. Hier geht
  /// es nur darum, dass der Gegner nicht bei fast vollen Lebenspunkten eine
  /// Runde ans Heilen verliert -- das liest sich wie ein Fehler, nicht wie
  /// Charakter.
  static const double _healUtilityBelow = 0.8;

  @override
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
    Side side = Side.enemy,
    Environment? environment,
    Random? random,
    double utilityChance = 0,
  }) {
    final affordable =
        loadout.where((m) => m.isAffordableBy(self.energy)).toList();
    if (affordable.isEmpty) {
      return _generatingMove(loadout);
    }

    final inTrouble = self.hp / self.maxHp < healBelowHpRatio;
    if (inTrouble && self.activeShield == null) {
      // Beide Heilarten zaehlen: HealSelf nimmt seine Zahl aus Balance,
      // HealSelfBy bringt eine eigene mit (Bluetentau).
      final heal = _firstWithEffect<HealSelf>(affordable) ??
          _firstWithEffect<HealSelfBy>(affordable);
      if (heal != null) return heal;
    }

    // Manchmal etwas anderes als zuschlagen: eine Umgebung legen, sich
    // abschirmen, dem Gegner das Fenster verengen.
    //
    // **Gewuerfelt, nicht gerechnet.** Eine Policy, die den besten
    // Utility-Zug ausrechnet, wuerde die Gegner berechenbar machen -- und
    // interessante Gegner entstehen im Konzept ueber Werte und Move-Sets,
    // nicht ueber schlaue Suche. Herausgefiltert wird nur, was offensichtlich
    // verschwendet waere; das liest sich sonst als Fehler.
    if (random != null && utilityChance > 0) {
      if (random.nextDouble() < utilityChance) {
        final sinnvoll = affordable
            .where((m) => !m.dealsDamage)
            .where((m) => _isWorthwhile(m, self, opponent, side, environment))
            .toList();
        if (sinnvoll.isNotEmpty) {
          return sinnvoll[random.nextInt(sinnvoll.length)];
        }
      }
    }

    final heavy = _strongestDamaging(affordable);
    if (heavy != null && heavy.power >= 2.0) return heavy;

    if (!_hasStatus(opponent, 'poison')) {
      final poison = _firstWithEffect<ApplyPoison>(affordable);
      if (poison != null) return poison;
    }

    return _strongestDamaging(affordable) ?? _generatingMove(loadout);
  }

  /// Ob dieser Utility-Zug jetzt ueberhaupt etwas bringt.
  ///
  /// Jede Bedingung steht fuer eine Runde, die sonst sichtbar verschwendet
  /// waere: heilen bei fast vollen HP, dieselbe eigene Umgebung noch einmal
  /// legen, einen Schutz stapeln, der schon steht.
  bool _isWorthwhile(
    Move move,
    Combatant self,
    Combatant opponent,
    Side side,
    Environment? environment,
  ) {
    for (final effect in move.effects) {
      final verschwendet = switch (effect) {
        HealSelf() || HealSelfBy() => self.hp >= self.maxHp * _healUtilityBelow,
        ShieldSelf() => self.activeShield != null,
        ReduceIncoming() => _hasStatus(self, 'damage_reduction'),
        ReflectIncoming() => _hasStatus(self, 'reflect'),
        DilateTime() => _hasStatus(self, 'time_dilation'),
        CheapenNext() => _hasStatus(self, 'cost_reduction'),
        ShrinkEnemyWindow() => _hasStatus(opponent, 'window_shrink'),
        LockEnemyTiming() => _hasStatus(opponent, 'timing_locked'),

        // Die eigene Umgebung nachzulegen frischt sie zwar auf, kostet aber
        // eine volle Runde fuer wenig. Die des Gegners zu ueberschreiben ist
        // dagegen immer richtig -- sie dreht sich damit zu seinen Ungunsten.
        SetEnvironment(:final environmentId) => environment != null &&
            environment.id == environmentId &&
            environment.owner == side,
        _ => false,
      };
      if (verschwendet) return false;
    }

    // Ein Zug, der nur Energie bringt, ist bei vollem Balken sinnlos.
    if (move.energyDelta > 0 && self.energy >= self.maxEnergy) return false;

    return true;
  }

  /// Fallback, wenn nichts bezahlbar ist: der Move, der Energie aufbaut.
  Move _generatingMove(List<Move> loadout) {
    for (final move in loadout) {
      if (move.energyDelta > 0) return move;
    }
    return loadout.first;
  }

  Move? _firstWithEffect<T extends MoveEffect>(List<Move> moves) {
    for (final move in moves) {
      if (move.effects.whereType<T>().isNotEmpty) return move;
    }
    return null;
  }

  Move? _strongestDamaging(List<Move> moves) {
    Move? best;
    for (final move in moves) {
      if (!move.dealsDamage) continue;
      if (best == null || move.power > best.power) best = move;
    }
    return best;
  }

  bool _hasStatus(Combatant combatant, String id) {
    return combatant.statuses.any((StatusEffect s) => s.id == id);
  }
}
