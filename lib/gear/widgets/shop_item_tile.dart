import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';
import 'copy_stats.dart';
import 'rarity_badge.dart';
import '../../ui/holz.dart';

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
                                  : Palette.text,
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
          if (block == PurchaseBlock.gesperrt) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Verdient ab Stufe $requiredRung der Grube.',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Palette.muted,
              ),
            ),
          ],
          if (block == PurchaseBlock.zuWenigGold) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Noch $missingGold Gold.',
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }

  /// Rechts beim Angebot: Preis und Kaufen — oder „gekauft".
  Widget _angebot() {
    if (_istVergriffen) {
      return const Text(
        'gekauft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Palette.muted,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          '${copy.paid} Gold',
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
