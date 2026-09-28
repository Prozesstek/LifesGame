/// Wie der Ausrüstungs-Bildschirm den Katalog ordnet (ADR-0057).
///
/// **Reine Rechnung, kein Widget.** Welche Stücke in welcher Gruppe und
/// in welcher Reihenfolge stehen, steht hier einmal, damit ein Test es
/// ohne Bildschirm prüfen kann, zum Beispiel, dass keine Gruppierung ein
/// Stück verliert.
library;

import 'package:gear/gear.dart';

/// Die vier Arten, den Katalog zu ordnen. Die erste ist der Standard.
enum GearGrouping {
  /// Ein durchgehendes Raster von A bis Z, damit man alles auf einmal sieht.
  alphabetisch('A–Z'),
  platz('Platz'),
  seltenheit('Seltenheit'),
  set('Set');

  const GearGrouping(this.label);

  final String label;
}

/// Eine Gruppe im Raster: eine Überschrift und ihre Stücke.
///
/// [title] ist null beim alphabetischen Raster, weil es dort nur die
/// eine Gruppe gibt und eine Überschrift darüber nichts sagt.
/// [rarity] ist nur bei der Gruppierung nach Seltenheit gesetzt: Die
/// Überschrift steht dann als Marke da, in derselben Farbe wie im Laden.
typedef GearGroup = ({String? title, GearRarity? rarity, List<GearItem> items});

/// Ordnet [items] nach [grouping]. Leere Gruppen fallen weg.
///
/// Standard ist der ganze Katalog. Ein Test übergibt eine eigene Liste,
/// wenn er etwas Bestimmtes prüfen will.
List<GearGroup> groupGear(
  GearGrouping grouping, {
  List<GearItem> items = GearCatalog.all,
}) {
  final groups = switch (grouping) {
    GearGrouping.alphabetisch => <GearGroup>[
      (title: null, rarity: null, items: _sorted(items, _byName)),
    ],
    GearGrouping.platz => <GearGroup>[
      for (final slot in GearSlot.values)
        (
          title: slot.label,
          rarity: null,
          items: _sorted(
            items.where((i) => i.slot == slot),
            _byRarityThenPrice,
          ),
        ),
    ],
    GearGrouping.seltenheit => <GearGroup>[
      for (final rarity in GearRarity.values)
        (
          title: rarity.label,
          rarity: rarity,
          items: _sorted(
            items.where((i) => i.rarity == rarity),
            _bySlotThenName,
          ),
        ),
    ],
    GearGrouping.set => <GearGroup>[
      for (final set in GearSets.all)
        (
          title: set.name,
          rarity: null,
          items: _sorted(
            items.where((i) => i.setId == set.id),
            _bySlotThenName,
          ),
        ),
      (
        title: 'Ohne Set',
        rarity: null,
        items: _sorted(items.where((i) => i.setId == null), _bySlotThenName),
      ),
    ],
  };
  return List<GearGroup>.unmodifiable(groups.where((g) => g.items.isNotEmpty));
}

List<GearItem> _sorted(
  Iterable<GearItem> items,
  int Function(GearItem, GearItem) compare,
) {
  return List<GearItem>.unmodifiable(items.toList()..sort(compare));
}

int _byName(GearItem a, GearItem b) =>
    sortKey(a.name).compareTo(sortKey(b.name));

int _byRarityThenPrice(GearItem a, GearItem b) {
  final stufe = a.rarity.index.compareTo(b.rarity.index);
  return stufe != 0 ? stufe : a.price.compareTo(b.price);
}

int _bySlotThenName(GearItem a, GearItem b) {
  final platz = a.slot.index.compareTo(b.slot.index);
  return platz != 0 ? platz : _byName(a, b);
}

/// Ein Name, wie er im Alphabet steht: Umlaute bei ihrem Grundlaut.
///
/// **Ohne das stünde „Übungsklinge" hinter „Zweihänder".** Dart
/// vergleicht Zeichenketten nach Zeichencode, und „Ü" liegt dort hinter
/// „Z". Ein deutsches Alphabet sortiert es unter U.
String sortKey(String name) {
  return name
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
}
