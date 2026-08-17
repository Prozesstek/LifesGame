import 'catalog.dart';
import 'item.dart';

/// Warum ein Kauf nicht geht. Null heißt: geht.
enum PurchaseBlock {
  /// Gibt es nicht — Tippfehler oder ein Stück aus einer neueren Version.
  unbekannt,

  /// Schon gekauft.
  bereitsGekauft,

  /// Zu teuer.
  zuWenigGold,
}

/// Was der Spieler besitzt und was er davon trägt.
///
/// Unveränderlich: Jede Änderung gibt ein neues [Loadout] zurück.
///
/// **Gold steht hier nicht drin, und das ist Absicht.** Wie bei
/// `TheoryProgress` und `HabitTracker` wird gerechnet statt gezählt: Der
/// Zufluss kommt aus Theorie und Gewohnheiten, der Abfluss ist die Summe
/// der Preise des Besitzes ([spentGold]). Ein Stand kann deshalb nicht
/// „falschen" Goldstand haben — es gibt keinen gespeicherten Goldstand, der
/// abweichen könnte.
///
/// Das ist auch der Grund, warum es keinen Verkauf gibt: Er bräuchte eine
/// Verkaufshistorie und damit die zweite Wahrheit, die ADR-0008 vermeiden
/// wollte. Der Preis dafür ist überschaubar, weil jedes Stück einen eigenen
/// Platz belegt — man kauft nichts doppelt.
class Loadout {
  Loadout({
    Iterable<String> ownedIds = const <String>[],
    Map<GearSlot, String> equipped = const <GearSlot, String>{},
  })  : _ownedIds = Set<String>.unmodifiable(ownedIds),
        _equipped = Map<GearSlot, String>.unmodifiable(equipped);

  const Loadout.empty()
      : _ownedIds = const <String>{},
        _equipped = const <GearSlot, String>{};

  /// Liest einen gespeicherten Stand.
  ///
  /// Nachsichtig wie die übrigen `fromJson` im Projekt: Unbekannte Ids
  /// werden übersprungen. Das ist hier besonders wichtig, weil ein
  /// entferntes Ausrüstungsstück sonst den Goldstand verfälschen würde —
  /// so verschwindet mit dem Stück auch genau sein Preis.
  factory Loadout.fromJson(Map<String, Object?> json) {
    final owned = <String>{};
    final rawOwned = json['ownedIds'];
    if (rawOwned is List) {
      for (final id in rawOwned) {
        if (id is String && GearCatalog.byId(id) != null) owned.add(id);
      }
    }

    final equipped = <GearSlot, String>{};
    final rawEquipped = json['equipped'];
    if (rawEquipped is Map) {
      for (final entry in rawEquipped.entries) {
        final slotName = entry.key;
        final itemId = entry.value;
        if (slotName is! String || itemId is! String) continue;
        if (!owned.contains(itemId)) continue;

        final item = GearCatalog.byId(itemId);
        if (item == null || item.slot.name != slotName) continue;
        equipped[item.slot] = itemId;
      }
    }

    return Loadout(ownedIds: owned, equipped: equipped);
  }

  final Set<String> _ownedIds;
  final Map<GearSlot, String> _equipped;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ownedIds': _ownedIds.toList()..sort(),
      'equipped': <String, Object?>{
        for (final entry in _equipped.entries) entry.key.name: entry.value,
      },
    };
  }

  // --- Besitz ---

  /// Alles Gekaufte, in der Reihenfolge des Katalogs.
  List<GearItem> get owned {
    final items = <GearItem>[
      for (final item in GearCatalog.all)
        if (_ownedIds.contains(item.id)) item,
    ];
    return List<GearItem>.unmodifiable(items);
  }

  bool isOwned(String itemId) => _ownedIds.contains(itemId);

  /// Wie viel Gold der Besitz gekostet hat. Der einzige Gold-Abfluss des
  /// Spiels.
  int get spentGold {
    var sum = 0;
    for (final id in _ownedIds) {
      sum += GearCatalog.byId(id)?.price ?? 0;
    }
    return sum;
  }

  /// Warum ein Kauf nicht geht — oder null, wenn er geht.
  ///
  /// Gibt einen Grund statt eines bloßen `false` zurück, damit die
  /// Oberfläche sagen kann, *warum* der Knopf aus ist. „Geht nicht" ohne
  /// Grund ist die häufigste Art, einen Nutzer zu verlieren.
  PurchaseBlock? blockFor(String itemId, {required int availableGold}) {
    final item = GearCatalog.byId(itemId);
    if (item == null) return PurchaseBlock.unbekannt;
    if (isOwned(itemId)) return PurchaseBlock.bereitsGekauft;
    if (item.price > availableGold) return PurchaseBlock.zuWenigGold;
    return null;
  }

  bool canBuy(String itemId, {required int availableGold}) {
    return blockFor(itemId, availableGold: availableGold) == null;
  }

  /// Kauft ein Stück und legt es gleich an.
  ///
  /// Gibt unverändert zurück, wenn der Kauf nicht geht — die Oberfläche
  /// fragt vorher mit [blockFor] und schaltet den Knopf ab. Sofort anlegen,
  /// weil ein gekauftes Stück, das nicht wirkt, wie ein Fehler aussieht;
  /// wer die alte Wahl zurück will, kann jederzeit umrüsten.
  Loadout buy(String itemId, {required int availableGold}) {
    if (!canBuy(itemId, availableGold: availableGold)) return this;
    final item = GearCatalog.byId(itemId);
    if (item == null) return this;

    return Loadout(
      ownedIds: <String>{..._ownedIds, itemId},
      equipped: <GearSlot, String>{..._equipped, item.slot: itemId},
    );
  }

  // --- Tragen ---

  String? equippedIdIn(GearSlot slot) => _equipped[slot];

  GearItem? equippedIn(GearSlot slot) {
    final id = _equipped[slot];
    return id == null ? null : GearCatalog.byId(id);
  }

  bool isEquipped(String itemId) => _equipped.containsValue(itemId);

  /// Legt ein besessenes Stück an. Verdrängt, was auf dem Platz lag.
  Loadout equip(String itemId) {
    if (!isOwned(itemId)) return this;
    final item = GearCatalog.byId(itemId);
    if (item == null) return this;

    return Loadout(
      ownedIds: _ownedIds,
      equipped: <GearSlot, String>{..._equipped, item.slot: itemId},
    );
  }

  Loadout unequip(GearSlot slot) {
    if (!_equipped.containsKey(slot)) return this;
    final next = <GearSlot, String>{..._equipped}..remove(slot);
    return Loadout(ownedIds: _ownedIds, equipped: next);
  }

  /// Die Summe aller getragenen Stücke. Was nur im Besitz ist, wirkt
  /// nicht.
  GearBonus get bonus {
    var total = const GearBonus();
    for (final slot in GearSlot.values) {
      final item = equippedIn(slot);
      if (item != null) total = total + item.bonus;
    }
    return total;
  }

  int get equippedCount => _equipped.length;
}
