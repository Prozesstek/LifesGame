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

/// Eine Zeitkugel wurde eingesammelt.
class TimeGained extends ActionEvent {
  const TimeGained({required this.at, required this.seconds});

  final Vec2 at;

  /// Was sie tatsächlich gebracht hat — bei voller Uhr weniger.
  final double seconds;
}

/// Der Lauf ist vorbei.
class RunEnded extends ActionEvent {
  const RunEnded({
    required this.won,
    required this.seconds,
    required this.kills,
    required this.timedOut,
  });

  final bool won;

  /// Ob die Uhr abgelaufen ist — dann ist [won] immer falsch.
  final bool timedOut;
  final double seconds;
  final int kills;
}

/// Ein Treffer des Bodenstosses, für einen Ring im Renderer.
class BossSlammed extends ActionEvent {
  const BossSlammed({required this.at, required this.radius});

  final Vec2 at;
  final double radius;
}

/// Der Wächter ist wütend geworden — einmal je Lauf.
class BossEnraged extends ActionEvent {
  const BossEnraged({required this.at});

  final Vec2 at;
}

/// Das Tor zum Wächterraum ist hinter dem Helden zugefallen.
///
/// [at] ist die Mitte des Tors, für einen Staubstoss und ein Geräusch.
/// Es geht nicht wieder auf: Fällt der Wächter, ist der Lauf vorbei.
class GateClosed extends ActionEvent {
  const GateClosed({required this.at});

  final Vec2 at;
}

/// Der Wächter ist bei seinem Auftritt aufgeschlagen. Ab hier stehen
/// Name und Balken da.
class BossLanded extends ActionEvent {
  const BossLanded({required this.at});

  final Vec2 at;
}

/// Ein Gegner hat bei seinem Tod Erfahrung und Gold gebracht — sein Teil
/// am Topf der Stufe (ADR-0041). Für eine Zahl über der Stelle.
class LootDropped extends ActionEvent {
  const LootDropped({required this.at, required this.xp, required this.gold});

  final Vec2 at;
  final int xp;
  final int gold;
}
