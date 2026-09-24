import 'package:gear/gear.dart';

/// Ein Katalogstück als Angebot mit genau 100 % und seinem Katalogpreis —
/// so, wie es vor ADR-0048 der Laden verkaufte. Für Tests, die ein
/// bestimmtes Stück besitzen wollen, ohne auf den Tagesladen zu warten.
///
/// Die Uid ist `test-<id>`: Dasselbe Stück zweimal zu „kaufen" ist damit
/// dasselbe Angebot und geht nur einmal.
GearCopy angebot(String itemId) {
  final item = GearCatalog.byId(itemId);
  return GearCopy(
    uid: 'test-$itemId',
    itemId: itemId,
    bonus: item?.bonus.scaled ?? const GearBonus(),
    paid: item?.price ?? 0,
  );
}
