import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../progression/level_provider.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';
import 'widgets/shop_item_tile.dart';

/// Der Laden — der einzige Ort, an dem Gold wieder verschwindet.
///
/// Ohne ihn war Gold eine Zahl, die nur wuchs. Das Konzept nennt
/// Gewohnheiten und Theorie ausdrücklich „Einnahme" und alles Weitere
/// „Ausgabe" (Abschnitt 1); bis hierher fehlte die zweite Hälfte.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ref.watch(goldProvider);
    final loadout = ref.watch(loadoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laden'),
        backgroundColor: Palette.surface,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$gold Gold',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: <Widget>[
                const Text(
                  'Gekauftes wird sofort angelegt. Umrüsten kostet nichts — '
                  'nur der Kauf kostet.',
                  style: TextStyle(fontSize: 13, color: Palette.textDim),
                ),
                const SizedBox(height: 18),
                for (final slot in GearSlot.values) ...<Widget>[
                  _SlotHeader(
                    slot: slot,
                    equippedName: loadout.equippedIn(slot)?.name,
                  ),
                  const SizedBox(height: 8),
                  for (final item in GearCatalog.forSlot(slot)) ...<Widget>[
                    ShopItemTile(
                      item: item,
                      block: loadout.blockFor(item.id, availableGold: gold),
                      isEquipped: loadout.isEquipped(item.id),
                      missingGold: item.price - gold,
                      onBuy: () => _buy(context, ref, item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _buy(BuildContext context, WidgetRef ref, GearItem item) {
    final block = ref.read(loadoutProvider.notifier).buy(item.id);
    if (!context.mounted) return;

    final message = switch (block) {
      null => '${item.name} gekauft und angelegt.',
      PurchaseBlock.zuWenigGold => 'Dafür reicht das Gold noch nicht.',
      PurchaseBlock.bereitsGekauft => 'Hast du schon.',
      PurchaseBlock.unbekannt => 'Dieses Stück gibt es nicht mehr.',
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

class _SlotHeader extends StatelessWidget {
  const _SlotHeader({required this.slot, required this.equippedName});

  final GearSlot slot;
  final String? equippedName;

  @override
  Widget build(BuildContext context) {
    final name = equippedName;

    return Row(
      children: <Widget>[
        Text(
          slot.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name == null ? 'nichts angelegt' : 'getragen: $name',
            style: const TextStyle(fontSize: 12, color: Palette.muted),
          ),
        ),
      ],
    );
  }
}
