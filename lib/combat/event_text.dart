import 'package:combat/combat.dart';

/// Übersetzt Kampf-Events in deutsche Sätze für den Log.
///
/// Reine Darstellung: Die Logik kennt keine Sprache, nur Events (ADR-0002).
/// `null` bedeutet: für den Spieler nicht interessant.
String? describeEvent(CombatEvent event) {
  return switch (event) {
    RoundStarted() => null,
    EnergyChanged() => null,
    MoveUsed(:final side, :final moveId) =>
      '${_who(side)} nutzt ${moveName(moveId)}.',
    MoveFailed(:final side) =>
      '${_who(side)} ${_verb(side, 'hast', 'hat')} nicht genug Energie.',
    DamageDealt(:final target, :final amount, :final timedHitFactor) =>
      '${_who(target)} ${_verb(target, 'nimmst', 'nimmt')} $amount Schaden'
          '${timedHitFactor > 1.0 ? ' — voller Treffer!' : '.'}',
    DamageAbsorbed(:final target, :final amount) =>
      '${_possessive(target)} Schild fängt $amount ab.',
    ShieldBroke(:final target) => '${_possessive(target)} Schild zerbricht.',
    Healed(:final target, :final amount) =>
      '${_who(target)} ${_verb(target, 'heilst', 'heilt')} $amount HP.',
    StatusApplied(:final target, :final statusId, :final turns) =>
      '${_who(target)}: ${statusName(statusId)} für $turns Runden.',
    StatusTicked(:final target, :final statusId, :final damage) =>
      '${_who(target)} ${_verb(target, 'verlierst', 'verliert')} $damage HP '
          'durch ${statusName(statusId)}.',
    StatusExpired(:final target, :final statusId) =>
      '${statusName(statusId)} bei ${_dative(target)} läuft aus.',
    CombatantDefeated(:final side) =>
      '${_who(side)} ${_verb(side, 'gehst', 'geht')} zu Boden.',
    CombatEnded() => null,
  };
}

/// Der Anzeigename eines Moves.
///
/// Sucht ueber `Moves.all`, nicht ueber das Standard-Set: Seit ADR-0017
/// bringt der Spieler sein eigenes Set mit, und ein Move ausserhalb der
/// vier alten haette sonst seine rohe Id im Log stehen.
String moveName(String id) => Moves.byId(id)?.name ?? id;

String statusName(String id) => switch (id) {
  'poison' => 'Gift',
  'defense_down' => 'Verteidigung gesenkt',
  'shield' => 'Schild',
  _ => id,
};

String _who(Side side) => side == Side.player ? 'Du' : 'Gegner';

/// Der Spieler wird geduzt, der Gegner in der dritten Person beschrieben.
String _verb(Side side, String zweitePerson, String drittePerson) =>
    side == Side.player ? zweitePerson : drittePerson;

String _possessive(Side side) => side == Side.player ? 'Dein' : 'Gegnerisches';

String _dative(Side side) => side == Side.player ? 'dir' : 'Gegner';
