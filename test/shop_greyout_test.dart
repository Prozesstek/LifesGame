import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/gear/widgets/shop_item_cell.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Was man mit einem Tipp nicht kaufen kann, ist ausgegraut (Issue #49).
///
/// Die Kachel fragt dafür dieselbe Stelle wie der Kaufknopf,
/// `Loadout.blockFor`. Geprüft wird deshalb der ganze Weg vom Gold bis
/// zur Kachel, nicht der Parameter allein.
void main() {
  Widget appMit(SaveData saved) {
    return ProviderScope(
      overrides: [savedGameProvider.overrideWithValue(saved)],
      child: const MaterialApp(home: ShopScreen()),
    );
  }

  /// Ein Stand, der nur aus den Lektionen Gold hat — genug für die
  /// billigste Waffe, zu wenig für die teuerste offene.
  SaveData nurTheorie() {
    var progress = const TheoryProgress.empty();
    for (final lesson in theoryTree.branches.expand((b) => b.lessons)) {
      progress = progress.submit(lesson, <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ]).progress;
    }
    return SaveData(theory: progress);
  }

  ShopItemCell zelle(WidgetTester tester, GearItem item) {
    return tester.widget<ShopItemCell>(
      find.byWidgetPredicate((w) => w is ShopItemCell && w.item.id == item.id),
    );
  }

  final waffen = GearCatalog.forSlot(GearSlot.waffe);
  final offen = waffen
      .where((i) => GearGates.isOpen(i.rarity, highestRung: 0))
      .toList();
  final billigste = offen.reduce((a, b) => a.price <= b.price ? a : b);
  final teuerste = offen.reduce((a, b) => a.price >= b.price ? a : b);
  final gesperrt = waffen.firstWhere((i) => i.rarity == GearRarity.epic);

  testWidgets('ohne Gold ist jede Kachel ausgegraut', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(appMit(const SaveData.empty()));
    await tester.pumpAndSettle();

    for (final item in waffen) {
      expect(zelle(tester, item).isOutOfReach, isTrue, reason: item.name);
    }
  });

  testWidgets('was das Gold trägt, ist nicht ausgegraut', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(appMit(nurTheorie()));
    await tester.pumpAndSettle();

    // Die Annahme, auf der der Test steht: Die Lektionen zahlen mehr als
    // die billigste Waffe und weniger als die teuerste.
    final gold = ProviderScope.containerOf(
      tester.element(find.byType(ShopScreen)),
    ).read(goldProvider);
    expect(gold, inInclusiveRange(billigste.price, teuerste.price - 1));

    final zelleBillig = zelle(tester, billigste);
    final zelleTeuer = zelle(tester, teuerste);
    expect(zelleBillig.block, isNull);
    expect(zelleTeuer.block, PurchaseBlock.zuWenigGold);

    expect(zelleBillig.isOutOfReach, isFalse);
    expect(zelleTeuer.isOutOfReach, isTrue);
    expect(zelle(tester, gesperrt).isOutOfReach, isTrue);
  });

  testWidgets('eine ausgegraute Kachel lässt sich trotzdem wählen', (
    tester,
  ) async {
    useTallView(tester);
    await tester.pumpWidget(appMit(const SaveData.empty()));
    await tester.pumpAndSettle();

    // Die Detailfläche muss sagen können, was fehlt — sonst wäre eine
    // ausgegraute Kachel eine Sackgasse.
    await tester.tap(find.text(teuerste.name));
    await tester.pumpAndSettle();

    expect(zelle(tester, teuerste).isSelected, isTrue);
  });

  test('was schon gehört, ist nicht ausgegraut', () {
    final cell = ShopItemCell(
      item: billigste,
      isSelected: false,
      isOwned: true,
      isEquipped: false,
      onTap: () {},
      block: PurchaseBlock.bereitsGekauft,
    );
    expect(cell.isOutOfReach, isFalse);
  });
}
