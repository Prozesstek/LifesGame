import 'catalog.dart';
import 'item.dart';

/// Ein Exemplar eines Ausrüstungsstücks — Katalogstück plus eigene Werte
/// (ADR-0048).
///
/// **Die Werte sind gespeichert, nicht nur ihr Startwert.** Wird die
/// Würfelregel später geändert, bleibt ein Stück, das man hat, wie es
/// war. Gewürfelt wird genau einmal: wenn es entsteht, im Tagesladen oder
/// als Beute (`GearRoll`).
///
/// **Die Werte stehen im Kampfmassstab** ([GearBonus.combatScale]), also
/// zehnmal so gross wie die Katalogzahl — „Angriff +11" statt „+1,1".
class GearCopy {
  const GearCopy({
    required this.uid,
    required this.itemId,
    required this.bonus,
    required this.paid,
  });

  /// Eindeutig und **aus der Herkunft gebildet** — `laden-20355-waffe`,
  /// `beute-12-20355-3`, `alt-gear-kurzbogen`. Ein Angebot des
  /// Tagesladens lässt sich deshalb nur einmal kaufen: Dieselbe Uid steht
  /// dann schon in der Historie.
  final String uid;

  /// Welches Katalogstück es ist.
  final String itemId;

  /// Die gewürfelten Werte, im Kampfmassstab.
  final GearBonus bonus;

  /// Was dafür bezahlt wurde. Null bei Beute.
  final int paid;

  /// Das Katalogstück. Null, wenn es das Stück nicht mehr gibt — dann
  /// wird das Exemplar beim Laden übersprungen (`Loadout.fromJson`).
  GearItem? get item => GearCatalog.byId(itemId);

  /// Wie gut dieser Wurf ist, im Verhältnis zum Katalogwert: 1,0 ist der
  /// Durchschnitt, 0,85 bis 1,15 die Spanne. Für die Anzeige.
  double get quality {
    final katalog = item?.bonus.scaled;
    if (katalog == null) return 1;
    final soll = katalog.total;
    if (soll == 0) return 1;
    return bonus.total / soll;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'u': uid,
      'i': itemId,
      'b': bonus.toJson(),
      if (paid != 0) 'p': paid,
    };
  }

  /// Nachsichtig: Fehlt etwas, gibt es null, und der Stand lädt ohne
  /// dieses eine Stück weiter.
  static GearCopy? fromJson(Object? json) {
    if (json is! Map) return null;
    final uid = json['u'];
    final itemId = json['i'];
    if (uid is! String || itemId is! String) return null;
    if (GearCatalog.byId(itemId) == null) return null;
    final paid = json['p'];
    return GearCopy(
      uid: uid,
      itemId: itemId,
      bonus: GearBonus.fromJson(json['b']),
      paid: paid is int && paid > 0 ? paid : 0,
    );
  }

  @override
  bool operator ==(Object other) => other is GearCopy && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
