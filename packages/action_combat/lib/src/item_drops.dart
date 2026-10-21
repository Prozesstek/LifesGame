part of 'world.dart';

/// Ausrüstung, die Gegner in der Grube fallen lassen (ADR-0083).
///
/// **Die Grube kennt keine Ausrüstung** — sie weiß nur, *dass* etwas
/// fällt und ob es vom Wächter kommt. Was es ist, würfelt die App mit
/// `GearLoot.cascade` aus dem Startwert des Laufs und der Nummer des
/// Fundes ([ItemDropped.nth]); dieselbe Nummer ergibt dasselbe Stück.
///
/// **Liegen lassen heißt verlieren**: Was am Ende des Laufs noch am
/// Boden liegt, gehört niemandem. Was eingesammelt ist, bleibt — auch
/// nach einer Niederlage. Nur die Beute des Wächters muss man nicht
/// holen: Mit ihm endet der Lauf.

/// Ein Fund am Boden.
class _ItemDrop {
  _ItemDrop({
    required this.id,
    required this.nth,
    required this.position,
    required this.boss,
  });

  final int id;
  final int nth;
  final bool boss;
  Vec2 position;
  bool taken = false;
}

/// Ein Fund am Boden, wie der Renderer ihn sieht.
class ItemDropView {
  const ItemDropView({
    required this.id,
    required this.nth,
    required this.position,
  });

  final int id;

  /// Der wievielte Fund des Laufs — darüber findet die App, was es ist.
  final int nth;
  final Vec2 position;
}

extension _ItemDrops on ActionWorld {
  /// Die erste Stufe der Kaskade: ob [gefallen] etwas fallen lässt.
  ///
  /// **Der Wächter immer**, zähe Gegner öfter als das Fussvolk, was im
  /// Lauf entsteht nie — sonst hinge die Beute daran, wie oft etwas
  /// zerfällt (`ActionEntity.lootless`).
  void _maybeDropItem(ActionEntity gefallen) {
    if (!dropsItems || gefallen.lootless) return;
    final boss = gefallen == _boss;
    if (!boss) {
      final zaeh = gefallen.kind == EnemyKind.brocken ||
          gefallen.kind == EnemyKind.grimlock;
      final chance = zaeh
          ? ActionBalance.itemDropChanceTough
          : ActionBalance.itemDropChance;
      if (_lootRng.nextDouble() >= chance) return;
    }

    _itemsDropped++;
    final fund = _ItemDrop(
      id: _nextId++,
      nth: _itemsDropped,
      // Ein Stück neben Heil- und Zeitkugel, damit alle drei zu sehen
      // sind.
      position: gefallen.position + const Vec2(-10, 6),
      boss: boss,
    );
    _items.add(fund);
    _events.add(
      ItemDropped(id: fund.id, nth: fund.nth, at: fund.position, boss: boss),
    );
    // Mit dem Wächter endet der Lauf — seine Beute holt niemand mehr ab.
    if (boss) _collectItem(fund);
  }

  /// Gleitet zum Helden, wenn er nah ist, und wird eingesammelt, wenn er
  /// ihn berührt.
  void _moveItems(double dt) {
    for (final fund in _items) {
      if (fund.taken) continue;
      final zumHelden = _hero.position - fund.position;
      final abstand = zumHelden.length;
      if (abstand <= ActionBalance.itemRadius + _hero.radius) {
        _collectItem(fund);
        continue;
      }
      if (abstand <= ActionBalance.itemMagnetRange) {
        fund.position = fund.position +
            zumHelden.normalized * (ActionBalance.itemMagnetSpeed * dt);
      }
    }
    _items.removeWhere((fund) => fund.taken);
  }

  void _collectItem(_ItemDrop fund) {
    if (fund.taken) return;
    fund.taken = true;
    _collectedItems.add(fund.nth);
    _events.add(ItemCollected(id: fund.id, at: fund.position));
  }
}
