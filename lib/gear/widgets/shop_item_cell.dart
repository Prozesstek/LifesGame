import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';
import '../copy_text.dart';
import '../gear_icon.dart';
import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import 'rarity_badge.dart';

/// Ein Exemplar als Kachel im Raster — ein Angebot des Tages oder ein
/// Stück im Inventar (ADR-0048).
///
/// **Sie wählt aus, sie kauft nicht.** Gekauft wird in der Detailfläche
/// darunter — dort steht, was das Stück kann, was es kostet und was noch
/// fehlt. Eine Kachel, die beides täte, müsste zwei Tippflächen tragen,
/// und genau diese Mehrdeutigkeit steht bei den Gewohnheiten schon als
/// offener Punkt in `state.md`.
///
/// Was sie zeigen muss, damit die Wahl überhaupt eine ist: den Namen, die
/// Seltenheit als Rand **und als Farbe des Namens**, und ob das Stück
/// schon einem gehört.
class ShopItemCell extends StatelessWidget {
  const ShopItemCell({
    required this.copy,
    required this.isSelected,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
    this.block,
    super.key,
  });

  final GearCopy copy;
  final bool isSelected;
  final bool isOwned;
  final bool isEquipped;

  /// Warum das Stück gerade nicht zu kaufen ist, oder `null`, wenn es
  /// geht — die Antwort von [Loadout.blockFor], nicht nachgerechnet.
  ///
  /// Gesperrt (ADR-0034) und zu teuer werden beide ausgegraut
  /// (Issue #49). Die Kachel bleibt dabei antippbar — die Detailfläche
  /// sagt, was fehlt. Eine Kachel, die auf nichts reagiert, sähe wie ein
  /// Fehler aus.
  final PurchaseBlock? block;
  final VoidCallback onTap;

  /// Wie stark ein Stück verblasst, das gerade nicht zu kaufen ist.
  ///
  /// Derselbe Weg wie beim gesperrten Bereichskreis: Eine Zeichnung
  /// lässt sich nicht grau färben, ohne sie zu ruinieren, sie wird
  /// deshalb blasser.
  static const double outOfReachOpacity = 0.4;

  bool get isLocked => block == PurchaseBlock.gesperrt;

  /// Gesperrt oder zu teuer — was man mit einem Tipp nicht kaufen kann.
  /// Was schon gehört, fällt nicht darunter: Es hat einen Zustand, keinen
  /// Preis.
  bool get isOutOfReach =>
      block == PurchaseBlock.gesperrt || block == PurchaseBlock.zuWenigGold;

  /// Abstand zwischen zwei Kacheln.
  static const double gap = 10;

  /// Wie breit der helle Ring um die gewählte Kachel ist. Schmaler als
  /// der halbe [gap], sonst berührten sich zwei Ringe.
  static const double wahlRing = 3;

  /// Wie viele Kacheln nebeneinander stehen.
  ///
  /// Drei sind bei 390 Pixeln Breite die letzte Zahl, bei der ein
  /// Itemname noch in zwei Zeilen passt. Bei vieren bricht
  /// „Schuppenpanzer" mitten im Wort.
  static const int columns = 3;

  /// Wie breit eine Kachel in einem [rowWidth] Pixel breiten Raster wird.
  static double sideFor(double rowWidth) {
    return (rowWidth - gap * (columns - 1)) / columns;
  }

  @override
  Widget build(BuildContext context) {
    final item = copy.item;
    if (item == null) return const SizedBox.shrink();
    final bild = GearIcons.forItemId(item.id);

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.name,
      child: Druck(
        // **Der Rahmen gehört der Seltenheit, die Wahl liegt außen
        // herum.** Bis zum 01.10. färbte die Wahl den Rand selbst; dann
        // hätte das gewählte Stück als einziges seine Seltenheit
        // verloren.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: <BoxShadow>[
              if (isSelected)
                const BoxShadow(
                  color: Palette.textOnDark,
                  spreadRadius: wahlRing,
                ),
            ],
          ),
          child: Material(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: RarityBadge.rahmenOf(item.rarity),
                    width: RarityBadge.rahmenBreite,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Opacity(
                        opacity: isOutOfReach ? outOfReachOpacity : 1,
                        child: bild == null
                            ? Icon(
                                GearIcons.fallbackFor(item.slot),
                                size: 30,
                                color: isOwned
                                    ? Palette.muted
                                    : Palette.textDim,
                              )
                            : Image.asset(
                                bild,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                                errorBuilder: (context, error, stack) => Icon(
                                  GearIcons.fallbackFor(item.slot),
                                  size: 30,
                                  color: Palette.muted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                        // Die Farbe der Seltenheit, auch wenn das Stück
                        // gerade nicht zu haben ist: Dass es nicht geht,
                        // sagen das blasse Bild und die Fußnote.
                        color: RarityBadge.colorOf(item.rarity),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // **Preis oder Besitz, nie beides.** Was einem gehört,
                    // hat keinen Preis mehr — es hat einen Zustand.
                    _fussnote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Getragen ein Haken, gesperrt ein Schloss, sonst Münze und Preis.
  Widget _fussnote() {
    if (isEquipped) {
      return const Icon(
        Icons.check_circle,
        size: 14,
        color: Palette.success,
        semanticLabel: 'getragen',
      );
    }
    // Im Inventar steht die Güte des Wurfs, im Laden der Preis.
    if (isOwned) {
      return Text(
        CopyText.quality(copy),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Palette.muted,
        ),
      );
    }
    if (isLocked) {
      return const Icon(
        Icons.lock,
        size: 14,
        color: Palette.muted,
        semanticLabel: 'gesperrt',
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const GoldIcon(size: 12),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '${copy.paid}',
            semanticsLabel: '${copy.paid} Gold',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOutOfReach ? Palette.muted : Palette.gold,
            ),
          ),
        ),
      ],
    );
  }
}
