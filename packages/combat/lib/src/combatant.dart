import 'status.dart';

/// Welche Seite handelt. Die Logik kennt keine Namen, nur Rollen.
enum Side { player, enemy }

/// Ein Kaempfer als unveraenderlicher Zustand.
///
/// Alle Aenderungen laufen ueber [copyWith] und erzeugen eine neue Instanz.
/// Damit ist jeder Zwischenstand einer Runde nachtraeglich inspizierbar,
/// was Balance-Analysen erheblich vereinfacht.
class Combatant {
  Combatant({
    required this.name,
    required this.maxHp,
    required this.hp,
    required this.attack,
    required this.defense,
    required this.maxEnergy,
    required this.energy,
    List<StatusEffect> statuses = const <StatusEffect>[],
  }) : statuses = List<StatusEffect>.unmodifiable(statuses);

  /// Frischer Kaempfer mit vollen Ressourcen.
  factory Combatant.fresh({
    required String name,
    required int maxHp,
    required int attack,
    required int defense,
    required int maxEnergy,
    int startEnergy = 0,
  }) {
    return Combatant(
      name: name,
      maxHp: maxHp,
      hp: maxHp,
      attack: attack,
      defense: defense,
      maxEnergy: maxEnergy,
      energy: startEnergy,
    );
  }

  final String name;
  final int maxHp;
  final int hp;
  final int attack;
  final int defense;
  final int maxEnergy;
  final int energy;
  final List<StatusEffect> statuses;

  bool get isDefeated => hp <= 0;

  /// Verteidigung inklusive aller Statuseffekte. Der Rohwert [defense] wird
  /// nie direkt zur Schadensberechnung verwendet.
  int get effectiveDefense {
    var value = defense.toDouble();
    for (final status in statuses) {
      if (status is DefenseDown) {
        value *= status.factor;
      }
    }
    return value.round();
  }

  Shield? get activeShield {
    for (final status in statuses) {
      if (status is Shield) return status;
    }
    return null;
  }

  /// HP veraendern, hart begrenzt auf 0..maxHp.
  Combatant withHpDelta(int delta) {
    final next = (hp + delta).clamp(0, maxHp);
    return copyWith(hp: next);
  }

  /// Energie veraendern, hart begrenzt auf 0..maxEnergy.
  Combatant withEnergyDelta(int delta) {
    final next = (energy + delta).clamp(0, maxEnergy);
    return copyWith(energy: next);
  }

  /// Effekt hinzufuegen. Ein bereits vorhandener Effekt derselben Art wird
  /// ersetzt, nicht gestapelt — sonst wird Gift trivial ueberstapelbar.
  Combatant withStatus(StatusEffect effect) {
    final next = statuses.where((s) => s.id != effect.id).toList()..add(effect);
    return copyWith(statuses: next);
  }

  Combatant withoutStatus(String id) {
    return copyWith(statuses: statuses.where((s) => s.id != id).toList());
  }

  Combatant withStatuses(List<StatusEffect> next) => copyWith(statuses: next);

  Combatant copyWith({
    String? name,
    int? maxHp,
    int? hp,
    int? attack,
    int? defense,
    int? maxEnergy,
    int? energy,
    List<StatusEffect>? statuses,
  }) {
    return Combatant(
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      hp: hp ?? this.hp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      energy: energy ?? this.energy,
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  String toString() => '$name($hp/$maxHp HP, $energy/$maxEnergy EN)';
}
