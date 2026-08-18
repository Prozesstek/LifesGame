import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Ein Ausrüstungsstück im Laden.
///
/// Zeigt auch, was **nicht** geht, und warum. „Kaufen" auszugrauen ohne
/// Grund ist die häufigste Art, einen Nutzer ratlos zurückzulassen —
/// deshalb liefert `Loadout.blockFor` einen Grund und nicht nur ein
/// `false`.
class ShopItemTile extends StatelessWidget {
  const ShopItemTile({
    required this.item,
    required this.block,
    required this.isEquipped,
    required this.missingGold,
    required this.onBuy,
    super.key,
  });

  final GearItem item;

  /// Warum der Kauf nicht geht. Null heißt: geht.
  final PurchaseBlock? block;

  final bool isEquipped;

  /// Wie viel Gold noch fehlt. Nur sinnvoll bei
  /// [PurchaseBlock.zuWenigGold].
  final int missingGold;

  final VoidCallback onBuy;

  bool get _isOwned => block == PurchaseBlock.bereitsGekauft;

  /// Gold, das ein voller Tag Gewohnheiten bringt.
  ///
  /// Abgeleitet statt hingeschrieben: Die beiden Zahlen stehen in
  /// `package:habits`, und die Schichtregel aus `CLAUDE.md` verbietet,
  /// sie hier zu wiederholen. Wer die Belohnung dort ändert, ändert diese
  /// Aussage mit.
  static int get _goldProTag =>
      HabitRewards.goldPerCheck * HabitRewards.maxActiveHabits;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: block == null,
      enabled: block == null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: isEquipped
              ? Border.all(color: Palette.accent, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isOwned ? Palette.textDim : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.bonus.labels.join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Action(
                  item: item,
                  block: block,
                  isEquipped: isEquipped,
                  onBuy: onBuy,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.why,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Palette.textDim,
              ),
            ),
            if (block == PurchaseBlock.zuWenigGold) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Noch $missingGold Gold — das sind etwa '
                '${(missingGold / _goldProTag).ceil()} Tage Gewohnheiten.',
                style: const TextStyle(fontSize: 11, color: Palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.item,
    required this.block,
    required this.isEquipped,
    required this.onBuy,
  });

  final GearItem item;
  final PurchaseBlock? block;
  final bool isEquipped;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    if (block == PurchaseBlock.bereitsGekauft) {
      return Text(
        isEquipped ? 'getragen' : 'gekauft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isEquipped ? Palette.accent : Palette.muted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          '${item.price} Gold',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Palette.gold,
          ),
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: block == null ? onBuy : null,
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('Kaufen'),
        ),
      ],
    );
  }
}
