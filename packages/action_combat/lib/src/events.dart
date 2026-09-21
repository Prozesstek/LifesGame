import 'ability.dart';
import 'entity.dart';
import 'vec2.dart';

/// Was in der Halle passiert ist — die einzige Naht nach aussen.
///
/// **Dieselbe Bauform wie `CombatEvent` im rundenbasierten Kampf**
/// (ADR-0002): Die Logik sagt, *was* geschehen ist, die Darstellung
/// entscheidet, *wie* es aussieht. Ein Treffer ist hier eine Zahl und ein
/// Ort; ob darüber eine rote Ziffer aufsteigt oder der Bildschirm wackelt,
/// weiss dieses Package nicht.
///
/// `sealed`, damit der Analyzer jede Stelle findet, die Ereignisse
/// auswertet, sobald eines dazukommt. Genau das hat sich bei
/// `AbilitySource` ausgezahlt.
sealed class ActionEvent {
  const ActionEvent();
}

/// Jemand hat zugeschlagen — unabhängig davon, ob er getroffen hat.
class AttackSwung extends ActionEvent {
  const AttackSwung({
    required this.attackerId,
    required this.faction,
    required this.from,
    required this.direction,
  });

  final int attackerId;
  final Faction faction;
  final Vec2 from;
  final Vec2 direction;
}

/// Ein Schlag ist angekommen.
class HitLanded extends ActionEvent {
  const HitLanded({
    required this.targetId,
    required this.targetFaction,
    required this.at,
    required this.amount,
    required this.isCrit,
  });

  final int targetId;
  final Faction targetFaction;
  final Vec2 at;
  final int amount;

  /// Ob es ein kritischer Treffer war. Die gibt es heute nur über
  /// [ActionStats.mitPotenz] — also im Prototyp, nicht im Spiel.
  final bool isCrit;
}

/// Eine Figur ist gefallen.
class EntityDied extends ActionEvent {
  const EntityDied({
    required this.id,
    required this.faction,
    required this.kind,
    required this.at,
  });

  final int id;
  final Faction faction;
  final EnemyKind kind;
  final Vec2 at;
}

/// Ein Gegner hat den Helden bemerkt. Für ein Zeichen über dem Kopf.
class EnemyNoticed extends ActionEvent {
  const EnemyNoticed({required this.id, required this.at});

  final int id;
  final Vec2 at;
}

/// Eine Fähigkeit wurde eingesetzt.
class AbilityUsed extends ActionEvent {
  const AbilityUsed({
    required this.ability,
    required this.at,
    required this.direction,
  });

  final ActionAbility ability;
  final Vec2 at;
  final Vec2 direction;
}

/// Eine Heilkugel ist gefallen.
/// Eine Fähigkeit aus einem Platz wurde gewirkt (ADR-0039).
class AbilityCast extends ActionEvent {
  const AbilityCast({required this.id, required this.at});

  final String id;
  final Vec2 at;
}

/// Der Held wurde geheilt — von einer Fähigkeit, nicht von einer Kugel.
class HeroHealed extends ActionEvent {
  const HeroHealed({required this.at, required this.amount});

  final Vec2 at;
  final int amount;
}

class OrbDropped extends ActionEvent {
  const OrbDropped({required this.id, required this.at});

  final int id;
  final Vec2 at;
}

/// Eine Heilkugel wurde eingesammelt.
class OrbCollected extends ActionEvent {
  const OrbCollected({required this.at, required this.healed});

  final Vec2 at;

  /// Was sie tatsächlich gebracht hat. Bei voller Gesundheit null — die
  /// Kugel ist dann trotzdem weg, und genau das soll die Anzeige sagen.
  final int healed;
}

/// Der Lauf ist vorbei.
class RunEnded extends ActionEvent {
  const RunEnded({
    required this.won,
    required this.seconds,
    required this.kills,
  });

  final bool won;
  final double seconds;
  final int kills;
}
