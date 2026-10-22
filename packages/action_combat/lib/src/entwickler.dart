part of 'world.dart';

/// **Nur für den Entwicklermodus**: Gegner und Funde von Hand in einen
/// laufenden Lauf setzen — um Legendäres anzusehen, ohne Gegner zu jagen,
/// und Schaden an einer bestimmten Art zu messen.
///
/// Beides nimmt denselben Weg wie im Spiel: ein Gegner aus `_enemyFor`
/// mit den Werten der Stufe, ein Fund als [ItemDropped] mit der nächsten
/// Nummer. Was es ist, würfelt weiter die App.
extension EntwicklerWerkzeug on ActionWorld {
  /// Setzt einen Gegner der Art [kind] auf das nächste freie Feld vor
  /// dem Helden. Der Wächter ist ausgenommen — er gehört in seinen Raum.
  void devBeschwoereGegner(EnemyKind kind) {
    if (kind == EnemyKind.endgegner || kind == EnemyKind.keiner) return;
    final feld = _freiesFeldVorDemHelden();
    if (feld == null) return;
    final gegner = _enemyFor(Spawn(kind: kind, tileX: feld.$1, tileY: feld.$2));
    _entities.add(gegner);
    _totalEnemies++;
  }

  /// Legt einen Fund neben den Helden und gibt seine Nummer zurück —
  /// darüber sagt die App, welche Seltenheit er haben soll.
  int devLegeFund() {
    _itemsDropped++;
    final fund = _ItemDrop(
      id: _nextId++,
      nth: _itemsDropped,
      position: _hero.position + _hero.facing * (ActionBalance.tileSize * 1.5),
      boss: false,
    );
    _items.add(fund);
    _events.add(
      ItemDropped(id: fund.id, nth: fund.nth, at: fund.position, boss: false),
    );
    return fund.nth;
  }

  /// Das erste begehbare Feld, zwei bis fünf Felder in Blickrichtung,
  /// sonst ringsum.
  (int, int)? _freiesFeldVorDemHelden() {
    const groesse = ActionBalance.tileSize;
    final hx = (_hero.position.x / groesse).floor();
    final hy = (_hero.position.y / groesse).floor();
    final blick = _hero.facing;
    for (var schritt = 3; schritt >= 2; schritt--) {
      final x = hx + (blick.x * schritt).round();
      final y = hy + (blick.y * schritt).round();
      if (!level.isWallAt(x, y)) return (x, y);
    }
    for (var r = 2; r <= 5; r++) {
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          if (!level.isWallAt(hx + dx, hy + dy)) return (hx + dx, hy + dy);
        }
      }
    }
    return null;
  }
}
