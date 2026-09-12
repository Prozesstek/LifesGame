import 'catalog.dart';
import 'gear_set.dart';
import 'item.dart';
import 'prices.dart';
import 'set_catalog.dart';

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
/// **Verkauf gibt es seit ADR-0031 — und er bricht die Regel nicht.** Was
/// gespeichert wird, ist keine zweite Wahrheit über den Kontostand, sondern
/// eine dritte *Historie* neben Besitz und Häkchen: [soldIds], die Liste
/// dessen, was verkauft wurde. Was daraus für das Gold folgt, wird weiter
/// gerechnet ([lostGold]).
class Loadout {
  Loadout({
    Iterable<String> ownedIds = const <String>[],
    Map<GearSlot, String> equipped = const <GearSlot, String>{},
    Iterable<String> soldIds = const <String>[],
  })  : _ownedIds = Set<String>.unmodifiable(ownedIds),
        _equipped = Map<GearSlot, String>.unmodifiable(equipped),
        _soldIds = List<String>.unmodifiable(soldIds);

  const Loadout.empty()
      : _ownedIds = const <String>{},
        _equipped = const <GearSlot, String>{},
        _soldIds = const <String>[];

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

    // **Die Verkaufshistorie behält ihre Reihenfolge und ihre
    // Wiederholungen.** Wer dasselbe Stück zweimal gekauft und verkauft
    // hat, hat auch zweimal draufgezahlt.
    final sold = <String>[];
    final rawSold = json['soldIds'];
    if (rawSold is List) {
      for (final id in rawSold) {
        if (id is String && GearCatalog.byId(id) != null) sold.add(id);
      }
    }

    return Loadout(ownedIds: owned, equipped: equipped, soldIds: sold);
  }

  final Set<String> _ownedIds;
  final Map<GearSlot, String> _equipped;
  final List<String> _soldIds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ownedIds': _ownedIds.toList()..sort(),
      'equipped': <String, Object?>{
        for (final entry in _equipped.entries) entry.key.name: entry.value,
      },
      // Nur schreiben, wenn etwas drinsteht: Ein Stand ohne Verkäufe sieht
      // aus wie vor ADR-0031.
      if (_soldIds.isNotEmpty) 'soldIds': _soldIds,
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

  /// Wie viel Gold ausgegeben ist: was der Besitz gekostet hat, plus was
  /// bei Verkäufen liegen geblieben ist.
  ///
  /// **Der zweite Summand ist der ganze Trick von ADR-0031.** Ohne ihn
  /// gäbe ein Verkauf den vollen Preis zurück — nicht weil es so gedacht
  /// wäre, sondern weil das Stück aus [_ownedIds] verschwindet und damit
  /// aus dieser Summe. Der Laden wäre folgenlos: kaufen, ansehen,
  /// zurückgeben.
  int get spentGold {
    var sum = lostGold;
    for (final id in _ownedIds) {
      sum += GearCatalog.byId(id)?.price ?? 0;
    }
    return sum;
  }

  /// Was Verkäufe gekostet haben — die Hälfte des Preises je Verkauf.
  ///
  /// **Gerechnet aus der Historie, nicht mitgezählt.** Dieselbe Bauform
  /// wie bei [spentGold] und wie bei der Erfahrung in `package:habits`:
  /// gespeichert wird, *was passiert ist*, abgeleitet wird, *was daraus
  /// folgt*. Eine mitgeführte Zahl könnte von der Liste abweichen; diese
  /// hier kann es nicht.
  int get lostGold {
    var sum = 0;
    for (final id in _soldIds) {
      final item = GearCatalog.byId(id);
      if (item == null) continue;
      sum += item.price - refundFor(item);
    }
    return sum;
  }

  /// Was ein Verkauf einbringt. Der Satz steht in [GearPrices].
  static int refundFor(GearItem item) {
    return (item.price * GearPrices.refundShare).floor();
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
      soldIds: _soldIds,
    );
  }

  // --- Verkaufen ---

  /// Alles, was verkauft wurde, in der Reihenfolge der Verkäufe.
  ///
  /// Mit Wiederholungen: Wer dasselbe Stück zweimal gekauft und verkauft
  /// hat, steht zweimal darin und hat zweimal draufgezahlt.
  List<String> get soldIds => _soldIds;

  bool canSell(String itemId) => isOwned(itemId);

  /// Verkauft ein Stück für die Hälfte seines Preises.
  ///
  /// Gibt unverändert zurück, was man nicht besitzt — dieselbe Nachsicht
  /// wie bei [equip]. Ein getragenes Stück wird dabei **abgelegt**: Es
  /// gehört einem nicht mehr, also kann es nicht mehr wirken.
  ///
  /// Zurückkaufen geht jederzeit, aber zum vollen Preis. Genau darin
  /// besteht die Entscheidung.
  Loadout sell(String itemId) {
    if (!canSell(itemId)) return this;
    final item = GearCatalog.byId(itemId);
    if (item == null) return this;

    final owned = <String>{..._ownedIds}..remove(itemId);
    final equipped = <GearSlot, String>{..._equipped};
    if (equipped[item.slot] == itemId) equipped.remove(item.slot);

    return Loadout(
      ownedIds: owned,
      equipped: equipped,
      soldIds: <String>[..._soldIds, itemId],
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
      soldIds: _soldIds,
    );
  }

  Loadout unequip(GearSlot slot) {
    if (!_equipped.containsKey(slot)) return this;
    final next = <GearSlot, String>{..._equipped}..remove(slot);
    return Loadout(ownedIds: _ownedIds, equipped: next, soldIds: _soldIds);
  }

  // --- Sets ---

  /// Wie viele Teile eines Sets **getragen** werden.
  ///
  /// Besitz zählt nicht. Ein Set im Rucksack ist kein Set — sonst wäre die
  /// Wahl auf jedem Platz folgenlos, sobald man einmal alles gekauft hat.
  int equippedPiecesOf(String setId) {
    var count = 0;
    for (final id in _equipped.values) {
      if (GearCatalog.byId(id)?.setId == setId) count++;
    }
    return count;
  }

  /// Ob überhaupt ein Set-Teil getragen wird.
  ///
  /// Nicht dasselbe wie „ein Set wirkt": Ein einzelnes Teil wirkt nicht,
  /// ist aber ein Anfang — und genau das soll der Charakterbildschirm
  /// zeigen dürfen, statt es zu verschweigen.
  bool get wearsAnySetPiece {
    return _equipped.values
        .any((id) => GearCatalog.byId(id)?.isSetPiece ?? false);
  }

  /// Alle Sets, die gerade wirken — mit Stufe und Wirkung.
  ///
  /// **Abgeleitet, nicht gespeichert**, wie das Gold (ADR-0011) und die
  /// Erfahrung (ADR-0008). Ein gespeicherter Set-Zustand könnte von dem
  /// abweichen, was tatsächlich getragen wird.
  List<ActiveSet> get activeSets {
    final aktiv = <ActiveSet>[];
    for (final set in GearSets.all) {
      final pieces = equippedPiecesOf(set.id);
      final perk = set.perkFor(pieces);
      if (perk == null) continue;
      aktiv.add(ActiveSet(set: set, pieces: pieces, perk: perk));
    }
    return List<ActiveSet>.unmodifiable(aktiv);
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

  // --- Was die Errungenschaften auslesen (ADR-0033) ---
  //
  // Alles hier fragt „je besessen" und nicht „im Besitz". Eine
  // Errungenschaft darf durch einen Verkauf nicht zurückgenommen werden
  // (ADR-0033, Punkt 3) — und dass sich das überhaupt rechnen lässt,
  // liegt an ADR-0031: [soldIds] ist eine Historie, keine Bilanz. Wäre
  // ein Verkauf nur ein Abzug gewesen, stünde hier nichts mehr, woraus
  // man es ableiten könnte.

  /// Jede Id, die je im Besitz war — Verkauftes eingeschlossen.
  Set<String> get everOwnedIds => <String>{..._ownedIds, ..._soldIds};

  /// Wie viele **verschiedene** Stücke je besessen wurden.
  ///
  /// Wer dasselbe Stück zweimal gekauft und verkauft hat, steht in
  /// [soldIds] zweimal und zählt hier trotzdem einmal.
  int get everOwnedCount {
    var count = 0;
    final ids = everOwnedIds;
    for (final item in GearCatalog.all) {
      if (ids.contains(item.id)) count++;
    }
    return count;
  }

  /// Auf wie vielen der sechs Plätze je ein Stück lag.
  int get slotsEverOwned {
    final slots = <GearSlot>{};
    for (final id in everOwnedIds) {
      final item = GearCatalog.byId(id);
      if (item != null) slots.add(item.slot);
    }
    return slots.length;
  }

  /// Wie viele Sets je vollständig zusammen waren.
  ///
  /// **Stück für Stück gezählt, nicht gleichzeitig getragen.** Das ist
  /// bewusst nicht [activeSets]: Dort geht es darum, was *jetzt* wirkt,
  /// hier darum, was jemand einmal beisammen hatte.
  int get completeSetsEverOwned {
    final ids = everOwnedIds;
    var count = 0;
    for (final set in GearSets.all) {
      final pieces = GearCatalog.all.where((i) => i.setId == set.id);
      if (pieces.isEmpty) continue;
      if (pieces.every((i) => ids.contains(i.id))) count++;
    }
    return count;
  }

  /// Wie oft verkauft wurde. Mit Wiederholungen — zweimal draufgezahlt
  /// ist zweimal verkauft.
  int get soldCount => _soldIds.length;
}
