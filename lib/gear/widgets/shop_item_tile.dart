import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';
import 'rarity_badge.dart';

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
    required this.onSell,
    this.abilityLine,
    this.setPieces = 0,
    super.key,
  });

  final GearItem item;

  /// Was die Waffe an Fähigkeit mitbringt, in einer Zeile.
  ///
  /// Nur Waffen haben eine (ADR-0017), deshalb null bei allem anderen.
  /// Zusammengesetzt wird sie im [ShopScreen] — `package:gear` kennt
  /// weder Fähigkeiten noch Moves, und soll es nicht.
  final String? abilityLine;

  /// Wie viele Teile des Sets dieses Stücks bereits getragen werden.
  ///
  /// Ohne die Zahl wäre die Marke nur ein Etikett; mit ihr ist sie ein
  /// Fortschritt. Gezählt wird in `Loadout.equippedPiecesOf` — hier steht
  /// nur das Ergebnis.
  final int setPieces;

  /// Warum der Kauf nicht geht. Null heißt: geht.
  final PurchaseBlock? block;

  final bool isEquipped;

  /// Wie viel Gold noch fehlt. Nur sinnvoll bei
  /// [PurchaseBlock.zuWenigGold].
  final int missingGold;

  final VoidCallback onBuy;

  /// Verkaufen. Fragt vorher nach — der Rückkauf kostet den vollen Preis.
  final VoidCallback onSell;

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
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isOwned
                                    ? Palette.textDim
                                    : Palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RarityBadge(rarity: item.rarity, faded: _isOwned),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.bonus.labels.join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.success,
                        ),
                      ),
                      // **Die Set-Marke gehört an das Stück, nicht in eine
                      // eigene Liste.** Wer nach einem Set kauft, sucht
                      // im Laden — nicht auf einem zweiten Bildschirm.
                      if (GearSets.byId(item.setId)
                          case final GearSet set) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          'Teil von „${set.name}" · $setPieces von '
                          '${GearSet.fullSize} getragen',
                          style: TextStyle(
                            fontSize: 12,
                            color: setPieces >= GearSet.smallSize
                                ? Palette.accent
                                : Palette.muted,
                          ),
                        ),
                      ],
                      // **Ohne diese Zeile ist der Waffenkauf blind.**
                      // Fünf Waffen mit fünf Rhythmen sind nur dann eine
                      // Entscheidung, wenn man vor dem Kauf sieht,
                      // welchen man bekommt (Ziel 3).
                      if (abilityLine case final String line) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          line,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Palette.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Action(
                  item: item,
                  block: block,
                  isEquipped: isEquipped,
                  onBuy: onBuy,
                  onSell: onSell,
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
    required this.onSell,
  });

  final GearItem item;
  final PurchaseBlock? block;
  final bool isEquipped;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    if (block == PurchaseBlock.bereitsGekauft) {
      // **Der Verkauf steht bei dem, was man besitzt** — an derselben
      // Stelle wie sonst der Kaufknopf. Ein eigener Bildschirm für den
      // Verkauf hieße, denselben Katalog zweimal zu durchsuchen.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            isEquipped ? 'getragen' : 'gekauft',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isEquipped ? Palette.accent : Palette.muted,
            ),
          ),
          // Spiegelbild der Kaufseite: erst die Zahl, dann der Knopf. Der
          // Betrag gehört **nicht** in die Knopfbeschriftung — dort wird
          // sie so breit, dass die Zeile überläuft, sobald ein Preis
          // vierstellig wird (`docs/context/gotchas.md`).
          Text(
            '+${Loadout.refundFor(item)} Gold',
            style: const TextStyle(fontSize: 12, color: Palette.gold),
          ),
          TextButton(
            onPressed: onSell,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 30),
              foregroundColor: Palette.textDim,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Verkaufen'),
          ),
        ],
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
