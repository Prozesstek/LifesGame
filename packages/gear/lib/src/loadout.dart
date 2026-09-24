import 'catalog.dart';
import 'copy.dart';
import 'gates.dart';
import 'gear_set.dart';
import 'item.dart';
import 'keys.dart';
import 'prices.dart';
import 'set_catalog.dart';

/// Warum ein Kauf nicht geht. Null heißt: geht.
enum PurchaseBlock {
  /// Gibt es nicht — Tippfehler oder ein Stück aus einer neueren Version.
  unbekannt,

  /// Dieses Angebot ist schon gekauft.
  bereitsGekauft,

  /// Zu teuer.
  zuWenigGold,

  /// Noch nicht verdient: Die Seltenheit hängt an der Gegnerreihe
  /// (`GearGates`), und die nötige Sprosse ist nicht geschlagen.
  gesperrt,
}

/// Was der Spieler besitzt und was er davon trägt.
///
/// Unveränderlich: Jede Änderung gibt ein neues [Loadout] zurück.
///
/// **Seit ADR-0048 hält er Exemplare, keine Ids.** Dasselbe Katalogstück
/// kann mehrmals da sein, jedes mit eigenen Werten ([GearCopy]).
///
/// **Gold steht hier nicht drin, und das bleibt so** (ADR-0011).
/// Gespeichert werden zwei Historien: alles je Erworbene samt dem, was es
/// gekostet hat ([_acquired]), und alles Verkaufte samt Erlös ([_sold]).
/// Was daraus fürs Gold folgt, wird gerechnet ([spentGold]). Ein
/// gespeicherter Kontostand könnte von der Rechnung abweichen, eine
/// Historie *ist* die Rechnung.
///
/// **Jede Methode, die einen neuen Loadout baut, gibt alle vier Felder
/// weiter** — und zwar über [_copyWith], das keines vergessen kann. Die
/// Falle aus `gotchas.md` (ein Feld mit Standardwert, das still
/// verschwindet) gab es hier mit `soldIds` schon einmal.
class Loadout {
  Loadout({
    Iterable<GearCopy> acquired = const <GearCopy>[],
    Map<String, int> sold = const <String, int>{},
    Map<GearSlot, String> equipped = const <GearSlot, String>{},
    this.keysConsumed = 0,
  })  : _acquired = List<GearCopy>.unmodifiable(acquired),
        _sold = Map<String, int>.unmodifiable(sold),
        _equipped = Map<GearSlot, String>.unmodifiable(equipped);

  const Loadout.empty()
      : _acquired = const <GearCopy>[],
        _sold = const <String, int>{},
        _equipped = const <GearSlot, String>{},
        keysConsumed = 0;

  /// Was ein Verkauf **vor** ADR-0048 zurückgab. Nur für die Übernahme
  /// alter Stände: Deren Verkäufe behalten ihre alte Rechnung.
  static const double legacyRefundShare = 0.5;

  /// Liest einen gespeicherten Stand — nachsichtig wie alle `fromJson`
  /// im Projekt: Unbekanntes wird übersprungen, nie geworfen.
  ///
  /// **Alte Stände (vor ADR-0048) werden übernommen, ohne Verlust:** Jedes
  /// besessene Stück wird ein Exemplar mit genau 100 %, zum heutigen
  /// Katalogpreis bezahlt; jeder frühere Verkauf ein Exemplar, das zum
  /// alten Satz verkauft wurde. Getragenes bleibt getragen.
  factory Loadout.fromJson(Map<String, Object?> json) {
    if (!json.containsKey('copies') && json.containsKey('ownedIds')) {
      return _fromLegacy(json);
    }

    final acquired = <GearCopy>[];
    final uids = <String>{};
    final rawCopies = json['copies'];
    if (rawCopies is List) {
      for (final raw in rawCopies) {
        final copy = GearCopy.fromJson(raw);
        if (copy == null || !uids.add(copy.uid)) continue;
        acquired.add(copy);
      }
    }

    final sold = <String, int>{};
    final rawSold = json['sold'];
    if (rawSold is Map) {
      for (final entry in rawSold.entries) {
        final uid = entry.key;
        final got = entry.value;
        if (uid is String && got is int && uids.contains(uid)) {
          sold[uid] = got;
        }
      }
    }

    final equipped = <GearSlot, String>{};
    final rawEquipped = json['equipped'];
    if (rawEquipped is Map) {
      for (final entry in rawEquipped.entries) {
        final slotName = entry.key;
        final uid = entry.value;
        if (slotName is! String || uid is! String) continue;
        if (sold.containsKey(uid)) continue;
        final copy = acquired.where((c) => c.uid == uid).firstOrNull;
        final item = copy?.item;
        if (item == null || item.slot.name != slotName) continue;
        equipped[item.slot] = uid;
      }
    }

    final keys = json['keys'];
    return Loadout(
      acquired: acquired,
      sold: sold,
      equipped: equipped,
      keysConsumed: keys is int && keys > 0 ? keys : 0,
    );
  }

  static Loadout _fromLegacy(Map<String, Object?> json) {
    final acquired = <GearCopy>[];
    final sold = <String, int>{};

    final rawOwned = json['ownedIds'];
    final owned = <String>{};
    if (rawOwned is List) {
      for (final id in rawOwned) {
        final item = id is String ? GearCatalog.byId(id) : null;
        if (item == null || !owned.add(item.id)) continue;
        acquired.add(_legacyCopy('alt-${item.id}', item));
      }
    }

    final rawSold = json['soldIds'];
    if (rawSold is List) {
      var i = 0;
      for (final id in rawSold) {
        final item = id is String ? GearCatalog.byId(id) : null;
        if (item == null) continue;
        final uid = 'alt-verkauft-${i++}-${item.id}';
        acquired.add(_legacyCopy(uid, item));
        sold[uid] = (item.price * legacyRefundShare).floor();
      }
    }

    final equipped = <GearSlot, String>{};
    final rawEquipped = json['equipped'];
    if (rawEquipped is Map) {
      for (final entry in rawEquipped.entries) {
        final itemId = entry.value;
        if (itemId is! String || !owned.contains(itemId)) continue;
        final item = GearCatalog.byId(itemId);
        if (item == null || item.slot.name != entry.key) continue;
        equipped[item.slot] = 'alt-$itemId';
      }
    }

    return Loadout(acquired: acquired, sold: sold, equipped: equipped);
  }

  static GearCopy _legacyCopy(String uid, GearItem item) {
    return GearCopy(
      uid: uid,
      itemId: item.id,
      bonus: item.bonus.scaled,
      paid: item.price,
    );
  }

  final List<GearCopy> _acquired;
  final Map<String, int> _sold;
  final Map<GearSlot, String> _equipped;

  /// Wie viele Schlüssel schon eingesetzt oder verfallen sind
  /// ([GearKeys]). Fällt nie.
  final int keysConsumed;

  Loadout _copyWith({
    List<GearCopy>? acquired,
    Map<String, int>? sold,
    Map<GearSlot, String>? equipped,
    int? keysConsumed,
  }) {
    return Loadout(
      acquired: acquired ?? _acquired,
      sold: sold ?? _sold,
      equipped: equipped ?? _equipped,
      keysConsumed: keysConsumed ?? this.keysConsumed,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'copies': <Object?>[for (final c in _acquired) c.toJson()],
      if (_sold.isNotEmpty) 'sold': _sold,
      'equipped': <String, Object?>{
        for (final entry in _equipped.entries) entry.key.name: entry.value,
      },
      if (keysConsumed > 0) 'keys': keysConsumed,
    };
  }

  // --- Besitz ---

  /// Was man gerade hat, in der Reihenfolge des Katalogs.
  List<GearCopy> get ownedCopies {
    final reihenfolge = <String, int>{
      for (var i = 0; i < GearCatalog.all.length; i++) GearCatalog.all[i].id: i,
    };
    final copies = _acquired.where((c) => !_sold.containsKey(c.uid)).toList()
      ..sort((a, b) {
        final nachKatalog =
            (reihenfolge[a.itemId] ?? 0).compareTo(reihenfolge[b.itemId] ?? 0);
        if (nachKatalog != 0) return nachKatalog;
        return b.bonus.total.compareTo(a.bonus.total);
      });
    return List<GearCopy>.unmodifiable(copies);
  }

  /// Was man auf einem Platz hat.
  List<GearCopy> copiesIn(GearSlot slot) {
    return List<GearCopy>.unmodifiable(
      ownedCopies.where((c) => c.item?.slot == slot),
    );
  }

  GearCopy? copyByUid(String uid) {
    if (_sold.containsKey(uid)) return null;
    return _acquired.where((c) => c.uid == uid).firstOrNull;
  }

  bool owns(String uid) => copyByUid(uid) != null;

  /// Ob ein Exemplar mit dieser Uid je da war — auch verkauft. Ein
  /// Angebot des Tagesladens gibt es damit genau einmal.
  bool hasAcquired(String uid) => _acquired.any((c) => c.uid == uid);

  /// Ob man irgendein Exemplar dieses Katalogstücks hat.
  bool ownsItem(String itemId) => ownedCopies.any((c) => c.itemId == itemId);

  /// Wie viel Gold ausgegeben ist: was je bezahlt wurde, minus was
  /// Verkäufe zurückgebracht haben.
  int get spentGold {
    var sum = 0;
    for (final copy in _acquired) {
      sum += copy.paid;
    }
    for (final got in _sold.values) {
      sum -= got;
    }
    return sum;
  }

  // --- Kaufen ---

  /// Warum ein Angebot nicht zu kaufen ist — oder null, wenn es geht.
  ///
  /// **Die Sperre kommt vor dem Gold**, wie bisher: Wer ein gesperrtes
  /// Stück ansieht, soll lesen, dass es verdient werden muss, nicht dass
  /// es zu teuer ist.
  PurchaseBlock? blockFor(
    GearCopy offer, {
    required int availableGold,
    int highestRung = 0,
  }) {
    final item = offer.item;
    if (item == null) return PurchaseBlock.unbekannt;
    if (hasAcquired(offer.uid)) return PurchaseBlock.bereitsGekauft;
    if (!GearGates.isOpen(item.rarity, highestRung: highestRung)) {
      return PurchaseBlock.gesperrt;
    }
    if (offer.paid > availableGold) return PurchaseBlock.zuWenigGold;
    return null;
  }

  /// Kauft ein Angebot. Unverändert, wenn es nicht geht.
  ///
  /// Angelegt wird es nur, wenn der Platz leer ist — ein gewürfeltes Stück
  /// kann schlechter sein als das getragene.
  Loadout buy(
    GearCopy offer, {
    required int availableGold,
    int highestRung = 0,
  }) {
    final block = blockFor(
      offer,
      availableGold: availableGold,
      highestRung: highestRung,
    );
    if (block != null) return this;
    return _add(offer);
  }

  /// Legt ein Exemplar ohne Preis ins Inventar — Beute des Wächters, oder
  /// ein Geschenk des Entwicklermodus. Kostet nichts, und das ist die
  /// Rechnung: `paid` wird auf null gesetzt.
  Loadout addFree(GearCopy copy) {
    if (copy.item == null || hasAcquired(copy.uid)) return this;
    return _add(
      GearCopy(
        uid: copy.uid,
        itemId: copy.itemId,
        bonus: copy.bonus,
        paid: 0,
      ),
    );
  }

  Loadout _add(GearCopy copy) {
    final item = copy.item;
    if (item == null) return this;
    final equipped = <GearSlot, String>{..._equipped};
    if (!equipped.containsKey(item.slot)) equipped[item.slot] = copy.uid;
    return _copyWith(
      acquired: <GearCopy>[..._acquired, copy],
      equipped: equipped,
    );
  }

  // --- Verkaufen ---

  /// Was ein Verkauf einbringt. Der Satz steht in [GearPrices].
  static int refundFor(GearItem item) {
    return (item.price * GearPrices.refundShare).floor();
  }

  bool canSell(String uid) => owns(uid);

  /// Verkauft ein Exemplar. Ein getragenes wird dabei abgelegt.
  Loadout sell(String uid) => sellAll(<String>[uid]);

  /// Verkauft mehrere auf einmal — für „alles Schlechtere verkaufen".
  Loadout sellAll(Iterable<String> uids) {
    final sold = <String, int>{..._sold};
    final equipped = <GearSlot, String>{..._equipped};
    for (final uid in uids) {
      final copy = copyByUid(uid);
      final item = copy?.item;
      if (copy == null || item == null || sold.containsKey(uid)) continue;
      sold[uid] = refundFor(item);
      if (equipped[item.slot] == uid) equipped.remove(item.slot);
    }
    if (sold.length == _sold.length) return this;
    return _copyWith(sold: sold, equipped: equipped);
  }

  /// Was sich gefahrlos verkaufen lässt: nicht getragen und nicht besser
  /// als das, was auf dem Platz getragen wird.
  ///
  /// **Nie dabei:** Set-Teile, Episches und Legendäres — ihr Wert steckt
  /// nicht in der Zahl. Waffen nur, wenn es dieselbe Waffe ist wie die
  /// getragene: Eine andere bringt einen anderen Grundangriff mit.
  List<GearCopy> get junk {
    final ergebnis = <GearCopy>[];
    for (final copy in ownedCopies) {
      final item = copy.item;
      if (item == null || isEquipped(copy.uid)) continue;
      if (item.isSetPiece || item.rarity.index >= GearRarity.epic.index) {
        continue;
      }
      final getragen = equippedCopyIn(item.slot);
      final getragenItem = getragen?.item;
      if (getragen == null || getragenItem == null) continue;
      if (item.slot == GearSlot.waffe && item.id != getragenItem.id) continue;
      final schlechtereStufe = item.rarity.index < getragenItem.rarity.index;
      final gleichUndSchwaecher = item.rarity == getragenItem.rarity &&
          copy.bonus.total <= getragen.bonus.total;
      if (schlechtereStufe || gleichUndSchwaecher) ergebnis.add(copy);
    }
    return List<GearCopy>.unmodifiable(ergebnis);
  }

  int get soldCount => _sold.length;

  /// Wie viele Stücke je als Beute kamen — die laufende Nummer der
  /// nächsten (`GearLoot.drop`), damit jede eine eigene Uid bekommt.
  int get lootCount =>
      _acquired.where((c) => c.uid.startsWith('beute-')).length;

  // --- Tragen ---

  GearCopy? equippedCopyIn(GearSlot slot) {
    final uid = _equipped[slot];
    return uid == null ? null : copyByUid(uid);
  }

  /// Das Katalogstück, das auf dem Platz getragen wird — für alles, was
  /// nur fragt, *welches* Stück es ist (Seltenheit, Waffenzug, Bild).
  GearItem? equippedIn(GearSlot slot) => equippedCopyIn(slot)?.item;

  bool isEquipped(String uid) => _equipped.containsValue(uid);

  /// Legt ein Exemplar an. Verdrängt, was auf dem Platz lag.
  Loadout equip(String uid) {
    final item = copyByUid(uid)?.item;
    if (item == null) return this;
    return _copyWith(
      equipped: <GearSlot, String>{..._equipped, item.slot: uid},
    );
  }

  Loadout unequip(GearSlot slot) {
    if (!_equipped.containsKey(slot)) return this;
    return _copyWith(
      equipped: <GearSlot, String>{..._equipped}..remove(slot),
    );
  }

  int get equippedCount => _equipped.length;

  /// Die Summe aller getragenen Exemplare, im Kampfmassstab. Was nur im
  /// Besitz ist, wirkt nicht.
  GearBonus get bonus {
    var total = const GearBonus();
    for (final slot in GearSlot.values) {
      final copy = equippedCopyIn(slot);
      if (copy != null) total = total + copy.bonus;
    }
    return total;
  }

  // --- Sets ---

  /// Wie viele Teile eines Sets **getragen** werden.
  int equippedPiecesOf(String setId) {
    var count = 0;
    for (final slot in GearSlot.values) {
      if (equippedIn(slot)?.setId == setId) count++;
    }
    return count;
  }

  bool get wearsAnySetPiece {
    return GearSlot.values.any((s) => equippedIn(s)?.isSetPiece ?? false);
  }

  /// Alle Sets, die gerade wirken — abgeleitet, nie gespeichert.
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

  // --- Schlüssel (ADR-0048) ---

  /// Setzt einen Schlüssel ein. [earned] rechnet die App aus Häkchen,
  /// Seiten und Rückfragen. Unverändert, wenn keiner da ist.
  Loadout useKey({required int earned}) {
    final next = GearKeys.consume(earned: earned, consumed: keysConsumed);
    if (next == keysConsumed) return this;
    return _copyWith(keysConsumed: next);
  }

  // --- Was die Errungenschaften auslesen (ADR-0033) ---
  //
  // Alles hier fragt „je besessen", nicht „im Besitz", und zählt
  // **Katalogstücke**, nicht Exemplare: Ein zweites Schwert derselben
  // Sorte ist keine neue Errungenschaft. Keine dieser Zahlen kann fallen.

  /// Jedes Katalogstück, von dem je ein Exemplar da war.
  Set<String> get everOwnedIds => <String>{
        for (final c in _acquired) c.itemId,
      };

  int get everOwnedCount {
    final ids = everOwnedIds;
    return GearCatalog.all.where((i) => ids.contains(i.id)).length;
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

  /// Wie viele Sets je vollständig beisammen waren, Stück für Stück.
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
}
