import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';
import 'copy_stats.dart';
import 'rarity_badge.dart';
import '../../ui/holz.dart';
import '../../ui/gold_icon.dart';

/// Ein Angebot des Tages im Laden (ADR-0048). Besessenes zeigt seit
/// Issue #88 nur noch der Ausrüstungs-Bildschirm.
///
/// Zeigt auch, was **nicht** geht, und warum. „Kaufen" auszugrauen ohne
/// Grund ist die häufigste Art, einen Nutzer ratlos zurückzulassen —
/// deshalb liefert `Loadout.blockFor` einen Grund und nicht nur ein
/// `false`.
class ShopItemTile extends StatelessWidget {
  const ShopItemTile({
    required this.copy,
    this.block,
    this.missingGold = 0,
    this.worn,
    this.onBuy,
    this.abilityLine,
    this.setPieces = 0,
    this.requiredRung = 0,
    super.key,
  });

  final GearCopy copy;

  /// Warum der Kauf nicht geht. Null heißt: geht.
  final PurchaseBlock? block;

  /// Wie viel Gold noch fehlt. Nur bei [PurchaseBlock.zuWenigGold].
  final int missingGold;

  /// Was auf diesem Platz gerade getragen wird — zum Vergleichen. Null,
  /// wenn nichts, oder wenn es dieses Exemplar selbst ist.
  final GearCopy? worn;

  final VoidCallback? onBuy;

  /// Was die Waffe an Fähigkeit mitbringt, in einer Zeile. Nur Waffen.
  final String? abilityLine;

  /// Wie viele Teile des Sets dieses Stücks bereits getragen werden.
  final int setPieces;

  /// Welche Sprosse der Gegnerreihe dieses Stück verlangt. Nur bei
  /// [PurchaseBlock.gesperrt].
  final int requiredRung;

  bool get _istVergriffen => block == PurchaseBlock.bereitsGekauft;

  /// Woran man den Kaufknopf findet — er trägt kein Wort mehr.
  static const Key kaufenKey = ValueKey<String>('laden-kaufen');

  @override
  Widget build(BuildContext context) {
    final item = copy.item;
    if (item == null) return const SizedBox.shrink();
    final set = GearSets.byId(item.setId);
    final vergleich = worn;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                              color: _istVergriffen
                                  ? Palette.textDim
                                  : RarityBadge.colorOf(item.rarity),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RarityBadge(rarity: item.rarity, faded: _istVergriffen),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // **Der Wurf, nicht der Katalogwert** — untereinander,
                    // und in Klammern, was er gegen das Getragene bringt.
                    CopyStats(copy: copy, worn: vergleich),
                    if (set != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Semantics(
                        label:
                            'Teil von „${set.name}", $setPieces von '
                            '${GearSet.fullSize} getragen',
                        excludeSemantics: true,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: setPieces >= GearSet.smallSize
                                  ? Palette.accent
                                  : Palette.muted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${set.name} · $setPieces / '
                                '${GearSet.fullSize}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: setPieces >= GearSet.smallSize
                                      ? Palette.accent
                                      : Palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              _angebot(),
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
          // Warum es nicht geht, als Zeichen: Schloss mit Stufe der
          // Grube, oder die Münze mit dem, was fehlt.
          if (block == PurchaseBlock.gesperrt) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              label: 'Verdient ab Stufe $requiredRung der Grube.',
              excludeSemantics: true,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.lock, size: 14, color: Palette.muted),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.stairs_outlined,
                    size: 14,
                    color: Palette.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$requiredRung',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (block == PurchaseBlock.zuWenigGold) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              label: 'Noch $missingGold Gold.',
              excludeSemantics: true,
              child: Row(
                children: <Widget>[
                  const GoldIcon(size: 13),
                  const SizedBox(width: 3),
                  Text(
                    '−$missingGold',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Palette.enemy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Rechts beim Angebot: Preis und Kaufen — oder „gekauft".
  Widget _angebot() {
    if (_istVergriffen) {
      return const Icon(
        Icons.check_circle,
        size: 22,
        color: Palette.muted,
        semanticLabel: 'gekauft',
      );
    }
    // Der Knopf trägt den Preis: Münze und Zahl, sonst nichts.
    return FilledButton(
      key: ShopItemTile.kaufenKey,
      onPressed: block == null ? onBuy : null,
      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.shopping_cart_outlined, size: 16),
          const SizedBox(width: 6),
          const GoldIcon(size: 14),
          const SizedBox(width: 3),
          Text('${copy.paid}', semanticsLabel: 'Kaufen für ${copy.paid} Gold'),
        ],
      ),
    );
  }
}
